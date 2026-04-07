{...}: {
  flake.nixosModules.udp-broadcast-relay = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }:
    with lib; let
      cfg = config.services.udp-broadcast-relay;
    in {
      options.services.udp-broadcast-relay = {
        enable = mkEnableOption "UDP broadcast relay";

        package = mkOption {
          type = types.package;
          default = inputs.self.packages.${pkgs.system}.udp-broadcast-relay;
          defaultText = "inputs.self.packages.\${pkgs.system}.udp-broadcast-relay";
          description = "The udp-broadcast-relay package to use.";
        };

        instances = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              id = mkOption {
                type = types.ints.between 1 255;
                description = "Unique instance ID (1–255), used as TTL to prevent packet echo.";
              };
              port = mkOption {
                type = types.port;
                description = "UDP port to relay.";
              };
              interfaces = mkOption {
                type = types.listOf types.str;
                description = "Network interfaces to relay between.";
              };
            };
          });
          default = {};
          description = "Relay instances, one per port.";
        };
      };

      config = mkIf cfg.enable {
        systemd.services = mapAttrs' (name: inst:
          nameValuePair "udp-broadcast-relay-${name}" {
            description = "UDP broadcast relay (${name}) on port ${toString inst.port}";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/udp-broadcast-relay-rs --id ${toString inst.id} --port ${toString inst.port} ${concatMapStringsSep " " (i: "--dev ${i}") inst.interfaces}";
              Restart = "on-failure";
              DynamicUser = true;
              AmbientCapabilities = ["CAP_NET_RAW"];
              CapabilityBoundingSet = ["CAP_NET_RAW"];
            };
          })
        cfg.instances;
      };
    };
}
