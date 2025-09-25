{inputs, ...}: {
  perSystem = {
    config,
    system,
    pkgs,
    lib,
    ...
  }: {
    devShells.default = let
      inherit (inputs.sops-nix.packages."${system}") sops-import-keys-hook ssh-to-pgp sops-init-gpg-key;
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
      };
    in
      pkgs.mkShell
      {
        packages = with pkgs; [
          wireguard-tools
          jq
          age
          ssh-to-age
          pwgen
          just
          nushell
          inputs.colmena.packages.${system}.colmena
          sops-import-keys-hook
          ssh-to-pgp
          sops-init-gpg-key
          treefmtEval.config.package
          inputs.cardano-parts.packages.x86_64-linux.cardano-node
        ];

        shellHook = ''
          if ! [ -f treefmt.toml ]; then
            echo "Copying treefmt.toml"
            cp -f ${treefmtEval.config.build.configFile} treefmt.toml
          else
            if ! $(cmp -s ${treefmtEval.config.build.configFile} treefmt.toml); then
              echo "Re-copying treefmt.toml for an update.  The difference between old and new treefmt.toml is:"
              icdiff treefmt.toml ${treefmtEval.config.build.configFile}
              cp -f ${treefmtEval.config.build.configFile} treefmt.toml
            else
              echo "treefmt.toml is up to date"
            fi
          fi
        '';
      };
  };
}
