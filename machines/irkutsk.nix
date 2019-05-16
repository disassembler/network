let
  custom_modules = import ../modules/modules-list.nix;
  nixosHardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/36d8bd88cd72cfa8ee4162e6580f0a8e7de132ba.tar.gz";
    sha256 = "00w075mlap81m82ria1s4z6aki3sgdap84lzfkxx747w2as7i1sv";
  };
  ouroborosNetwork = builtins.fetchTarball {
    url = "https://github.com/input-output-hk/ouroboros-network/archive/e5ecaffed328b91d6d04d0c5a7d1336e775f66f4.tar.gz";
    sha256 = "16k8gbh5l2qzsrgffbrdnaknk611a15sr5z0wy8bi4zhkakahqcf";
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
