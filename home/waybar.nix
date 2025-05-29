{pkgs, ...}: {
  programs = {
    waybar = {
      enable = true;
      systemd.enable = true;

      settings = [
        {
          id = "top";
          height = 32;
          margin-top = 4;
          margin-left = 4;
          margin-right = 4;
          name = "top";
          layer = "top";

          modules-right = [
            "tray"
            "disk"
            "memory"
            "cpu"
            "network"
            "pulseaudio"
            "idle_inhibitor"
            "clock"
          ];

          modules-center = [
            "niri/window"
          ];

          modules-left = [
            "niri/workspaces"
          ];

          "niri/window" = {
            format = "{}";
            separate-outputs = true;
          };

          "niri/workspaces" = {
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
              "10" = "10";
            };
          };

          "clock" = {
            format = "{:%e %B %H:%M}";
            tooltip = true;
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
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

          backlight = {
            device = "intel_backlight";
            format = "{icon}";
            format-icons = [
              "󰃜"
              "󰃛"
              "󰃚"
            ];
            on-scroll-up = "exec brightnessctl set 5%+";
            on-scroll-down = "brightnessctl set 5%-";
            states = {
              low = 0;
              mid = 50;
              high = 75;
            };
            smooth-scrolling-threshold = 1;
          };

          pulseaudio = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{icon} {volume}% {format_source}";
            format-bluetooth-muted = "󰖁 {format_source}";
            format-muted = "󰖁 {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            on-click = "${pkgs.ponymix}/bin/ponymix -N -t sink toggle";
            on-click-right = "${pkgs.ponymix}/bin/ponymix -N -t source toggle";
            format-icons = {
              car = "";
              default = ["🔈" "🔉" "🔊"];
              handsfree = "";
              headphones = "";
              headset = "";
              phone = "";
              portable = "";
            };
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
      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family:
            "Roboto Mono for Powerline",
            "FontAwesome6Free",
            "PowerlineExtraSymbols"
            ;
          font-size: 14px;
          min-height: 12px;
          margin: 0px;
        }

        #workspaces {
          padding: 0px;
          margin: 0px;
        }

        #workspaces button {
          padding: 0 2px;
          margin: 0px;
          background: transparent;
          border: 1px solid #1b1d1e;
          font-weight: bold;
        }

        #workspaces button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
        }

        #workspaces button.focused {
          background: #00afd7;
        }

        #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
          padding: 0 3px;
          margin: 0 2px;
        }

        #network.disconnected { background: #f53c3c; }
        #pulseaudio.muted { }
      '';
    };
  };
}
