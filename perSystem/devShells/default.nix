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
          config.treefmt.build.wrapper
          inputs.cardano-parts.packages.x86_64-linux.cardano-node
        ];
      };
  };
}
