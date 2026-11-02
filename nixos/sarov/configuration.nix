{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  snapshotConverter = inputs.cardano-parts.packages.x86_64-linux.snapshot-converter;
  nodeConfigForConverter = pkgs.writeText "sc-config.json"
    (builtins.toJSON config.services.cardano-node.nodeConfig);
in {
  deployment = {
    targetHost = "10.40.33.40";
    targetPort = 22;
    targetUser = "root";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.requestEncryptionCredentials = [];
  boot.zfs.forceImportRoot = false;
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  nix = {
    settings.sandbox = true;
    settings.cores = 4;
    settings.extra-sandbox-paths = ["/etc/nsswitch.conf" "/etc/protocols"];
    settings.substituters = ["https://cache.nixos.org" "https://cache.iog.io"];
    settings.trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfree = true;
  networking = {
    hostName = "sarov";
    hostId = "d11ab455";
  };

  environment.systemPackages = with pkgs;
  with inputs.cardano-parts.packages.x86_64-linux; [
    openssl
    magic-wormhole
    wget
    vim
    screen
    git
    gnupg
    pinentry-curses
    orchestrator-cli
    cc-sign
    cardano-signer
    tx-bundle
    python3Packages.ipython
    sqlite-interactive
    srm
    jq
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };

  services.cardano-node.extraNodeConfig.ConsensusMode = "GenesisMode";

  # Enable UTxO-HD LSM storage backend (requires kernel >= 6.15, set above).
  services.cardano-node.withUtxoHdLsmt = true;
  services.cardano-node.lsmDatabasePath = "/var/lib/cardano-node/lsm-mainnet";

  services.mithril-client.enable = true;
  # Allow mithril ancillary (ledger snapshot) download for mainnet.
  # Default only includes preprod/preview; mainnet key exists but is opt-in.
  services.mithril-client.allowedAncillary = ["preprod" "preview" "mainnet"];

  systemd.services.cardano-node.after = lib.mkForce ["network-online.target"];

  # Convert mithril-downloaded ancillary (Mem format) to LSM before cardano-node starts.
  systemd.services.cardano-node-lsm-convert = {
    description = "Convert mithril ancillary Mem ledger snapshot to LSM for cardano-node";
    before = ["cardano-node.service"];
    wantedBy = ["cardano-node.service"];

    path = [snapshotConverter];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "cardano-node";
      Group = "cardano-node";
      StateDirectory = "cardano-node";

      ExecStart = pkgs.writeShellScript "cardano-node-lsm-convert" ''
        set -euo pipefail

        DB_DIR="/var/lib/cardano-node/db-mainnet"
        LSM_DIR="/var/lib/cardano-node/lsm-mainnet"
        LEDGER_DIR="$DB_DIR/ledger"
        SENTINEL="$LEDGER_DIR/.lsm_converted"

        if [ -f "$SENTINEL" ]; then
          echo "Ledger snapshot already converted to LSM, skipping"
          exit 0
        fi

        if ! [ -d "$LEDGER_DIR" ]; then
          echo "No ledger directory at $LEDGER_DIR, nothing to convert"
          exit 0
        fi

        SNAPSHOT_DIR=$(find "$LEDGER_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
        if [ -z "$SNAPSHOT_DIR" ]; then
          echo "No ledger snapshot found in $LEDGER_DIR, nothing to convert"
          exit 0
        fi
        SLOT=$(basename "$SNAPSHOT_DIR")

        echo "Converting Mem snapshot at $SNAPSHOT_DIR (slot $SLOT) to LSM..."
        snapshot-converter \
          --input-mem        "$SNAPSHOT_DIR" \
          --output-lsm-snapshot "$LEDGER_DIR/''${SLOT}_lsm" \
          --output-lsm-database "$LSM_DIR" \
          --config           "${nodeConfigForConverter}"

        rm -rf "$SNAPSHOT_DIR"
        touch "$SENTINEL"
        echo "Conversion complete; LSM database at $LSM_DIR"
      '';
    };
  };

  services.trezord.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="2b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="3b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="4b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1807", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1808", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0004", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2c97"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2581"
  '';

  services.openssh = {
    settings.PasswordAuthentication = false;
    enable = true;
  };

  users.users.root = {
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
    shell = pkgs.lib.mkOverride 50 "${pkgs.bashInteractive}/bin/bash";
  };

  system.stateVersion = "20.09";
}
