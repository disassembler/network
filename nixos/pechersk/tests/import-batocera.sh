#!/usr/bin/env bash
set -euo pipefail
importer=${1:?Pass the built pechersk-import-batocera executable}
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
source_dir="$fixture/source userdata"
dest_dir="$fixture/target userdata"
es_dir="$fixture/ES-DE"
mkdir -p "$source_dir/roms/nes/images" "$source_dir/roms/nes/nested" "$source_dir/bios" "$source_dir/saves/nes" "$dest_dir/saves/nes"
printf 'rom' > "$source_dir/roms/nes/nested/Game One.nes"
printf 'battery save' > "$source_dir/roms/nes/Save Demo.nes.sav"
printf 'cover' > "$source_dir/roms/nes/images/cover.png"
printf 'original save' > "$source_dir/saves/nes/Game One.srm"
printf 'newer save' > "$dest_dir/saves/nes/Game One.srm"
printf 'new imported save' > "$source_dir/saves/nes/Game Two.srm"
printf 'private outside source' > "$fixture/outside.png"
ln -s "$fixture/outside.png" "$source_dir/roms/nes/images/outside.png"
cat > "$source_dir/roms/nes/gamelist.xml" <<'XML'
<gameList>
  <game><path>nested/Game One.nes</path><name>Game One</name><favorite>true</favorite><image>./images/cover.png</image></game>
  <game><path>./Missing.nes</path><image>./images/outside.png</image></game>
  <game><path>../../Escape.nes</path><image>./images/cover.png</image></game>
</gameList>
XML
cp -a "$source_dir" "$fixture/source reference"
"$importer" "$source_dir" "$dest_dir" "$es_dir"
cmp "$source_dir/roms/nes/nested/Game One.nes" "$dest_dir/roms/nes/nested/Game One.nes"
test "$(cat "$dest_dir/saves/nes/Game One.srm")" = 'newer save'
cmp "$source_dir/saves/nes/Game Two.srm" "$dest_dir/saves/nes/Game Two.srm"
cmp "$source_dir/roms/nes/Save Demo.nes.sav" "$dest_dir/saves/nes/Save Demo.srm"
cmp "$source_dir/roms/nes/images/cover.png" "$es_dir/downloaded_media/nes/covers/nested/Game One.png"
test ! -e "$es_dir/downloaded_media/nes/covers/Missing.png"
test ! -e "$es_dir/downloaded_media/Escape.png"
test "$(xmlstarlet sel -t -v '/gameList/game[1]/path' "$es_dir/gamelists/nes/gamelist.xml")" = './nested/Game One.nes'
test "$(xmlstarlet sel -t -v '/gameList/game[1]/favorite' "$es_dir/gamelists/nes/gamelist.xml")" = 'true'
printf 'played again' > "$dest_dir/saves/nes/Game Two.srm"
printf 'edited title' > "$es_dir/gamelists/nes/keep.txt"
"$importer" "$source_dir" "$dest_dir" "$es_dir"
test "$(cat "$dest_dir/saves/nes/Game Two.srm")" = 'played again'
test "$(cat "$es_dir/gamelists/nes/keep.txt")" = 'edited title'
diff --no-dereference -r "$source_dir" "$fixture/source reference"
if "$importer" "$source_dir" "$source_dir/nested destination" "$es_dir"; then
  echo 'Importer accepted a destination inside the source' >&2
  exit 1
fi
printf 'PASS: source unchanged; existing saves preserved; repeat import safe; nested artwork and metadata converted; external paths rejected.\n'
