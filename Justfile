set shell := ["bash", "-uc"]
set positional-arguments

# List all just recipes available
default:
  @just --list

# Deploy select machines
apply machine:
  colmena apply --verbose --on {{machine}}

# Build a nixos configuration
build-machine MACHINE *ARGS:
  nix build -L .#nixosConfigurations.{{MACHINE}}.config.system.build.toplevel {{ARGS}}

# Build a nixos installer iso
build-iso MACHINE *ARGS:
  nix build -L .#nixosConfigurations.{{MACHINE}}.config.system.build.isoImage {{ARGS}}

# Build all nixosConfigurations
build-machines *ARGS:
  #!/usr/bin/env nu
  let nodes = (nix eval --json '.#nixosConfigurations' --apply builtins.attrNames | from json)
  for node in $nodes {just build-machine $node {{ARGS}}}

provision-disko machine ip:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "--- Partitioning and Formatting ---"
  # Build the script locally and store the path
  DISKO_SCRIPT=$(nix build .#nixosConfigurations.{{machine}}.config.system.build.diskoScript --no-link --print-out-paths)
  
  # Copy the closure and execute
  nix copy --to ssh://root@{{ip}} "$DISKO_SCRIPT"
  ssh root@{{ip}} "$DISKO_SCRIPT"
  export HOSTID="$(ssh root@{{ip}} "$(head -c 8 /etc/machine-id)")"
  echo "Edit configuration.nix and set hostId to $HOSTID"
  echo "Then run: just provision-deploy {{machine}} {{ip}}"

provision-deploy machine ip:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Building and Pushing System Closure ---"
  TOPLEVEL=$(nix build .#nixosConfigurations.{{machine}}.config.system.build.toplevel --no-link --print-out-paths)
  echo "toplevel: $TOPLEVEL"
  nix copy --to ssh://root@{{ip}} "$TOPLEVEL"

  echo "Installing to /mnt ---"
  ssh root@{{ip}} "nixos-install --system $TOPLEVEL --no-root-passwd --no-channel-copy"

  echo "--- Cleaning up ---"
  ssh root@{{ip}} "umount -R /mnt && zpool export zpool"

  echo "--- DONE ---"
  echo "Reboot the machine!"


# Generate age key
generate-age-key:
  #!/usr/bin/env bash
  mkdir -p ~/.config/sops/age
  if [ ! -f ~/.config/sops/age/keys.txt ]; then
    echo "Generating private age key..."
    age-keygen -o ~/.config/sops/age/keys.txt
    echo "Backup ~/.config/sops/age/keys.txt or you will lose access to secrets!!!"
  else
    echo "Not regenerating key because age key already exists!"
  fi
  echo "Your public key is: $(age-keygen -y ~/.config/sops/age/keys.txt)"
