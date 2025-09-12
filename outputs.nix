{ self
, flake-utils
, nixpkgs
, nixpkgsLegacy
, sops-nix
, deploy
, colmena
, ...
} @ inputs:
(flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages."${system}";
    legacyPkgs = import inputs.nixpkgsLegacy {
      inherit system;
      config = {
        allowUnfree = true;
        # required for mongodb 3.4
        permittedInsecurePackages = [ "openssl-1.0.2u" ];
      };
    };
    qemu-run-iso = pkgs.writeShellApplication {
      name = "qemu-run-iso";
      runtimeInputs = with pkgs; [ fd qemu_kvm ];

      text = ''
        if fd --type file --has-results 'nixos-.*\.iso' result/iso 2> /dev/null; then
          echo "Symlinking the existing iso image for qemu:"
          ln -sfv result/iso/nixos-*.iso result-iso
          echo
        else
          echo "No iso file exists to run, please build one first, example:"
          echo "  nix build -L .#nixosConfigurations.installeriso.config.system.build.isoImage"
          exit
        fi

        if [ ! -f ./diskroot.img ]; then
          qemu-img create -f qcow2 diskroot.img 10G
          qemu-kvm \
            -smp 2 \
            -m 4G \
            -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
            -drive file=result-iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
            -device ahci,id=achi0 \
            -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
            -device ahci,id=sata \
            -drive id=diskroot,if=none,file="./diskroot.img",format=qcow2 \
            -device ide-hd,bus=sata.0,drive=diskroot
        else
          qemu-kvm \
            -smp 2 \
            -m 4G \
            -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
            -device ahci,id=sata \
            -drive id=diskroot,if=none,file="./diskroot.img",format=qcow2 \
            -device ide-hd,bus=sata.0,drive=diskroot \
            -netdev user,id=net0 -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
            -device VGA,vgamem_mb=128
        fi

      '';
    };
  in
  {
    minecraft = pkgs.callPackage ./nixos/optina/minecraft-bedrock.nix {};
    omadad = legacyPkgs.callPackage ./modules/services/omadad/package.nix {
      mongodb = legacyPkgs.mongodb;
    };
    devShells.default = pkgs.callPackage ./shell.nix {
      inherit (sops-nix.packages."${pkgs.system}") sops-import-keys-hook ssh-to-pgp sops-init-gpg-key;
      inherit (deploy.packages."${pkgs.system}") deploy-rs;
      inherit (colmena.packages."${pkgs.system}") colmena;
      inherit qemu-run-iso;
    };
  })) // {
  nixosConfigurations = import ./nixos/configurations.nix (inputs // {
    inherit self inputs;
  });

  homeConfigurations = import ./home/configurations.nix (inputs // {
    inherit inputs;
  });

  deploy = import ./nixos/deploy.nix (inputs // {
    inherit inputs;
  });
  colmena = import ./nixos/colmena.nix (inputs // {
    inherit inputs;
  });

  #hydraJobs = nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel) self.nixosConfigurations;
  #checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy.lib;
}
