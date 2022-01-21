# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:
let
  inherit (inputs) cardano-node;
  pkgs' = pkgs;
  #baseCardanoContainer = {

  #  privateNetwork = true;
  #  autoStart = true;
  #  config = { config, pkgs, ... }: {
  #    imports = [ pkgs'.cardanoNodeModule ];
  #    networking.firewall.allowedTCPPorts = [ 3001 12798 ];
  #    environment = {
  #      systemPackages = with pkgs'; [
  #        dnsutils
  #        screen
  #        vim
  #        jq
  #        cardano-node
  #        cardano-cli
  #      ];
  #      variables = {
  #        CARDANO_NODE_SOCKET_PATH = config.services.cardano-node.socketPath;
  #      };
  #    };
  #    services = {
  #      cardano-node = {
  #        enable = true;
  #        environment = "mainnet";
  #        package = pkgs'.cardano-node;
  #        systemdSocketActivation = true;
  #        nodeConfig = pkgs'.cardanoEnvironments.mainnet.nodeConfig // {
  #          hasPrometheus = [ "0.0.0.0" 12798 ];
  #          TraceMempool = false;
  #          setupScribes = [{
  #            scKind = "JournalSK";
  #            scName = "cardano";
  #            scFormat = "ScText";
  #          }];
  #          defaultScribes = [
  #            [
  #              "JournalSK"
  #              "cardano"
  #            ]
  #          ];
  #        };
  #      };
  #      promtail = {
  #        enable = true;
  #        configuration = {
  #          server = {
  #            http_listen_port = 28183;
  #            grpc_listen_port = 0;
  #          };

  #          positions = {
  #            filename = "/tmp/positions.yaml";
  #          };

  #          clients = [{
  #            # TODO: get address of host running container
  #            url = "http://10.40.33.21:3100/loki/api/v1/push";
  #          }];

  #          scrape_configs = [{
  #            job_name = "journal";
  #            journal = {
  #              max_age = "12h";
  #              labels = {
  #                job = "systemd-journal";
  #                # TODO: get container name to prevent clashing and make it easier to query
  #                host = "container_name";
  #              };
  #            };
  #            relabel_configs = [{
  #              source_labels = ["__journal__systemd_unit"];
  #              target_label = "unit";
  #            }];
  #          }];
  #        };
  #      };
  #    };
  #    systemd.sockets.cardano-node.partOf = [ "cardano-node.socket" ];
  #    systemd.services.cardano-node.after = lib.mkForce [ "network-online.target" "cardano-node.socket" ];
  #    users.users.cardano-node.isSystemUser = true;
  #  };
  #};

in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };

  nix = {
    useSandbox = true;
    buildCores = 4;
    sandboxPaths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ cardano-node.overlay ];
  networking = {
    hostName = "valaam";
    hostId = "07c7b2e8";
    useDHCP = false;
    interfaces.enp4s0.useDHCP = true;
    interfaces.enp5s0f3u4u2.useDHCP = true;
    interfaces.wlp3s0.useDHCP = true;
    networkmanager.enable = false;
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp4s0";
    };
    #wireless = {
    #  enable = true;
    #  networks = secrets.wifiNetworks;
    #};
  };

  time.timeZone = "GMT";

  environment.variables = {
    CARDANO_NODE_SOCKET_PATH = "/relay-run-cardano/node.socket";
  };

  environment.systemPackages = with pkgs; [
    #cncli
    docker_compose
    wget
    vim
    screen
    gitMinimal
    pinentry
    gnupg
    pinentry-curses
    #adawallet
    bech32
    cardano-node.packages.x86_64-linux.cardano-node
    cardano-cli
    #cardano-address
    #cardano-completions
    #cardano-hw-cli
    #cardano-rosetta-py
    python3Packages.ipython
    python3Packages.trezor
    sqliteInteractive
    srm
    jq
  ];

  programs.gnupg.agent = { enable = true; enableSSHSupport = false; };

  services = {
    openssh = {
      passwordAuthentication = false;
      enable = true;
    };

    prometheus = {
      enable = true;
      extraFlags = [
        "--storage.tsdb.retention.time 8760h"
      ];
      scrapeConfigs = [
        {
          job_name = "prometheus";
          scrape_interval = "5s";
          static_configs = [
            {
              targets = [
                "localhost:9090"
              ];
            }
          ];
        }
        {
          job_name = "node";
          scrape_interval = "10s";
          static_configs = [
            {
              targets = [
                "localhost:9100"
              ];
              labels = {
                alias = "pskov-host";
              };
            }
          ];
        }
        {
          job_name = "cardano";
          scrape_interval = "10s";
          static_configs = [
            {
              targets = [
                "10.10.1.2:12798"
              ];
              labels = {
                alias = "leder-pool";
              };
            }
            {
              targets = [
                "10.10.1.4:12798"
              ];
              labels = {
                alias = "leder-relay";
              };
            }
            {
              targets = [
                "10.10.1.6:12798"
              ];
              labels = {
                alias = "leder-db-sync-node";
              };
            }
          ];
        }
        {
          job_name = "db-sync";
          scrape_interval = "10s";
          metrics_path = "/";
          static_configs = [
            {
              targets = [
                "localhost:8080"
              ];
              labels = {
                alias = "leder-db-sync";
              };
            }
          ];
        }
      ];
      exporters = {
        blackbox = {
          enable = true;
          configFile = pkgs.writeText "blackbox-exporter.yaml" (builtins.toJSON {
            modules = {
              https_2xx = {
                prober = "http";
                timeout = "5s";
                http = {
                  fail_if_not_ssl = true;
                };
              };
              htts_2xx = {
                prober = "http";
                timeout = "5s";
              };
              ssh_banner = {
                prober = "tcp";
                timeout = "10s";
                tcp = {
                  query_response = [{ expect = "^SSH-2.0-"; }];
                };
              };
              tcp_v4 = {
                prober = "tcp";
                timeout = "5s";
                tcp = {
                  preferred_ip_protocol = "ip4";
                };
              };
              tcp_v6 = {
                prober = "tcp";
                timeout = "5s";
                tcp = {
                  preferred_ip_protocol = "ip6";
                };
              };
              icmp_v4 = {
                prober = "icmp";
                timeout = "60s";
                icmp = {
                  preferred_ip_protocol = "ip4";
                };
              };
              icmp_v6 = {
                prober = "icmp";
                timeout = "5s";
                icmp = {
                  preferred_ip_protocol = "ip6";
                };
              };
            };
          });
        };
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
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        ingester = {
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
          lifecycler = {
            address = "127.0.0.1";
            final_sleep = "0s";
            ring = {
              kvstore = { store = "inmemory"; };
              replication_factor = 1;
            };
          };
        };

        limits_config = {
          enforce_metric_name = false;
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          ingestion_rate_mb = 160;
          ingestion_burst_size_mb = 160;
        };

        schema_config = {
          configs = [{
            from = "2020-05-15";
            index = {
              period = "168h";
              prefix = "index_";
            };
            object_store = "filesystem";
            schema = "v11";
            store = "boltdb";
          }];
        };

        server = { http_listen_port = 3100; };

        storage_config = {
          boltdb = { directory = "/var/lib/loki/index"; };
          filesystem = { directory = "/var/lib/loki/chunks"; };
        };
      };
    };
    grafana = {
      enable = true;
      addr = "0.0.0.0";
    };
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
    };
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 3001 9090 3000 3100 ];
  users.groups.cardano-node.gid = 10016;
  # TODO: pull users from secrets.nix instead
  users.users.sam = {
    uid = 10016;
    isNormalUser = true;
    extraGroups = [ "wheel" "cardano-node" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q==" ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
    shell = pkgs.lib.mkOverride 50 "${pkgs.bashInteractive}/bin/bash";
  };


  containers = {
    #pool = lib.mkMerge [ baseCardanoContainer {
    #  hostAddress = "10.10.1.1";
    #  localAddress = "10.10.1.2";
    #  bindMounts."/pool-keys" = { hostPath = "/var/leder-keys"; isReadOnly = false; };
    #  config = {
    #    services.cardano-node = {
    #      hostAddr = "10.10.1.2";
    #      topology = __toFile "topology.json" (__toJSON {
    #        Producers = [
    #          { addr = "10.10.1.4"; port = 3001; valency = 1; }
    #        ];
    #      });
    #      operationalCertificate = "/pool-keys/leder.opcert";
    #      kesKey = "/pool-keys/leder-kes.skey";
    #      vrfKey = "/pool-keys/leder-vrf.skey";
    #    };

    #  };
    #}];
    #relay = lib.mkMerge [ baseCardanoContainer {
    #  hostAddress = "10.10.1.3";
    #  localAddress = "10.10.1.4";
    #  forwardPorts = [ { protocol = "tcp"; hostPort = 3001; containerPort = 3001; } ];
    #  bindMounts."/run/cardano-node" = { hostPath = "/relay-run-cardano"; isReadOnly = false; };
    #  config = {
    #    services.cardano-node = {
    #      hostAddr = "10.10.1.4";
    #      topology = __toFile "topology.json" (__toJSON {
    #        Producers = [
    #          { addr = "relays-new.cardano-mainnet.iohk.io"; port = 3001; valency = 3; }
    #          #{ addr = "10.10.1.2"; port = 3001; valency = 1; }
    #        ];
    #      });
    #    };
    #  };
    #}];
    #db-sync = lib.mkMerge [ baseCardanoContainer {
    #  hostAddress = "10.10.1.5";
    #  localAddress = "10.10.1.6";
    #  config = {
    #    imports = [ pkgs'.cardanoDBSyncModule ];
    #    services.cardano-node = {
    #      hostAddr = "10.10.1.6";
    #      topology = __toFile "topology.json" (__toJSON {
    #        Producers = [
    #          { addr = "10.10.1.4"; port = 3001; valency = 1; }
    #        ];
    #      });
    #    };
    #    services.cardano-db-sync = {
    #      cluster = "mainnet";
    #      enable = false;
    #      socketPath = "/run/cardano-node/node.socket";
    #      user = "cexplorer";
    #      extended = true;
    #      postgres = {
    #        database = "cexplorer";
    #      };
    #    };
    #    services.postgresql = {
    #      enable = true;
    #      enableTCPIP = false;
    #      settings = {
    #        max_connections = 200;
    #        shared_buffers = "2GB";
    #        effective_cache_size = "6GB";
    #        maintenance_work_mem = "512MB";
    #        checkpoint_completion_target = 0.7;
    #        wal_buffers = "16MB";
    #        default_statistics_target = 100;
    #        random_page_cost = 1.1;
    #        effective_io_concurrency = 200;
    #        work_mem = "10485kB";
    #        min_wal_size = "1GB";
    #        max_wal_size = "2GB";
    #      };
    #      identMap = ''
    #        explorer-users /postgres postgres
    #        explorer-users /cexplorer cexplorer
    #      '';
    #      authentication = ''
    #        local all all ident map=explorer-users
    #        local all all trust
    #      '';
    #      ensureDatabases = [
    #        "cexplorer"
    #      ];
    #      ensureUsers = [
    #        {
    #          name = "cexplorer";
    #          ensurePermissions = {
    #            "DATABASE cexplorer" = "ALL PRIVILEGES";
    #            "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
    #          };
    #        }
    #      ];
    #    };

    #    users.users.cexplorer.isSystemUser = true;
    #    systemd.services.cardano-db-sync.serviceConfig = {
    #      SupplementaryGroups = "cardano-node";
    #      Restart = "always";
    #      RestartSec = "30s";
    #    };
    #  };
    #}];
  };


  powerManagement.enable = false;
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.03"; # Did you read the comment?

}
