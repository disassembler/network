{
  pkgs,
  lib,
  ...
}: let
  home = "/var/lib/pechersk";
  control = pkgs.writeShellApplication {
    name = "pechersk-menu-music";
    runtimeInputs = [pkgs.coreutils pkgs.systemd];
    text = ''
      disabled="$HOME/.config/pechersk/music-disabled"
      case "''${1:-resume}" in
        resume)
          if [ ! -e "$disabled" ] && [ -s /userdata/music/menu/pechersk.m4a ]; then
            systemctl --user start pechersk-menu-music.service
          fi
          ;;
        stop) systemctl --user stop pechersk-menu-music.service ;;
        toggle)
          mkdir -p "$(dirname "$disabled")"
          if [ -e "$disabled" ]; then
            rm "$disabled"
            systemctl --user start pechersk-menu-music.service
          else
            touch "$disabled"
            systemctl --user stop pechersk-menu-music.service
          fi
          ;;
        *) echo "Usage: pechersk-menu-music resume|stop|toggle" >&2; exit 2 ;;
      esac
    '';
  };
  hook = action:
    pkgs.writeShellScript "pechersk-music-${action}" ''
      exec ${lib.getExe control} ${action}
    '';
in {
  system.build.pecherskMusic = control;
  environment.systemPackages = [control];
  systemd.user.services.pechersk-menu-music = {
    description = "Pechersk frontend background music";
    unitConfig.ConditionPathExists = "/userdata/music/menu/pechersk.m4a";
    serviceConfig = {
      ExecCondition = "${pkgs.coreutils}/bin/test ! -e %h/.config/pechersk/music-disabled";
      ExecStart = "${pkgs.mpv}/bin/mpv --no-config --no-video --audio-display=no --no-terminal --loop-file=inf --volume=90 --ao=pipewire,pulse /userdata/music/menu/pechersk.m4a";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
  systemd.tmpfiles.rules = [
    "d /userdata/music/menu 0775 gamer gamer -"
    "d ${home}/.config/pechersk 0700 gamer gamer -"
    "d ${home}/ES-DE/scripts 0755 gamer gamer -"
    "d ${home}/ES-DE/scripts/startup 0755 gamer gamer -"
    "d ${home}/ES-DE/scripts/quit 0755 gamer gamer -"
    "d ${home}/ES-DE/scripts/game-start 0755 gamer gamer -"
    "d ${home}/ES-DE/scripts/game-end 0755 gamer gamer -"
    "L+ ${home}/ES-DE/scripts/startup/pechersk-music.sh - gamer gamer - ${hook "resume"}"
    "L+ ${home}/ES-DE/scripts/quit/pechersk-music.sh - gamer gamer - ${hook "stop"}"
    "L+ ${home}/ES-DE/scripts/game-start/pechersk-music.sh - gamer gamer - ${hook "stop"}"
    "L+ ${home}/ES-DE/scripts/game-end/pechersk-music.sh - gamer gamer - ${hook "resume"}"
    "f ${home}/tools/Music.tool 0644 gamer gamer - -"
  ];
}
