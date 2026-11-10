{pkgs, ...}: let
  rules = pkgs.writeTextDir "lib/udev/rules.d/71-pechersk-dance-pads.rules" ''
    # Remove seat ACL access before 73-seat-late.rules applies uaccess.
    SUBSYSTEM=="input", ATTRS{idVendor}=="0b43", ATTRS{idProduct}=="0003", ENV{ID_SEAT}="seat-stepmania", TAG-="uaccess", GROUP:="stepmania-pads", MODE:="0660"
  '';
in {
  users.groups.stepmania-pads = {};
  services.udev.packages = [rules];
  # Grant only this fixed game executable access to the dedicated pad group.
  security.wrappers.pechersk-stepmania = {
    source = "${pkgs.stepmania}/stepmania-5.1/stepmania";
    owner = "root";
    group = "stepmania-pads";
    setuid = false;
    setgid = true;
  };
  system.activationScripts.pechersk-dance-pad-access = {
    deps = ["users"];
    text = ''
      # Existing logind ACLs must also be removed when switching generations.
      for device in /sys/class/input/event* /sys/class/input/js*; do
        [ -r "$device/device/id/vendor" ] || continue
        [ "$(cat "$device/device/id/vendor")" = 0b43 ] || continue
        [ "$(cat "$device/device/id/product")" = 0003 ] || continue
        node="/dev/input/''${device##*/}"
        [ -c "$node" ] || continue
        ${pkgs.acl}/bin/setfacl -b "$node"
        chgrp stepmania-pads "$node"
        chmod 0660 "$node"
      done
    '';
  };
}
