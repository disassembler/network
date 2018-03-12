let
  secrets = import ./secrets.nix;
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
      (import ./optina { inherit secrets; })
    ] ++ custom_modules;
  };
  portal = { ... }: {
    deployment = {
      targetHost = "10.40.33.1";
    };
    imports = [
      (import ./portal { inherit secrets; })
    ] ++ custom_modules;
  };
}
