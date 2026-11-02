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
  #!/run/current-system/sw/bin/env nu
  let nodes = (nix eval --json '.#nixosConfigurations' --apply builtins.attrNames | from json)
  for node in $nodes {just build-machine $node {{ARGS}}}

provision-disko machine ip:
  #!/run/current-system/sw/bin/env bash
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
  #!/run/current-system/sw/bin/env bash
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


# Partial mithril sync on sarov: pull new immutables + ancillary ledger state, convert to LSM
sarov-mithril-sync:
  #!/usr/bin/env bash
  set -euo pipefail

  ssh root@10.40.33.40 'bash -s' << 'SCRIPT'
  set -euo pipefail

  STATE="/var/lib/cardano-node"
  DB="$STATE/db-mainnet"
  STAGING="$STATE/mithril-staging"

  # Ancillary VK for mainnet (from iohk-nix)
  ANCILLARY_VK="5b32332c37312c39362c3133332c34372c3235332c3232362c3133362c3233352c35372c3136342c3130362c3138362c322c32312c32392c3132302c3136332c38392c3132312c3137372c3133382c3230382c3133382c3231342c39392c35382c32322c302c35382c332c36395d"

  systemctl stop cardano-node

  # Query certified snapshot to get end immutable number
  CERTIFIED=$(mithril-client --json cardano-db snapshot show latest | jq -r '.beacon.immutable_file_number')
  echo "Certified immutable end: $CERTIFIED"

  PARTIAL_ARGS=(--start "$CERTIFIED" --end "$CERTIFIED" --allow-override)
  if [ -d "$DB/immutable" ]; then
    LOCAL=$(ls "$DB/immutable"/*.chunk 2>/dev/null | sort -V | tail -1 | xargs basename | sed 's/\.chunk//')
    LOCAL_NUM=$((10#$LOCAL))
    echo "Local immutable tip: $LOCAL_NUM"
    if [ "$LOCAL_NUM" -lt "$CERTIFIED" ]; then
      PARTIAL_ARGS=(--start $((LOCAL_NUM + 1)) --end "$CERTIFIED" --allow-override)
    else
      echo "Local chain ($LOCAL_NUM) >= certified ($CERTIFIED), fetching ancillary only (--start/--end $CERTIFIED)"
    fi
  fi

  if [ -d "$STAGING/db" ]; then
    echo "Staging dir $STAGING/db already exists, skipping mithril download"
  else
    mkdir -p "$STAGING"

    mithril-client \
      --json \
      cardano-db download latest \
      --download-dir "$STAGING" \
      --genesis-verification-key "$GENESIS_VERIFICATION_KEY" \
      --include-ancillary \
      --ancillary-verification-key "$ANCILLARY_VK" \
      "${PARTIAL_ARGS[@]+"${PARTIAL_ARGS[@]}"}"
  fi

  # Merge new immutables into db (cp -n skips existing files)
  if [ -d "$STAGING/db/immutable" ]; then
    echo "Merging new immutables into $DB/immutable/"
    mkdir -p "$DB/immutable"
    find "$STAGING/db/immutable" -maxdepth 1 -type f -exec cp -n {} "$DB/immutable/" \;
  fi

  # Replace volatile with the ancillary volatile
  if [ -d "$STAGING/db/volatile" ]; then
    echo "Replacing volatile"
    rm -rf "$DB/volatile"
    mv "$STAGING/db/volatile" "$DB/volatile"
  fi

  MEM_SNAP=$(find "$STAGING/db/ledger" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)
  if [ -z "$MEM_SNAP" ]; then
    echo "ERROR: no Mem ledger snapshot found in $STAGING/db/ledger" >&2
    exit 1
  fi

  SLOT=$(basename "$MEM_SNAP")
  NODE_SCRIPT=$(systemctl show cardano-node.service --property=ExecStart --value \
    | grep -oP '(?<=path=)[^ ;]+' | head -1)
  CONFIG=$(grep -oP '(?<=--config )\S+' "$NODE_SCRIPT" | tr -d '"\\' | head -1 || true)
  if [ -z "$CONFIG" ]; then
    echo "ERROR: could not find --config in $NODE_SCRIPT" >&2
    exit 1
  fi
  echo "Using config: $CONFIG"

  echo "Converting Mem snapshot at $MEM_SNAP (slot $SLOT) -> LSM"
  snapshot-converter \
    --input-mem            "$MEM_SNAP" \
    --output-lsm-snapshot  "$STAGING/db/ledger/${SLOT}_lsm" \
    --output-lsm-database  "$STAGING/db/lsm" \
    --config               "$CONFIG"

  # Install converted LSM snapshot, clearing stale ledger snapshots
  echo "Installing LSM ledger snapshot"
  rm -rf "$DB/ledger"
  mkdir -p "$DB/ledger"
  mv "$STAGING/db/ledger/${SLOT}_lsm" "$DB/ledger/${SLOT}_lsm"
  touch "$DB/ledger/.lsm_converted"

  # Install LSM database
  echo "Installing LSM database"
  rm -rf "$STATE/lsm-mainnet"
  mv "$STAGING/db/lsm" "$STATE/lsm-mainnet"

  rm -rf "$STAGING"
  chown -R cardano-node:cardano-node "$DB/immutable" "$DB/ledger" "$STATE/lsm-mainnet"
  systemctl start cardano-node
  echo "Done. cardano-node restarted with LSM snapshot at slot $SLOT."
  SCRIPT

# Generate age key
generate-age-key:
  #!/run/current-system/sw/bin/env bash
  mkdir -p ~/.config/sops/age
  if [ ! -f ~/.config/sops/age/keys.txt ]; then
    echo "Generating private age key..."
    age-keygen -o ~/.config/sops/age/keys.txt
    echo "Backup ~/.config/sops/age/keys.txt or you will lose access to secrets!!!"
  else
    echo "Not regenerating key because age key already exists!"
  fi
  echo "Your public key is: $(age-keygen -y ~/.config/sops/age/keys.txt)"
