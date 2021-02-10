let
  secrets = import ./load-secrets.nix;
  shared = import ./shared.nix;
  custom_modules = (import ./modules/modules-list.nix);
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
    ] ++ custom_modules;
    deployment.keys = {
      "gitea-dbpass".text = secrets.gitea_dbpass;
    };
  };
  portal = { ... }: {
    deployment = {
      targetHost = "10.40.33.1";
    };
    imports = [
      (import ./portal )
    ] ++ custom_modules;
    deployment.keys = {
      "wg0-private".text = secrets.portal_wg0_private;
    };
  };
}
