{ lib, config, pkgs, secrets, shared, ... }:
let
  externalInterface = "enp1s0";
  internalInterfaces = [
    "br0"
    "enp3s0.3"
    "enp3s0.9"
    "enp3s0.12"
    "enp3s0.40"
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
  tftp_root = pkgs.runCommand "tftproot" {} ''
    mkdir -pv $out
    cp -vi ${ipxe'}/undionly.kpxe $out/undionly.kpxe
    cp -vi ${ipxe'}/x86_64-ipxe.efi $out/x86_64-ipxe.efi
    cp -vi ${ipxe'}/i386-ipxe.efi $out/i386-ipxe.efi
  '';


in {
  imports =
    [
      ./hardware.nix
    ];
  deployment.keys."wg0-private".text = secrets.portal_wg0_private;


  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.enp1s0.accept_ra" = 2;
  };

  networking = {
    hostName = "portal.wedlake.lan";
    hostId = "fa4b7394";
    nameservers = [ "10.40.33.1" "8.8.8.8" ];
    vlans = {
      lan_port = {
        interface = "enp3s0";
        id = 33;
      };
      mgmt = {
        interface = "enp3s0";
        id = 3;
      };
      voip = {
        interface = "enp3s0";
        id = 40;
      };
    };
    bridges = {
      br0.interfaces = [ "lan_port" "enp2s0" ];
    };
    interfaces = {
      ${externalInterface} = {
        useDHCP = true;
      };
      br0 = {
        ipv4.addresses = [{
          address = "10.40.33.1";
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
    };
    nat = {
      enable = true;
      externalInterface = "${externalInterface}";
      internalIPs = [ "10.40.33.0/24" "10.40.40.0/24" ];
      internalInterfaces = [ "voip" "br0" "ovpn-guest" ];
      forwardPorts = [
        { sourcePort = 32400; destination = "10.40.33.20:32400"; proto = "tcp"; }
        #{ sourcePort = 1194; destination = "10.40.33.20:1194"; proto = "udp"; }
      ];
    };
    enableIPv6 = true;
    dhcpcd.persistent = true;
    dhcpcd.extraConfig = ''
      noipv6rs
      interface ${externalInterface}
      ia_na 1
      ia_pd 2/::/60 br0/0/64 voip/1/64
    '';
    firewall = {
      enable = true;
      allowPing = true;
      extraCommands = let
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
      in lib.concatStrings [
        (lib.concatMapStrings allowPortOnlyPrivately
          [
            67    # DHCP
            69    # TFTP
            546   # DHCPv6
            547   # DHCPv6
            9100  # prometheus
          ])
        (lib.concatMapStrings dropPortNoLog
          [
            23   # Common from public internet
            143  # Common from public internet
            139  # From RT AP
            515  # From RT AP
            9100 # From RT AP
          ])
        (dropPortIcmpLog)
        ''
          # block internal traffic from guest vpn
          ip46tables -A FORWARD -m state --state NEW -i ovpn-guest -o br0 -j DROP
          # allow from trusted interfaces
          ip46tables -A FORWARD -m state --state NEW -i br0 -o enp1s0 -j ACCEPT
          ip46tables -A FORWARD -m state --state NEW -i voip -o enp1s0 -j ACCEPT
          ip46tables -A FORWARD -m state --state NEW -i wg0 -o enp1s0 -j ACCEPT
          ip46tables -A FORWARD -m state --state NEW -i tun0 -o enp1s0 -j ACCEPT
          # allow traffic with existing state
          ip46tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
          # block forwarding from external interface
          ip6tables -A FORWARD -i enp1s0 -j DROP
        ''
      ];
      allowedTCPPorts = [ 32400 5222 5060 53 ];
      allowedUDPPorts = [ 51820 1194 1195 5060 5222 53 ];
    };
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.40.9.1/24" "fd00::1" ];
        listenPort = 51820;
        privateKeyFile = "/run/keys/wg0-private";
        peers = [
          {
            publicKey = "mFn9gVTlPTEa+ZplilmKiZ0pYqzzof75IaDiG9q/pko=";
            allowedIPs = [ "10.40.9.39/32" "10.39.0.0/24" "2601:98a:4000:9ed0::1/64" "fd00::39/128" ];
          }
          {
            publicKey = "b1mP5d9m041QyP0jbXicP145BOUYwNefUOOqo6XXwF8=";
            allowedIPs = [ "10.40.9.2/32" "fd00::2/128" ];
          }
          {
            publicKey = "dCKIaTC40Y5sQqbdsYw1adSgVDmV+1SZMV4DVx1ctSk=";
            allowedIPs = [ "10.38.0.0/24" "fd00::38/128" ];
          }
          {
            publicKey = "eR6I+LI/BayJ90Kjt0wJyfJUsoSmayD+cb6Kb7qdCV4=";
            allowedIPs = [ "10.37.4.0/24" "10.37.6.1/32" "fd00::37/128" ];
          }
        ];

      };
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (import ../overlays/asterisk.nix)
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    vim
    tmux
    git
    tcpdump
    dnsutils
  ];

  services = {
    unbound = {
      enable = true;
      interfaces = [ "0.0.0.0" "::" ];
      allowedAccess = [
        "10.40.33.0/24"
        "10.39.0.0/24"
        "10.40.9.39/32"
        "2601:98a:4101:bff0::/60"
        "2601:98a:4000:3900::/64"
      ];
      extraConfig = ''
        # server indent level
          logfile: ""
          log-queries: no
          verbosity: 4
          do-not-query-localhost: no
          domain-insecure: "wedlake.lan"
        forward-zone:
          name: "wedlake.lan"
          forward-addr: ::1@5353
      '';
    };
    nsd = {
      enable = true;
      interfaces = [ "127.0.0.1" "::1" ];
      port = 5353;
      zones."wedlake.lan.".data = ''
        @ SOA ns.wedlake.lan portal.wedlake.lan 666 7200 3600 1209600 3600
        optina      A       10.40.33.20
        optina      AAAA    2601:98a:4101:bff0:d63d:7eff:fe4d:c47f
        cloud       CNAME   optina
        crate       CNAME   optina
        git         CNAME   optina
        hledger     CNAME   optina
        hydra       CNAME   optina
        mpd         CNAME   optina
        netboot     CNAME   optina
        plex        CNAME   optina
        unifi       CNAME   optina
        printer     A       10.40.33.50
        ns          A       10.40.33.1
        ns          AAAA    2601:98a:4101:bff0::1
        portal      A       10.40.33.1
        portal      AAAA    2601:98a:4101:bff0::1
        prod01      AAAA    fd00::2
      '';
    };
    asterisk = {
      enable = true;
      confFiles = import ./asterisk-config.nix;
    };
    tftpd = {
      enable = true;
      path = tftp_root;
    };
    dhcpd4 = {
      interfaces = [ "br0" "voip" "mgmt" ];
      enable = true;
      machines = [
        { hostName = "optina"; ethernetAddress = "d4:3d:7e:4d:c4:7f"; ipAddress = "10.40.33.20"; }
        { hostName = "printer"; ethernetAddress = "a4:5d:36:d6:22:d9"; ipAddress = "10.40.33.50"; }
      ];
      extraConfig = ''
        option arch code 93 = unsigned integer 16;
        option rpiboot code 43 = text;
        subnet 10.40.33.0 netmask 255.255.255.0 {
          option domain-search "wedlake.lan";
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.33.255;
          option routers 10.40.33.1;
          option domain-name-servers 10.40.33.1;
          range 10.40.33.100 10.40.33.200;
          next-server 10.40.33.1;
          if exists user-class and option user-class = "iPXE" {
            filename "http://netboot.wedlake.lan/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
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
          option domain-name-servers 10.40.33.20;
          range 10.40.40.100 10.40.40.200;
        }
      '';
    };
    radvd = {
      enable = true;
      config = ''
        interface br0
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
        hosts: ["optina.wedlake.lan:9092"]
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
    openvpn = {
      servers = {
        wedlake = {
          config = ''
          dev tun
          proto udp
          port 1194
          tun-ipv6
          ca /var/lib/openvpn/ca.crt
          cert /var/lib/openvpn/crate.wedlake.lan.crt
          key /var/lib/openvpn/crate.wedlake.lan.key
          dh /var/lib/openvpn/dh2048.pem
          server 10.40.12.0 255.255.255.0
          server-ipv6 2601:98a:4101:bff2::/64
          push "route 10.40.33.0 255.255.255.0"
          push "route-ipv6 2000::/3"
          push "dhcp-option DNS 10.40.33.20"
          duplicate-cn
          keepalive 10 120
          tls-auth /var/lib/openvpn/ta.key 0
          comp-lzo
          user openvpn
          group root
          persist-key
          persist-tun
          status openvpn-status.log
          verb 3
          '';
        };
        guest = {
          config = ''
          dev ovpn-guest
          dev-type tun
          proto udp
          port 1195
          tun-ipv6
          ca /var/lib/openvpn/ca.crt
          cert /var/lib/openvpn/crate.wedlake.lan.crt
          key /var/lib/openvpn/crate.wedlake.lan.key
          dh /var/lib/openvpn/dh2048.pem
          server 10.40.13.0 255.255.255.0
          push "redirect-gateway def1"
          push "dhcp-option DNS 8.8.8.8"
          duplicate-cn
          keepalive 10 120
          tls-auth /var/lib/openvpn/ta-guest.key 0
          comp-lzo
          user openvpn
          group root
          persist-key
          persist-tun
          status openvpn-status.log
          verb 3
          '';
        };
      };
    };
  };

  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.extraUsers.openvpn = {
    isNormalUser = true;
    uid = 1003;
  };
  system.stateVersion = "17.09";
}
