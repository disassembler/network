{ self
, nixpkgs
, sops-nix
, inputs
, nixos-hardware
, cardano-node
, nix
  #, cardano-db-sync
, ...
}:
let
  nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
  customModules = import ../modules/modules-list.nix;
  baseModules = [
    {
      imports = [
        ({ pkgs, ... }: {
          nix.nixPath = [
            "nixpkgs=${pkgs.path}"
          ];
          # TODO: remove when switching to 22.05
          nix.package = nixpkgs.lib.mkForce nix.packages.x86_64-linux.nix;
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          documentation.info.enable = false;
        })
        #./modules/upgrade-diff.nix # TODO: look at these from Mic92
        #./modules/nix-daemon.nix
        #./modules/minimal-docs.nix
        sops-nix.nixosModules.sops
      ];
    }
  ];
  defaultModules = baseModules ++ customModules;
in
{
  #irkutsk = nixosSystem {
  #  system = "x86_64-linux";
  #  modules = defaultModules ++ [
  #    nixos-hardware.nixosModules.dell-xps-13-9380
  #    ./irkutsk/configuration.nix
  #  ];
  #  specialArgs = { inherit inputs; };
  #};
  pskov = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./pskov/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  optina = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./optina/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  portal = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./portal/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  sarov = nixosSystem {
    system = "x86_64-linux";
    modules = baseModules ++ [
      cardano-node.nixosModules.cardano-node
      ./sarov/configuration.nix
    ];
    specialArgs = { inherit inputs cardano-node; };
  };
  valaam = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      cardano-node.nixosModules.cardano-node
      #cardano-db-sync.nixosModules.cardano-db-sync
      ./valaam/configuration.nix
    ];
    specialArgs = { inherit inputs cardano-node; };
  };
  prod01 = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./prod01/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  prod03 = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./prod03/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  installer = nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./installer/configuration.nix
    ];
    specialArgs = { inherit inputs; };
  };
  airgap = nixosSystem {
    system = "x86_64-linux";
    modules = baseModules ++ [
      ./airgap/configuration.nix
    ];
    specialArgs = { inherit inputs cardano-node; };
  };
}
