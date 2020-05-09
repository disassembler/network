{ config, pkgs, lib, ... }:
let
  cfg = config.profiles.vim;
  dev = cfg.dev;
  customization = (import ./vim/customization.nix { inherit pkgs dev; });
  nvim = pkgs.neovim.override {
    vimAlias = true;
    configure = customization;
    extraPython3Packages = ps: [ ps.requests ps.html2text ps.markdown ];
  };
  vim = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig.vam = customization.vam;
    vimrcConfig.customRC = customization.customRC;
  };
in {
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
      pkgs.ctags
      #pkgs.python
      #pkgs.python35Packages.neovim
    ];
  };

}
