{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.profiles.x11;
in {
  options.profiles.x11 = {
    enable = mkEnableOption "x11 server profile";

    compositor = mkEnableOption "compositor";

    displayManager = mkEnableOption "display manager";

    gtk2 = {
      theme = mkOption {
        description = "GTK2 theme name";
        default = "Clearlooks";
      };

      settings = mkOption {
        description = "Extra settings for gtk2";
        type = types.lines;
        default = "";
      };
    };

    gtk3 = {
      theme = mkOption {
        description = "GTK2 theme name";
        default = "Clearlooks";
      };

      settings = mkOption {
        description = "Extra settings for gtk3";
        type = types.lines;
        default = "";
      };
    };

    qt = {
      theme = mkOption {
        description = "QT theme name";
        type = types.str;
        default = "Fusion";
      };

      settings = mkOption {
        description = "QT theme settings";
        type = types.lines;
        default = "";
      };
    };

    iconTheme = mkOption {
      type = types.str;
      description = "Icon theme name";
      default = "Numix";
    };

    cursorTheme = mkOption {
      type = types.str;
      description = "Cursor theme name";
      default = "Numix";
    };

    Xresources = mkOption {
      description = "Additional xresources";
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = [ pkgs.cantarell_fonts pkgs.ttf_bitstream_vera ];

    services.compton.enable = cfg.compositor;
    services.compton.extraOptions = ''
      opacity-rule = [
        "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'",
        "80:class_g = 'i3bar' && !_NET_WM_STATE@:32a"
      ];
    '';

    services.xserver = {
      enable = true;
      autorun = true;
      exportConfiguration = true;

      layout = "en";

      desktopManager.xterm.enable = false;
      displayManager.slim.enable = mkDefault cfg.displayManager;
    };

    environment.systemPackages = with pkgs; [
      xorg.xauth xorg.xev xsel xfontsel

      # needed for gtk config saving
      gnome3.dconf

      # icons fallback
      gnome3.adwaita-icon-theme
      hicolor_icon_theme

      # gtk engines
      gtk_engines
      gtk-engine-murrine
    ];

    environment.variables = {
      # Set GTK_PATH so that GTK+ can find the Xfce theme engines
      GTK_PATH = ["${config.system.path}/lib/gtk-2.0"];

      # GTK3: add /etc/xdg/gtk-3.0 to search path for settings.ini
      # We use /etc/xdg/gtk-3.0/settings.ini to set the icon and theme name for GTK 3
      XDG_CONFIG_DIRS = ["/etc/xdg"];

      # GTK3: add themes to search path
      XDG_DATA_DIRS = ["${config.system.path}/share"];

      # Find the cursors
      XCURSOR_PATH = ["${config.system.path}/share/icons"];

      # SVG loader for pixbuf (needed for GTK svg icon themes)
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";

			# Set GTK_DATA_PREFIX so that GTK+ can find the themes 
      GTK_DATA_PREFIX = ["${config.system.path}"];

      # Set gtk2 rc file
      GTK2_RC_FILES = [(toString (pkgs.writeText "iconrc" ''
        gtk-theme-name="${cfg.gtk2.theme}"
        gtk-icon-theme-name="${cfg.iconTheme}"
        ${cfg.gtk2.settings}
      ''))];

      GIO_EXTRA_MODULES = [ "${pkgs.gnome3.dconf}/lib/gio/modules" ];
    };

    # Needed for themes and backgrounds
    environment.pathsToLink = [ "/share" ];

    # custom Xresources
    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge /etc/X11/Xresources
    '';

    environment.etc."X11/Xresources" = {
      text = ''
        Xcursor.theme: ${cfg.cursorTheme}

        ${cfg.Xresources}
      '';
      mode = "444";
    };

    # GTK3 global theme (widget and icon theme)
    environment.etc."xdg/gtk-3.0/settings.ini" = {
      text = ''
        [Settings]
        gtk-theme-name=${cfg.gtk3.theme}
        gtk-icon-theme-name=${cfg.iconTheme}
        ${cfg.gtk3.settings}
      '';
      mode = "444";
    };

    # QT4/5 global theme
    environment.etc."xdg/Trolltech.conf" = {
      text = ''
        [Qt]
        style=${cfg.qt.theme}
        ${cfg.qt.settings}
      '';
      mode = "444";
    };

    # set default theme
    themes.numix-solarized.enable = mkDefault true;
  };
}
