{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    unfreePkgs = import pkgs.path {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages = {
      inherit (unfreePkgs) mongodb mongosh mongodb-ce;
    };
  };
}
