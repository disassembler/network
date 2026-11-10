{
  pkgs,
  lib,
  ...
}: let
  home = "/var/lib/pechersk";
  python = pkgs.python3.withPackages (p: with p; [pygame psutil pyudev evdev]);
  tuxRacer = pkgs.extremetuxracer.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./extreme-tux-racer-keyboard.patch];
  });
  launcher = pkgs.writeShellApplication {
    name = "pechersk-port";
    runtimeInputs = with pkgs; [coreutils rsync crudini gnused patch nix];
    text = ''
      game="$1"
      # Flat frontend aliases retain the original game/data/save locations.
      case "$game" in
        /userdata/roms/pcgames/*.pcgame)
          case "$(basename "$game" .pcgame)" in
            ${lib.concatMapStringsSep "\n" (g: "${g.id}) game=${lib.escapeShellArg "/userdata/roms/${g.system}/${g.path}"} ;;") (import ./pc-games-list.nix)}
            *) echo "Unknown PC game: $game" >&2; exit 2 ;;
          esac
          ;;
      esac
      case "$game" in
        /userdata/roms/prboom/doom1_shareware.wad)
          exec ${lib.getExe pkgs.libretro.prboom} --config ${home}/.config/retroarch/retroarch.cfg \
            --appendconfig /etc/pechersk/retroarch-prboom.cfg "$game"
          ;;
        /userdata/roms/windows/tuxracer/tuxracer.exe)
          export WINEPREFIX="${home}/.local/share/wine-tuxracer"
          export WINEDEBUG=-all
          cd /userdata/roms/windows/tuxracer
          exec ${pkgs.wineWow64Packages.stable}/bin/wine "$game"
          ;;
        /userdata/roms/pygame/retrotrivia/retrotrivia.pygame)
          cd "$(dirname "$game")"
          cache="$HOME/.cache/pechersk/retrotrivia"
          mkdir -p "$cache"
          # Preserve the installed upstream copy and its adjacent assets/modules.
          sed 's/\r$//' "$game" > "$cache/upstream.pygame"
          patch --silent --output="$cache/retrotrivia.pygame" \
            "$cache/upstream.pygame" ${./retrotrivia.patch}
          chmod +x "$cache/retrotrivia.pygame"
          ${pkgs.antimicrox}/bin/antimicrox --hidden --no-tray --eventgen xtest --log-level warn \
            --profile /etc/pechersk/quit.gamecontroller.amgp \
            > "$cache/exit-controller.log" 2>&1 &
          mapper=$!
          # shellcheck disable=SC2329
          cleanup_trivia() {
            kill "$mapper" 2>/dev/null || true
            wait "$mapper" 2>/dev/null || true
            ${pkgs.xdotool}/bin/xdotool keyup Alt_L F4 || true
          }
          trap cleanup_trivia EXIT
          # The adapted upstream script declares dependencies in its Nix header.
          # Pin that header's environment to this deployment's Nixpkgs revision.
          NIX_PATH="nixpkgs=${pkgs.path}" PYTHONPATH="$PWD" "$cache/retrotrivia.pygame"
          exit
          ;;
        /userdata/roms/pygame/pygun/pygun.pygame)
          cd "$(dirname "$game")"
          exec ${python}/bin/python "$game"
          ;;
      esac
      case "$(basename "$game")" in
        SuperTux.port|Sonic-Robo-Blast-2.port|Neverball.port)
          mkdir -p "$HOME/.cache/pechersk"
          case "$(basename "$game")" in
            SuperTux.port)
              state="$HOME/.local/share/pechersk/supertux"
              mkdir -p "$state"
              if [ ! -e "$state/config" ]; then
                cp ${./controllers/supertux-config} "$state/config"
                chmod u+w "$state/config"
              fi
              set -- ${lib.getExe pkgs.supertux} --fullscreen --userdir "$state"
              ;;
            Sonic-Robo-Blast-2.port)
              state="$HOME/.srb2"
              mkdir -p "$state"
              if [ ! -e "$state/.pechersk-atari-v1" ]; then
                if [ -f "$state/config.cfg" ]; then
                  cp -a "$state/config.cfg" "$state/config.cfg.before-pechersk-atari-v1"
                fi
                cat ${./controllers/srb2.cfg} >> "$state/config.cfg"
                touch "$state/.pechersk-atari-v1"
              fi
              set -- ${lib.getExe pkgs.srb2} -opengl -fullscreen
              ;;
            Neverball.port)
              state="$HOME/.neverball"
              mkdir -p "$state"
              if [ ! -e "$state/.pechersk-atari-v1" ]; then
                if [ -f "$state/neverballrc" ]; then
                  cp -a "$state/neverballrc" "$state/neverballrc.before-pechersk-atari-v1"
                fi
                cat ${./controllers/neverballrc} >> "$state/neverballrc"
                touch "$state/.pechersk-atari-v1"
              fi
              set -- ${lib.getExe' pkgs.neverball "neverball"}
              ;;
          esac
          ${pkgs.antimicrox}/bin/antimicrox --hidden --no-tray --eventgen xtest --log-level warn \
            --profile /etc/pechersk/quit.gamecontroller.amgp \
            > "$HOME/.cache/pechersk/$(basename "$game").controller.log" 2>&1 &
          mapper=$!
          # shellcheck disable=SC2329
          cleanup_native() {
            kill "$mapper" 2>/dev/null || true
            wait "$mapper" 2>/dev/null || true
            ${pkgs.xdotool}/bin/xdotool keyup Alt_L F4 || true
          }
          trap cleanup_native EXIT
          "$@"
          exit
          ;;
        SuperTuxKart.sh)
          config="''${XDG_CONFIG_HOME:-$HOME/.config}/supertuxkart/config-0.10"
          mkdir -p "$config"
          # Seed once; later in-game controller adjustments remain writable.
          if [ ! -e "$config/.pechersk-atari-input-v1" ]; then
            if [ -f "$config/input.xml" ]; then
              cp -a "$config/input.xml" "$config/input.xml.before-pechersk-atari-v1"
            else
              printf '<input version="1"/>\n' > "$config/input.xml"
            fi
            ${pkgs.libxslt}/bin/xsltproc ${./controllers/supertuxkart-input.xsl} \
              "$config/input.xml" > "$config/input.xml.pechersk-new"
            mv "$config/input.xml.pechersk-new" "$config/input.xml"
            touch "$config/.pechersk-atari-input-v1"
          fi
          ${pkgs.antimicrox}/bin/antimicrox --hidden --no-tray --eventgen xtest --log-level warn \
            --profile /etc/pechersk/quit.gamecontroller.amgp \
            > "$config/pechersk-exit-controller.log" 2>&1 &
          mapper=$!
          # shellcheck disable=SC2329
          cleanup_tux_kart() {
            kill "$mapper" 2>/dev/null || true
            wait "$mapper" 2>/dev/null || true
            ${pkgs.xdotool}/bin/xdotool keyup Alt_L F4 || true
          }
          trap cleanup_tux_kart EXIT
          ${lib.getExe pkgs.supertuxkart} --fullscreen
          exit
          ;;
        sdlpop.sdlpop) exec ${lib.getExe pkgs.sdlpop} full ;;
        smw.game) exec ${pkgs.supermariowar}/games/smw --datadir /userdata/roms/superbroswar ;;
        MrBoom.libretro) exec ${lib.getExe pkgs.libretro.mrboom} --config ${home}/.config/retroarch/retroarch.cfg ;;
        StepMania.flatpak)
          # Flatpak kept songs, profiles and settings outside Batocera's ROMs.
          # Seed the native application's writable home once, preserving edits.
          previous=/userdata/saves/flatpak/data/.var/app/com.stepmania.StepMania/.stepmania-5.1
          current="$HOME/.stepmania-5.1"
          if [ -d "$previous" ] && [ ! -e "$current/.batocera-imported" ]; then
            mkdir -p "$current"
            rsync -rt --ignore-existing --safe-links --exclude=Cache/ --exclude=Logs/ "$previous/" "$current/"
            touch "$current/.batocera-imported"
          fi
          mkdir -p "$current/Save" "$current/Logs"
          preferences="$current/Save/Preferences.ini"
          # Built-in EMS USB2 automapping matches 0b43:0003 by device name,
          # keeping pad assignments independent of Atari controller Joy IDs.
          if [ ! -e "$current/Save/.pechersk-dance-mapping-v2" ]; then
            cp -a "$preferences" "$preferences.before-pechersk-dance-mapping"
            if [ -f "$current/Save/Keymaps.ini" ]; then
              cp -a "$current/Save/Keymaps.ini" "$current/Save/Keymaps.ini.before-pechersk-dance-mapping"
            fi
            crudini --set "$preferences" Options AutoMapOnJoyChange 1
            crudini --set "$preferences" Options LastSeenInputDevices ""
            touch "$current/Save/.pechersk-dance-mapping-v2"
          fi
          # Nixpkgs' bin/ symlink does not establish the required data cwd.
          cd ${pkgs.stepmania}/stepmania-5.1
          # Send the normal X11 close chord only while StepMania is running.
          # Stop the mapper before the launcher returns control to ES-DE.
          ${pkgs.antimicrox}/bin/antimicrox --hidden --no-tray --eventgen xtest --log-level warn \
            --profile /etc/pechersk/quit.gamecontroller.amgp \
            > "$current/Logs/pechersk-exit-controller.log" 2>&1 &
          mapper=$!
          # ShellCheck does not follow this function's EXIT-trap invocation.
          # shellcheck disable=SC2329
          cleanup_mapper() {
            kill "$mapper" 2>/dev/null || true
            wait "$mapper" 2>/dev/null || true
            # The game can close before a held Start button is released.
            ${pkgs.xdotool}/bin/xdotool keyup Alt_L F4 || true
          }
          trap cleanup_mapper EXIT
          # Escape the frontend's AppImage user namespace so the fixed setgid
          # wrapper can grant pad access. Wait here for normal game-end hooks.
          ${pkgs.systemd}/bin/systemd-run --user --wait --collect --pipe \
            --service-type=exec --unit=pechersk-stepmania \
            --working-directory=${pkgs.stepmania}/stepmania-5.1 \
            --setenv=DISPLAY="''${DISPLAY:-:0}" \
            --setenv=XAUTHORITY="''${XAUTHORITY:-$HOME/.Xauthority}" \
            --setenv=SDL_GAMECONTROLLERCONFIG="''${SDL_GAMECONTROLLERCONFIG:-}" \
            /run/wrappers/bin/pechersk-stepmania
          exit
          ;;
        Steam.steam) exec ${lib.getExe pkgs.steam} ;;
        Minecraft.sh) exec ${lib.getExe pkgs.prismlauncher} ;;
        Extreme-Tux-Racer.port)
          mkdir -p "$HOME/.cache/pechersk"
          ${pkgs.antimicrox}/bin/antimicrox --hidden --no-tray --eventgen xtest --log-level warn \
            --profile /etc/pechersk/tux-racer.gamecontroller.amgp \
            > "$HOME/.cache/pechersk/tux-racer-controller.log" 2>&1 &
          mapper=$!
          # shellcheck disable=SC2329
          cleanup_tux_racer() {
            kill "$mapper" 2>/dev/null || true
            wait "$mapper" 2>/dev/null || true
            ${pkgs.xdotool}/bin/xdotool keyup Left Right Up Down Return Escape space t p r Alt_L F4 || true
          }
          trap cleanup_tux_racer EXIT
          ${lib.getExe tuxRacer}
          exit
          ;;
        *) echo "Unsupported port: $game" >&2; exit 2 ;;
      esac
    '';
  };
in {
  system.build.pecherskPortLauncher = launcher;
  environment.systemPackages = [launcher python pkgs.supertux pkgs.srb2 pkgs.neverball pkgs.supertuxkart pkgs.sdlpop pkgs.supermariowar pkgs.stepmania tuxRacer pkgs.wineWow64Packages.stable pkgs.antimicrox pkgs.ffmpeg];
  environment.etc."pechersk/quit.gamecontroller.amgp".source = ./controllers/quit.gamecontroller.amgp;
  environment.etc."pechersk/tux-racer.gamecontroller.amgp".source = ./controllers/tux-racer.gamecontroller.amgp;
  programs.steam.enable = true;
  systemd.tmpfiles.rules = [
    "d ${home}/.local/share 0755 gamer gamer -"
    "d /userdata/roms/native 0775 gamer gamer -"
    "f /userdata/roms/native/Extreme-Tux-Racer.port 0644 gamer gamer - -"
    "f /userdata/roms/native/SuperTux.port 0644 gamer gamer - -"
    "f /userdata/roms/native/Sonic-Robo-Blast-2.port 0644 gamer gamer - -"
    "f /userdata/roms/native/Neverball.port 0644 gamer gamer - -"
    # Unmodified upstream Retrotrivia invokes this absolute executable path.
    "L+ /usr/bin/ffmpeg - root root - ${pkgs.ffmpeg}/bin/ffmpeg"
  ];
}
