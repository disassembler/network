{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # TODO: move to flake
  shared = import ../../shared.nix;
  externalInterface = "enp1s0";
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
  keaDdnsConf = pkgs.writeText "kea-dhcp-ddns.conf" ''
    {
      "DhcpDdns": {
        "ip-address": "127.0.0.1",
        "port": 53001,
        "dns-server-timeout": 500,
        "ncr-protocol": "UDP",
        "ncr-format": "JSON",
        "tsig-keys": [ <?include "${config.sops.secrets.portal_knot_tsig.path}" ?> ],
        "forward-ddns": {
          "ddns-domains": [
            {
              "name": "disasm.us.",
              "dns-servers": [
                { "ip-address": "10.40.9.2", "port": 53, "key-name": "portal" }
              ]
            }
          ]
        },
        "reverse-ddns": { "ddns-domains": [] },
        "loggers": [
          {
            "name": "kea-dhcp-ddns",
            "output-options": [{ "output": "syslog" }],
            "severity": "INFO"
          }
        ]
      }
    }
  '';
in {
  deployment = {
    #targetHost = "10.40.33.1";
    targetHost = "portal.lan.disasm.us";
    targetPort = 22;
    targetUser = "root";
  };
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.portal_wg0_private = {};
  sops.secrets.portal_knot_tsig.owner = "kea";
  _module.args = {
    inherit shared;
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = ["console=ttyS0,115200n8"];
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
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
    enableIPv6 = true;
    dhcpcd.persistent = true;
    dhcpcd.extraConfig = ''
      noipv6rs
      interface ${externalInterface}
      ia_na 1
      ia_pd 2/::/60 lan/0/64 mgmt/1/64 guest/2/64 iot/4/64
    '';
    firewall.enable = false;
    nftables = {
      enable = true;
      tables."portal" = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority filter; policy drop;
            ct state established,related accept
            ct state invalid drop
            iifname "lo" accept
            ip protocol icmp log prefix "nftables[icmp]: " accept
            ip6 nexthdr icmpv6 log prefix "nftables[icmp-v6]: " accept

            # Noisy ports — drop silently before general rules
            tcp dport { 23, 139, 143, 515 } drop
            udp dport { 23, 139, 143, 515 } drop

            # Public services (all interfaces)
            tcp dport { 22, 53, 3001, 5060, 5222, 32400 } accept
            udp dport { 53, 5060, 5222, 5353, 19132, 51820, 51821 } accept

            # Internal-only services
            iifname { "mgmt", "lan", "guest", "voip", "iot", "wg0" } tcp dport { 67, 69, 546, 547, 5201, 9100 } accept
            iifname { "mgmt", "lan", "guest", "voip", "iot", "wg0" } udp dport { 67, 69, 546, 547, 5201, 9100 } accept

            # synaptex-router
            iifname "lan" tcp dport 50052 accept
            iifname { "lan", "iot" } udp dport { 6666, 6667 } accept

            # DHCPv6 client on WAN — allow ISP server responses (ADVERTISE/REPLY → port 546)
            iifname "enp1s0" udp dport 546 accept

            # IPv6: port 3001 from WAN to mice-rel-1 (EUI-64 match)
            iifname "enp1s0" ip6 daddr & ::ffff:ffff:ffff:ffff == ::1046:d1ff:feea:9276 tcp dport 3001 accept
          }

          chain forward {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ct state invalid drop
            tcp flags syn tcp option maxseg size set rt mtu

            # Allow trusted interfaces → WAN
            iifname { "lan", "mgmt", "guest", "voip", "iot", "wg0" } oifname "enp1s0" accept

            # Allow WAN → port-forwarded internal servers (Plex, gaming, WG relay)
            iifname "enp1s0" ip daddr { 10.40.33.20, 10.40.33.21, 10.40.33.156 } accept

            # Allow WireGuard ↔ internal networks
            iifname "wg0" oifname { "lan", "mgmt" } accept
            iifname { "lan", "mgmt" } oifname "wg0" accept

            # lan ↔ mgmt: full lan access to mgmt (switch web UIs etc.)
            iifname "lan" oifname "mgmt" accept
            # mgmt → lan: only optina and kursk
            iifname "mgmt" oifname "lan" ip daddr { 10.40.33.20, 10.40.33.70 } accept

            # Tuya: lan → iot device communication
            iifname "lan" oifname "iot" tcp dport 6668 accept
            iifname "lan" oifname "iot" ip protocol icmp accept

            # IPv6: port 3001 from WAN → mice-rel-1
            iifname "enp1s0" ip6 daddr & ::ffff:ffff:ffff:ffff == ::1046:d1ff:feea:9276 tcp dport 3001 accept

            # Drop all other IPv6 inbound from WAN
            iifname "enp1s0" meta nfproto ipv6 drop
          }
        '';
      };
      tables."portal-nat" = {
        family = "ip";
        content = ''
          chain prerouting {
            type nat hook prerouting priority dstnat;

            # Plex
            iifname "enp1s0" tcp dport 32400 dnat to 10.40.33.20:32400

            # WireGuard relay (port remap 51821→51820)
            iifname "enp1s0" udp dport 51821 dnat to 10.40.33.156:51820

            # Minecraft Bedrock
            iifname "enp1s0" udp dport 19132 dnat to 10.40.33.21

            # Ark Survival Ascended
            iifname "enp1s0" udp dport { 7777, 7778, 7787, 7788, 7797, 7798, 7807, 7808 } dnat to 10.40.33.21

            # Steam
            iifname "enp1s0" udp dport { 27015, 27016, 27017, 27018 } dnat to 10.40.33.21
          }

          chain postrouting {
            type nat hook postrouting priority srcnat;

            # Masquerade internal subnets out WAN
            oifname "enp1s0" iifname { "lan", "mgmt", "guest", "voip", "iot" } masquerade
          }
        '';
      };
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
            allowedIPs = ["10.40.9.39/32" "10.39.0.0/24" "fd00::39/128"];
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
            publicKey = "vTj/lpoqdzFPtrQs7w9Wox58Puu1seMxOKSjWICLiGg=";
            allowedIPs = ["10.38.0.3/32" "10.38.1.0/24"];
            endpoint = "vpn.bower-law.com:51820";
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
    synaptex-router = {
      enable = true;
      package = inputs.synaptex.packages.x86_64-linux.synaptex-router;
      interfaces = ["iot" "lan"];
      # TODO deploy with sops
      # clientCaFile = /path/to/core.crt;  # enable mTLS

      # Build synaptex_hook.so against this system's kea (version-matched).
      keaHookSrc = inputs.synaptex + "/src/kea-hook";

      # Kea DHCP integration
      keaSocket = "/run/synaptex-router/kea-hook.sock";
      keaIotRelay = ["10.40.8.1"];
      keaSubnetId = 10408;

      # Managed IP allocation: .21–.223 in 10.40.8.0/24
      # .20 reserved for camera DVR; .224/27 is the Kea default pool
      managedSubnet = "10.40.8";
      managedHostStart = 21;
      managedHostEnd = 223;
    };
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

          # synaptex hook: classifies DHCP packets (SYNAPTEX_KNOWN / IOT_DEVICE)
          # and manages reservations in-process via Kea's HostMgr API.
          # Reservations are in-memory; synaptex-router re-syncs them at startup.
          # pkgs.kea is extended via nixpkgs.overlays to include synaptex_hook.so,
          # satisfying Kea's store-path security check.
          hooks-libraries = [
            {
              library = "${pkgs.kea}/lib/kea/hooks/synaptex_hook.so";
              parameters.socket = "/run/synaptex-router/kea-hook.sock";
            }
          ];

          lease-database = {
            name = "/var/lib/kea/dhcp4.leases";
            persist = true;
            type = "memfile";
          };

          # Log to stderr (journald) — avoids log4cplus trying to create
          # /run/kea/logger_lockfile on a read-only filesystem.
          loggers = [{
            name = "kea-dhcp4";
            output_options = [{ output = "stderr"; }];
            severity = "INFO";
            debuglevel = 0;
          }];
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

          # Disable DDNS globally; only the lan subnet opts in
          ddns-send-updates = false;

          dhcp-ddns = {
            enable-updates = true;
            server-ip = "127.0.0.1";
            server-port = 53001;
            ncr-protocol = "UDP";
            ncr-format = "JSON";
          };

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
              ddns-send-updates = true;
              ddns-override-no-update = true;
              ddns-override-client-update = true;
              ddns-replace-client-name = "when-not-present";
              ddns-qualifying-suffix = "lan.disasm.us.";
              ddns-update-on-renew = true;
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
                  hostname = "night-val-1";
                  hw-address = "42:3c:d8:19:86:16";
                  ip-address = "10.40.33.25";
                }
                #{
                #  hostname = "kazan";
                #  hw-address = "74:d4:35:9b:84:62";
                #  ip-address = "10.40.33.26";
                #}
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
                  pool = "10.40.8.224 - 10.40.8.254";
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
                  hostname = "camera-dvr";
                  hw-address = "3c:1b:f8:72:04:ca";
                  ip-address = "10.40.8.20";
                }
                # TODO remove once wled added to synaptex
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
              ];
              "valid-lifetime" = 60; # Total lease duration
              "renew-timer" = 30; # T1: Client checks in every 30s
              "rebind-timer" = 52; # T2: Client panics/broadcasts at 52s
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
                {
                  # TP-Link Omada controller discovery (RFC 5415 CAPWAP, reused by Omada)
                  code = 138;
                  data = "10.40.33.20";
                }
              ];
              reservations = [
                {
                  hostname = "eap610-1";
                  hw-address = "54:af:97:96:75:ac";
                  ip-address = "10.40.3.20";
                }
                {
                  hostname = "eap610-2";
                  hw-address = "54:af:97:96:77:7e";
                  ip-address = "10.40.3.21";
                }
                {
                  hostname = "eap610-3";
                  hw-address = "54:af:97:96:77:a6";
                  ip-address = "10.40.3.22";
                }
              ];
              subnet = "10.40.3.0/24";
              id = 10403;
            }
          ];
        };
      };
      dhcp-ddns = {
        enable = true;
        configFile = keaDdnsConf;
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
  };
  systemd.services.kea-dhcp4-server = {
    serviceConfig = {
      RuntimeDirectoryMode = lib.mkForce "0770";
    };
  };
  systemd.services.kea-dhcp-ddns-server = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "kea";
      Group = "kea";
    };
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
  system.stateVersion = "17.09";
}
