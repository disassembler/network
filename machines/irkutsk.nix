let
  custom_modules = import ../modules/modules-list.nix;
  nixosHardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/2b8807f75b02cdc7541022cfb0f704af715481dc.tar.gz";
    sha256 = "0zsw7alwf4wqqawrldklmmmgcp55wbk44js952m9x8qcwl4f47zs";
  };

in {
  imports =
  [ # Include the results of the hardware scan.
    ../hardware-configurations/irkutsk.nix
    # Machine specific config
    ../nixconfigs/irkutsk.nix
    (import (nixosHardware + "/dell/xps/13-9370"))
  ] ++ custom_modules;

}
