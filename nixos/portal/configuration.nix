{
  lib,
  config,
  pkgs,
  ...
}: let
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
  tftp_root = pkgs.runCommand "tftproot" {} ''
    mkdir -pv $out
    cp -vi ${ipxe'}/undionly.kpxe $out/undionly.kpxe
    cp -vi ${ipxe'}/x86_64-ipxe.efi $out/x86_64-ipxe.efi
    cp -vi ${ipxe'}/i386-ipxe.efi $out/i386-ipxe.efi
  '';
in {
  deployment = {
    targetHost = "10.40.33.1";
    targetPort = 22;
    targetUser = "root";
  };
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.portal_wg0_private = {};
  _module.args = {
    inherit shared;
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = ["console=ttyS0,115200n8"];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.enp1s0.accept_ra" = 2;
  };

  security.pki.certificates = [shared.wedlake_ca_cert];

  networking = {
    hostName = "portal";
    domain = "lan.disasm.us";
    hostId = "fa4b7394";
    nameservers = ["10.40.33.1" "8.8.8.8"];
    hosts = lib.mkForce {
      "127.0.0.1" = ["localhost"];
      "::1" = ["localhost"];
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
      br0.interfaces = ["enp2s0" "enp3s0"];
    };
    interfaces = {
      ${externalInterface} = {
        useDHCP = true;
      };
      lan = {
        ipv4.addresses = [
          {
            address = "10.40.33.1";
            prefixLength = 24;
          }
        ];
      };
      iot = {
        ipv4.addresses = [
          {
            address = "10.40.8.1";
            prefixLength = 24;
          }
        ];
      };
      voip = {
        ipv4.addresses = [
          {
            address = "10.40.40.1";
            prefixLength = 24;
          }
        ];
      };
      mgmt = {
        ipv4.addresses = [
          {
            address = "10.40.3.1";
            prefixLength = 24;
          }
        ];
      };
      guest = {
        ipv4.addresses = [
          {
            address = "10.40.10.1";
            prefixLength = 24;
          }
        ];
      };
    };
    nat = {
      enable = true;
      externalInterface = "${externalInterface}";
      internalIPs = ["10.40.33.0/24" "10.40.40.0/24" "10.40.3.0/24" "10.40.10.0/24"];
      internalInterfaces = ["iot" "voip" "lan" "guest" "mgmt" "ovpn-guest"];
      forwardPorts = [
        {
          sourcePort = 32400;
          destination = "10.40.33.20:32400";
          proto = "tcp";
        }
        {
          sourcePort = 19132;
          destination = "10.40.33.21:19132";
          proto = "udp";
        }
        # Ark Survival Ascended
        {
          sourcePort = 7777;
          destination = "10.40.33.21:7777";
          proto = "udp";
        }
        {
          sourcePort = 7778;
          destination = "10.40.33.21:7778";
          proto = "udp";
        }
        {
          sourcePort = 7787;
          destination = "10.40.33.21:7787";
          proto = "udp";
        }
        {
          sourcePort = 7788;
          destination = "10.40.33.21:7788";
          proto = "udp";
        }
        {
          sourcePort = 7797;
          destination = "10.40.33.21:7797";
          proto = "udp";
        }
        {
          sourcePort = 7798;
          destination = "10.40.33.21:7798";
          proto = "udp";
        }
        {
          sourcePort = 7807;
          destination = "10.40.33.21:7807";
          proto = "udp";
        }
        {
          sourcePort = 7808;
          destination = "10.40.33.21:7808";
          proto = "udp";
        }
        {
          sourcePort = 27015;
          destination = "10.40.33.21:27015";
          proto = "udp";
        }
        {
          sourcePort = 27016;
          destination = "10.40.33.21:27016";
          proto = "udp";
        }
        {
          sourcePort = 27017;
          destination = "10.40.33.21:27017";
          proto = "udp";
        }
        {
          sourcePort = 27018;
          destination = "10.40.33.21:27018";
          proto = "udp";
        }
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
      extraCommands = let
        dropPortNoLog = port: ''
          ip46tables -A nixos-fw -p tcp \
          --dport ${toString port} -j nixos-fw-refuse
          ip46tables -A nixos-fw -p udp \
          --dport ${toString port} -j nixos-fw-refuse
        '';

        dropPortIcmpLog = ''
          iptables -A nixos-fw -p icmp \
          -j LOG --log-prefix "iptables[icmp]: "
          ip6tables -A nixos-fw -p ipv6-icmp \
          -j LOG --log-prefix "iptables[icmp-v6]: "
        '';

        refusePortOnInterface = port: interface: ''
          ip46tables -A nixos-fw -i ${interface} -p tcp \
          --dport ${toString port} -j nixos-fw-log-refuse
          ip46tables -A nixos-fw -i ${interface} -p udp \
          --dport ${toString port} -j nixos-fw-log-refuse
        '';
        acceptPortOnInterface = port: interface: ''
          ip46tables -A nixos-fw -i ${interface} -p tcp \
          --dport ${toString port} -j nixos-fw-accept
          ip46tables -A nixos-fw -i ${interface} -p udp \
          --dport ${toString port} -j nixos-fw-accept
        '';
        # IPv6 flat forwarding. For ipv4, see nat.forwardPorts
        forwardPortToHost = port: interface: proto: host: ''
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

        allowPortOnlyPrivately = port: ''
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
          dropPortIcmpLog
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
            ${forwardPortToHost 3001 "enp1s0" "tcp" "2601:985:4c00:c880:1046:d1ff:feea:9276"}
            # block forwarding from external interface
            ip6tables -A FORWARD -i enp1s0 -j DROP
          ''
        ];
      allowedTCPPorts = [32400 5222 5060 53 3001];
      allowedUDPPorts = [51820 1194 1195 5060 5222 53 19132 5353];
    };
    wireguard.interfaces = {
      wg0 = {
        ips = ["10.40.9.1/24" "fd00::1"];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets.portal_wg0_private.path;
        peers = [
          {
            publicKey = "PiXwxQyrMi7iCZvTrmd2V9OB6008aOIU1bOaWi9xOlI=";
            allowedIPs = ["10.40.9.25/32"];
          }
          {
            publicKey = "GJbyHq3IdbkT8xeUb54Ot4PPgU4UtkzpImzNT/Wx+HI=";
            allowedIPs = ["10.40.9.26/32"];
          }
          {
            publicKey = "5f6TDkTVN8OS/xF7M12+rEUibIWljqMrMrBwXU34MUw=";
            allowedIPs = ["10.70.0.1/32"];
          }
          {
            publicKey = "mFn9gVTlPTEa+ZplilmKiZ0pYqzzof75IaDiG9q/pko=";
            allowedIPs = ["10.40.9.39/32" "10.39.0.0/24" "2601:985:4c00:c880::1/64" "fd00::39/128"];
          }
          {
            publicKey = "b1mP5d9m041QyP0jbXicP145BOUYwNefUOOqo6XXwF8=";
            allowedIPs = ["10.40.9.2/32" "fd00::2/128"];
            endpoint = "45.76.4.212:51820";
          }
          {
            publicKey = "V6iLYqTiCzv/zoluqhfWDV49eIIISoZgN30IbS4XZCw=";
            allowedIPs = ["10.42.1.1/32"];
          }
          {
            publicKey = "dCKIaTC40Y5sQqbdsYw1adSgVDmV+1SZMV4DVx1ctSk=";
            allowedIPs = ["10.38.0.0/24" "fd00::38/128"];
          }
          {
            publicKey = "eR6I+LI/BayJ90Kjt0wJyfJUsoSmayD+cb6Kb7qdCV4=";
            allowedIPs = ["10.37.4.0/24" "10.37.6.1/32" "fd00::37/128"];
          }
          #{
          #  # buffalo run
          #  publicKey = "b1SJJq77euLkBM/femF+jJ5HbR/dc3cEQEejYZMtFCA=";
          #  allowedIPs = [ "10.40.9.5/32" ];
          #}
          {
            # greenacres
            publicKey = "NhywNZQlIJitXta1V+HCLSiOTYlgxWOQGvxh2Tvinmk=";
            allowedIPs = ["10.36.3.0/24" "fd00::36/128" "192.168.254.0/24"];
          }
          {
            # bower-office
            publicKey = "rsRvtd4mm4hucE5W1QqCjWJwmSlhWnSWaIWts/Z8/xY=";
            allowedIPs = ["10.38.0.1/32" "192.168.0.0/24"];
            endpoint = "174.175.23.241:51820";
          }
          {
            # bower-home
            publicKey = "3sHFhvDxx6nVX/DBroIGTdHfehl9I/OOB4Fo5v7Vvxc=";
            allowedIPs = ["10.38.0.2/32" "192.168.1.0/24" "192.168.10.0/24"];
            endpoint = "98.235.35.253:51820";
          }
          {
            # clever
            publicKey = "oycbQ1DhtRh0hhD5gpyiKTUh0USkAwbjMer6/h/aHg8=";
            allowedIPs = ["10.40.9.3/32" "fd00::3/128"];
            endpoint = "nas.earthtools.ca:51821";
          }
          {
            # johnalotoski
            publicKey = "MRowDI1eC9B5Hx/zgPk5yyq2eWSq6kYFW5Sjm7w52AY=";
            allowedIPs = ["10.40.9.4/32" "fd00::4/128"];
          }
          # installeriso - uncomment and rotate key when remote installing
          {
            publicKey = "JR2LSc/P4EkEtzywUzf5flIVYz7yR+p7fPEERYrdQ0U=";
            allowedIPs = ["10.40.9.5/32" "fd00::5/128"];
          }
          {
            # hydra-arcade-1
            publicKey = "aq7dxIkmWEQXr3eB7uzZOBEZ0WT6kgEW9BsqqH2eBDE=";
            allowedIPs = ["10.40.9.6/32" "fd00::6/128"];
          }
          {
            # hydra-arcade-2
            publicKey = "Q+Sx+o4ckWuO/CQ9IVCIIfBytXZkgDUIkSS50eUmCWU=";
            allowedIPs = ["10.40.9.7/32" "fd00::7/128"];
          }
          {
            # hydra-arcade-qemu
            publicKey = "A0LYo/Pjx99kUTA9jBzSzfi8qRELOfM+0N0JD1HhcBY=";
            allowedIPs = ["10.40.9.8/32" "fd00::8/128"];
          }
          {
            # hydra-doom-mini
            publicKey = "hP0Z/mlzGoiZ3XgavKGL40wypHKcRVDR1Hkx2Cz28Sg=";
            allowedIPs = ["10.40.9.9/32" "fd00::9/128"];
          }
          {
            # carlos
            publicKey = "/9YVN8nraowBRjhe6ysajY5bp4fUVqJE622OpLpl4Hs=";
            allowedIPs = ["10.40.9.100/32" "fd00::100/128"];
          }
        ];
      };
    };
  };

  nix = {
    settings.substituters = ["https://cache.nixos.org" "https://cache.iog.io"];
    settings.trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  profiles.vim.enable = lib.mkForce false;

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
      allowInterfaces = ["lan" "iot" "mgmt"];
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
      settings = {
        address = [
          "/hivebedrock.network/10.40.33.21"
        ];
      };
    };
    tftpd = {
      enable = true;
      path = tftp_root;
    };
    kea = {
      dhcp4 = {
        enable = true;
        settings = {
          interfaces-config = {
            interfaces = ["lan" "mgmt" "guest" "iot"];
          };
          lease-database = {
            name = "/var/lib/kea/dhcp4.leases";
            persist = true;
            type = "memfile";
          };
          option-data = [
            {
              name = "domain-name-servers";
              data = "10.40.33.1";
              always-send = true;
            }
            {
              name = "routers";
              data = "10.40.33.1";
            }
            {
              name = "domain-name";
              data = "lan.disasm.us";
            }
          ];

          rebind-timer = 2000;
          renew-timer = 1000;
          valid-lifetime = 4000;

          subnet4 = [
            {
              pools = [
                {
                  pool = "10.40.33.100 - 10.40.33.200";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.40.33.1";
                }
              ];
              subnet = "10.40.33.0/24";
              id = 104033;
              reservations = [
                {
                  hostname = "optina";
                  hw-address = "74:d4:35:9b:84:62";
                  ip-address = "10.40.33.20";
                }
                {
                  hostname = "valaam";
                  hw-address = "00:c0:08:9d:ba:42";
                  ip-address = "10.40.33.21";
                }
                {
                  hostname = "mice-rel-1";
                  hw-address = "12:46:d1:ea:92:76";
                  ip-address = "10.40.33.30";
                }
                {
                  hostname = "mice-bp-1";
                  hw-address = "3a:58:ab:bd:83:d1";
                  ip-address = "10.40.33.31";
                }
                {
                  hostname = "atari";
                  hw-address = "94:08:53:84:9b:9d";
                  ip-address = "10.40.33.22";
                }
                {
                  hostname = "kodiak";
                  hw-address = "ec:f4:bb:e7:4b:dc";
                  ip-address = "10.40.33.23";
                }
                {
                  hostname = "valaam-wifi";
                  hw-address = "3c:58:c2:f9:87:5b";
                  ip-address = "10.40.33.24";
                }
                {
                  hostname = "printer";
                  hw-address = "a4:5d:36:d6:22:d9";
                  ip-address = "10.40.33.50";
                }
                {
                  hostname = "sarov";
                  hw-address = "a8:20:66:3b:f4:b9";
                  ip-address = "10.40.33.40";
                }
                {
                  hostname = "iviron";
                  hw-address = "58:02:05:59:84:1c";
                  ip-address = "10.40.33.60";
                }
                {
                  hostname = "irkutsk";
                  hw-address = "9c:b6:d0:95:88:9f";
                  ip-address = "10.40.33.61";
                }
                {
                  hostname = "pskov";
                  hw-address = "cc:15:31:5c:56:b1";
                  ip-address = "10.40.33.62";
                }
                {
                  hostname = "silouan";
                  hw-address = "c0:bf:be:60:c8:10";
                  ip-address = "10.40.33.63";
                }
              ];
            }
            {
              pools = [
                {
                  pool = "10.40.40.100 - 10.40.40.200";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.40.40.1";
                }
              ];
              subnet = "10.40.40.0/24";
              id = 104040;
            }
            {
              pools = [
                {
                  pool = "10.40.10.100 - 10.40.10.200";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.40.10.1";
                }
              ];
              subnet = "10.40.10.0/24";
              id = 104010;
            }
            {
              pools = [
                {
                  pool = "10.40.8.100 - 10.40.8.200";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.40.8.1";
                }
              ];
              subnet = "10.40.8.0/24";
              id = 10408;
              reservations = [
                {
                  hostname = "roof-wled";
                  hw-address = "dc:4f:22:52:e1:d3";
                  ip-address = "10.40.8.60";
                }
                {
                  hostname = "attic-wled";
                  hw-address = "48:55:19:ee:35:9a";
                  ip-address = "10.40.8.61";
                }
                {
                  hostname = "camera-dvr";
                  hw-address = "3c:1b:f8:72:04:ca";
                  ip-address = "10.40.8.20";
                }
              ];
            }
            {
              pools = [
                {
                  pool = "10.40.3.100 - 10.40.3.200";
                }
              ];
              option-data = [
                {
                  name = "routers";
                  data = "10.40.3.1";
                }
              ];
              subnet = "10.40.3.0/24";
              id = 10403;
            }
          ];
        };
      };
    };

    #dhcpd4 = {
    #  interfaces = [ "lan" "mgmt" "guest" "iot" ];
    #  enable = true;
    #  machines = [
    #    { hostName = "optina"; ethernetAddress = "d4:3d:7e:4d:c4:7f"; ipAddress = "10.40.33.20"; }
    #    { hostName = "valaam"; ethernetAddress = "00:c0:08:9d:ba:42"; ipAddress = "10.40.33.21"; }
    #    { hostName = "atari"; ethernetAddress = "94:08:53:84:9b:9d"; ipAddress = "10.40.33.22"; }
    #    { hostName = "kodiak"; ethernetAddress = "ec:f4:bb:e7:4b:dc"; ipAddress = "10.40.33.23"; }
    #    { hostName = "valaam-wifi"; ethernetAddress = "3c:58:c2:f9:87:5b"; ipAddress = "10.40.33.31"; }
    #    { hostName = "printer"; ethernetAddress = "a4:5d:36:d6:22:d9"; ipAddress = "10.40.33.50"; }
    #  ];
    #  extraConfig = ''
    #  option arch code 93 = unsigned integer 16;
    #  option rpiboot code 43 = text;

    #    # Allow UniFi devices to locate the controller from a separate VLAN
    #    option space ubnt;
    #    option ubnt.UNIFI-IP-ADDRESS code 1 = ip-address;
    #    option ubnt.UNIFI-IP-ADDRESS 10.40.33.20;
    #    option ovwma code 138 = ip-address;

    #    class "ubnt" {
    #      match if substring (option vendor-class-identifier, 0, 4) = "ubnt";
    #      option vendor-class-identifier "ubnt";
    #      vendor-option-space ubnt;
    #    }

    #    subnet 10.40.33.0 netmask 255.255.255.0 {
    #      option domain-search "lan.disasm.us";
    #      option subnet-mask 255.255.255.0;
    #      option broadcast-address 10.40.33.255;
    #      option routers 10.40.33.1;
    #      option domain-name-servers 10.40.33.1;
    #      range 10.40.33.100 10.40.33.200;
    #      next-server 10.40.33.1;
    #      if exists user-class and option user-class = "iPXE" {
    #        filename "http://netboot.lan.disasm.us/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
    #      } else {
    #        if option arch = 00:07 or option arch = 00:09 {
    #          filename = "x86_64-ipxe.efi";
    #        } else {
    #          filename = "undionly.kpxe";
    #        }
    #      }
    #      option rpiboot "Raspberry Pi Boot   ";
    #    }
    #    subnet 10.40.40.0 netmask 255.255.255.0 {
    #      option subnet-mask 255.255.255.0;
    #      option broadcast-address 10.40.40.255;
    #      option routers 10.40.40.1;
    #      option domain-name-servers 10.40.40.1;
    #      range 10.40.40.100 10.40.40.200;
    #    }
    #    subnet 10.40.10.0 netmask 255.255.255.0 {
    #      option subnet-mask 255.255.255.0;
    #      option broadcast-address 10.40.10.255;
    #      option routers 10.40.10.1;
    #      option domain-name-servers 10.40.10.1;
    #      range 10.40.10.100 10.40.10.200;
    #    }
    #    subnet 10.40.8.0 netmask 255.255.255.0 {
    #      option subnet-mask 255.255.255.0;
    #      option broadcast-address 10.40.8.255;
    #      option routers 10.40.8.1;
    #      option domain-name-servers 10.40.8.1;
    #      range 10.40.8.100 10.40.8.200;
    #    }
    #    subnet 10.40.3.0 netmask 255.255.255.0 {
    #      option subnet-mask 255.255.255.0;
    #      option broadcast-address 10.40.3.255;
    #      option routers 10.40.3.1;
    #      option domain-name-servers 10.40.3.1;
    #      range 10.40.3.100 10.40.3.200;
    #      option ovwma 10.40.33.20;
    #    }
    #    '';
    #  };
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
    #        server-ipv6 2601:98a:94b1:bff3::/64
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
    extraGroups = ["wheel"];
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
