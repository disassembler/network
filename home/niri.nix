{
  config,
  pkgs,
  ...
}: let
  niri = "${config.programs.niri.package}/bin/niri";
in {
  programs.niri.settings = {
    prefer-no-csd = true;
    spawn-at-startup = [
      {command = ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"];}
    ];
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    animations.slowdown = 0.5;

    environment = {
      DISPLAY = ":0";
      QT_QPA_PLATFORM = "wayland";
    };

    input = {
      keyboard = {
        xkb = {
          layout = "jp,de";
          options = "caps:ctrl_modifier";
        };

        repeat-delay = 150;
        repeat-rate = 40;
        track-layout = "global";
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
      workspace-auto-back-and-forth = true;
    };

    outputs."DP-1" = {
      scale = 1;

      mode = {
        width = 5120;
        height = 1440;
        refresh = 119.970;
      };

      position = {
        x = 1280;
        y = 0;
      };
    };

    layout = {
      gaps = 1;
      center-focused-column = "on-overflow";
      default-column-width = {};
      border.enable = false;
      struts = {};

      preset-column-widths = [
        {proportion = 1.0 / 2.0;}
        {proportion = 1.0 / 3.0;}
        {proportion = 1.0 / 4.0;}
      ];

      focus-ring = {
        width = 1;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };

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
    };

    window-rules = [
      {
        matches = [{app-id = "^lobster$";}];
        open-floating = true;
      }
      {
        # This regular expression is intentionally made as specific as possible,
        # since this is the default config, and we want no false positives.
        # You can get away with just app-id="wezterm" if you want.
        matches = [{app-id = "^org\.wezfurlong\.wezterm$";}];
        default-column-width = {};
      }
      {
        # This app-id regular expression will work for both:
        # - host Firefox (app-id is "firefox")
        # - Flatpak Firefox (app-id is "org.mozilla.firefox")
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
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
        screenshot
        # screenshot-screen
        # screenshot-window
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
      # Keys consist of modifiers separated by + signs, followed by an XKB key name
      # in the end. To find an XKB name for a particular key, you may use a program
      # like wev.
      #
      # "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
      # when running as a winit window.
      #
      # Most actions that you can bind here can also be invoked programmatically with
      # `niri msg action do-something`.
      # Mod-Shift-/, which is usually the same as Mod-?,
      # shows a list of important hotkeys.
      "Mod+Shift+Slash".action = show-hotkey-overlay;
      # Suggested binds for running programs: terminal, app launcher, screen locker.
      "Mod+Return".action = spawn "ghostty";
      "Mod+D".action = spawn "fuzzel";
      "Super+Alt+L".action = spawn "swaylock";
      "Mod+Tab".action = spawn ["rofi" "-show" "window"];
      # You can also use a shell. Do this if you need pipes, multiple commands, etc.
      # Note: the entire command goes as a single argument in the end.
      # Mod+T { spawn "bash" "-c" "notify-send hello && exec alacritty"; }
      # Example volume keys mappings for PipeWire & WirePlumber.
      # The allow-when-locked=true property makes them work even when the session is locked.
      XF86AudioRaiseVolume = {
        action = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
        allow-when-locked = true;
      };
      XF86AudioLowerVolume = {
        action = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
        allow-when-locked = true;
      };
      XF86AudioMute = {
        action = spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
        allow-when-locked = true;
      };
      XF86AudioMicMute = {
        action = spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
        allow-when-locked = true;
      };

      "Mod+Shift+C".action = close-window;

      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+L".action = focus-column-right;

      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+L".action = move-column-right;
      # Alternative commands that move across workspaces when reaching
      # the first or last window in a column.
      # Mod+J     { focus-window-or-workspace-down; }
      # Mod+K     { focus-window-or-workspace-up; }
      # Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
      # Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action = move-column-to-last;
      # Mod+Ctrl+Left  { focus-monitor-left; }
      # Mod+Ctrl+Down  { focus-monitor-down; }
      # Mod+Ctrl+Up    { focus-monitor-up; }
      # Mod+Ctrl+Right { focus-monitor-right; }
      # Mod+Ctrl+H     { focus-monitor-left; }
      # Mod+Ctrl+J     { focus-monitor-down; }
      # Mod+Ctrl+K     { focus-monitor-up; }
      # Mod+Ctrl+L     { focus-monitor-right; }
      # Mod+Ctrl+Left  { move-column-to-monitor-left; }
      # Mod+Ctrl+Down  { move-column-to-monitor-down; }
      # Mod+Ctrl+Up    { move-column-to-monitor-up; }
      # Mod+Ctrl+Right { move-column-to-monitor-right; }
      # Mod+Ctrl+H     { move-column-to-monitor-left; }
      # Mod+Ctrl+J     { move-column-to-monitor-down; }
      # Mod+Ctrl+K     { move-column-to-monitor-up; }
      # Mod+Ctrl+L     { move-column-to-monitor-right; }
      # Alternatively, there are commands to move just a single window:
      # Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
      # ...
      # And you can also move a whole workspace to another monitor:
      # Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
      # ...

      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+N".action = focus-workspace-down;
      "Mod+P".action = focus-workspace-up;
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+N".action = move-column-to-workspace-down;
      "Mod+Ctrl+P".action = move-column-to-workspace-up;
      # Alternatively, there are commands to move just a single window:
      # Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
      # ...

      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action = move-workspace-up;
      "Mod+Shift+N".action = move-workspace-down;
      "Mod+Shift+P".action = move-workspace-up;
      # You can bind mouse wheel scroll ticks using the following syntax.
      # These binds will change direction based on the natural-scroll setting.
      #
      # To avoid scrolling through workspaces really fast, you can use
      # the cooldown-ms property. The bind will be rate-limited to this value.
      # You can set a cooldown on any bind, but it's most useful for the wheel.
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action = focus-workspace-down;
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action = focus-workspace-up;
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action = move-column-to-workspace-down;
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action = move-column-to-workspace-up;
      };

      "Mod+WheelScrollRight".action = focus-column-right;
      "Mod+WheelScrollLeft".action = focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action = move-column-left;
      # Usually scrolling up and down with Shift in applications results in
      # horizontal scrolling; these binds replicate that.
      "Mod+Shift+WheelScrollDown".action = focus-column-right;
      "Mod+Shift+WheelScrollUp".action = focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;
      # Similarly, you can bind touchpad scroll "ticks".
      # Touchpad scrolling is continuous, so for these binds it is split into
      # discrete intervals.
      # These binds are also affected by touchpad's natural-scroll, so these
      # example binds are "inverted", since we have natural-scroll enabled for
      # touchpads by default.
      # Mod+TouchpadScrollDown { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02+"; }
      # Mod+TouchpadScrollUp   { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02-"; }
      # You can refer to workspaces by index. However, keep in mind that
      # niri is a dynamic workspace system, so these commands are kind of
      # "best effort". Trying to refer to a workspace index bigger than
      # the current workspace count will instead refer to the bottommost
      # (empty) workspace.
      #
      # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
      # will all refer to the 3rd workspace.
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;
      "Mod+Ctrl+1".action = spawn [niri "msg" "action" "move-column-to-workspace" "1"];
      "Mod+Ctrl+2".action = spawn [niri "msg" "action" "move-column-to-workspace" "2"];
      "Mod+Ctrl+3".action = spawn [niri "msg" "action" "move-column-to-workspace" "3"];
      "Mod+Ctrl+4".action = spawn [niri "msg" "action" "move-column-to-workspace" "4"];
      "Mod+Ctrl+5".action = spawn [niri "msg" "action" "move-column-to-workspace" "5"];
      "Mod+Ctrl+6".action = spawn [niri "msg" "action" "move-column-to-workspace" "6"];
      "Mod+Ctrl+7".action = spawn [niri "msg" "action" "move-column-to-workspace" "7"];
      "Mod+Ctrl+8".action = spawn [niri "msg" "action" "move-column-to-workspace" "8"];
      "Mod+Ctrl+9".action = spawn [niri "msg" "action" "move-column-to-workspace" "9"];
      # Alternatively, there are commands to move just a single window:
      # Mod+Ctrl+1 { move-window-to-workspace 1; }
      # Switches focus between the current and the previous workspace.
      # Mod+Tab { focus-workspace-previous; }
      # The following binds move the focused window in and out of a column.
      # If the window is alone, they will consume it into the nearby column to the side.
      # If the window is already in a column, they will expel it out.
      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;
      # Consume one window from the right to the bottom of the focused column.
      "Mod+Comma".action = consume-window-into-column;
      # Expel the bottom window from the focused column to the right.
      "Mod+Period".action = expel-window-from-column;

      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+R".action = reset-window-height;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      # Expand the focused column to space not taken up by other fully visible columns.
      # Makes the column "fill the rest of the space".
      "Mod+Ctrl+F".action = expand-column-to-available-width;

      "Mod+C".action = center-column;
      # Finer width adjustments.
      # This command can also:
      # * set width in pixels: "1000"
      # * adjust width in pixels: "-5" or "+5"
      # * set width as a percentage of screen width: "25%"
      # * adjust width as a percentage of screen width: "-10%" or "+10%"
      # Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
      # set-column-width "100" will make the column occupy 200 physical screen pixels.
      "Mod+Semicolon".action = set-column-width "-5%";
      "Mod+Colon".action = set-column-width "+5%";
      # Finer height adjustments when in column with other windows.
      "Mod+Shift+Semicolon".action = set-window-height "-5%";
      "Mod+Shift+Colon".action = set-window-height "+5%";
      # Move the focused window between the floating and the tiling layout.
      "Mod+V".action = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
      # Toggle tabbed column display mode.
      # Windows in this column will appear as vertical tabs,
      # rather than stacked on top of each other.
      "Mod+W".action = toggle-column-tabbed-display;
      # Actions to switch layouts.
      # Note: if you uncomment these, make sure you do NOT have
      # a matching layout switch hotkey configured in xkb options above.
      # Having both at once on the same hotkey will break the switching,
      # since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
      "Mod+At".action = switch-layout "next";
      # Mod+Shift+Space { switch-layout "prev"; }

      "Print".action = screenshot;
      # "Ctrl+Print".action = screenshot-screen;
      # "Alt+Print".action = screenshot-window;
      # Applications such as remote-desktop clients and software KVM switches may
      # request that niri stops processing the keyboard shortcuts defined here
      # so they may, for example, forward the key presses as-is to a remote machine.
      # It's a good idea to bind an escape hatch to toggle the inhibitor,
      # so a buggy application can't hold your session hostage.
      #
      # The allow-inhibiting=false property can be applied to other binds as well,
      # which ensures niri always processes them, even when an inhibitor is active.
      "Mod+Escape" = {
        allow-inhibiting = false;
        action = toggle-keyboard-shortcuts-inhibit;
      };
      # The quit action will show a confirmation dialog to avoid accidental exits.
      "Mod+Shift+E".action = quit;
      "Ctrl+Alt+Delete".action = quit;
      # Powers off the monitors. To turn them back on, do any input like
      # moving the mouse or pressing any other key.
      "Mod+Shift+M".action = power-off-monitors;
    };
  };
}
