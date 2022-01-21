let
  pkgs_mac = import <nixpkgs> { system = "x86_64-darwin"; };
  pkgs_native = import <nixpkgs> { };
in
rec {
  darwin-tools =
    let
      ghc = pkgs_mac.haskellPackages.ghcWithPackages (ps: [ ps.turtle (pkgs_mac.haskell.lib.dontCheck ps.universum) ps.megaparsec ]);
    in
    pkgs_mac.stdenv.mkDerivation {
      name = "deploy-nix-darwin";
      buildInputs = [ ghc ];
      shellHook = "eval $(egrep ^export ${ghc}/bin/ghc)";
      src = ./nix-darwin-tools;
      installPhase = ''
        mkdir -p $out/bin
        ghc -o patch-prepare patch-prepare.hs
        ghc -o $out/bin/prepare everything.hs
        ln -s prepare $out/bin/nuke-nix
        ./patch-prepare
      '';
    };
  prepare-mac = pkgs_native.writeScriptBin "prepare-mac" ''
    #!${pkgs_native.stdenv.shell}
    set -e
    ssh -t $1 "chmod -R +w darwin-tools; rm -rf darwin-tools" || true
    scp -r ${darwin-tools}/bin $1:darwin-tools
    ssh -t $1 "sudo darwin-tools/nuke-nix"
    ssh -t $1 "darwin-tools/prepare"
  '';
  deploy-darwin =
    let
      ghc = pkgs_native.haskellPackages.ghcWithPackages (ps: [ ps.turtle (pkgs_native.haskell.lib.dontCheck ps.universum) ps.megaparsec ]);
    in
    pkgs_native.stdenv.mkDerivation {
      name = "deploy-darwin";
      buildInputs = [ ghc ];
      shellHook = "eval $(egrep ^export ${ghc}/bin/ghc)";
      src = ./nix-darwin-tools;
      installPhase = ''
        mkdir -p $out/bin
        ghc -o $out/bin/deploy deploy-darwin.hs
      '';
    };
  tools = pkgs_native.buildEnv {
    name = "scripts";
    paths = [ prepare-mac deploy-darwin ];
  };
}
