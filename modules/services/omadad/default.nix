{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.omadad;
  defaultUser = "omadad";
  # mongodb-ce is SSPL (unfree); import a local pkgs with allowUnfree so the
  # default works even when the system nixpkgs config doesn't set it globally.
  unfreePkgs = import pkgs.path {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
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
      example = "omadad";
      type = types.str;
      description = ''
        The name of an existing user account to use to own the omadad server
        process. If not specified, a default user will be created.
      '';
    };

    group = mkOption {
      default = defaultUser;
      example = "omadad";
      type = types.str;
      description = ''
        Group to own the omadad server process.
      '';
    };

    dataDir = mkOption {
      default = "/var/lib/omadad/";
      example = "/home/omadad/.omadad/";
      type = types.path;
      description = ''
        The state directory for omadad.  This is the effective OMADA_HOME;
        relative paths in omada.properties resolve from dataDir/lib/.
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
      default = 27217;
      description = "Mongo database connection port.  Specify alternate if running multiple instances.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {
        mongodb = cfg.mongodb;
        commonsDaemon = pkgs.commonsDaemon;
      };
      description = ''
        Omada package
      '';
    };

    mongodb = mkOption {
      type = types.package;
      default = unfreePkgs.mongodb-ce;
      description = ''
        mongodb package.  Omada 6.x supports MongoDB 8.x (use pkgs.mongodb-ce).
      '';
    };

    java = mkOption {
      type = types.package;
      default = pkgs.jdk17_headless;
      description = ''
        JDK package for jsvc.  Must be Java 17+.  The .home attribute is used
        to pass the correct JAVA_HOME to jsvc, since nixpkgs JDK packages place
        the JVM under lib/openjdk rather than at the package root.
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
    environment.systemPackages = [cfg.package];

    systemd.services.omadad = {
      description = "Wifi access point controller";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.bash cfg.mongodb pkgs.nettools pkgs.curl pkgs.procps];

      serviceConfig = let
        main_class = "com.tplink.smb.omada.starter.OmadaLinuxMain";
        java_opts = "-server -XX:MaxHeapFreeRatio=60 -XX:MinHeapFreeRatio=30 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${cfg.dataDir}/logs/java_heapdump.hprof -Djava.awt.headless=true";
        classpath = "${cfg.dataDir}/lib/*:${cfg.dataDir}/properties";
      in {
        Type = "forking";
        PIDFile = "/run/omadad/jsvc.pid";
        RuntimeDirectory = "omadad";
        TimeoutStartSec = 300;
        User = cfg.user;
        Group = cfg.group;
        # Working directory is OMADA_HOME/lib so that relative paths in
        # omada.properties (e.g. ../data/db) resolve correctly.
        WorkingDirectory = "${cfg.dataDir}/lib";
        ExecStart = "${pkgs.jsvc}/bin/jsvc -java-home ${cfg.java.home} -cwd ${cfg.dataDir}/lib -pidfile /run/omadad/jsvc.pid -outfile ${cfg.dataDir}/logs/startup.log -errfile ${cfg.dataDir}/logs/startup.log -cp ${classpath} -procname omadad ${java_opts} ${main_class}";
      };

      preStart = ''
        # Mutable data directories
        mkdir -p ${cfg.dataDir}/data/db
        mkdir -p ${cfg.dataDir}/data/portal
        mkdir -p ${cfg.dataDir}/data/map
        mkdir -p ${cfg.dataDir}/data/keystore
        mkdir -p ${cfg.dataDir}/data/pdf
        mkdir -p ${cfg.dataDir}/data/autobackup
        mkdir -p ${cfg.dataDir}/logs
        mkdir -p ${cfg.dataDir}/work

        # lib must be writable (Omada may modify JARs at runtime)
        rm -rf ${cfg.dataDir}/lib
        cp -a ${cfg.package}/lib ${cfg.dataDir}/lib
        chmod -R +rw ${cfg.dataDir}/lib

        rm -f ${cfg.dataDir}/bin && ln -sf ${cfg.package}/bin ${cfg.dataDir}/bin

        # Static web assets from the package (read-only symlinks)
        mkdir -p ${cfg.dataDir}/data
        rm -f ${cfg.dataDir}/data/html && ln -sf ${cfg.package}/data/html ${cfg.dataDir}/data/html
        rm -f ${cfg.dataDir}/data/static && ln -sf ${cfg.package}/data/static ${cfg.dataDir}/data/static

        # Fresh properties (writable, with port substitutions applied)
        rm -rf ${cfg.dataDir}/properties
        cp -a ${cfg.package}/properties ${cfg.dataDir}/properties
        chmod -R +rw ${cfg.dataDir}/properties
        sed -i 's/^manage\.http\.port=.*/manage.http.port=${toString cfg.httpPort}/' ${cfg.dataDir}/properties/omada.properties
        sed -i 's/^manage\.https\.port=.*/manage.https.port=${toString cfg.httpsPort}/' ${cfg.dataDir}/properties/omada.properties
        sed -i 's/^eap\.mongod\.port=.*/eap.mongod.port=${toString cfg.mongoPort}/' ${cfg.dataDir}/properties/omada.properties
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.httpPort cfg.httpsPort];

    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        description = "omadad server daemon owner";
        group = defaultUser;
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
    };

    users.groups = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        members = [defaultUser];
      };
    };
  };
}
