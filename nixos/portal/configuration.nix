{ lib, config, pkgs, ... }:
let
  # TODO: move to flake
  shared = import ../../shared.nix;
  externalInterface = "enp1s0";
  internalInterfaces = [
    "mgmt"
    "lan"
    "guest"
    "voip"
    "iot"
    "wg0"
    "tun0"
  ];
  ipxe' = pkgs.ipxe.overrideDerivation (drv: {
    installPhase = ''
      ${drv.installPhase}
      make $makeFlags bin-x86_64-efi/ipxe.efi bin-i386-efi/ipxe.efi
      cp -v bin-x86_64-efi/ipxe.efi $out/x86_64-ipxe.efi
      cp -v bin-i386-efi/ipxe.efi $out/i386-ipxe.efi
    '';
  });
  tftp_root = pkgs.runCommand "tftproot" { } ''
    mkdir -pv $out
    cp -vi ${ipxe'}/undionly.kpxe $out/undionly.kpxe
    cp -vi ${ipxe'}/x86_64-ipxe.efi $out/x86_64-ipxe.efi
    cp -vi ${ipxe'}/i386-ipxe.efi $out/i386-ipxe.efi
  '';


in
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.portal_wg0_private = { };
  imports =
    [
      ./hardware-configuration.nix
    ];
  # TODO: move up
  _module.args = {
    inherit shared;
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.enp1s0.accept_ra" = 2;
  };

  security.pki.certificates = [ shared.wedlake_ca_cert ];

  networking = {
    hostName = "portal";
    domain = "lan.disasm.us";
    hostId = "fa4b7394";
    nameservers = [ "10.40.33.1" "8.8.8.8" ];
    hosts = lib.mkForce {
      "127.0.0.1" = [ "localhost" ];
      "::1" = [ "localhost" ];
    };
    vlans = {
      lan = {
        interface = "br0";
        id = 33;
      };
      mgmt = {
        interface = "br0";
        id = 3;
      };
      iot = {
        interface = "br0";
        id = 8;
      };
      guest = {
        interface = "br0";
        id = 9;
      };
      voip = {
        interface = "br0";
        id = 40;
      };
    };
    bridges = {
      br0.interfaces = [ "enp2s0" "enp3s0" ];
    };
    interfaces = {
      ${externalInterface} = {
        useDHCP = true;
      };
      lan = {
        ipv4.addresses = [{
          address = "10.40.33.1";
          prefixLength = 24;
        }];
      };
      iot = {
        ipv4.addresses = [{
          address = "10.40.8.1";
          prefixLength = 24;
        }];
      };
      voip = {
        ipv4.addresses = [{
          address = "10.40.40.1";
          prefixLength = 24;
        }];
      };
      mgmt = {
        ipv4.addresses = [{
          address = "10.40.3.1";
          prefixLength = 24;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = "10.40.10.1";
          prefixLength = 24;
        }];
      };
    };
    nat = {
      enable = true;
      externalInterface = "${externalInterface}";
      internalIPs = [ "10.40.33.0/24" "10.40.40.0/24" "10.40.3.0/24" "10.40.10.0/24" ];
      internalInterfaces = [ "iot" "voip" "lan" "guest" "mgmt" "ovpn-guest" ];
      forwardPorts = [
        { sourcePort = 32400; destination = "10.40.33.20:32400"; proto = "tcp"; }
        { sourcePort = 19132; destination = "10.40.33.20:19132"; proto = "udp"; }
      ];
    };
    enableIPv6 = true;
    dhcpcd.persistent = true;
    # NOTE: 3 is taken by openvpn
    dhcpcd.extraConfig = ''
      noipv6rs
      interface ${externalInterface}
      ia_na 1
      ia_pd 2/::/60 lan/0/64 mgmt/1/64 guest/2/64 iot/4/64
    '';
    firewall = {
      enable = true;
      allowPing = true;
      extraCommands =
        let
          dropPortNoLog = port:
            ''
              ip46tables -A nixos-fw -p tcp \
                --dport ${toString port} -j nixos-fw-refuse
              ip46tables -A nixos-fw -p udp \
                --dport ${toString port} -j nixos-fw-refuse
            '';

          dropPortIcmpLog =
            ''
              iptables -A nixos-fw -p icmp \
                -j LOG --log-prefix "iptables[icmp]: "
              ip6tables -A nixos-fw -p ipv6-icmp \
                -j LOG --log-prefix "iptables[icmp-v6]: "
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
          # IPv6 flat forwarding. For ipv4, see nat.forwardPorts
          forwardPortToHost = port: interface: proto: host:
            ''
              ip6tables -A FORWARD -i ${interface} \
                -p ${proto} -d ${host} \
                --dport ${toString port} -j ACCEPT
              ip6tables -A nixos-fw -i ${interface} \
                -p ${proto} -d ${host} \
                --dport ${toString port} -j ACCEPT
            '';

          privatelyAcceptPort = port:
            lib.concatMapStrings
              (interface: acceptPortOnInterface port interface)
              internalInterfaces;

          publiclyRejectPort = port:
            refusePortOnInterface port externalInterface;

          allowPortOnlyPrivately = port:
            ''
              ${privatelyAcceptPort port}
              ${publiclyRejectPort port}
            '';
        in
        lib.concatStrings [
          (lib.concatMapStrings allowPortOnlyPrivately
            [
              67 # DHCP
              69 # TFTP
              546 # DHCPv6
              547 # DHCPv6
              9100 # prometheus
              5201 # iperf
            ])
          (lib.concatMapStrings dropPortNoLog
            [
              23 # Common from public internet
              143 # Common from public internet
              139 # From RT AP
              515 # From RT AP
              9100 # From RT AP
            ])
          (dropPortIcmpLog)
          ''
            # block internal traffic from guest vpn
            ip46tables -A FORWARD -m state --state NEW -i ovpn-guest -o br0 -j DROP
            # allow from trusted interfaces
            ip46tables -A FORWARD -m state --state NEW -i br0 -o enp1s0 -j ACCEPT
            ip46tables -A FORWARD -m state --state NEW -i wg0 -o enp1s0 -j ACCEPT
            ip46tables -A FORWARD -m state --state NEW -i tun0 -o enp1s0 -j ACCEPT
            # allow traffic with existing state
            ip46tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
            # Allow forwarding the following ports from Internet via IPv6 only
            ${forwardPortToHost 3001 "enp1s0" "tcp" "2601:98a:4102:ef0:8c6d:c3ff:fe13:5d63"}
            # block forwarding from external interface
            ip6tables -A FORWARD -i enp1s0 -j DROP
          ''
        ];
      allowedTCPPorts = [ 32400 5222 5060 53 3001 ];
      allowedUDPPorts = [ 51820 1194 1195 5060 5222 53 config.services.toxvpn.port 19132 5353 ];
    };
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.40.9.1/24" "fd00::1" ];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets.portal_wg0_private.path;
        peers = [
          {
            publicKey = "PiXwxQyrMi7iCZvTrmd2V9OB6008aOIU1bOaWi9xOlI=";
            allowedIPs = [ "10.40.9.25/32" ];
          }
          {
            publicKey = "mFn9gVTlPTEa+ZplilmKiZ0pYqzzof75IaDiG9q/pko=";
            allowedIPs = [ "10.40.9.39/32" "10.39.0.0/24" "2601:98a:4000:9ed0::1/64" "fd00::39/128" ];
          }
          {
            publicKey = "b1mP5d9m041QyP0jbXicP145BOUYwNefUOOqo6XXwF8=";
            allowedIPs = [ "10.40.9.2/32" "fd00::2/128" ];
            endpoint = "45.76.4.212:51820";
          }
          {
            publicKey = "V6iLYqTiCzv/zoluqhfWDV49eIIISoZgN30IbS4XZCw=";
            allowedIPs = [ "10.42.1.1/32" ];
          }
          {
            publicKey = "dCKIaTC40Y5sQqbdsYw1adSgVDmV+1SZMV4DVx1ctSk=";
            allowedIPs = [ "10.38.0.0/24" "fd00::38/128" ];
          }
          {
            publicKey = "eR6I+LI/BayJ90Kjt0wJyfJUsoSmayD+cb6Kb7qdCV4=";
            allowedIPs = [ "10.37.4.0/24" "10.37.6.1/32" "fd00::37/128" ];
          }
          {
            # buffalo run
            publicKey = "b1SJJq77euLkBM/femF+jJ5HbR/dc3cEQEejYZMtFCA=";
            allowedIPs = [ "10.40.9.5/32" ];
          }
          {
            # greenacres
            publicKey = "NhywNZQlIJitXta1V+HCLSiOTYlgxWOQGvxh2Tvinmk=";
            allowedIPs = [ "10.36.3.0/24" "fd00::36/128" "192.168.254.0/24" ];
          }
          {
            # bower-office
            publicKey = "rsRvtd4mm4hucE5W1QqCjWJwmSlhWnSWaIWts/Z8/xY=";
            allowedIPs = [ "10.38.0.1/32" "192.168.0.0/24" ];
            endpoint = "73.230.94.119:51820";
          }
          {
            # bower-home
            publicKey = "3sHFhvDxx6nVX/DBroIGTdHfehl9I/OOB4Fo5v7Vvxc=";
            allowedIPs = [ "10.38.0.2/32" "192.168.1.0/24" "192.168.10.0/24" ];
            endpoint = "98.235.35.253:51820";
          }
          {
            # clever
            publicKey = "oycbQ1DhtRh0hhD5gpyiKTUh0USkAwbjMer6/h/aHg8=";
            allowedIPs = [ "10.40.9.3/32" "fd00::3/128" ];
            endpoint = "nas.earthtools.ca:51821";
          }
          {
            # johnalotoski
            publicKey = "MRowDI1eC9B5Hx/zgPk5yyq2eWSq6kYFW5Sjm7w52AY=";
            allowedIPs = [ "10.40.9.4/32" "fd00::4/128" ];
          }
        ];

      };
    };
  };

  nix = {
    settings.substituters = [ "https://cache.nixos.org" "https://hydra.iohk.io" ];
    settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    package = pkgs.nixUnstable;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  environment.systemPackages = with pkgs; [
    jq
    wget
    vim
    tmux
    git
    tcpdump
    dnsutils
  ];

  services = {
    avahi = {
      enable = true;
      interfaces = [ "lan" "iot" "mgmt" ];
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    toxvpn = {
      enable = false;
      localip = "10.40.13.1";
    };
    dnsmasq = {
      enable = true;
      extraConfig = ''
        address=/hivebedrock.network/10.40.33.20
      '';
    };
    tftpd = {
      enable = true;
      path = tftp_root;
    };
    dhcpd4 = {
      interfaces = [ "lan" "mgmt" "guest" "iot" ];
      enable = true;
      machines = [
        { hostName = "optina"; ethernetAddress = "d4:3d:7e:4d:c4:7f"; ipAddress = "10.40.33.20"; }
        { hostName = "valaam"; ethernetAddress = "00:c0:08:9d:ba:42"; ipAddress = "10.40.33.21"; }
        { hostName = "atari"; ethernetAddress = "94:08:53:84:9b:9d"; ipAddress = "10.40.33.22"; }
        { hostName = "valaam-wifi"; ethernetAddress = "3c:58:c2:f9:87:5b"; ipAddress = "10.40.33.31"; }
        { hostName = "printer"; ethernetAddress = "a4:5d:36:d6:22:d9"; ipAddress = "10.40.33.50"; }
      ];
      extraConfig = ''
        option arch code 93 = unsigned integer 16;
        option rpiboot code 43 = text;

        # Allow UniFi devices to locate the controller from a separate VLAN
        option space ubnt;
        option ubnt.UNIFI-IP-ADDRESS code 1 = ip-address;
        option ubnt.UNIFI-IP-ADDRESS 10.40.33.20;

        class "ubnt" {
          match if substring (option vendor-class-identifier, 0, 4) = "ubnt";
          option vendor-class-identifier "ubnt";
          vendor-option-space ubnt;
        }

        subnet 10.40.33.0 netmask 255.255.255.0 {
          option domain-search "lan.disasm.us";
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.33.255;
          option routers 10.40.33.1;
          option domain-name-servers 10.40.33.1;
          range 10.40.33.100 10.40.33.200;
          next-server 10.40.33.1;
          if exists user-class and option user-class = "iPXE" {
            filename "http://netboot.lan.disasm.us/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
          } else {
            if option arch = 00:07 or option arch = 00:09 {
              filename = "x86_64-ipxe.efi";
            } else {
              filename = "undionly.kpxe";
            }
          }
          option rpiboot "Raspberry Pi Boot   ";
        }
        subnet 10.40.40.0 netmask 255.255.255.0 {
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.40.255;
          option routers 10.40.40.1;
          option domain-name-servers 10.40.40.1;
          range 10.40.40.100 10.40.40.200;
        }
        subnet 10.40.10.0 netmask 255.255.255.0 {
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.10.255;
          option routers 10.40.10.1;
          option domain-name-servers 10.40.10.1;
          range 10.40.10.100 10.40.10.200;
        }
        subnet 10.40.8.0 netmask 255.255.255.0 {
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.8.255;
          option routers 10.40.8.1;
          option domain-name-servers 10.40.8.1;
          range 10.40.8.100 10.40.8.200;
        }
        subnet 10.40.3.0 netmask 255.255.255.0 {
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.3.255;
          option routers 10.40.3.1;
          option domain-name-servers 10.40.3.1;
          range 10.40.3.100 10.40.3.200;
        }
      '';
    };
    radvd = {
      enable = true;
      config = ''
        interface lan
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
        interface mgmt
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
        interface guest
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
        interface voip
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
        interface iot
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
      '';
    };
    journald = {
      rateLimitBurst = 0;
      extraConfig = "SystemMaxUse=50M";
    };
    journalbeat = {
      enable = false;
      extraConfig = ''
        journalbeat:
          seek_position: cursor
          cursor_seek_fallback: tail
          write_cursor_state: true
          cursor_flush_period: 5s
          clean_field_names: true
          convert_to_numbers: false
          move_metadata_to_field: journal
          default_type: journal
        output.kafka:
          hosts: ["optina.lan.disasm.us:9092"]
          topic: KAFKA-LOGSTASH-ELASTICSEARCH
      '';
    };
    prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "tcpstat"
          "conntrack"
          "diskstats"
          "entropy"
          "filefd"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "netstat"
          "stat"
          "time"
          "vmstat"
          "logind"
          "interrupts"
          "ksmd"
        ];
      };
    };
    #openvpn = {
    #  servers = {
    #    wedlake = {
    #      config = ''
    #        dev tun
    #        proto udp
    #        port 1194
    #        tun-ipv6
    #        ca /var/lib/openvpn/ca.crt
    #        cert /var/lib/openvpn/crate.wedlake.lan.crt
    #        key /var/lib/openvpn/crate.wedlake.lan.key
    #        dh /var/lib/openvpn/dh2048.pem
    #        server 10.40.12.0 255.255.255.0
    #        server-ipv6 2601:98a:4101:bff3::/64
    #        push "route 10.40.33.0 255.255.255.0"
    #        push "route-ipv6 2000::/3"
    #        push "dhcp-option DNS 10.40.12.1"
    #        duplicate-cn
    #        keepalive 10 120
    #        tls-auth /var/lib/openvpn/ta.key 0
    #        comp-lzo
    #        user openvpn
    #        group root
    #        persist-key
    #        persist-tun
    #        status openvpn-status.log
    #        verb 3
    #      '';
    #    };
    #    guest = {
    #      config = ''
    #        dev ovpn-guest
    #        dev-type tun
    #        proto udp
    #        port 1195
    #        tun-ipv6
    #        ca /var/lib/openvpn/ca.crt
    #        cert /var/lib/openvpn/crate.wedlake.lan.crt
    #        key /var/lib/openvpn/crate.wedlake.lan.key
    #        dh /var/lib/openvpn/dh2048.pem
    #        server 10.40.13.0 255.255.255.0
    #        push "redirect-gateway def1"
    #        push "dhcp-option DNS 8.8.8.8"
    #        duplicate-cn
    #        keepalive 10 120
    #        tls-auth /var/lib/openvpn/ta-guest.key 0
    #        comp-lzo
    #        user openvpn
    #        group root
    #        persist-key
    #        persist-tun
    #        status openvpn-status.log
    #        verb 3
    #      '';
    #    };
    #  };
    #};
  };
  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.extraUsers.root = {
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.extraUsers.openvpn = {
    isNormalUser = true;
    uid = 1003;
  };
  system.stateVersion = "17.09";
}
