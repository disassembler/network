{ config, lib, pkgs, ... }:

with lib;

let
  minecraft-bedrock-server = pkgs.callPackage ./minecraft-bedrock.nix {};
  cfg = config.services.minecraft-bedrock-server;

  cfgToString = v: if builtins.isBool v then boolToString v else toString v;

  serverPropertiesFile = pkgs.writeText "server.properties" (''
    # server.properties managed by NixOS configuration
  '' + concatStringsSep "\n" (mapAttrsToList
    (n: v: "${n}=${cfgToString v}")
    cfg.serverProperties));

  defaultServerPort = 19132;

  serverPort = cfg.serverProperties.server-port or defaultServerPort;

in
{
  options = {
    services.minecraft-bedrock-server = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If enabled, start a Minecraft Bedrock Server. The server
          data will be loaded from and saved to
          <option>services.minecraft-bedrock-server.dataDir</option>.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/minecraft-bedrock";
        description = ''
          Directory to store Minecraft Bedrock database and other state/data files.
        '';
      };

      serverProperties = mkOption {
        type = with types; attrsOf (oneOf [ bool int str ]);
        default = {
          server-name = "Dedicated Server";
          gamemode = "survival";
          difficulty = "hard";
          allow-cheats = false;
          max-players = 100;
          online-mode = false;
          white-list = false;
          server-port = 19132;
          server-portv6 = 19133;
          view-distance = 32;
          tick-distance = 4;
          player-idle-timeout = 30;
          max-threads = 8;
          level-name = "Bedrock level";
          level-seed = "";
          default-player-permission-level = "member";
          texturepack-required = false;
          content-log-file-enabled = false;
          compression-threshold = 1;
          server-authoritative-movement = "server-auth";
          player-movement-score-threshold = 20;
          player-movement-distance-threshold = "0.3";
          player-movement-duration-threshold-in-ms = 500;
          correct-player-movement = false;
        };
        example = literalExample ''
          {
            server-name = "Dedicated Server";
            gamemode = "survival";
            difficulty = "easy";
            allow-cheats = false;
            max-players = 100;
            online-mode = false;
            white-list = false;
            server-port = 19132;
            server-portv6 = 19133;
            view-distance = 32;
            tick-distance = 4;
            player-idle-timeout = 30;
            max-threads = 8;
            level-name = "Bedrock level";
            level-seed = "";
            default-player-permission-level = "member";
            texturepack-required = false;
            content-log-file-enabled = false;
            compression-threshold = 1;
            server-authoritative-movement = "server-auth";
            player-movement-score-threshold = 20;
            player-movement-distance-threshold = 0.3;
            player-movement-duration-threshold-in-ms = 500;
            correct-player-movement = false;
          }
        '';
        description = ''
          Minecraft Bedrock server properties for the server.properties file.
        '';
      };

      package = mkOption {
        type = types.package;
        default = minecraft-bedrock-server;
        defaultText = "pkgs.minecraft-bedrock-server";
        example = literalExample "pkgs.minecraft-bedrock-server-1_16";
        description = "Version of minecraft-bedrock-server to run.";
      };

    };
  };

  config = mkIf cfg.enable {

    users.users.minecraft = {
      description = "Minecraft server service user";
      home = cfg.dataDir;
      createHome = true;
      uid = 114;
      group = "minecraft";
    };
    users.groups.minecraft = { };

    systemd.services.minecraft-bedrock-server = {
      description = "Minecraft Bedrock Server Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/bedrock_server";
        Restart = "always";
        User = "minecraft";
        WorkingDirectory = cfg.dataDir;
      };

      preStart = ''
        rm -rf /var/lib/minecraft-bedrock/*
        cp -a -n ${cfg.package}/var/lib/* .
        cp -f ${serverPropertiesFile} server.properties
        chmod -R u+w .
        ln -sf /var/lib/minecraft-bedrock-data/permissions.json /var/lib/minecraft-bedrock/permissions.json
        ln -sf /var/lib/minecraft-bedrock-data/worlds /var/lib/minecraft-bedrock/worlds
      '';
    };

    networking.firewall = {
      allowedUDPPorts = [ serverPort ];
    };
  };
}
