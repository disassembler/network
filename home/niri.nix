{
  inputs,
  config,
  pkgs,
  lib,
  hostname ? null,
  ...
}: let
  niri = "${config.programs.niri.package}/bin/niri";
in {
  # Use the unstable niri package from your inputs
  programs.niri.package = inputs.niri.packages.x86_64-linux.niri-unstable;

  programs.niri.settings = {
    prefer-no-csd = true;

    # Modernized startup sequence for a full desktop experience
    spawn-at-startup = [
      {command = ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"];}
      {command = ["${pkgs.waybar}/bin/waybar"];}
      {command = ["${pkgs.mako}/bin/mako"];} # Notification daemon
      {command = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"];} # Auth agent
      {command = ["swww-daemon"];}
      # This sets the image immediately after the daemon starts
      {command = ["swww" "img" "~/images/background.png"];}
    ];

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    animations.slowdown = 0.5;

    environment = {
      DISPLAY = ":0";
      QT_QPA_PLATFORM = "wayland";
    };

    input = {
      keyboard = {
        xkb.layout = "en,us";
        track-layout = "global";
      };

      # Optimized for laptop/trackpad usage
      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = true; # Disable-while-typing
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
      workspace-auto-back-and-forth = true;
    };

    layout = {
      gaps = 12;
      center-focused-column = "on-overflow";

      # Visual focus indicators
      border = {
        enable = true;
        width = 2;
        active.color = "#504945";
        inactive.color = "#3c3836";
      };

      focus-ring.enable = false;

      shadow = {
        enable = true;
        color = "#0007";
        softness = 20;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
      };

      preset-column-widths = [
        {proportion = 1.0 / 2.0;}
        {proportion = 1.0 / 3.0;}
        {proportion = 1.0 / 4.0;}
      ];
    };

    window-rules = [
      {
        matches = [{app-id = "^com\.mitchellh\.ghostty$";}];
        draw-border-with-background = false;
      }
      {
        matches = [{app-id = "^lobster$";}];
        open-floating = true;
      }
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
      }
      {
        # Utility windows that should always float
        matches = [
          {app-id = "pavucontrol";}
          {app-id = "gnome-calculator";}
          {app-id = "org.gnome.Nautilus";}
          {app-id = "blueman-manager";}
        ];
        open-floating = true;
      }
    ];

    binds = let
      inherit
        (config.lib.niri.actions)
        center-column
        close-window
        consume-or-expel-window-left
        consume-or-expel-window-right
        consume-window-into-column
        expand-column-to-available-width
        expel-window-from-column
        focus-column-first
        focus-column-last
        focus-column-left
        focus-column-right
        focus-window-down
        focus-window-up
        focus-workspace
        focus-workspace-down
        focus-workspace-up
        focus-workspace-previous
        fullscreen-window
        maximize-column
        move-column-left
        move-column-right
        move-column-to-first
        move-column-to-last
        move-column-to-workspace-down
        move-column-to-workspace-up
        move-window-down
        move-window-up
        move-workspace-down
        move-workspace-up
        power-off-monitors
        quit
        reset-window-height
        set-column-width
        set-window-height
        show-hotkey-overlay
        spawn
        switch-focus-between-floating-and-tiling
        switch-layout
        switch-preset-column-width
        switch-preset-window-height
        toggle-column-tabbed-display
        toggle-keyboard-shortcuts-inhibit
        toggle-window-floating
        ;
    in {
      "Mod+Shift+Slash".action = show-hotkey-overlay;
      "Mod+Return".action = spawn "ghostty";
      "Mod+D".action = spawn "fuzzel";
      "Mod+Tab".action = focus-workspace-previous;

      # Audio & Brightness
      "XF86AudioRaiseVolume" = {
        action = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
        allow-when-locked = true;
      };
      "XF86MonBrightnessUp".action = spawn "light -A 10";
      "XF86MonBrightnessDown".action = spawn "light -U 10";

      "Mod+Shift+C".action = close-window;

      # Navigation (Vim Bindings)
      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+L".action = focus-column-right;

      # Moving Windows
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+L".action = move-column-right;

      # Workspace Control
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      # Window & Column Sizing
      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+C".action = center-column;
      "Mod+V".action = toggle-window-floating;
      "Mod+W".action = toggle-column-tabbed-display;

      # Session Management
      "Mod+Shift+E".action = quit;
      "Mod+Shift+M".action = power-off-monitors;
      "Mod+Escape" = {
        allow-inhibiting = false;
        action = toggle-keyboard-shortcuts-inhibit;
      };
    };
  };

  # Host-specific settings for iviron
  programs.niri.settings.outputs = lib.optionalAttrs (hostname == "iviron") {
    "0-eDP-2" = {
      name = "eDP-2";
      focus-at-startup = true;
      position = {
        x = 0;
        y = 0;
      };
      mode = {
        width = 2560;
        height = 1600;
      };
      scale = 1.5;
    };
    "HDMI-A-1" = {
      position = {
        x = 1706;
        y = 0;
      };
      mode = {
        width = 1920;
        height = 1080;
      };
    };
  };
}
