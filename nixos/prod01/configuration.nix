{ config, pkgs, lib, inputs, ... }: let
      inherit (inputs) styx;
      styxOverlay = prev: final: {
        inherit (styx.packages.x86_64-linux) styx;
        nixedge_site = (final.callPackage ./nixedge/site.nix { styx = final.styx; styx-themes = styx.styx-themes.x86_64-linux; styxLib = styx.lib.x86_64-linux;}).site;
        blog_site = (final.callPackage ./blog/site.nix { styx = final.styx; styx-themes = styx.styx-themes.x86_64-linux; styxLib = styx.lib.x86_64-linux;}).site;
      };

in {
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.prod01_wg0_private = {};
  sops.secrets.prod01_wg1_private = {};
  nixpkgs.overlays = [ styxOverlay ];
      security.acme = {
        email = "disasm@gmail.com";
        acceptTerms = true;
      };
      networking = {
        domain = "samleathers.com";
        search = [ "samleathers.com" ];
        nat = {
          enable = true;
          externalInterface = "ens3";
          internalInterfaces = [ "wg1" ];
          forwardPorts = [
            { sourcePort = 3001; destination = "10.42.2.2:3001"; proto = "tcp"; }
          ];
        };
        nameservers = [ "127.0.0.1" "8.8.8.8" ];
        wireguard.interfaces = {
          wg0 = {
            ips = [ "10.40.9.2/24" "fd00::2" ];
            listenPort = 51820;
            privateKeyFile = config.sops.secrets.prod01_wg0_private.path;
            peers = [
              {
                publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
                allowedIPs = [ "10.40.33.0/24" "10.40.9.1/32" "2601:98a:4101:bff0::1/64" "fd00::1/64" ];
                endpoint = "2001:558:6031:52:ec23:4ce0:f3ac:925d:51820";
              }
            ];

          };
          wg1 = {
            ips = [ "10.42.2.1/24" ];
            listenPort = 51821;
            privateKeyFile = config.sops.secrets.prod01_wg1_private.path;
            peers = [
              {
                publicKey = "QRx40Uq3nvbDzePVgCpQKt8pyswccctQAOZHh7pMAlk=";
                allowedIPs = [ "10.42.2.0/24" ];
              }
            ];
          };
        };
        firewall.allowedTCPPorts = [ 80 443 53 3001 ];
        firewall.allowedUDPPorts = [ 53 51820 51821 ];
        firewall.extraCommands = let
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
        in ''
                iptables -P FORWARD DROP
                ${acceptPortOnInterface 9100 "wg0"}
                ${forwardNATPort 3001 "10.42.2.1" "10.42.2.2" "ens3" "wg1"}
        '';
      };
      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "btrfs";
      };
      fileSystems."/data" = {
        device = "/dev/vdb";
        fsType = "btrfs";
      };
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      boot.loader.grub.device = "/dev/vda";
      boot.kernelPackages = pkgs.linuxPackages_latest;
      nix = {
        useSandbox = true;
        buildCores = 4;
        sandboxPaths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
        binaryCaches = [ "https://cache.nixos.org" "https://hydra.iohk.io" ];
        binaryCachePublicKeys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
        distributedBuilds = true;
        extraOptions = ''
          allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive
        '';
      };
      swapDevices = [ { device = "/dev/vda2"; } ];
      environment.systemPackages = with pkgs; [
        wget
        vim
        tmux
        git
        wp-cli
        bind
        powerdns
        pdns-recursor
        nix-index
      ];
      services.fail2ban.enable = true;
      services.nginx = {
        enable = true;
        virtualHosts = {
          "nixedge.com" = {
            enableACME = true;
            forceSSL = true;
            serverAliases = [ "www.nixedge.com" ];
            root = pkgs.nixedge_site;
          };
          "rats.fail" = let
            metadata = ''
              {
                "name": "RATS Pool",
                "ticker": "RATS",
                "description": "RATS pool is ran by Charles Hoskinson and Samuel Leathers",
                "homepage": "https://rats.fail"
              }
            '';
            metadataJson = pkgs.writeText "pool.json" metadata;
            index = ''
              Future home of Cardano RATS Stake Pool
            '';
            index-html = pkgs.writeText "index.html" index;
            ratsRoot = pkgs.runCommandNoCC "rats-root" {} ''
              mkdir -p $out
              cp ${metadataJson} $out/pool.json
              cp ${index-html} $out/index.html
            '';
          in {
            enableACME = true;
            forceSSL = true;
            serverAliases = [ "www.rats.fail" ];
            root = ratsRoot;
          };
          "samleathers.com" = {
            enableACME = true;
            forceSSL = true;
            serverAliases = [ "www.samleathers.com" ];
            root = pkgs.blog_site;
          };
          "util.samleathers.com" = {
            enableACME = true;
            forceSSL = true;
            root = "/data/web/vhosts/samleathers/util";
          };
        };
      };
      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
      };

      #services.powerdns = {
      #  enable = true;
      #  extraConfig =
      #    ''
      #      launch=gmysql
      #      local-address=127.0.0.1
      #      local-ipv6=fd00::2
      #      local-port=5300
      #      webserver=yes
      #      master=yes
      #      allow-axfr-ips=127.0.0.1/32
      #      disable-axfr=no
      #    '';
      #  };
        services.pdns-recursor = {
          enable = true;
          dns.allowFrom = [ "127.0.0.1/8"  ];
          dns.port = 5301;
      #forwardZonesRecurse = {
      #  "." = "8.8.8.8;7.7.7.7";
      #};
      forwardZones = {
        "wedlake.lan" = "10.40.33.20:53";
      };
    };
    services.dnsdist = {
      enable = true;
      listenAddress = "0.0.0.0";
      listenPort = 53;
      extraConfig =
        ''
          setACL({'0.0.0.0/0', '::/0'})
          newServer({address='127.0.0.1:5300', pool='auth'})
          newServer({address='127.0.0.1:5301', pool='recursor'})
          recursive_ips = newNMG()
          recursive_ips:addMask('127.0.0.1')
          addAction(NetmaskGroupRule(recursive_ips), PoolAction('recursor'))
          addAction(AndRule({OrRule({QTypeRule(dnsdist.AXFR), QTypeRule(dnsdist.IXFR)}), NotRule(makeRule("45.63.23.13/32"))}), RCodeAction(dnsdist.REFUSED))
          addAction(AllRule(), PoolAction('auth'))
        '';
      };
      systemd.services.dnsdist.serviceConfig.CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID";
      systemd.services.dnsdist.serviceConfig.AmbientCapabilities = lib.mkForce "CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID";
    #systemd.services.dnsdist.serviceConfig.ExecStart = lib.mkForce "${pkgs.libcap_progs}/bin/capsh --print";
    services.openssh.enable = true;
    services.openssh.passwordAuthentication = false;
    services.journald = {
      rateLimitBurst = 0;
      extraConfig = "SystemMaxUse=50M";
    };
    services.prometheus.exporters.node = {
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

    users.users.sam = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
      ];
    };
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
  }
