{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.omadad;
  defaultUser = "omadad";
in {
  options.services.omadad = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable TP-Link Omada Controller (wifi access point controller).
      '';
    };

    user = mkOption {
      default = defaultUser;
      example = "john";
      type = types.str;
      description = ''
        The name of an existing user account to use to own the omadad server
        process. If not specified, a default user will be created.
      '';
    };

    group = mkOption {
      default = defaultUser;
      example = "john";
      type = types.str;
      description = ''
        Group to own the omadad server process.
      '';
    };

    dataDir = mkOption {
      default = "/var/lib/omadad/";
      example = "/home/john/.omadad/";
      type = types.path;
      description = ''
        The state directory for omadad.
      '';
    };

    httpPort = mkOption {
      type = types.int;
      default = 8088;
      description = "http listening port";
    };

    httpsPort = mkOption {
      type = types.int;
      default = 8043;
      description = "https listening port";
    };

    mongoPort = mkOption {
      type = types.int;
      default = 27212;
      description = "Mongo database connection port.  Specify alternate if running multiple instances.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {};
      description = ''
        Omada package
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open ports in the firewall for omadad.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package pkgs.jre ];

    systemd.services.omadad = {
      description = "Wifi access point controller";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.bash pkgs.mongodb pkgs.nettools pkgs.curl pkgs.procps ];

      serviceConfig = let
        java_opts = "-classpath '${cfg.dataDir}/lib/*' -server -Xms128m -Xmx1024m -XX:MaxHeapFreeRatio=60 -XX:MinHeapFreeRatio=30 -XX:+HeapDumpOnOutOfMemoryError -DhttpPort=${toString cfg.httpPort} -DhttpsPort=${toString cfg.httpsPort} -DmongoPort=${toString cfg.mongoPort} -DdataDir=${cfg.dataDir}/data -Deap.home=${cfg.dataDir} --add-opens=java.base/sun.security.x509=ALL-UNNAMED";
        main_class = "com.tplink.smb.omada.starter.OmadaLinuxMain";
      in {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.jre}/bin/java ${java_opts} ${main_class}";
        WorkingDirectory = "${cfg.dataDir}/data";
      };

      preStart = ''
          mkdir -p ${cfg.dataDir}/data/db
          mkdir -p ${cfg.dataDir}/data/portal
          mkdir -p ${cfg.dataDir}/data/map
          mkdir -p ${cfg.dataDir}/data/keystore
          mkdir -p ${cfg.dataDir}/data/pdf
          mkdir -p ${cfg.dataDir}/logs
          mkdir -p ${cfg.dataDir}/work
          # Some stuff has to be writeable, so we make dataDir home and
          rm -rf ${cfg.dataDir}/lib
          cp -a ${cfg.package}/lib ${cfg.dataDir}/lib
          chmod -R +rw ${cfg.dataDir}/lib
          rm -f ${cfg.dataDir}/bin && ln -sf ${cfg.package}/bin ${cfg.dataDir}/bin
          rm -f ${cfg.dataDir}/data/html && ln -sf ${cfg.package}/data/html ${cfg.dataDir}/data/html
          rm -rf ${cfg.dataDir}/properties
          cp -a ${cfg.package}/properties ${cfg.dataDir}/properties
          chmod -R +rw ${cfg.dataDir}/properties
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.httpPort cfg.httpsPort];

    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} =
        { description = "omadad server daemon owner";
          group = defaultUser;
          isSystemUser = true;
          # uid = config.ids.uids.omadad;
          home = cfg.dataDir;
          createHome = true;
        };
    };

    users.groups = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} =
        { # gid = config.ids.gids.omadad;
          members = [ defaultUser ];
        };
    };
  };
}
