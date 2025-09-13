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
