{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.profiles.vim;
  inherit (cfg) dev;
  nvim = inputs.neovim-flake.packages.x86_64-linux.neovim;
in
{
  options.profiles.vim = with lib; {
    enable = mkEnableOption "enable vim profile";
    dev = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable development plugins like haskell/js";
    };
  };
  config = {
    environment.systemPackages = [
      nvim
    ];
  };

}
