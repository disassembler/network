{ config, lib, ... }:
with lib;

let
  cfg = config.networking.prod03;
in
{
  options = {
    networking.prod03.ipv4.address = mkOption {
      type = types.str;
      default = "45.63.23.13";
    };
    networking.prod03.ipv4.cidr = mkOption {
      type = types.str;
      default = "23";
    };

    networking.prod03.ipv4.gateway = mkOption {
      type = types.str;
      default = "45.63.22.1";
    };

    networking.prod03.ipv6.addresses = mkOption {
      type = types.listOf types.str;
      default = [
        "2001:19f0:0:1025:5400:ff:fe25:c6da"
      ];
    };

    networking.prod03.ipv6.subnet = mkOption {
      type = types.str;
      default = "2001:19f0:0:1025::/64";
    };

    networking.prod03.ipv6.cidr = mkOption {
      type = types.str;
      default = "64";
    };
    networking.prod03.ipv6.gateway = mkOption {
      type = types.str;
      default = "2001:19f0:0:1025::/64";
    };
  };
  config = {
    networking = {
      hostName = "prod03";
      hostId = "8556b001";
      domain = "samleathers.com";
      search = [ "samleathers.com" ];
      nameservers = [ "127.0.0.1" "8.8.8.8" ];
      useDHCP = false;
      interfaces.ens3.useDHCP = true;
      interfaces.ens7.useDHCP = true;

      #wireguard.interfaces = {
      #  wg0 = {
      #    ips = [ "10.40.9.3/24" "fd00::3" ];
      #    listenPort = 51820;
      #    privateKeyFile = config.sops.secrets.prod03_wg0_private.path;
      #    peers = [
      #      {
      #        publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
      #        allowedIPs = [ "10.40.33.0/24" "10.40.9.1/32" "2601:98a:4101:bff0::1/64" "fd00::1/64" ];
      #        endpoint = "2001:558:6031:52:ec23:4ce0:f3ac:925d:51820";
      #      }
      #    ];

      #  };
      #};
      firewall.extraCommands =
        let
          dropPortNoLog = port:
            ''
              ip46tables -A nixos-fw -p tcp \
              --dport ${toString port} -j nixos-fw-refuse
              ip46tables -A nixos-fw -p udp \
              --dport ${toString port} -j nixos-fw-refuse
            '';

          refusePortOnInterface = port: interface:
            ''
              ip46tables -A nixos-fw -i ${interface} -p tcp \
              --dport ${toString port} -j nixos-fw-log-refuse
              ip46tables -A nixos-fw -i ${interface} -p udp \
              --dport ${toString port} -j nixos-fw-log-refuse
            '';
          acceptPortOnInterface = port: interface:
            ''
              ip46tables -A nixos-fw -i ${interface} -p tcp \
              --dport ${toString port} -j nixos-fw-accept
              ip46tables -A nixos-fw -i ${interface} -p udp \
              --dport ${toString port} -j nixos-fw-accept
            '';
          forwardNATPort = port: source_ip: dest_ip: external_int: internal_int: ''
            iptables -A FORWARD -i ${external_int} -o ${internal_int} -p tcp --syn --dport ${toString port} -m conntrack --ctstate NEW -j ACCEPT
            iptables -A FORWARD -i ${external_int} -o ${internal_int} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -A FORWARD -i ${internal_int} -o ${external_int} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -t nat -A PREROUTING -i ${external_int} -p tcp --dport ${toString port} -j DNAT --to-destination ${dest_ip}
            iptables -t nat -A POSTROUTING -o ${internal_int} -p tcp --dport ${toString port} -d ${dest_ip} -j SNAT --to-source ${source_ip}

          '';
        in
        ''
          iptables -P FORWARD DROP
          ${acceptPortOnInterface 9100 "wg0"}
        '';
    };
  };
}
