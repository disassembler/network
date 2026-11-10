{
  pkgs,
  lib,
  ...
}: let
  home = "/var/lib/pechersk";
  games = import ./pc-games-list.nix;
  manifest = pkgs.writeText "pc-games.tsv" (lib.concatMapStrings (g: "${g.id}\t${g.title}\t${g.system}\t${g.path}\n") games);
  migrate = pkgs.writeShellApplication {
    name = "pechersk-migrate-pc-games";
    runtimeInputs = [pkgs.coreutils pkgs.libxslt pkgs.xmlstarlet];
    text = ''
      root="''${1:-/userdata/roms}"
      es="''${2:-${home}/ES-DE}"
      catalog="$root/pcgames"
      mkdir -p "$catalog" "$es/downloaded_media/pcgames"
      if [ -e "$catalog/.metadata-migrated-v1" ]; then
        echo 'PC Games metadata already migrated; preserving current edits.'
        exit 0
      fi
      if [ -e "$catalog/gamelist.xml" ] || [ -e "$es/gamelists/pcgames/gamelist.xml" ]; then
        echo 'Existing PC Games metadata found; refusing to replace it.' >&2
        exit 1
      fi
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      printf '<gameList/>\n' > "$work/empty.xml"
      printf '<?xml version="1.0"?>\n<gameList>\n' > "$work/gamelist.xml"
      shopt -s nullglob
      while IFS=$'\t' read -r id title system original; do
        metadata="$root/$system/gamelist.xml"
        if [ ! -f "$metadata" ]; then metadata="$es/gamelists/$system/gamelist.xml"; fi
        if [ ! -f "$metadata" ]; then metadata="$work/empty.xml"; fi
        xsltproc --stringparam old-path "./$original" \
          --stringparam new-path "./$id.pcgame" --stringparam title "$title" \
          --stringparam romdir "$root/$system" ${./pc-games-metadata.xsl} "$metadata" >> "$work/gamelist.xml"
        stem="''${original%.*}"
        for kind in covers screenshots marquees videos 3dboxes backcovers fanart manuals miximages physicalmedia titlescreens; do
          for media in "$es/downloaded_media/$system/$kind/$stem".*; do
            [ -f "$media" ] || continue
            mkdir -p "$es/downloaded_media/pcgames/$kind"
            destination="$es/downloaded_media/pcgames/$kind/$id.''${media##*.}"
            if [ ! -e "$destination" ]; then cp "$media" "$destination"; fi
          done
        done
      done < ${manifest}
      printf '</gameList>\n' >> "$work/gamelist.xml"
      xmlstarlet val --well-formed --err "$work/gamelist.xml"
      mv "$work/gamelist.xml" "$catalog/gamelist.xml"
      touch "$catalog/.metadata-migrated-v1"
    '';
  };
in {
  system.build.pecherskPCGamesMigration = migrate;
  environment.systemPackages = [migrate];
  systemd.tmpfiles.rules =
    [
      "d /userdata/roms/pcgames 0775 gamer gamer -"
      "r ${home}/tools/Minecraft.tool - - - -"
    ]
    ++ map (g: "f /userdata/roms/pcgames/${g.id}.pcgame 0644 gamer gamer - -") games;
}
