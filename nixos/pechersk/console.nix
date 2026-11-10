{
  config,
  pkgs,
  lib,
  ...
}: let
  esDE = pkgs.callPackage ./es-de.nix {};
  home = "/var/lib/pechersk";
  lotrSinglePlayer = pkgs.writeText "lotr-single-player.rmp" ''
    input_libretro_device_p1 = "1"
    input_libretro_device_p2 = "0"
    input_libretro_device_p3 = "0"
    input_libretro_device_p4 = "0"
    input_libretro_device_p5 = "0"
    input_libretro_device_p6 = "0"
    input_libretro_device_p7 = "0"
    input_libretro_device_p8 = "0"
    input_remap_port_p1 = "0"
    input_remap_port_p2 = "1"
    input_remap_port_p3 = "2"
    input_remap_port_p4 = "3"
    input_remap_port_p5 = "4"
    input_remap_port_p6 = "5"
    input_remap_port_p7 = "6"
    input_remap_port_p8 = "7"
    input_player1_analog_dpad_mode = "1"
  '';
  # Keep core port 2 assigned: RetroArch disconnects unused core ports,
  # including the Multitap, even when its configured device remains 257.
  # Frontend pads: leader, Pippin, Sam, Merry/Gimli, then Frodo after Aragorn.
  lotrMultiplayer = pkgs.writeText "lotr-multiplayer.rmp" ''
    input_libretro_device_p1 = "1"
    input_libretro_device_p2 = "257"
    input_libretro_device_p3 = "1"
    input_libretro_device_p4 = "1"
    input_libretro_device_p5 = "1"
    input_libretro_device_p6 = "0"
    input_libretro_device_p7 = "0"
    input_libretro_device_p8 = "0"
    input_remap_port_p1 = "0"
    input_remap_port_p2 = "3"
    input_remap_port_p3 = "2"
    input_remap_port_p4 = "4"
    input_remap_port_p5 = "1"
    input_remap_port_p6 = "5"
    input_remap_port_p7 = "6"
    input_remap_port_p8 = "7"
    input_player1_analog_dpad_mode = "1"
    input_player2_analog_dpad_mode = "1"
    input_player3_analog_dpad_mode = "1"
    input_player4_analog_dpad_mode = "1"
    input_player5_analog_dpad_mode = "1"
  '';
  portCommand = "${lib.getExe config.system.build.pecherskPortLauncher} %ROM%";
  systems =
    [
      {
        name = "atari2600";
        label = "Atari 2600";
        core = "stella";
        extensions = ".a26 .bin .rom .zip .7z";
      }
      {
        name = "atari800";
        label = "Atari 800";
        core = "atari800";
        extensions = ".atr .atx .xfd .dcm .cas .xex .car .rom .bin .zip .7z";
      }
      {
        name = "c64";
        label = "Commodore 64";
        core = "vice-x64";
        extensions = ".d64 .d71 .d81 .t64 .tap .crt .prg .p00 .zip .7z";
      }
      {
        name = "mame";
        label = "Arcade";
        core = "mame2003-plus";
        extensions = ".zip .7z .chd";
      }
      {
        name = "gba";
        label = "Game Boy Advance";
        core = "mgba";
        extensions = ".gba .zip .7z";
      }
      {
        name = "megadrive";
        label = "Sega Mega Drive";
        core = "genesis-plus-gx";
        extensions = ".md .gen .bin .smd .zip .7z";
      }
      {
        name = "nes";
        label = "Nintendo Entertainment System";
        core = "nestopia";
        extensions = ".nes .unf .unif .fds .zip .7z";
      }
      {
        name = "pcengine";
        label = "PC Engine";
        core = "beetle-pce-fast";
        extensions = ".pce .cue .ccd .chd .zip .7z";
      }
      {
        name = "psx";
        label = "PlayStation";
        core = "beetle-psx";
        extensions = ".cue .chd .m3u .pbp .ccd .exe";
      }
      {
        name = "snes";
        label = "Super Nintendo";
        core = "snes9x";
        extensions = ".smc .sfc .fig .swc .zip .7z";
      }
      {
        name = "prboom";
        label = "Doom";
        core = "prboom";
        extensions = ".wad";
        theme = "doom";
      }
      {
        name = "n64";
        label = "Nintendo 64";
        extensions = ".z64 .n64 .v64 .zip";
        command = "${pkgs.mupen64plus}/bin/mupen64plus --fullscreen --configdir ${home}/.config/mupen64plus --datadir ${pkgs.mupen64plus}/share/mupen64plus %ROM%";
      }
      {
        name = "gamecube";
        label = "Nintendo GameCube";
        extensions = ".iso .gcm .gcz .ciso .wbfs .rvz .wad .m3u";
        command = "${pkgs.dolphin-emu}/bin/dolphin-emu --batch --exec %ROM%";
      }
      {
        name = "wii";
        label = "Nintendo Wii";
        extensions = ".iso .gcm .gcz .ciso .wbfs .rvz .wad .m3u";
        command = "${pkgs.dolphin-emu}/bin/dolphin-emu --batch --exec %ROM%";
      }
      {
        name = "psp";
        label = "PlayStation Portable";
        extensions = ".iso .cso .pbp .chd";
        command = "${lib.getExe pkgs.ppsspp} --fullscreen %ROM%";
      }
      {
        name = "model3";
        label = "Sega Model 3";
        extensions = ".zip";
        command = "${pkgs.supermodel}/bin/supermodel %ROM% -fullscreen -res=1920,1080";
      }
    ]
    ++ map (s: s // {command = portCommand;}) [
      {
        name = "pcgames";
        label = "PC Games";
        extensions = ".pcgame";
        platform = "pc";
        theme = "ports";
      }
    ];
  cleanEnv = "${pkgs.coreutils}/bin/env -u LD_LIBRARY_PATH -u LD_PRELOAD";
  coreCommand = s: "${lib.getExe pkgs.libretro.${s.core}} --config ${home}/.config/retroarch/retroarch.cfg --appendconfig /etc/pechersk/retroarch-${s.name}.cfg %ROM%";
  xmlEscape = lib.replaceStrings ["&" "<" ">" "\"" "'"] ["&amp;" "&lt;" "&gt;" "&quot;" "&apos;"];
  systemXML = s: ''
    <system>
      <name>${s.name}</name><fullname>${s.label}</fullname>
      <path>${s.path or "/userdata/roms/${s.name}"}</path>
      <extension>${s.extensions} ${lib.toUpper s.extensions}</extension>
      <command label="Pechersk">${xmlEscape "${cleanEnv} ${s.command or (coreCommand s)}"}</command>
      ${lib.optionalString (s.name == "mame") ''<command label="Current MAME">${xmlEscape "${cleanEnv} ${lib.getExe pkgs.libretro.mame} --config ${home}/.config/retroarch/retroarch.cfg --appendconfig /etc/pechersk/retroarch-mame.cfg %ROM%"}</command>''}
      <platform>${s.platform or s.name}</platform><theme>${s.theme or s.name}</theme>
    </system>
  '';
  systemsXML = pkgs.writeText "es_systems.xml" ''
    <?xml version="1.0"?>
    <!-- Use only the systems managed here; bundled definitions resurrect Ports. -->
    <loadExclusive/>
    <systemList>
      ${lib.concatMapStringsSep "\n" systemXML (builtins.filter (s: s.name != "prboom") systems)}
      <system>
        <name>pechersk</name><fullname>Console tools</fullname>
        <path>${home}/tools</path><extension>.tool</extension>
        <command>${cleanEnv} ${consoleTool}/bin/pechersk-tool %ROM%</command>
        <platform>ignore</platform><theme>desktop</theme>
      </system>
    </systemList>
  '';
  consoleTool = pkgs.writeShellApplication {
    name = "pechersk-tool";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      case "$(basename "$1" .tool)" in
        Bluetooth) exec ${lib.getExe config.system.build.pecherskBluetooth} ;;
        Wi-Fi) exec ${pkgs.networkmanagerapplet}/bin/nm-connection-editor ;;
        Audio) exec ${pkgs.pavucontrol}/bin/pavucontrol ;;
        Kodi) exec ${pkgs.kodi}/bin/kodi ;;
        Music) exec ${lib.getExe config.system.build.pecherskMusic} toggle ;;
        Shutdown) exec ${pkgs.systemd}/bin/systemctl poweroff ;;
        Restart) exec ${pkgs.systemd}/bin/systemctl reboot ;;
        *) echo "Unknown console tool" >&2; exit 1 ;;
      esac
    '';
  };
  importer = pkgs.writeShellApplication {
    name = "pechersk-import-batocera";
    runtimeInputs = with pkgs; [rsync xmlstarlet coreutils findutils];
    text = builtins.readFile ./import-batocera.sh;
  };
  # Current SDL orders BTN_GAMEPAD before the Atari KEY_MENU/BACK/HOMEPAGE keys.
  # Captured on this host: bottom physical A=0, actual Start=8 (not source 4/0).
  sdlMapping = lib.concatMapStringsSep "\n" (guid: "${guid},Atari VCS Modern Controller,a:b0,b:b1,x:b2,y:b3,back:b9,guide:b10,start:b8,leftstick:b6,rightstick:b7,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:+a5,righttrigger:+a4,platform:Linux,") [
    "05000000503200000210000000000000"
    # SDL 2.32 includes the controller-name CRC in the GUID on this host.
    "0500d25b503200000210000000000000"
    "03000000503200000210000000000000"
  ];
  session = pkgs.writeShellApplication {
    name = "pechersk-session";
    runtimeInputs = with pkgs; [coreutils gawk xset xrandr];
    text = ''
      export SDL_GAMECONTROLLERCONFIG='${sdlMapping}'
      export QT_QPA_PLATFORM=xcb
      xset s off
      xset -dpms
      output=$(xrandr --query | awk '/ connected/ {print $1; exit}')
      if [ -n "$output" ]; then
        xrandr --output "$output" --mode 1920x1080 --rate 60 || true
      fi
      ${pkgs.openbox}/bin/openbox &
      wm=$!
      trap 'kill "$wm" 2>/dev/null || true' EXIT
      ${pkgs.unclutter-xfixes}/bin/unclutter --timeout 2 &
      # Give the user sound server time to enumerate HDMI. Initialize once only.
      if [ ! -f "$HOME/.audio-initialized" ]; then
        for _attempt in $(seq 1 20); do
          if ${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gnugrep}/bin/grep -q 'alsa_output.pci-0000_03_00.1.hdmi-stereo'; then
            ${pkgs.pulseaudio}/bin/pactl set-default-sink alsa_output.pci-0000_03_00.1.hdmi-stereo
            ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ 40%
            touch "$HOME/.audio-initialized"
            break
          fi
          sleep 1
        done
      fi
      while true; do
        ${esDE}/bin/es-de --no-update-check || true
        sleep 2
      done
    '';
  };
  mupenController = i: ''
    [Input-SDL-Control${toString i}]
    Version = 2
    mode = 0
    device = ${toString (i - 1)}
    name = "Game Controller"
    plugged = True
    plugin = 2
    mouse = False
    AnalogDeadzone = "328,328"
    AnalogPeak = "32768,32768"
    A Button = "button(0)"
    B Button = "button(2)"
    Start = "button(8)"
    L Trig = "button(4)"
    R Trig = "button(5)"
    Z Trig = "axis(5+)"
    DPad U = "hat(0 Up)"
    DPad D = "hat(0 Down)"
    DPad L = "hat(0 Left)"
    DPad R = "hat(0 Right)"
    X Axis = "axis(0-,0+)"
    Y Axis = "axis(1-,1+)"
    C Button R = "button(1) axis(2+)"
    C Button U = "axis(3-) button(3)"
    C Button D = "axis(3+)"
    C Button L = "axis(2-)"
    Mempak switch = "button(6)"
    Rumblepak switch = "button(7)"
  '';
  dolphinController = i: ''
    [GCPad${toString i}]
    Device = evdev/${toString (i - 1)}/Game Controller
    Buttons/A = `Button 5`
    Buttons/B = `Button 4`
    Buttons/X = `Button 7`
    Buttons/Y = `Button 6`
    Buttons/Z = `Button 9`
    Buttons/Start = `Button 0`
    Main Stick/Left = `Axis 0-`
    Main Stick/Right = `Axis 0+`
    Main Stick/Up = `Axis 1-`
    Main Stick/Down = `Axis 1+`
    C-Stick/Left = `Axis 2-`
    C-Stick/Right = `Axis 2+`
    C-Stick/Up = `Axis 3-`
    C-Stick/Down = `Axis 3+`
    Triggers/L = `Axis 5+`
    Triggers/L-Analog = `Axis 5+`
    Triggers/R = `Axis 4+`
    Triggers/R-Analog = `Axis 4+`
    D-Pad/Left = `Axis 6-`
    D-Pad/Right = `Axis 6+`
    D-Pad/Up = `Axis 7-`
    D-Pad/Down = `Axis 7+`
  '';
  defaults = {
    "ES-DE/settings/es_settings.xml" = pkgs.writeText "es_settings.xml" ''
      <?xml version="1.0"?>
      <string name="ROMDirectory" value="/userdata/roms" />
      <string name="MediaDirectory" value="${home}/ES-DE/downloaded_media" />
      <bool name="LegacyGamelistFileLocation" value="true" />
      <bool name="EnableSounds" value="true" />
      <int name="ScreensaverTimer" value="0" />
      <bool name="ScreensaverControls" value="false" />
      <string name="Theme" value="pechersk-es-de" />
      <bool name="CustomEventScripts" value="true" />
    '';
    ".config/retroarch/retroarch.cfg" = pkgs.writeText "retroarch.cfg" ''
      # Writable defaults; per-system save/BIOS locations are appended at launch.
      menu_driver = "ozone"
      input_driver = "udev"
      input_joypad_driver = "udev"
      input_autodetect_enable = "true"
      joypad_autoconfig_dir = "/etc/pechersk/autoconfig"
      video_driver = "glcore"
      video_fullscreen = "true"
      video_fullscreen_x = "1920"
      video_fullscreen_y = "1080"
      video_vsync = "true"
      video_smooth = "false"
      audio_driver = "pulse"
      audio_latency = "64"
      system_directory = "/userdata/bios"
      core_options_path = "${home}/.config/retroarch/retroarch-core-options.cfg"
      screenshot_directory = "/userdata/screenshots"
      assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets"
      config_save_on_exit = "false"
      quit_press_twice = "false"
      sort_savefiles_enable = "false"
      sort_savestates_enable = "false"
      input_enable_hotkey = "shift"
      input_enable_hotkey_btn = "11"
      input_exit_emulator = "escape"
      input_exit_emulator_btn = "9"
      input_menu_toggle = "f1"
      input_menu_toggle_btn = "1"
      input_save_state = "f3"
      input_save_state_btn = "3"
      input_load_state = "f4"
      input_load_state_btn = "4"
      input_reset_btn = "2"
      input_screenshot_btn = "5"
      input_state_slot_increase_btn = "h0up"
      input_state_slot_decrease_btn = "h0down"
      input_hold_fast_forward_btn = "h0right"
      input_player1_analog_dpad_mode = "1"
      input_player2_analog_dpad_mode = "1"
    '';
    ".config/retroarch/retroarch-core-options.cfg" = ./retroarch-core-options.cfg;
    # Named presets can be loaded live; the game starts with multiplayer.
    ".config/retroarch/remaps/Snes9x/Lord of the Ring.rmp" = lotrMultiplayer;
    ".config/retroarch/remaps/Snes9x/LOTR - Single Player.rmp" = lotrSinglePlayer;
    ".config/retroarch/remaps/Snes9x/LOTR - Multiplayer.rmp" = lotrMultiplayer;
    ".config/retroarch/config/Snes9x/Lord of the Ring.cfg" = pkgs.writeText "lotr-remap-policy.cfg" ''
      remap_save_on_exit = "false"
    '';
    ".config/mupen64plus/mupen64plus.cfg" = pkgs.writeText "mupen64plus.cfg" ''
      [Core]
      Version = 1.01
      ScreenshotPath = "/userdata/screenshots"
      SaveStatePath = "/userdata/saves/n64"
      SaveSRAMPath = "/userdata/saves/n64"
      AutoStateSlotIncrement = True
      [CoreEvents]
      Version = 1
      Joy Mapping Stop = "J0B10/B8"
      Joy Mapping Save State = "J0B10/B2"
      Joy Mapping Load State = "J0B10/B3"
      Joy Mapping Screenshot = "J0B10/B4"
      Joy Mapping Increment Slot = "J0B10/H0V1"
      Kbd Mapping Stop = 27
      [UI-Console]
      Version = 1
      PluginDir = "${pkgs.mupen64plus}/lib/mupen64plus"
      VideoPlugin = "mupen64plus-video-glide64mk2.so"
      AudioPlugin = "mupen64plus-audio-sdl.so"
      InputPlugin = "mupen64plus-input-sdl.so"
      RspPlugin = "mupen64plus-rsp-hle.so"
      [Video-General]
      Version = 1
      Fullscreen = True
      ScreenWidth = 1920
      ScreenHeight = 1080
      VerticalSync = True
      ${mupenController 1}
      ${mupenController 2}
    '';
    ".config/dolphin-emu/GCPadNew.ini" = pkgs.writeText "GCPadNew.ini" (dolphinController 1 + dolphinController 2);
    ".config/dolphin-emu/Dolphin.ini" = pkgs.writeText "Dolphin.ini" ''
      [General]
      ISOPaths = 2
      ISOPath0 = /userdata/roms/wii
      ISOPath1 = /userdata/roms/gamecube
      [Core]
      GFXBackend = OGL
      WiimoteContinuousScanning = True
      SIDevice0 = 6
      SIDevice1 = 6
      [Interface]
      ConfirmStop = False
      SkipNKitWarning = True
      [Display]
      Fullscreen = True
      [Analytics]
      Enabled = False
      PermissionAsked = True
    '';
    ".config/dolphin-emu/WiimoteNew.ini" = pkgs.writeText "WiimoteNew.ini" (lib.concatMapStrings (i: ''
      [Wiimote${toString i}]
      Source = 1
      Device = evdev/${toString (i - 1)}/Game Controller
      Extension = Classic
      Buttons/A = `Button 4`
      Buttons/B = `Button 5`
      Buttons/1 = `Button 6`
      Buttons/2 = `Button 7`
      Buttons/- = `Button 1`
      Buttons/+ = `Button 0`
      Buttons/Home = `Button 2`
      D-Pad/Up = `Axis 7-`
      D-Pad/Down = `Axis 7+`
      D-Pad/Left = `Axis 6-`
      D-Pad/Right = `Axis 6+`
      IR/Up = `Axis 3-`
      IR/Down = `Axis 3+`
      IR/Left = `Axis 2-`
      IR/Right = `Axis 2+`
      Classic/Buttons/A = `Button 5`
      Classic/Buttons/B = `Button 4`
      Classic/Buttons/X = `Button 7`
      Classic/Buttons/Y = `Button 6`
      Classic/Buttons/ZL = `Button 8`
      Classic/Buttons/ZR = `Button 9`
      Classic/Buttons/- = `Button 1`
      Classic/Buttons/+ = `Button 0`
      Classic/Buttons/Home = `Button 2`
      Classic/Left Stick/Up = `Axis 1-`
      Classic/Left Stick/Down = `Axis 1+`
      Classic/Left Stick/Left = `Axis 0-`
      Classic/Left Stick/Right = `Axis 0+`
      Classic/Right Stick/Up = `Axis 3-`
      Classic/Right Stick/Down = `Axis 3+`
      Classic/Right Stick/Left = `Axis 2-`
      Classic/Right Stick/Right = `Axis 2+`
      Classic/Triggers/L = `Axis 5+`
      Classic/Triggers/R = `Axis 4+`
      Classic/D-Pad/Up = `Axis 7-`
      Classic/D-Pad/Down = `Axis 7+`
      Classic/D-Pad/Left = `Axis 6-`
      Classic/D-Pad/Right = `Axis 6+`
    '') [1 2]);
    ".config/dolphin-emu/GFX.ini" = pkgs.writeText "GFX.ini" ''
      [Settings]
      InternalResolution = 1
      MSAA = 0
      [Hardware]
      VSync = True
    '';
    ".config/dolphin-emu/Hotkeys.ini" = pkgs.writeText "Hotkeys.ini" ''
      [Hotkeys]
      Device = evdev/0/Game Controller
      General/Exit = `Button 2` & `Button 0`
      General/Take Screenshot = `Button 2` & `Button 8`
      Save State/Save to Selected Slot = `Button 2` & `Button 6`
      Load State/Load from Selected Slot = `Button 2` & `Button 7`
    '';
  };
in {
  system.build = {
    pecherskFrontend = esDE;
    pecherskImporter = importer;
    pecherskSession = session;
  };
  services = {
    xserver = {
      enable = true;
      videoDrivers = ["modesetting"];
      displayManager.lightdm.enable = true;
      windowManager.session = [
        {
          name = "pechersk";
          start = ''
            ${session}/bin/pechersk-session &
            waitPID=$!
          '';
        }
      ];
    };
    displayManager = {
      defaultSession = "none+pechersk";
      autoLogin = {
        enable = true;
        user = "gamer";
      };
    };
  };
  fonts.packages = [pkgs.dejavu_fonts pkgs.noto-fonts];
  environment.systemPackages = [esDE importer pkgs.retroarch-bare pkgs.mupen64plus pkgs.dolphin-emu pkgs.kodi pkgs.ppsspp pkgs.supermodel pkgs.prismlauncher];
  environment.etc =
    {
      "pechersk/es_systems.xml".source = systemsXML;
      "pechersk/gamecontrollerdb.txt".text = sdlMapping;
      "pechersk/autoconfig/udev/Atari-VCS-Modern.cfg".source = ./controllers/atari-modern.cfg;
    }
    // lib.listToAttrs (map (s: {
      name = "pechersk/retroarch-${s.name}.cfg";
      value.text =
        ''
          savefile_directory = "/userdata/saves/${s.name}"
          savestate_directory = "/userdata/saves/${s.name}"
          system_directory = "/userdata/bios"
        ''
        + lib.optionalString (s.name == "snes") ''
          input_remapping_directory = "${home}/.config/retroarch/remaps"
          rgui_config_directory = "${home}/.config/retroarch/config"
        '';
    }) (builtins.filter (s: s ? core) systems));

  systemd.tmpfiles.rules =
    [
      "d ${home} 0700 gamer gamer -"
      "d ${home}/.config 0700 gamer gamer -"
      "d ${home}/.config/retroarch 0755 gamer gamer -"
      "d ${home}/.config/retroarch/remaps 0755 gamer gamer -"
      "d ${home}/.config/retroarch/remaps/Snes9x 0755 gamer gamer -"
      "d ${home}/.config/retroarch/config 0755 gamer gamer -"
      "d ${home}/.config/retroarch/config/Snes9x 0755 gamer gamer -"
      "d ${home}/.config/mupen64plus 0755 gamer gamer -"
      "d ${home}/.config/dolphin-emu 0755 gamer gamer -"
      "d ${home}/.config/ppsspp 0755 gamer gamer -"
      "d ${home}/.local 0755 gamer gamer -"
      "d ${home}/.local/share 0755 gamer gamer -"
      "d /userdata/saves/dolphin-emu 0775 gamer gamer -"
      "L ${home}/.local/share/dolphin-emu - gamer gamer - /userdata/saves/dolphin-emu"
      "d /userdata/saves/psp 0775 gamer gamer -"
      "d /userdata/saves/psp/PSP 0775 gamer gamer -"
      "L ${home}/.config/ppsspp/PSP - gamer gamer - /userdata/saves/psp/PSP"
      "d ${home}/ES-DE 0755 gamer gamer -"
      "d ${home}/ES-DE/settings 0755 gamer gamer -"
      "d ${home}/ES-DE/custom_systems 0755 gamer gamer -"
      "d ${home}/ES-DE/downloaded_media 0755 gamer gamer -"
      "L+ ${home}/ES-DE/custom_systems/es_systems.xml - gamer gamer - /etc/pechersk/es_systems.xml"
      "d ${home}/tools 0755 gamer gamer -"
      "d /userdata 0775 gamer gamer -"
    ]
    ++ map (d: "d /userdata/${d} 0775 gamer gamer -") ["roms" "bios" "saves" "screenshots" "music" "themes"]
    ++ lib.concatMap (s: ["d /userdata/roms/${s.name} 0775 gamer gamer -" "d /userdata/saves/${s.name} 0775 gamer gamer -"]) systems
    ++ lib.mapAttrsToList (path: src: "C \"${home}/${path}\" 0644 gamer gamer - ${src}") defaults
    ++ map (name: "f ${home}/tools/${name}.tool 0644 gamer gamer - -") ["Bluetooth" "Wi-Fi" "Audio" "Kodi" "Shutdown" "Restart"];
}
