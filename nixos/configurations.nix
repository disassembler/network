{ self
, nixpkgs
, sops-nix
, inputs
, nixos-hardware
, cardano-node
  #, cardano-db-sync
, ...
}:
let
  nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
  customModules = import ../modules/modules-list.nix;
  defaultModules = [
    # make flake inputs accessiable in NixOS
    { _module.args.inputs = inputs; }
    {
      imports = [
        ({ pkgs, ... }: {
          nix.nixPath = [
            "nixpkgs=${pkgs.path}"
          ];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          documentation.info.enable = false;
        })
        #./modules/upgrade-diff.nix # TODO: look at these from Mic92
        #./modules/nix-daemon.nix
        #./modules/minimal-docs.nix
        sops-nix.nixosModules.sops
      ] ++ customModules;
    }
  ];
in
{
  #irkutsk = nixosSystem {
  #  system = "x86_64-linux";
  #  modules = defaultModules ++ [
  #    nixos-hardware.nixosModules.dell-xps-13-9380
  #    ./irkutsk/configuration.nix
  #  ];
  #};
  pskov = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./pskov/configuration.nix
    ];
  };
  #optina = nixosSystem {
  #  system = "x86_64-linux";
  #  modules = defaultModules ++ [
  #    ./optina/configuration.nix
  #  ];
  #};
  portal = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./portal/configuration.nix
    ];
  };
  #sarov = nixosSystem {
  #  system = "x86_64-linux";
  #  modules = defaultModules ++ [
  #    cardano-node.nixosModules.cardano-node # no idea why this works here but not in sarov/configuration.nix
  #    ./sarov/configuration.nix
  #  ];
  #};
  #valaam = nixosSystem {
  #  system = "x86_64-linux";
  #  modules = defaultModules ++ [
  #    cardano-node.nixosModules.cardano-node
  #    #cardano-db-sync.nixosModules.cardano-db-sync
  #    ./valaam/configuration.nix
  #  ];
  #};
  prod01 = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./prod01/configuration.nix
    ];
  };
}
