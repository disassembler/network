{ self
, flake-utils
, nixpkgs
, sops-nix
, deploy
, colmena
, ...
} @ inputs:
(flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages."${system}";
  in
  {
    minecraft = pkgs.callPackage ./nixos/optina/minecraft-bedrock.nix {};
    omadad = pkgs.callPackage ./modules/services/omadad/package.nix {};
    devShell = pkgs.callPackage ./shell.nix {
      inherit (sops-nix.packages."${pkgs.system}") sops-import-keys-hook ssh-to-pgp sops-init-gpg-key;
      inherit (deploy.packages."${pkgs.system}") deploy-rs;
      inherit (colmena.packages."${pkgs.system}") colmena;
    };
  })) // {
  nixosConfigurations = import ./nixos/configurations.nix (inputs // {
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
