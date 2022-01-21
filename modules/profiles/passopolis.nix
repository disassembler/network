{ config, lib, ... }:

with lib;

let
  cfg = config.profiles.passopolis;
in {
  options.profiles.passopolis = {
    enable = mkEnableOption "enable passopolis profile.";
  };

  config = mkIf (cfg.enable)  {
    services = {
      passopolis = {
        enable = true;
      };
      postgresql = {
        enable = true;
        authentication = ''
          local all all trust
          host all all 127.0.0.1/32 trust
        '';
      };
    };
  };
}
