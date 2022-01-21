{ config, lib, ... }:

with lib;

let
  cfg = config.profiles.gitea;
in
{
  options.profiles.gitea = {
    enable = mkEnableOption "enable gitea profile.";
  };

  config = mkIf (cfg.enable) {
    services = {
      gitea = {
        enable = true;
      };
    };
    nixpkgs.config.packageOverrides = pkgs: { gitea = (import gitea/pkg.nix { }); };
  };
}
