{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.profiles.i3;
  i3StatusBarConfig =
    ''
      general {
        colors = true
        interval = 1
        output_format = i3bar
        color_good = "#2267a5"
        color_degraded = "#8c7f22"
        color_bad = "#be2422"
      }

      order += "disk /"
      order += "wireless wlp2s0"
      order += "cpu_usage"
      order += "battery 0"
      order += "volume master"
      order += "tztime local"

      tztime local {
        format = " Date: %m/%d/%y  Time: %H:%M "
      }

      cpu_usage {
        format = " CPU: %usage "
      }

      disk "/" {
        format = " Disk: %free "
      }

      volume master {
        format = " Vol: %volume "
        device = "default"
        mixer = "Master"
        mixer_idx = 0
      }
    ''
    + (
      if (parameters.machine == "ohrid")
      then ''
        wireless wlp2s0 {
          format_up = " WiFi: %ip %quality %essid %bitrate "
          format_down = " WiFi: (/) "
        }

        battery 0 {
          format = " Power: %status %percentage %remaining left "
          path = "/sys/class/power_supply/BAT0/uevent"
          low_threshold = 20
        }
      ''
      else ""
    );

  i3Lock = pkgs.writeScript "i3-lock.sh" ''
    #!${pkgs.bash}/bin/bash
    ${pkgs.scrot}/bin/scrot /tmp/screen_locked.png
    ${pkgs.imagemagick}/bin/convert /tmp/screen_locked.png -scale 10% -scale 1000% /tmp/screen_locked.png
    ${pkgs.i3lock-color}/bin/i3lock-color 0 -i /tmp/screen_locked.png \
        --insidevercolor=ffffff22 \
        --insidewrongcolor=C6666655 \
        --insidecolor=ffffff22 \
        --ringvercolor=09343Fff \
        --ringwrongcolor=09343Fff \
        --ringcolor=262626ff \
        --textcolor=ffffffff \
        --linecolor=1B465100 \
        --keyhlcolor=1B4651ff \
        --bshlcolor=1B4651ff
  '';
in {
  options.profiles.i3 = {
    enable = mkEnable "Whether to enable i3 profile.";
    primaryMonitor = mkOption {
      description = "Identifier of the primary monitor";
      type = types.str;
      default = "eDP1";
    };

    secondaryMonitor = mkOption {
      description = "Identifier of the secondary monitor";
      type = types.str;
      default = "HDMI1";
    };

    terminal = mkOption {
      description = "Command to start terminal";
      type = types.str;
      default = config.profiles.terminal.command;
    };

    background = mkOption {
      description = "Background image to use";
      type = types.package;
      default = pkgs.fetchurl {
        url = "https://i.redd.it/szkzdvg2lu5x.png";
        sha256 = "0lsrjsbwm5678an31282vp703gkzy1nin2l0v37g240zgxi3d5zq";
      };
    };
  };

  config = mkIf cfg.enable {
    profiles.x11 = {
      enable = true;
      compositor = mkDefault true;
      displayManager = true;
    };

    services.xserver.windowManager.default = mkDefault "i3";
    services.xserver.windowManager.i3 = {
      enable = mkDefault true;
      extraSessionCommands = ''
        ${pkgs.feh}/bin/feh --bg-fill ${cfg.background}
        ${pkgs.dunst}/bin/dunst &
        ${optionalString config.networking.networkmanager.enable "${pkgs.networkmanagerapplet}/bin/nm-applet &"}
        ${optionalString config.hardware.bluetooth.enable "${pkgs.blueman}/bin/blueman-applet &"}
      '';
      configFile = pkgs.writeText "i3.cfg" ''
          # i3 config file (v4)
          #
          # Please see http://i3wm.org/docs/userguide.html for a complete reference!

          set $mod Mod4

          # Font for window titles. Will also be used by the bar unless a different font
          # is used in the bar {} block below.
        font pango:DejaVu Sans Mono 17

          # Before i3 v4.8, we used to recommend this one as the default:
          # font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
          # The font above is very space-efficient, that is, it looks good, sharp and
          # clear in small sizes. However, its unicode glyph coverage is limited, the old
          # X core fonts rendering does not support right-to-left and this being a bitmap
          # font, it doesn’t scale on retina/hidpi displays.

          # Use Mouse+$mod to drag floating windows to their wanted position
          floating_modifier $mod

          # start a terminal
          bindsym $mod+Return exec ${i3}/bin/i3-sensible-terminal

          # kill focused window
          bindsym $mod+Shift+q kill

          # start dmenu (a program launcher)
          bindsym $mod+d exec ${dmenu}/bin/dmenu_run

          # There also is the (new) i3-dmenu-desktop which only displays applications
          # shipping a .desktop file. It is a wrapper around dmenu, so you need that
          # installed.
          # bindsym $mod+d exec --no-startup-id ${i3}/bin/i3-dmenu-desktop

          # change focus
          bindsym $mod+h focus left
          bindsym $mod+j focus down
          bindsym $mod+k focus up
          bindsym $mod+l focus right

          # alternatively, you can use the cursor keys:
          bindsym $mod+Left focus left
          bindsym $mod+Down focus down
          bindsym $mod+Up focus up
          bindsym $mod+Right focus right

          # move focused window
          bindsym $mod+Shift+h move left
          bindsym $mod+Shift+j move down
          bindsym $mod+Shift+k move up
          bindsym $mod+Shift+l move right

          # alternatively, you can use the cursor keys:
          bindsym $mod+Shift+Left move left
          bindsym $mod+Shift+Down move down
          bindsym $mod+Shift+Up move up
          bindsym $mod+Shift+Right move right

          # split in horizontal orientation
          bindsym $mod+bar split h

          # split in vertical orientation
          bindsym $mod+apostrophe split v

          # enter fullscreen mode for the focused container
          bindsym $mod+f fullscreen toggle

          # change container layout (stacked, tabbed, toggle split)
          bindsym $mod+s layout stacking
          bindsym $mod+w layout tabbed
          bindsym $mod+e layout toggle split

          # toggle tiling / floating
          bindsym $mod+Shift+space floating toggle

          # change focus between tiling / floating windows
          bindsym $mod+space focus mode_toggle

          # focus the parent container
          bindsym $mod+a focus parent

          # focus the child container
          #bindsym $mod+d focus child

          # switch to workspace
          bindsym $mod+1 workspace 1
          bindsym $mod+2 workspace 2
          bindsym $mod+3 workspace 3
          bindsym $mod+4 workspace 4
          bindsym $mod+5 workspace 5
          bindsym $mod+6 workspace 6
          bindsym $mod+7 workspace 7
          bindsym $mod+8 workspace 8
          bindsym $mod+9 workspace 9
          bindsym $mod+0 workspace 10

          # move focused container to workspace
          bindsym $mod+Shift+1 move container to workspace 1
          bindsym $mod+Shift+2 move container to workspace 2
          bindsym $mod+Shift+3 move container to workspace 3
          bindsym $mod+Shift+4 move container to workspace 4
          bindsym $mod+Shift+5 move container to workspace 5
          bindsym $mod+Shift+6 move container to workspace 6
          bindsym $mod+Shift+7 move container to workspace 7
          bindsym $mod+Shift+8 move container to workspace 8
          bindsym $mod+Shift+9 move container to workspace 9
          bindsym $mod+Shift+0 move container to workspace 10

          # Pulse Audio controls
          # run pactl list sinks
          bindsym XF86AudioRaiseVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 +5% #increase sound volume
          bindsym XF86AudioLowerVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 -5% #decrease sound volume
          bindsym XF86AudioMute exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-mute 0 toggle # mute sound

          # Sreen brightness controls
          bindsym XF86MonBrightnessUp exec ${xorg.xbacklight}/bin/xbacklight -inc 10 # increase screen brightness
          bindsym XF86MonBrightnessDown exec ${xorg.xbacklight}/bin/xbacklight -dec 10 # decrease screen brightness

          # multimedia keys
          #bindsym XF86AudioPlay  exec "mpc toggle"
          #bindsym XF86AudioStop  exec "mpc stop"
          #bindsym XF86AudioNext  exec "mpc next"
          #bindsym XF86AudioPrev  exec "mpc prev"
          #bindsym XF86AudioPause exec "mpc pause"

          # reload the configuration file
          bindsym $mod+Shift+c reload
          # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
          bindsym $mod+Shift+r restart
          # exit i3 (logs you out of your X session)
          bindsym $mod+Shift+e exec "${i3}/bin/i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

          bindsym --release $mod+z exec "${scrot}/bin/scrot -s ~/screenshots/screenshot-`date +%Y-%m-%d-%H-%M-%s`.png"

          # resize window (you can also use the mouse for that)
          mode "resize" {
                  # These bindings trigger as soon as you enter the resize mode

                  # Pressing left will shrink the window’s width.
                  # Pressing right will grow the window’s width.
                  # Pressing up will shrink the window’s height.
                  # Pressing down will grow the window’s height.
                  bindsym h resize shrink width 10 px or 10 ppt
                  bindsym j resize grow height 10 px or 10 ppt
                  bindsym k resize shrink height 10 px or 10 ppt
                  bindsym l resize grow width 10 px or 10 ppt

                  # same bindings, but for the arrow keys
                  bindsym Left resize shrink width 10 px or 10 ppt
                  bindsym Down resize grow height 10 px or 10 ppt
                  bindsym Up resize shrink height 10 px or 10 ppt
                  bindsym Right resize grow width 10 px or 10 ppt

                  # back to normal: Enter or Escape
                  bindsym Return mode "default"
                  bindsym Escape mode "default"
          }

          bindsym $mod+r mode "resize"

          # Start i3bar to display a workspace bar (plus the system information i3status
          # finds out, if available)
          bar {
                  font termsyn:monospace 8
                  status_command ${i3status}/bin/i3status -c ${
          writeText "i3status-config" i3StatusBarConfig
        }
          }
      '';
    };

    systemd.services."i3lock" = {
      description = "Pre-Sleep i3 lock";
      wantedBy = ["sleep.target"];
      before = ["sleep.target"];
      environment.DISPLAY = ":0";
      serviceConfig.ExecStart = i3Lock;
      serviceConfig.Type = "forking";
    };

    environment.systemPackages = with pkgs; [
      i3status
      acpi
      rofi
      rofi-pass
      st
      xterm
    ];
  };
}
