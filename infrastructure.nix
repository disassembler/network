let
  secrets = import ./secrets.nix;
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
    _module.args = {
      inherit secrets shared;
    };
    imports = [
      (import ./optina )
    ] ++ custom_modules;
  };
  portal = { ... }: {
    deployment = {
      targetHost = "10.40.33.1";
    };
    _module.args = {
      inherit secrets shared;
    };
    imports = [
      (import ./portal )
    ] ++ custom_modules;
  };
}
