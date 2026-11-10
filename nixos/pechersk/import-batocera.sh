#!/usr/bin/env bash
set -euo pipefail
# Packaged by writeShellApplication; run as gamer with the source mounted read-only
# or with a separate local copy. No source script is executed.
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
  echo "Usage: pechersk-import-batocera SOURCE_USERDATA [DEST_USERDATA [ES_DE_DATA]]" >&2
  exit 2
fi
source_dir=$(realpath -e -- "$1")
dest_dir=$(realpath -m -- "${2:-/userdata}")
es_dir=$(realpath -m -- "${3:-$HOME/ES-DE}")
if [ ! -d "$source_dir/roms" ] || [ ! -d "$source_dir/bios" ]; then
  echo "Source must contain Batocera roms/ and bios/ directories" >&2
  exit 2
fi
case "$dest_dir/" in "$source_dir/"*) echo "Destination must be outside the source" >&2; exit 2 ;; esac
case "$source_dir/" in "$dest_dir/"*) echo "Source must be outside the destination" >&2; exit 2 ;; esac
case "$es_dir/" in "$source_dir/"*) echo "ES-DE data must be outside the source" >&2; exit 2 ;; esac
mkdir -p -- "$dest_dir" "$es_dir/gamelists" "$es_dir/downloaded_media"

for directory in roms bios saves screenshots music themes cheats decorations recordings splash; do
  if [ -d "$source_dir/$directory" ] && [ ! -L "$source_dir/$directory" ]; then
    mkdir -p -- "$dest_dir/$directory"
    rsync -rt --ignore-existing --safe-links --no-perms --chmod=Du+rwx,Fu+rw \
      -- "$source_dir/$directory/" "$dest_dir/$directory/"
  fi
done

# Older Nintendo collections keep battery saves beside their ROMs. Preserve those
# originals and seed the corresponding libretro SRAM filename only when absent.
for system in nes snes gba; do
  [ -d "$dest_dir/roms/$system" ] || continue
  mkdir -p "$dest_dir/saves/$system"
  while IFS= read -r -d '' save; do
    stem=$(basename "$save")
    stem=${stem%.*}
    case "${stem,,}" in *.nes|*.gba) stem=${stem%.*} ;; esac
    target="$dest_dir/saves/$system/$stem.srm"
    if [ ! -e "$target" ]; then cp -- "$save" "$target"; fi
  done < <(find "$dest_dir/roms/$system" -maxdepth 1 -type f \( -iname '*.srm' -o -iname '*.sav' \) -print0)
done

# ES-DE reads metadata but resolves artwork by ROM filename, not by XML media
# tags. Convert on the destination only. Leave source and existing assets intact.
while IFS= read -r -d '' gamelist; do
  system=$(basename "$(dirname "$gamelist")")
  mkdir -p -- "$es_dir/gamelists/$system"
  metadata="$es_dir/gamelists/$system/gamelist.xml"
  if [ ! -e "$metadata" ]; then
    xmlstarlet ed -u '/gameList/game/path[not(starts-with(., "./")) and not(starts-with(., "/"))]' \
      -x 'concat("./", .)' "$gamelist" > "$metadata"
  fi
  for pair in image:covers thumbnail:screenshots marquee:marquees video:videos; do
    tag=${pair%:*}
    media_type=${pair#*:}
    # Each selected row contains exactly two nonempty paths.
    while IFS=$'\t' read -r game asset; do
      [ -n "$game" ] && [ -n "$asset" ] || continue
      game=${game#./}
      game_path=$(realpath -m -- "$dest_dir/roms/$system/$game")
      case "$game_path" in "$dest_dir/roms/$system/"*) ;; *) continue ;; esac
      case "$asset" in
        /userdata/*) asset="$source_dir/${asset#/userdata/}" ;;
        /*) continue ;;
        *) asset="$(dirname "$gamelist")/$asset" ;;
      esac
      asset_path=$(realpath -e -- "$asset" 2>/dev/null) || continue
      case "$asset_path" in "$source_dir/"*) ;; *) continue ;; esac
      [ -f "$asset_path" ] || continue
      extension=${asset_path##*.}
      target="$es_dir/downloaded_media/$system/$media_type/${game%.*}.$extension"
      if [ ! -e "$target" ]; then
        mkdir -p -- "$(dirname "$target")"
        cp -- "$asset_path" "$target"
      fi
    done < <(xmlstarlet sel -t -m "/gameList/game[path != '' and $tag != '']" \
      -v path -o $'\t' -v "$tag" -n "$gamelist")
  done
done < <(find "$source_dir/roms" -mindepth 2 -maxdepth 2 -type f -name gamelist.xml -print0)
echo "Imported available data without replacing existing files. Source was only read."
echo "Check BIOS discovery, battery saves and artwork before playing; keep original savestates."
