{
  self,
  inputs,
  lib,
  ...
}: {
  flake.colmena = let
    customModules = import ../modules/modules-list.nix;
    baseModules = [
      {
        imports = [
          ({pkgs, ...}: {
            nix.nixPath = [
              "nixpkgs=${pkgs.path}"
            ];
            nix.package = lib.mkForce inputs.nix.packages.x86_64-linux.nix;
            nix.extraOptions = ''
              experimental-features = nix-command flakes
            '';
            documentation.info.enable = false;
          })
          inputs.sops-nix.nixosModules.sops
        ];
      }
      inputs.nixvim.nixosModules.nixvim
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.extraSpecialArgs = {
          inherit inputs;
        };
      }
    ];
    defaultModules = baseModules ++ customModules;
  in {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };
      specialArgs.inputs = inputs;
    };
    # modules we want on all deployments
    defaults = {...}: {
      imports = defaultModules;
    };

    # laptops
    iviron = {...}: {
      imports = [
        ../nixos/iviron/configuration.nix
        ../nixos/iviron/hardware-configuration.nix
      ];
    };
    irkutsk = {...}: {
      imports = [
        inputs.nixos-hardware.nixosModules.dell-xps-13-9380
        ../nixos/irkutsk/configuration.nix
        ../nixos/irkutsk/hardware-configuration.nix
      ];
    };
    pskov = {...}: {
      imports = [
        ../nixos/pskov/configuration.nix
        ../nixos/pskov/hardware-configuration.nix
      ];
    };
    silouan = {...}: {
      imports = [
        ../nixos/silouan/configuration.nix
        ../nixos/silouan/hardware-configuration.nix
      ];
    };

    # home servers

    portal = {...}: {
      imports = [
        ../nixos/portal/configuration.nix
        ../nixos/portal/hardware-configuration.nix
      ];
    };

    optina = {...}: {
      imports = [
        ../nixos/optina/configuration.nix
        ../nixos/optina/hardware-configuration.nix
      ];
    };

    valaam = {...}: {
      imports = [
        ../nixos/valaam/configuration.nix
        ../nixos/valaam/hardware-configuration.nix
        inputs.wled-sequencer.nixosModules.wled-sequencer
      ];
    };

    kazan = {...}: {
      imports = [
        ../nixos/kazan/configuration.nix
        ../nixos/kazan/hardware-configuration.nix
      ];
    };

    sarov = {...}: {
      imports = [
        ../nixos/sarov/configuration.nix
        ../nixos/sarov/hardware-configuration.nix
      ];
    };

    # production servers

    prod01 = {...}: {
      imports = [
        ../nixos/prod01/configuration.nix
      ];
    };

    prod03 = {...}: {
      imports = [
        ../nixos/prod01/configuration.nix
      ];
    };
  };
  flake.colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
}
