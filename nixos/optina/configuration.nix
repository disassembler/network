{ lib, config, pkgs, inputs, ... }:


with lib;

let
  legacyPkgs = import inputs.nixpkgsLegacy {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
      # required for mongodb 3.4
      permittedInsecurePackages = [ "openssl-1.0.2u" ];
    };
  };
  shared = import ../../shared.nix;
  netboot_root = pkgs.runCommand "nginxroot" { } ''
    mkdir -pv $out
    cat <<EOF > $out/boot.php
    <?php
    if (\$_GET['version'] == "") {
    ?>
    #!ipxe
    chain tftp://10.40.33.1/undionly.kpxe
    <?php
    } else {
    ?>
    #!ipxe
    chain netboot/netboot.ipxe
    <?php
    }
    ?>
    EOF
    ln -sv ${netboot} $out/netboot
  '';
  netboot =
    let
      build = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
        system = "x86_64-linux";
        modules = [
          (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
          ./justdoit.nix
          module
        ];
      }).config.system.build;
    in
    pkgs.symlinkJoin {
      name = "netboot";
      paths = with build; [ netbootRamdisk kernel netbootIpxeScript ];
    };
  module = {
    kexec.justdoit = {
      luksEncrypt = false;
      rootDevice = "/dev/sda";
      swapSize = 256;
      bootSize = 64;
    };
  };
in
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    gitea_dbpass = { };
    mpd_pw = { };
    mpd_icecast_pw = { };
    alertmanager = { };
    lego-knot-credentials.owner = "acme";
  };
  imports =
    [
      ./hardware-configuration.nix
      ./minecraft-bedrock-server.nix
    ];
  _module.args = {
    inherit shared;
  };

  nix =
    let
      buildMachines = import ../../build-machines.nix;
    in
    {
      sshServe = {
        enable = true;
        keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6A3QRIK9XfLf/eDYb9Z4UO7iTmH7Gy3xwHphDx/ZEF9xZ6NuSsotihNZCpGIq2W3G7lx+3TlJW4WuI2GUHr9LZRsI+Z7T2+tSEtQZ1sE4p4rvlkNBzORobfrjXWs32Wd4ZH1i9unJRY6sFouWHt0ejjpnH49F8q5grTZALzrwh+Rz+Wj7Z1No7FccVMB15EtROq9jFQjP1Yqc+jScSFhgurHBpQbyJZXHXaelwVwLLM7DfDyLCDLgkB+1PDDMmfCMFEdV4oTMWmN6kZb52ko4B5ygzFg/RgOe73yYv9FRxUZK3kQQQfl4/VOIB8DhJieD/2VfmjCI0Q46xnia0rdz root@sarov" ];
      };
      buildMachines = [
        buildMachines.linux.optina
      ];
      settings.substituters = [ "https://cache.nixos.org" "https://hydra.iohk.io" ];
      settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
      extraOptions = ''
        allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk
      '';
    };

  # Use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;
  boot.loader = {
    grub = {
      efiSupport = true;
      device = "nodev";
      memtest86.enable = true;
      efiInstallAsRemovable = true;
    };
    efi = {
      canTouchEfiVariables = false;
    };
  };
  boot.supportedFilesystems = [ "zfs" ];
  #profiles.vim.enable = false;
  profiles.zsh.enable = true;
  profiles.tmux.enable = true;

  networking = {
    hostName = "optina";
    domain = "lan.disasm.us";
    hostId = "1768b40b";
    tempAddresses = "disabled";
    interfaces.enp2s0.ipv4.addresses = [{ address = "10.40.33.20"; prefixLength = 24; }];
    defaultGateway = "10.40.33.1";
    nameservers = [ "10.40.33.1" "8.8.8.8" ];
    extraHosts =
      ''
        10.233.1.2 rtorrent.optina.local
        10.40.33.20 crate.lan.disasm.us
      '';
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp2s0";
    };
    firewall = {
      enable = false;
      allowPing = true;
      allowedTCPPorts = [
        53
        80
        139
        443
        445
        631
        3000 # grafana
        4444
        5900
        5951
        5952
        6600
        6667
        8000
        8080
        8083
        8086
        8091
        8123 # home assistant
        9090
        9092
        9093
        9100
        9200 # elasticsearch
        22022
        24000
        32400 # plex
        5201 # iperf
        29811 # omada
        29812
        29813
        29814
        8844
        8043
      ];
      allowedUDPPorts = [ 53 137 138 1194 500 4500 5353 19132 29810 27001 ];
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "disasm@gmail.com";
  security.acme.certs."lan.disasm.us" = {
    domain = "*.lan.disasm.us";
    postRun = "systemctl reload nginx.service";
    group = "nginx";
    keyType = "ec384";
    dnsProvider = "rfc2136";
    credentialsFile = config.sops.secrets.lego-knot-credentials.path;
  };
  security.pki.certificates = [ shared.wedlake_ca_cert ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # required for mongodb 3.4
      permittedInsecurePackages = [ "openssl-1.0.2u" ];
      packageOverrides = pkgs: rec {
        #weechat = pkgs.weechat.override {
        #  configure = {availablePlugins, ...}: {
        #    plugins = with availablePlugins; [
        #            (python.withPackages (ps: with ps; [ websocket_client ]))
        #            perl ruby
        #    ];
        #  };
        #};
      };
    };
    overlays = [
      #(import ../overlays/plex.nix)
    ];
  };

  environment.systemPackages = with pkgs; [
    direnv
    hello
    qemu_kvm
    aspell
    aspellDicts.en
    ncdu
    unrar
    conky
    #chromium
    unzip
    zip
    gnupg
    gnupg1compat
    rxvt_unicode
    tcpdump
    nix-prefetch-git
    ncmpc
    git
    fasd
    dnsutils
    #openssl
    powerdns
    virt-manager
    config.services.home-assistant.package
  ];

  services = {
    syslog-ng = {
      enable = true;
      extraConfig = ''
        source s_net {
          tcp(ip(0.0.0.0) port(514));
          udp(ip(0.0.0.0) port(514));
        };
        destination d_fromnet {file("/var/log/remote");};
        log {source(s_net); destination(d_fromnet);};

      '';
    };
    avahi = {
      enable = true;
      allowInterfaces = [ "enp2s0" ];
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
    home-assistant = {
      enable = true;
      package = (pkgs.home-assistant.override {
        extraComponents = [ "sense" "roku" "homekit" ];
      }).overrideAttrs (oldAttrs: { doInstallCheck = false; });
      config = {
        default_config = { };
        met = { };
        sense = { };
        roku = { };
        homekit = { };
      };
    };
    matterbridge = {
      enable = false;
      configPath = "/etc/nixos/matterbridge.toml";
    };
    minecraft-bedrock-server.enable = true;
    vaultwarden = {
      enable = true;
      config = {
        signupsAllowed = false;
        domain = "https://vw.lan.disasm.us";
      };
    };
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="74:d4:35:9b:84:62", NAME="enp2s0"
    '';

    hledger-web = {
      enable = true;
      port = 8002;
      baseUrl = "https://hledger.lan.disasm.us/";
      allow = "edit";
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

    logstash = {
      enable = false;
      inputConfig = ''
        kafka {
          zk_connect => "localhost:2181"
          topic_id => "KAFKA-LOGSTASH-ELASTICSEARCH"
          codec => json {}
        }
      '';
      outputConfig = ''
        elasticsearch {
            index  => "systemd-logs-%{+YYYY.MM.dd}"
            hosts => ["localhost:9200"]
            sniffing => false
         }
      '';
    };

    displayManager = {
      defaultSession = "none+i3";
    };
    xserver = {
      autorun = true;
      enable = true;
      xkb.layout = "us";
      windowManager.i3 = {
        enable = true;
        #extraSessionCommands = ''
        #  ${pkgs.feh} --bg-scale /home/sam/photos/20170503_183237.jpg
        #'';
        package = pkgs.i3-gaps;
      };
      displayManager.lightdm = {
        enable = true;
        background = "/etc/lightdm/background.jpg";
      };
    };
    bitlbee.enable = true;
    gitea = {
      enable = false;
      appName = "Personal Git Server";
      settings.server = {
        ROOT_URL = "https://git.lan.disasm.us";
        HTTP_PORT = 3001;
        HTTP_ADDR = "127.0.0.1";
        DOMAIN = "git.lan.disasm.us";
      };
      database = {
        type = "postgres";
        port = 5432;
        passwordFile = config.sops.secrets.gitea_dbpass.path;
      };
    };
    # TODO: run omadad and unifi in a controller with an older nixpkgs
    omadad = {
      enable = true;
      httpPort = 8089;
      httpsPort = 10443;
      mongodb = legacyPkgs.mongodb;
    };
    unifi = {
      enable = true;
      unifiPackage = legacyPkgs.unifi6;
      mongodbPackage = legacyPkgs.mongodb-4_4;
      openFirewall = true;
    };
    #telegraf = {
    #  enable = true;
    #  extraConfig = {
    #    outputs = {
    #      influxdb = [{
    #        urls = ["http://localhost:8086"];
    #        database = "telegraf";
    #      }];
    #      prometheus_client = [{
    #        listen = ":9101";
    #      }];
    #    };
    #    inputs = {
    #      cpu = [{}];
    #      disk = [{}];
    #      diskio = [{}];
    #      kernel = [{}];
    #      mem = [{}];
    #      swap = [{}];
    #      netstat = [{}];
    #      nstat = [{}];
    #      ntpq = [{}];
    #      procstat = [{}];
    #    };
    #  };
    #};
    prometheus.exporters = {
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
      #surfboard = {
      #  enable = true;
      #};
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
      #unifi = {
      #  enable = false;
      #  unifiAddress = "https://unifi.lan.disasm.us";
      #  unifiUsername = "prometheus";
      #  unifiPassword = secrets.unifi_password_ro;
      #  openFirewall = true;
      #};
    };
    prometheus = {
      enable = true;
      extraFlags = [
        "--storage.tsdb.retention.time 8760h"
      ];
      alertmanagers = [{
        scheme = "http";
        path_prefix = "/";
        static_configs = [{
          targets = [ "optina.lan.disasm.us:9093" ];
        }];
      }];
      rules = [
        (builtins.toJSON {
          groups = [
            {
              name = "system";
              rules = [
                {
                  alert = "node_down";
                  expr = "up == 0";
                  for = "5m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Node is down.";
                    description = "{{$labels.alias}} has been down for more than 5 minutes.";
                  };
                }
                {
                  alert = "node_systemd_service_failed";
                  expr = "node_systemd_unit_state{state=\"failed\"} == 1";
                  for = "4m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Service {{$labels.name}} failed to start.";
                    description = "{{$labels.alias}} failed to (re)start service {{$labels.name}}.";
                  };
                }
                {
                  alert = "node_filesystem_full_90percent";
                  expr = "sort(node_filesystem_free_bytes{device!=\"ramfs\"} < node_filesystem_size_bytes{device!=\"ramfs\"} * 0.1) / 1024^3";
                  for = "5m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Filesystem is running out of space soon.";
                    description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} got less than 10% space left on its filesystem.";
                  };
                }
                {
                  alert = "node_filesystem_full_in_4h";
                  expr = "predict_linear(node_filesystem_free_bytes{device!=\"ramfs\",device!=\"tmpfs\",fstype!=\"autofs\",fstype!=\"cd9660\"}[4h], 4*3600) <= 0";
                  for = "5m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Filesystem is running out of space in 4 hours.";
                    description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} is running out of space of in approx. 4 hours";
                  };
                }
                {
                  alert = "node_filedescriptors_full_in_3h";
                  expr = "predict_linear(node_filefd_allocated[1h], 3*3600) >= node_filefd_maximum";
                  for = "20m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}} is running out of available file descriptors in 3 hours.";
                    description = "{{$labels.alias}} is running out of available file descriptors in approx. 3 hours";
                  };
                }
                {
                  alert = "node_load1_90percent";
                  expr = "node_load1 / on(alias) count(node_cpu_seconds_total{mode=\"system\"}) by (alias) >= 0.9";
                  for = "1h";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Running on high load.";
                    description = "{{$labels.alias}} is running with > 90% total load for at least 1h.";
                  };
                }
                {
                  alert = "node_cpu_util_90percent";
                  expr = "100 - (avg by (alias) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) >= 90";
                  for = "1h";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: High CPU utilization.";
                    description = "{{$labels.alias}} has total CPU utilization over 90% for at least 1h.";
                  };
                }
                {
                  alert = "node_ram_using_99percent";
                  expr = "node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes < node_memory_MemTotal_bytes * 0.01";
                  for = "30m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Using lots of RAM.";
                    description = "{{$labels.alias}} is using at least 90% of its RAM for at least 30 minutes now.";
                  };
                }
                {
                  alert = "node_swap_using_80percent";
                  expr = "node_memory_SwapTotal_bytes - (node_memory_SwapFree_bytes + node_memory_SwapCached_bytes) > node_memory_SwapTotal_bytes * 0.8";
                  for = "10m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Running out of swap soon.";
                    description = "{{$labels.alias}} is using 80% of its swap space for at least 10 minutes now.";
                  };
                }
                {
                  alert = "node_time_unsync";
                  expr = "abs(node_timex_offset_seconds) > 0.050 or node_timex_sync_status != 1";
                  for = "1m";
                  labels = {
                    severity = "page";
                  };
                  annotations = {
                    summary = "{{$labels.alias}}: Clock out of sync with NTP";
                    description = "{{$labels.alias}} Local clock offset is too large or out of sync with NTP";
                  };
                }
              ];
            }
          ];
        })
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
                "portal.lan.disasm.us:9100"
              ];
              labels = {
                alias = "portal.lan.disasm.us";
              };
            }
            {
              targets = [
                "optina.lan.disasm.us:9100"
              ];
              labels = {
                alias = "optina.lan.disasm.us";
              };
            }
            #{
            #  targets = [
            #    "10.40.9.5:9100"
            #  ];
            #  labels = {
            #    alias = "buffalo_run.home";
            #  };
            #}
            {
              targets = [
                "10.40.9.2:9100"
              ];
              labels = {
                alias = "prod01.samleathers.com";
              };
            }
          ];
        }
        #{
        #  job_name = "surfboard";
        #  scrape_interval = "5s";
        #  static_configs = [
        #    {
        #      targets = [
        #        "localhost:9239"
        #      ];
        #    }
        #  ];
        #}
        #{
        #  job_name = "unifi";
        #  scrape_interval = "10s";
        #  static_configs = [
        #    {
        #      targets = [
        #        "localhost:9130"
        #      ];
        #      labels = {
        #        alias = "unifi.lan.disasm.us";
        #      };
        #    }
        #  ];
        #}
        {
          job_name = "blackbox";
          scrape_interval = "60s";
          metrics_path = "/probe";
          params = {
            module = [ "ssh_banner" ];
          };
          static_configs = [
            {
              targets = [
                "73.230.94.119"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.*)(:.*)?";
              replacement = "\${1}:22";
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [ ];
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
        {
          job_name = "icmp-sarov";
          scrape_interval = "10s";
          metrics_path = "/probe";
          params = {
            module = [ "icmp_v4" ];
          };
          static_configs = [
            {
              targets = [
                "10.40.33.165"
                "10.40.33.167"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.*)";
              replacement = "\${1}";
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [ ];
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
      ];
    };
    prometheus.alertmanager = {
      enable = true;
      environmentFile = config.sops.secrets.alertmanager.path;
      listenAddress = "0.0.0.0";
      configuration = {
        "global" = {
          "smtp_smarthost" = "smtp.gmail.com:587";
          "smtp_from" = "alertmanager@samleathers.com";
          "smtp_auth_username" = "disasm@gmail.com";
          "smtp_auth_password" = "$SMTP_PW";
        };
        "route" = {
          "group_by" = [ "alertname" "alias" ];
          "group_wait" = "30s";
          "group_interval" = "2m";
          "repeat_interval" = "4h";
          "receiver" = "team-admins";
        };
        "receivers" = [
          {
            "name" = "team-admins";
            "email_configs" = [
              {
                "to" = "disasm@gmail.com";
                "send_resolved" = true;
              }
            ];
            "pagerduty_configs" = [
              {
                "service_key" = "$PAGERDUTY_TOKEN";
              }
            ];
          }
        ];
      };
    };
    grafana = {
      enable = true;
      settings.server.http_addr = "0.0.0.0";
    };
    phpfpm = {
      #phpPackage = pkgs.php71;
      pools = {
        mypool = {
          user = "nginx";
          settings = {
            "pm" = "dynamic";
            "pm.max_children" = 5;
            "pm.start_servers" = 1;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 2;
            "pm.max_requests" = 50;
          };
        };
      };
      phpOptions =
        ''
          [opcache]
          opcache.enable=1
          opcache.memory_consumption=128
          opcache.interned_strings_buffer=8
          opcache.max_accelerated_files=4000
          opcache.revalidate_freq=60
          opcache.fast_shutdown=1
        '';
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "netboot.lan.disasm.us" = {
          root = netboot_root;
          extraConfig = ''
            location ~ [^/]\.php(/|$) {
              fastcgi_pass unix:${config.services.phpfpm.pools.mypool.socket};
            }
          '';
        };
        "noc.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://optina.lan.disasm.us:3000";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
        "hass.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://optina.lan.disasm.us:8123";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
          locations."/api/websocket" = {
            proxyPass = "http://optina.lan.disasm.us:8123";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
            '';
          };
        };
        "vw.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8000";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
        "hledger.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          #locations."/api".extraConfig = ''
          #  proxy_pass http://localhost:8001/api;
          #  proxy_set_header Host $host;
          #  proxy_set_header X-Forwarded-Proto $scheme;
          #  proxy_set_header  X-Real-IP         $remote_addr;
          #  proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
          #'';
          locations."/".extraConfig = ''
            proxy_pass http://localhost:8002/;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header  X-Real-IP         $remote_addr;
            proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
          '';
        };
        "stg.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          root = "/var/storage";
        };
        "unifi.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          locations."/".extraConfig = ''
            proxy_set_header Referer "";
            proxy_pass https://localhost:8443/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
        "omada.lan.disasm.us" = {
          useACMEHost = "lan.disasm.us";
          forceSSL = true;
          locations."/".extraConfig = ''
            proxy_pass https://localhost:8043;
          '';
        };
        #"git.lan.disasm.us" = {
        #  forceSSL = true;
        #  sslCertificate = "/data/ssl/git.lan.disasm.us.crt";
        #  sslCertificateKey = "/data/ssl/git.lan.disasm.us.key";
        #  locations."/".extraConfig = ''
        #    proxy_pass http://localhost:3001/;
        #    proxy_set_header Host $host;
        #    proxy_set_header X-Forwarded-Proto $scheme;
        #    proxy_set_header  X-Real-IP         $remote_addr;
        #    proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
        #  '';
        #};
      };
    };

    samba = {
      enable = true;
      shares = {
        meganbackup =
          {
            path = "/data/backups/other/megan";
            "valid users" = "sam megan";
            writable = "yes";
            comment = "Megan's Backup";
          };
        musicdrive =
          {
            path = "/data/pvr/music";
            "valid users" = "sam megan nursery";
            writable = "yes";
            comment = "music share";
          };
      };
      extraConfig = ''
        guest account = nobody
        map to guest = bad user
      '';
    };
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
      defaultShared = true;
      browsing = true;
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      extraConf = ''
        ServerAlias *
      '';
    };

    mopidy = {
      enable = false;
      configuration = ''
        [local]
        enabled = true
        media_dir = /data/pvr/music
      '';
    };
    mpd = {
      enable = false;
      musicDirectory = "/data/pvr/music";
      credentials = [
        {
          passwordFile = config.sops.secrets.mpd_pw.path;
          permissions = [ "admin" "read" "add" "control" ];
        }
        {
          passwordFile = config.sops.secrets.mpd_icecast_pw.path;
          permissions = [ "read" "add" "control" ];
        }
      ];
      extraConfig = ''
        log_level "verbose"
        restore_paused "no"
        metadata_to_use "artist,album,title,track,name,genre,date,composer,performer,disc,comment"
        bind_to_address "10.40.33.20"
        input {
        plugin "curl"
        }
        audio_output {
        type        "shout"
        encoding    "ogg"
        name        "Icecast stream"
        host        "prophet.samleathers.com"
        port        "8000"
        mount       "/mpd.ogg"
        public      "yes"
        bitrate     "192"
        format      "44100:16:1"
        user        "mpd"
        }
        audio_output {
        type "alsa"
        name "fake out"
        driver "null"
        }
      '';
    };
    postgresql = {
      enable = true;
      authentication = ''
        local gitea all ident map=gitea-users
      '';
      identMap = ''
        gitea-users gitea gitea
      '';
    };
    postgresqlBackup.enable = true;
    # Plex
    plex = {
      enable = true;
      #package = pkgs.plex.overrideAttrs (x: let
      #version = "1.24.5.5173-8dcc73a59";
      #sha256 = "sha256-vyTOeb3ySegH6cUJIP+WoLIRQyAVyanQFJDRSTGjV8w=";
      #  in {
      #    name = "plex-${version}";
      #    src = pkgs.fetchurl {
      #      url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
      #      inherit sha256;
      #    };
      #  }
      #);
    };

  };
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.docker.storageDriver = "zfs";
  #virtualisation.podman.enable = true;
  #virtualisation.podman.dockerCompat = true;
  #virtualisation.podman.dockerSocket.enable = true;
  #virtualisation.podman.defaultNetwork.dnsname.enable = true;
  #systemd.services.podman.serviceConfig.ExecStart = lib.mkForce [
  #  ""
  #  "${config.virtualisation.podman.package}/bin/podman --storage-driver zfs $LOGGING system service"
  #];
  virtualisation.libvirtd.enable = false;
  containers.rtorrent = {
    privateNetwork = true;
    hostAddress = "10.233.1.1";
    localAddress = "10.233.1.2";
    enableTun = true;
    bindMounts = {
      "/opt/rtorrent" = {
        hostPath = "/data/rtorrent";
        isReadOnly = false;
      };
    };
    config = { config, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        rtorrent
        openvpn
        tmux
        sudo
      ];
      users.users.rtorrent = {
        isNormalUser = true;
        uid = 10001;
      };
    };
  };
  # TODO move omada and unifi here
  containers.wifiController = {
    privateNetwork = true;
    hostAddress = "10.233.1.3";
    localAddress = "10.233.1.4";
    #bindMounts = {
    #  "/opt/rtorrent" = {
    #    hostPath = "/data/rtorrent";
    #    isReadOnly = false;
    #  };
    #};
    config = { config, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        tmux
        sudo
      ];
    };
  };
  users.users.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" "libvirtd" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.users.samchat = {
    isNormalUser = true;
    description = "Sam Leathers (chat)";
    uid = 1005;
    extraGroups = [ ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  system.activationScripts.samchat-tmp =
    let bashrc = builtins.toFile "samchat-bashrc" "export TMUX_TMPDIR=/tmp";
    in "ln -svf ${bashrc} ${config.users.users.samchat.home}/.bash_profile";
  users.users.mitro = {
    isNormalUser = true;
    uid = 1001;
  };
  users.users.megan = {
    isNormalUser = true;
    uid = 1002;
  };
  users.users.nursery = {
    isNormalUser = true;
    uid = 1004;
  };
  # don't change this without reading release notes
  system.stateVersion = "22.05";
}
