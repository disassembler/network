{ }:

let
  pkgs = import <nixpkgs> {};
in with (import ./lib.nix { inherit pkgs; });
with pkgs.lib;
let
  defaults = globalDefaults // {
    nixexprinput = "nixos-configs";
    nixexprpath = "release.nix";
    checkinterval = 600;
  };
  nixos-configs = defaults // {
    description = "nixos-configs";
    inputs = {
      nixos-configs = mkFetchGithub "https://github.com/disassembler/network master";
      nixpkgs = mkFetchGithub "https://github.com/nixos/nixpkgs-channels.git nixos-unstable-small";
    };
  };
  jobsetsAttrs = { inherit nixos-configs; };
in {
  jobsets = pkgs.writeText "spec.json" (builtins.toJSON jobsetsAttrs);
}
