#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
log=$(mktemp)
trap 'rm -f "$log"' EXIT
ui=(dialog --backtitle 'Pechersk Bluetooth | D-pad / stick: move | A / Start: select | B / Back: return' --no-collapse)
show_result() {
  "${ui[@]}" --title "$1" --exit-label Continue --textbox "$log" 20 76
}
while true; do
  items=(SCAN 'Find new controllers (enable pairing mode first)')
  while read -r marker mac name; do
    [ "$marker" = Device ] || continue
    items+=("$mac" "${name:-Unknown device}")
  done < <(bluetoothctl devices)
  selection=$("${ui[@]}" --stdout --title 'Bluetooth controllers' --cancel-label 'Return to games' --menu 'Select a controller, or scan for a new one.' 22 86 12 "${items[@]}") || break
  if [ "$selection" = SCAN ]; then
    "${ui[@]}" --title 'Finding controllers' --infobox 'Put the new controller in pairing mode. Scanning for 12 seconds...' 7 76
    bluetoothctl power on > "$log" 2>&1 || { show_result 'Bluetooth could not be powered on'; continue; }
    bluetoothctl --timeout 12 scan on >> "$log" 2>&1 || true
    continue
  fi
  [[ "$selection" =~ ^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$ ]] || continue
  info=$(bluetoothctl info "$selection" | grep -E 'Device |Name:|Paired:|Bonded:|Trusted:|Connected:')
  action=$("${ui[@]}" --stdout --title "$selection" --menu "$info" 24 88 4 CONNECT 'Pair / trust / connect' DISCONNECT 'Disconnect controller' FORGET 'Remove saved pairing') || continue
  : > "$log"
  case "$action" in
    CONNECT)
      "${ui[@]}" --infobox 'Connecting... For a new controller, keep it in pairing mode.' 6 76
      if ! grep -q 'Paired: yes' <<< "$info"; then
        bluetoothctl --agent NoInputNoOutput --timeout 30 pair "$selection" >> "$log" 2>&1 || { show_result 'Pairing failed (some devices require a PIN)'; continue; }
      fi
      bluetoothctl trust "$selection" >> "$log" 2>&1 && bluetoothctl --timeout 20 connect "$selection" >> "$log" 2>&1 || true
      show_result 'Connection result'
      ;;
    DISCONNECT|FORGET)
      "${ui[@]}" --defaultno --yesno 'Disconnecting the controller used for this menu will require another controller or a keyboard to continue. Proceed?' 9 80 || continue
      if [ "$action" = FORGET ]; then
        bluetoothctl remove "$selection" > "$log" 2>&1 || true
      else
        bluetoothctl disconnect "$selection" > "$log" 2>&1 || true
      fi
      show_result 'Bluetooth result'
      ;;
  esac
done
