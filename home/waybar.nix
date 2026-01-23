{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings = [
      {
        layer = "top";
        position = "top";
        spacing = 0; # We manage spacing via CSS margins for the "pill" look

        modules-left = ["niri/workspaces" "niri/window"];
        modules-center = ["clock" "mpris"];
        modules-right = ["pulseaudio" "cpu" "memory" "temperature" "battery" "network" "tray"];

        "niri/workspaces" = {
          format = "{index}"; # Just the number/name for a clean look
          format-active = "󰮯 {index}"; # Adds a distinct "focused" icon
        };

        "niri/window" = {
          format = "󰣆 {title}";
          max-length = 30;
          rewrite = {
            "(.*) - Brave" = "󰖟 $1";
          };
        };

        "clock" = {
          format = "󰃭 {:%A, %B %d, %Y %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        "mpris" = {
          format = " {player_icon} {title} ";
          format-paused = " {status_icon} <i>{title}</i> ";
          player-icons = {
            default = "▶";
            google-chrome = "󰖟";
          };
          status-icons = {
            paused = "󰏤";
          };
          max-length = 40;
        };

        "network" = {
          # This uses icons and actual info instead of interface names
          format-wifi = "  {essid} ({ipaddr})";
          format-ethernet = "󰈀  {ipaddr}";
          format-disconnected = "󰖪  Offline";
          tooltip-format = "{ifname} via {gwaddr}";
          max-length = 30;
        };

        "battery" = {
          format = "{icon} {capacity}%";
          format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };

        "cpu" = {format = " {usage}%";};
        "memory" = {format = " {percentage}%";};

        "temperature" = {
          # thermal-zone = 2; # You might need to adjust this for your CPU
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input"; # Standard path for many laptops
          critical-threshold = 80;
          format = "{icon} {temperatureF}°F";
          format-icons = ["" "" ""];
        };

        "custom/power" = {
          # Extracts power in Watts from hwmon7
          exec = "awk '{print $1/1000000 \" W\"}' /sys/class/hwmon/hwmon7/power1_input";
          interval = 5;
          format = "󱐋 {}";
          tooltip = false;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-icons = {default = ["󰕿" "󰖀" "󰕾"];};
        };
      }
    ];

    style = ''
      /* This gives the modules room to breathe away from the screen edges */
      .modules-left {
          margin: 5px 0 0 15px;
      }

      .modules-center {
          margin: 5px 0 0 0;
      }

      .modules-right {
          margin: 5px 15px 0 0;
      }

      #workspaces {
          background: transparent;
      }

      #workspaces button {
          color: #ebdbb2;
          /* Clean underline style */
          border-bottom: 3px solid transparent;
          transition: all 0.3s ease;
      }

      #workspaces button.active {
          color: #ebdbb2;
          border-bottom: 3px solid #458588;
      }

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        font-weight: bold;
        border: none;
      }

      window#waybar {
        background: transparent; /* Makes the main bar invisible */
      }

      /* Base styling for every "Island" */
      #workspaces, #window, #clock, #mpris, #cpu, #memory, #temperature, #pulseaudio, #battery, #network, #tray {
        padding: 0 15px;
        margin: 4px 3px;
        border-radius: 15px;
        background: rgba(69, 133, 136, 0.3);
        color: #ebdbb2;
      }

      #window {
        color: #ebdbb2;
      }

      #clock {
        color: #282828;
      }

      #clock {
          color: #ebdbb3;      /* Light cream text */
      }

      /* Make the icons inside the pills a different color than the text */
      #clock span {
          color: #fabd2f; /* Yellow icon color */
      }

      #pulseaudio {
        color: #282828;
      }
      /* Individual module styling for better separation */
      #cpu, #memory, #temperature, #network, #battery {
          color: #ebdbb2;      /* Gruvbox Light Text */
      }

      /* Specific icon colors to make them "pop" without the big background blocks */
      #cpu { color: #83a598; }      /* Blue icon/text */
      #memory { color: #b8bb26; }   /* Green icon/text */
      #temperature { color: #fabd2f; } /* Yellow icon/text */
      #temperature.critical { color: #fb4934; } /* Red when hot */
      /* 1. The "Invisible" Base State (Startup) */
      #mpris {
          background: none;
          border: none;
          margin: 0;
          padding: 0;
          font-size: 0;
      }

      /* 2. The "Visible" Island State (Active/Paused/Stopped) */
      #mpris.playing,
      #mpris.paused,
      #mpris.stopped {
          background: rgba(69, 133, 136, 0.3);
          border: 1px solid #504945;
          border-radius: 15px;
          padding: 0 15px;
          margin: 4px 3px;
          font-size: 13px; /* Brings the text back */
      }

      /* 3. Text Colors for states */
      #mpris.playing { color: #8ec07c; } /* Aqua */
      #mpris.paused, #mpris.stopped { color: #928374; } /* Muted Gray */

      /* Fix the network pill to match */
      #network {
          color: #d3869b; /* Purple tint */
      }


    '';
  };
}
