{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.profiles.vim;
  nvim = pkgs.neovim.override {
    vimAlias = true;
    configure = (import ./vim/customization.nix { pkgs = pkgs; });
  };
in {
  options.profiles.vim = {
    enable = mkEnableOption "enable vim profile";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ 
      nvim
      pkgs.ctags
      pkgs.python
      pkgs.python35Packages.neovim
    ];
  };
}
