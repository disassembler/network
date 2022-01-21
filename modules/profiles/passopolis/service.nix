{ config, lib, ... }:

with lib;

let
  sources = import nix/sources.nix { };
  pkgs = import sources.nixpkgs-passopolis { };
  cfg = config.services.passopolis;
in
{
  ###### interface

  options = {

    services.passopolis = {

      enable = mkEnableOption "Passopolis";

      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./pkg.nix { antBuild = pkgs.releaseTools.antBuild; };
        description = "Passopolis package";
      };

      user = mkOption {
        type = types.str;
        default = "passopolis";
        description = "User account under which passopolis runs.";
      };

      statePath = mkOption {
        type = types.str;
        default = "/var/passopolis";
        description = "The state directory";
      };

      databaseHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Database hostname";
      };

      databaseName = mkOption {
        type = types.str;
        default = "passopolis";
        description = "Database name";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {
    users.users.passopolis =
      {
        isSystemUser = true;
        name = cfg.user;
        description = "Passopolis service user";
        group = "passopolis";
      };
    users.groups.passopolis = { };

    systemd.services.passopolis =
      {
        description = "Passopolis service";
        after = [ "network.target" "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
          config.services.postgresql.package
        ];
        preStart = ''
          mkdir -p ${cfg.statePath}
          chown ${cfg.user} ${cfg.statePath}
          if [ "${cfg.databaseHost}" = "127.0.0.1" ]; then
            if ! test -e "${cfg.statePath}/db-created"; then
              psql postgres -c "CREATE ROLE ${cfg.user} WITH LOGIN NOCREATEDB NOCREATEROLE NOCREATEUSER"
              ${config.services.postgresql.package}/bin/createdb --owner ${cfg.user} ${cfg.databaseName} || true
              touch "${cfg.statePath}/db-created"
            fi
          fi
        '';

        serviceConfig = {
          PermissionsStartOnly = true; # preStart must be run as root
          Type = "simple";
          ExecStart = "${pkgs.jre}/bin/java -DgenerateSecretsForTest=true -Dhttp_port=8089 -Dhttps_port=8445 -Ddatabase_url=jdbc:postgresql://${cfg.databaseHost}:5432/${cfg.databaseName} -ea -jar ${cfg.package}/share/java/mitrocore.jar";
          User = cfg.user;
        };
      };
  };
}
