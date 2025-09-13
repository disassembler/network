{ inputs, ... }: {
  perSystem = {config, system, pkgs, lib, ...}: {
    treefmt.projectRootFile = "flake.nix";
  };
}
