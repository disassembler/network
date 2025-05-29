{ lib, hyprland, hy3, pkgs, ... }: {
  systemd.user.services.waybar.Service.Environment = [
    "PATH=${lib.makeBinPath [pkgs.hyprland]}"
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      debug = {
        disable_logs = false;
        enable_stdout_logs = true;
      };
      "$mod" = "SUPER";
      "$terminal" = "${pkgs.kitty}/bin/kitty";
      "$menu" = "${pkgs.wofi}/bin/wofi  --show drun";

      exec-once = [
        ''${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.clipman}/bin/clipman store --max-items=50''
        ''${pkgs.swayidle}/bin/swayidle -w timeout 3600 "${pkgs.sway}/bin/swaymsg 'output * dpms off'" resume "${pkgs.sway}/bin/swaymsg 'output * dpms on'"''
      ];
      bind = [
        "$mod      , Return    , exec, ${pkgs.ghostty}/bin/ghostty"
        "$mod      , D         , exec, ${pkgs.rofi-wayland}/bin/rofi -show run"
        "$mod SHIFT, C         , killactive,"
        "$mod SHIFT, E         , exit,"
        "$mod SHIFT, Space     , togglefloating,"
        "$mod      , P         , pseudo," # dwindle
        "$mod      , I         , togglesplit," # dwindle
        "$mod      , F         , fullscreen, 0"
        "$mod      , H         , movefocus, l"
        "$mod      , L         , movefocus, r"
        "$mod      , K         , movefocus, u"
        "$mod      , J         , movefocus, d"
        "$mod SHIFT, H         , movewindow, l"
        "$mod SHIFT, L         , movewindow, r"
        "$mod SHIFT, K         , movewindow, u"
        "$mod SHIFT, J         , movewindow, d"
        "$mod      , N         , cyclenext"
        "$mod      , P         , layoutmsg, cycleprev"
        "$mod      , U         , focusurgentorlast"
        "$mod      , 1         , workspace, 1"
        "$mod      , 2         , workspace, 2"
        "$mod      , 3         , workspace, 3"
        "$mod      , 4         , workspace, 4"
        "$mod      , 5         , workspace, 5"
        "$mod      , 6         , workspace, 6"
        "$mod      , 7         , workspace, 7"
        "$mod      , 8         , workspace, 8"
        "$mod      , 9         , workspace, 9"
        "$mod      , 0         , workspace, 10"
        "$mod SHIFT, 1         , movetoworkspace, 1"
        "$mod SHIFT, 2         , movetoworkspace, 2"
        "$mod SHIFT, 3         , movetoworkspace, 3"
        "$mod SHIFT, 4         , movetoworkspace, 4"
        "$mod SHIFT, 5         , movetoworkspace, 5"
        "$mod SHIFT, 6         , movetoworkspace, 6"
        "$mod SHIFT, 7         , movetoworkspace, 7"
        "$mod SHIFT, 8         , movetoworkspace, 8"
        "$mod SHIFT, 9         , movetoworkspace, 9"
        "$mod SHIFT, 0         , movetoworkspace, 10"
        "$mod      , mouse_down, workspace, e+1"
        "$mod      , mouse_up  , workspace, e-1"
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      monitor = [
        ",preferred,auto,auto"
      ];
      # unscale XWayland
      xwayland = {
        force_zero_scaling = false;
      };
      # toolkit-specific scale
      env = [
        "HYPRCURSOR_SIZE,24"
        "XCURSOR_SIZE,24"
        "AQ_DRM_DEVICES,/dev/dri/card1"
      ];
      input = {
        kb_layout = "us";
      };
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing  = false;
        layout = "dwindle";
      };
      master = {
        always_center_master = true;
        orientation = "center";
        mfact = 0.4;
      };
      decoration = {
        rounding = 10;
        # drop_shadow = "yes";
        # shadow_range = 4;
        # shadow_render_power = 3;
        # col.shadow = "rgba(${colors.base06}ee)";
      };
      animations = {
        enabled = "yes";
        animation = [
          "windows, 1, 4, default, slide"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      dwindle = {
        pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "yes"; # you probably want this
      };
      master = {
        # no_gaps_when_only = true;
      };
      input = {
        mouse_refocus = false;
        #repeat_delay = 150;
        #repeat_rate = 30;
        follow_mouse = 1;
        sensitivity = 0;
      };
      windowrulev2 = [
        "float,class:(com.nextcloud.desktopclient.nextcloud)"
        "size 400 800,class:(com.nextcloud.desktopclient.nextcloud)"
        "move 100%-412 44,class:(com.nextcloud.desktopclient.nextcloud)"
      ];
    };
  };
  programs = {
    waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          id = "top";
          height = 0;
          margin = "0px 0px 0p 0px";
          name = "top";
          layer = "top";
          position = "left";
          reload_style_on_change = true;
          modules-right = [
            "tray"
            "disk"
            "memory"
            "cpu"
            "network"
            "pulseaudio"
            "idle_inhibitor"
            "clock#1"
          ];
          modules-center = [
            "hyprland/window"
          ];
          modules-left = [
            "hyprland/workspaces"
          ];
          "hyprland/window" = {
            format = "{}";
            separate-outputs = true;
            rotate = 90;
          };
          "hyprland/workspaces" = {
            disable-scroll = false;
            alphabetical_sort = true;
            format = "{icon}";
            persistent_workspaces = builtins.listToAttrs (
              builtins.genList
              (i: {
                name = toString (i + 1);
                value = {};
              })
              10
            );
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
            };
          };
          "clock#1" = {
            format = "{:%a %d %b %H:%M}";
            tooltip = true;
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            rotate = 90;
          };
          network = {
            format = "{icon}";
            format-icons = {
              wifi = [
                "󰖩"
              ];
              ethernet = [
                "󰈀"
              ];
              disconnected = [
                "󰈂"
              ];
            };
            format-alt-click = "click-right";
            format-wifi = "󰖩";
            format-ethernet = "󰈀";
            format-disconnected = "󰖪";
            tooltip-format = "{ifname} via {gwaddr}";
            tooltip-format-wifi = "    {essid} 󰘊\n{ipaddr} {signalStrength}%";
            tooltip-format-ethernet = "{ifname} {ipaddr} 󰈀";
            tooltip-format-disconnected = "Disconnected";
            on-click = "gnome-control-center network";
            tooltip = true;
          };
          pulseaudio = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{icon} {volume}% {format_source}";
            format-bluetooth-muted = "󰖁 {format_source}";
            format-icons = {
              car = "";
              default = ["🔈" "🔉" "🔊"];
              handsfree = "";
              headphones = "";
              headset = "";
              phone = "";
              portable = "";
            };
            format-muted = "󰖁 {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            on-click = "${pkgs.ponymix}/bin/ponymix -N -t sink toggle";
            on-click-right = "${pkgs.ponymix}/bin/ponymix -N -t source toggle";
            rotate = 90;
          };
          # cpu = {
          #   interval = 10;
          #   format = "";
          #   format-alt-click = "click-right";
          #   on-click = "~/.config/waybar/custom/stats.sh cpu";
          #   states = {
          #     low = 0;
          #     mid = 25;
          #     high = 50;
          #   };
          # };
          cpu = {
            # format = "󰍛 {icon}";
            format = "{icon}";
            format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
            tooltip = false;
            interval = 1;
            # rotate = 90;
            states = {
              low = 0;
              mid = 50;
              high = 75;
            };
          };
          memory = {
            interval = 30;
            format = "";
            tooltip-format = "{used:0.1f}G used\n{avail:0.1f}G available\n{total:0.1f}G total";
            format-alt-click = "click-right";
            on-click = "~/.config/waybar/custom/stats.sh memory";
            states = {
              low = 0;
              mid = 50;
              high = 75;
            };
          };
          disk = {
            interval = 30;
            format = "󰋊";
            format-alt-click = "click-right";
            tooltip-format = "{used} used\n{free} free\n{total} total";
            on-click = "~/.config/waybar/custom/disk_stats.sh";
            path = "/";
            states = {
              low = 0;
              mid = 25;
              high = 50;
            };
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰛐";
              deactivated = "󰛑";
            };
          };
          tray = {
            icon-size = 12;
            spacing = 10;
          };
          "wlr/taskbar" = {
            format = "{icon}";
            sort-by-app-id = true;
            icon-size = 13;
            icon-theme = "Numix-Circle";
            tooltip-format = "{title}";
            on-click = "activate";
            on-click-right = "close";
            markup = true;
            ignore-list = [
              "kitty"
            ];
          };
        }
      ];
      # https://www.nerdfonts.com/cheat-sheet
      #style = ''
      #  * {
      #    border: none;
      #    border-radius: 0;
      #    font-family:
      #      "Roboto Mono for Powerline",
      #      "FontAwesome6Free",
      #      "PowerlineExtraSymbols"
      #      ;
      #    font-size: 18px;
      #    min-height: 14px;
      #    margin: 0px;
      #  }
      #  #workspaces {
      #    padding: 0px;
      #    margin: 0px;
      #  }
      #  #workspaces button {
      #    padding: 0 2px;
      #    margin: 0px;
      #    background: transparent;
      #    border: 1px solid #1b1d1e;
      #    font-weight: bold;
      #  }
      #  #workspaces button:hover {
      #    box-shadow: inherit;
      #    text-shadow: inherit;
      #  }
      #  #workspaces button.focused {
      #    background: #00afd7;
      #  }
      #  #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
      #    padding: 0 3px;
      #    margin: 0 2px;
      #  }
      #  #network.disconnected { background: #f53c3c; }
      #  #pulseaudio.muted { }
      #'';
    };
  };
}
