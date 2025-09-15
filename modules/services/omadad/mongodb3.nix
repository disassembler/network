{
  stdenv,
  callPackage,
  lib,
  boost,
}: let
  buildMongoDB = callPackage ./mongodb.nix {
    inherit boost;
  };
in
  buildMongoDB {
    version = "3.6.23";
    sha256 = "sha256-EJpIerW4zcGJvHfqJ65fG8yNsLRlUnRkvYfC+jkoFJ4=";
    patches = [./forget-build-dependencies.patch];
  }
