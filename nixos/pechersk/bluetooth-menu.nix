{pkgs, ...}: let
  menu = pkgs.writeShellApplication {
    name = "pechersk-bluetooth-menu";
    runtimeInputs = with pkgs; [bluez dialog coreutils gnugrep];
    text = builtins.readFile ./bluetooth-menu.sh;
  };
  launcher = pkgs.writeShellApplication {
    name = "pechersk-bluetooth";
    runtimeInputs = with pkgs; [coreutils];
    text = ''
      ${pkgs.antimicrox}/bin/antimicrox --hidden --profile /etc/pechersk/menu.gamecontroller.amgp > "$HOME/.bluetooth-controller-menu.log" 2>&1 &
      mapper=$!
      trap 'kill "$mapper" 2>/dev/null || true; wait "$mapper" 2>/dev/null || true' EXIT
      ${pkgs.xterm}/bin/xterm -fullscreen -fa 'DejaVu Sans Mono' -fs 22 -title 'Pechersk Bluetooth' -e ${menu}/bin/pechersk-bluetooth-menu
    '';
  };
in {
  environment.systemPackages = [launcher];
  environment.etc."pechersk/menu.gamecontroller.amgp".source = ./controllers/menu.gamecontroller.amgp;
  system.build.pecherskBluetooth = launcher;
}
