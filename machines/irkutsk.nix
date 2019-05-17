let
  custom_modules = import ../modules/modules-list.nix;
  nixosHardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/36d8bd88cd72cfa8ee4162e6580f0a8e7de132ba.tar.gz";
    sha256 = "00w075mlap81m82ria1s4z6aki3sgdap84lzfkxx747w2as7i1sv";
  };
  ouroborosNetwork = builtins.fetchTarball {
    url = "https://github.com/input-output-hk/ouroboros-network/archive/7bed99644a4c2e291478573c6bcafe28e2767bed.tar.gz";
    sha256 = "10s3c7zpa3a8zv875qzsiiw7anbx4pyl0j8ihlxh2k8zgfi6s4xp";
  };

in {
  imports =
  [ # Include the results of the hardware scan.
    ../hardware-configurations/irkutsk.nix
    # Machine specific config
    ../nixconfigs/irkutsk.nix
    (import (nixosHardware + "/dell/xps/13-9380"))
    (ouroborosNetwork + "/nix/nixos")
  ] ++ custom_modules;

}
