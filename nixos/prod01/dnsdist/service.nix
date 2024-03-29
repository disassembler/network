{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnsdist;
  dnsdist = pkgs.callPackage ./package.nix { };
  configFile = pkgs.writeText "dndist.conf" ''
    setLocal('${cfg.listenAddress}:${toString cfg.listenPort}')
    ${cfg.extraConfig}
  '';
in
{
  options = {
    services.dnsdist = {
      enable = mkEnableOption "dnsdist domain name server";

      listenAddress = mkOption {
        type = types.str;
        description = "Listen IP Address";
        default = "0.0.0.0";
      };
      listenPort = mkOption {
        type = types.int;
        description = "Listen port";
        default = 53;
      };

      extraConfig = mkOption {
        type = types.lines;
        default = ''
        '';
        description = ''
          Extra lines to be added verbatim to dnsdist.conf.
        '';
      };
    };
  };

  config = mkIf config.services.dnsdist.enable {
    systemd.services.dnsdist = {
      description = "dnsdist load balancer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "1";
        User = "root";
        StartLimitInterval = "0";
        PrivateTmp = true;
        PrivateDevices = true;
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE CAP_SETGID CAP_SETUID";
        ExecStart = "${dnsdist}/bin/dnsdist --supervised --disable-syslog --config ${configFile}";
        ProtectSystem = "full";
        ProtectHome = true;
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
        LimitNOFILE = "16384";
        TasksMax = "8192";
      };
    };
  };
}
