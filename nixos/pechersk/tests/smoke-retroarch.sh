#!/usr/bin/env bash
# Run as gamer inside the actual X11 session, with xmlstarlet in PATH.
set -uo pipefail
cd "$HOME"
report=${1:?Pass an empty private report directory}
mkdir -p "$report/saves" "$report/states"
report=$(realpath "$report")
cat > "$report/verification.cfg" <<EOF
savefile_directory = "$report/saves"
savestate_directory = "$report/states"
savestate_auto_save = "false"
savestate_auto_load = "false"
config_save_on_exit = "false"
EOF
summary="$report/results.tsv"
printf 'system\tresult\tstatus\tcontent\n' > "$summary"
failed=0
systems=(atari2600 atari800 c64 mame gba megadrive nes pcengine psx snes prboom)
if [ "$#" -gt 1 ]; then systems=("${@:2}"); fi
for system in "${systems[@]}"; do
  directory="/userdata/roms/$system"
  rom=''
  while IFS= read -r -d '' candidate; do
    case "${candidate,,}" in
      */prboom.wad) continue ;;
      *.a26|*.atr|*.d64|*.zip|*.gba|*.gen|*.md|*.nes|*.pce|*.cue|*.chd|*.smc|*.sfc|*.wad)
        rom="$candidate"; break ;;
    esac
  done < <(find "$directory" -maxdepth 1 -type f -print0 | sort -z)
  if [ "$system" = atari800 ] && [ -f "$directory/Pac-Man.ATR" ]; then rom="$directory/Pac-Man.ATR"; fi
  if [ "$system" = mame ] && [ -f "$directory/arkanoid.zip" ]; then rom="$directory/arkanoid.zip"; fi
  if [ -z "$rom" ]; then
    printf '%s\tNO_CONTENT\t-\t-\n' "$system" >> "$summary"
    failed=1
    continue
  fi
  command=$(xmlstarlet sel -t -v "/systemList/system[name='$system']/command[1]" /etc/pechersk/es_systems.xml)
  read -r -a words <<< "$command"
  # Generated command begins: env -u LD_LIBRARY_PATH -u LD_PRELOAD CORE-WRAPPER.
  program=${words[5]}
  status=0
  env -u LD_LIBRARY_PATH -u LD_PRELOAD timeout --signal=TERM --kill-after=5s 45s "$program" \
    --config "$HOME/.config/retroarch/retroarch.cfg" \
    --appendconfig "/etc/pechersk/retroarch-$system.cfg|$report/verification.cfg" \
    --verbose --max-frames=180 --max-frames-ss --max-frames-ss-path="$report/$system.png" \
    "$rom" > "$report/$system.log" 2>&1 || status=$?
  if [ "$status" -eq 0 ] && [ -s "$report/$system.png" ] &&
    ! grep -Eiq 'Failed to load content|Required files are missing|Fatal error|Failed to open libretro core' "$report/$system.log"; then
    result=PASS
  else
    result=FAIL
    failed=1
  fi
  printf '%s\t%s\t%s\t%s\n' "$system" "$result" "$status" "${rom#"$directory/"}" >> "$summary"
done
cat "$summary"
exit "$failed"
