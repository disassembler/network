{ config, pkgs, lib, ... }:

with lib;

{
  options.profiles.tmux.enable = mkEnableOption "tmux profile";

  config = mkIf config.profiles.tmux.enable {
    programs.tmux = {
      enable = true;
      newSession = true;
      extraConfig = builtins.readFile ./tmux.conf;
      terminal = "screen-256color";
    };

  };
}
