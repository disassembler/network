{
  lib,
  hyprland,
  hy3,
  pkgs,
  ...
}: {
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
        "$mod      , D         , exec, ${pkgs.rofi}/bin/rofi -show run"
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
        allow_tearing = false;
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
}
