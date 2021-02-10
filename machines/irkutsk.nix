let
  custom_modules = import ../modules/modules-list.nix;
in {
  disabledModules = [ "services/networking/jormungandr.nix" ];
  imports =
  [ # Include the results of the hardware scan.
    ../hardware-configurations/irkutsk.nix
    # Machine specific config
    ../nixconfigs/irkutsk.nix
    <nixos-hardware/dell/xps/13-9380>
    /home/sam/work/iohk/cardano-graphql/nix/nixos
    /home/sam/work/iohk/cardano-node/local-service/nix/nixos
    /home/sam/work/iohk/cardano-db-sync/local-service/nix/nixos
    #/home/sam/work/iohk/cardano-byron-proxy/master/nix/nixos
    #/home/sam/work/iohk/jormungandr-nix/reward-api/nixos
    ../cachix.nix
  ] ++ custom_modules;

}
