{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = {
    airgap = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ../../nixos/airgap/configuration.nix
      ];
      specialArgs = {
        inherit self inputs;
        system = "x86_64-linux";
      };
    };
    installer = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ../../nixos/installer/configuration.nix
      ];
      specialArgs = {
        inherit self inputs;
        system = "x86_64-linux";
      };
    };
    installeriso = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ../../nixos/installeriso/configuration.nix
      ];
      specialArgs = {
        inherit self inputs;
        system = "x86_64-linux";
      };
    };
  };
}
