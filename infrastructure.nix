let
  secrets = import ./load-secrets.nix;
  shared = import ./shared.nix;
  custom_modules = (import ./modules/modules-list.nix);
  sources = import ./nix/sources.nix;
in
{
  network = {
    description = "home network";
    enableRollback = true;
  };
  optina = { ... }: {
    deployment = {
      targetHost = "10.40.33.20";
    };
    imports = [
      (import ./optina )
      (sources.cardano-node + "/nix/nixos")
    ] ++ custom_modules;
    deployment.keys = {
      "gitea-dbpass".text = secrets.gitea_dbpass;
      "cardano-kes" = {
        keyFile = ./. + "/keys/optina-kes.skey";
        user = "cardano-node";
      };
      "cardano-vrf" = {
        keyFile = ./. + "/keys/optina-vrf.skey";
        user = "cardano-node";
      };
      "cardano-opcert" = {
        keyFile = ./. + "/keys/optina.opcert";
        user = "cardano-node";
      };
    };
  };
  portal = { ... }: {
    deployment = {
      targetHost = "10.40.33.1";
    };
    imports = [
      (import ./portal )
      (sources.cardano-node + "/nix/nixos")
    ] ++ custom_modules;
    deployment.keys = {
      "wg0-private".text = secrets.portal_wg0_private;
    };
  };
}
