let
  custom_modules = import ../modules/modules-list.nix;

in {
  imports =
  [ # Include the results of the hardware scan.
    ../hardware-configurations/sarov.nix
    # Machine specific config
    ../nixconfigs/sarov.nix
    ../legacy/sarov.nix
  ] ++ custom_modules;

}
