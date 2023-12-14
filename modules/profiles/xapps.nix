{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.profiles.xapps;
in
{
  options.profiles.xapps = {
    enable = mkEnableOption "enable xapps";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      slack
      dmenu
      #chromium
      feh
      xpra
      xdg_utils
      xlockmore
      xtrlock-pam
      rxvt_unicode-with-plugins
      xsel
      virt-manager
      xclip
      gnome3.gnome_session
      libnotify
      scrot
      xorg.xbacklight
      remmina
      lxappearance
      xfce.thunar
      claws-mail
    ];
  };
}
