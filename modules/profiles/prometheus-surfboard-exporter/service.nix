{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.prometheus.surfboardExporter;
  pkg = pkgs.callPackage ./pkg.nix { };

in
{
  options = {
    services.prometheus.surfboardExporter = {
      enable = mkEnableOption "prometheus surfboard exporter";

      port = mkOption {
        type = types.int;
        default = 9239;
        description = ''
          Port to listen on.
        '';
      };

      modemAddress = mkOption {
        type = types.str;
        default = "192.168.100.1";
        description = ''
          The hostname or IP of the cable modem.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra commandline options when launching the surfboard exporter.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open port in firewall for incoming connections.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

    systemd.services.prometheus-surfboard-exporter = {
      description = "Prometheus exporter for surfboard cable modem";
      unitConfig.Documentation = "https://github.com/ipstatic/surfboard_exporter";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "nobody";
        Restart = "always";
        PrivateTmp = true;
        WorkingDirectory = /tmp;
        ExecStart = ''
          ${pkg}/bin/surfboard_exporter \
            -web.listen-address :${toString cfg.port} \
            -modem-address ${cfg.modemAddress} \
            ${concatStringsSep " \\\n  " cfg.extraFlags}
        '';
      };
    };
  };
}
