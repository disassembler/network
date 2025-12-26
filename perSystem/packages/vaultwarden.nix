
{ inputs, ... }: {
  perSystem = { system, config, lib, pkgs, ... }: {
    packages = {
      inherit (pkgs) vaultwarden;
    };
  };
}
