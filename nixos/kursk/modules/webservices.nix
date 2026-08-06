{
  lib,
  config,
  pkgs,
  ...
}: {
  # ── TLS / ACME ──────────────────────────────────────────────────────────────
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "disasm@gmail.com";
  security.acme.certs."lan.disasm.us" = {
    domain = "*.lan.disasm.us";
    postRun = "systemctl reload nginx.service";
    group = "nginx";
    keyType = "ec384";
    dnsProvider = "rfc2136";
    environmentFile = config.sops.secrets."lego-knot-credentials".path;
  };

  # ── NGINX ───────────────────────────────────────────────────────────────────
  services.nginx = {
    enable = true;
    virtualHosts = {
      # TODO: set up netboot (needs netboot_root derivation, see optina for reference)
      #"netboot.lan.disasm.us" = { ... };

      "noc.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://10.40.33.70:3000";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
      "demo.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://10.40.33.60:3000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400;
          '';
        };
      };
      "hass.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://10.40.33.70:8123";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/api/websocket" = {
          proxyPass = "http://10.40.33.70:8123";
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
          proxyPass = "http://10.40.33.70:8000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/notifications/hub" = {
          proxyPass = "http://10.40.33.70:8000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
      };
      "rpc-sanchonet.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://10.40.33.21:9944"; # container on valaam
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
          '';
        };
      };
      "hledger.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://127.0.0.1:8002/;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
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
      "git.lan.disasm.us" = {
        useACMEHost = "lan.disasm.us";
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://127.0.0.1:3001/;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
      "irc.lan.disasm.us" = {
        forceSSL = true;
        useACMEHost = "lan.disasm.us";
        locations."/weechat" = {
          proxyPass = "http://127.0.0.1:9001/weechat";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_read_timeout 4h;
          '';
        };
        locations."/" = {
          root = pkgs.glowing-bear;
        };
      };
    };
  };

  # ── MONITORING ──────────────────────────────────────────────────────────────
  services.prometheus.exporters = {
    blackbox = {
      enable = true;
      configFile = pkgs.writeText "blackbox-exporter.yaml" (builtins.toJSON {
        modules = {
          https_2xx = {
            prober = "http";
            timeout = "5s";
            http.fail_if_not_ssl = true;
          };
          htts_2xx = {
            prober = "http";
            timeout = "5s";
          };
          ssh_banner = {
            prober = "tcp";
            timeout = "10s";
            tcp.query_response = [{expect = "^SSH-2.0-";}];
          };
          tcp_v4 = {
            prober = "tcp";
            timeout = "5s";
            tcp.preferred_ip_protocol = "ip4";
          };
          tcp_v6 = {
            prober = "tcp";
            timeout = "5s";
            tcp.preferred_ip_protocol = "ip6";
          };
          icmp_v4 = {
            prober = "icmp";
            timeout = "60s";
            icmp.preferred_ip_protocol = "ip4";
          };
          icmp_v6 = {
            prober = "icmp";
            timeout = "5s";
            icmp.preferred_ip_protocol = "ip6";
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
    postgres = {
      enable = true;
      runAsLocalSuperUser = true;
    };
    unpoller = {
      enable = true;
      controllers = [{
        url = "https://127.0.0.1:8443";
        user = "prometheus";
        pass = config.sops.secrets."unifi-exporter-password".path;
        verify_ssl = false;
      }];
    };
  };

  # Second postgres_exporter instance for the AI postgres on 10.40.33.71:5432.
  # The primary exporters.postgres only supports one unix-socket instance.
  systemd.services.prometheus-postgres-ai-exporter = {
    description = "Prometheus PostgreSQL exporter for AI instance";
    wantedBy = ["multi-user.target"];
    after = ["postgresql-ai.service" "network-online.target"];
    environment.DATA_SOURCE_NAME = "postgresql://postgres-ai@10.40.33.71:5432/postgres?sslmode=disable";
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-postgres-exporter}/bin/postgres_exporter --web.listen-address=:9188";
      DynamicUser = true;
      Restart = "always";
      RestartSec = "5s";
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "10.40.33.70";
    extraFlags = ["--storage.tsdb.retention.time 8760h"];
    alertmanagers = [
      {
        scheme = "http";
        path_prefix = "/alertmanager";
        static_configs = [{targets = ["10.40.33.70:3000"];}];
      }
    ];
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
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Node is down.";
                  description = "{{$labels.alias}} has been down for more than 5 minutes.";
                };
              }
              {
                alert = "node_systemd_service_failed";
                expr = "node_systemd_unit_state{state=\"failed\"} == 1";
                for = "4m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Service {{$labels.name}} failed to start.";
                  description = "{{$labels.alias}} failed to (re)start service {{$labels.name}}.";
                };
              }
              {
                alert = "node_filesystem_full_90percent";
                expr = "sort(node_filesystem_free_bytes{device!=\"ramfs\"} < node_filesystem_size_bytes{device!=\"ramfs\"} * 0.1) / 1024^3";
                for = "5m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Filesystem is running out of space soon.";
                  description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} got less than 10% space left on its filesystem.";
                };
              }
              {
                alert = "node_filesystem_full_in_4h";
                expr = "predict_linear(node_filesystem_free_bytes{device!=\"ramfs\",device!=\"tmpfs\",fstype!=\"autofs\",fstype!=\"cd9660\"}[4h], 4*3600) <= 0";
                for = "5m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Filesystem is running out of space in 4 hours.";
                  description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} is running out of space of in approx. 4 hours";
                };
              }
              {
                alert = "node_filedescriptors_full_in_3h";
                expr = "predict_linear(node_filefd_allocated[1h], 3*3600) >= node_filefd_maximum";
                for = "20m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}} is running out of available file descriptors in 3 hours.";
                  description = "{{$labels.alias}} is running out of available file descriptors in approx. 3 hours";
                };
              }
              {
                alert = "node_load1_90percent";
                expr = "node_load1 / on(alias) count(node_cpu_seconds_total{mode=\"system\"}) by (alias) >= 0.9";
                for = "1h";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Running on high load.";
                  description = "{{$labels.alias}} is running with > 90% total load for at least 1h.";
                };
              }
              {
                alert = "node_cpu_util_90percent";
                expr = "100 - (avg by (alias) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) >= 90";
                for = "1h";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: High CPU utilization.";
                  description = "{{$labels.alias}} has total CPU utilization over 90% for at least 1h.";
                };
              }
              {
                alert = "node_ram_using_99percent";
                expr = "node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes < node_memory_MemTotal_bytes * 0.01";
                for = "30m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Using lots of RAM.";
                  description = "{{$labels.alias}} is using at least 90% of its RAM for at least 30 minutes now.";
                };
              }
              {
                alert = "node_swap_using_80percent";
                expr = "node_memory_SwapTotal_bytes - (node_memory_SwapFree_bytes + node_memory_SwapCached_bytes) > node_memory_SwapTotal_bytes * 0.8";
                for = "10m";
                labels.severity = "page";
                annotations = {
                  summary = "{{$labels.alias}}: Running out of swap soon.";
                  description = "{{$labels.alias}} is using 80% of its swap space for at least 10 minutes now.";
                };
              }
              {
                alert = "node_time_unsync";
                expr = "abs(node_timex_offset_seconds) > 0.050 or node_timex_sync_status != 1";
                for = "1m";
                labels.severity = "page";
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
        static_configs = [{targets = ["localhost:9090"];}];
      }
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = ["portal.lan.disasm.us:9100"];
            labels.alias = "portal.lan.disasm.us";
          }
          {
            targets = ["kursk.lan.disasm.us:9100"];
            labels.alias = "kursk.lan.disasm.us";
          }
          {
            targets = ["10.40.9.2:9100"];
            labels.alias = "prod01.samleathers.com";
          }
          {
            targets = ["10.40.33.21:9100"];
            labels.alias = "valaam.lan.disasm.us";
          }
        ];
      }
      {
        job_name = "postgres";
        scrape_interval = "30s";
        static_configs = [{targets = ["localhost:9187"];}];
      }
      {
        job_name = "gitea";
        scrape_interval = "30s";
        metrics_path = "/metrics";
        static_configs = [{targets = ["127.0.0.1:3001"];}];
      }
      {
        job_name = "grafana";
        scrape_interval = "30s";
        metrics_path = "/metrics";
        static_configs = [{targets = ["10.40.33.70:3000"];}];
      }
      {
        job_name = "blackbox-https";
        scrape_interval = "60s";
        metrics_path = "/probe";
        params.module = ["https_2xx"];
        static_configs = [{
          targets = [
            "https://noc.lan.disasm.us"
            "https://vw.lan.disasm.us"
            "https://hledger.lan.disasm.us"
            "https://git.lan.disasm.us"
            "https://irc.lan.disasm.us"
            "https://unifi.lan.disasm.us"
            "https://omada.lan.disasm.us"
          ];
        }];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            source_labels = [];
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
      {
        job_name = "blackbox";
        scrape_interval = "60s";
        metrics_path = "/probe";
        params.module = ["ssh_banner"];
        static_configs = [{targets = ["73.230.94.119"];}];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            regex = "(.*)(:.*)?";
            replacement = "\${1}:22";
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            source_labels = [];
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
      {
        job_name = "icmp-sarov";
        scrape_interval = "10s";
        metrics_path = "/probe";
        params.module = ["icmp_v4"];
        static_configs = [
          {targets = ["10.40.33.165" "10.40.33.167"];}
        ];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            regex = "(.*)";
            replacement = "\${1}";
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            source_labels = [];
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
      {
        job_name = "unifi";
        scrape_interval = "30s";
        static_configs = [{
          targets = ["localhost:9130"];
          labels.alias = "kursk.lan.disasm.us";
        }];
      }
      {
        job_name = "postgres-ai";
        scrape_interval = "30s";
        static_configs = [{targets = ["localhost:9188"];}];
      }
    ];
  };

  services.prometheus.alertmanager.enable = false;

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.40.33.70";
        root_url = "https://noc.lan.disasm.us";
      };
      "auth.google" = {
        enabled = true;
        client_id = "$__env{GF_AUTH_GOOGLE_CLIENT_ID}";
        client_secret = "$__env{GF_AUTH_GOOGLE_CLIENT_SECRET}";
        scopes = "openid email profile";
        auth_url = "https://accounts.google.com/o/oauth2/auth";
        token_url = "https://oauth2.googleapis.com/token";
        allowed_domains = "nixedge.com";
        allow_sign_up = true;
      };
      smtp = {
        enabled = true;
        host = "smtp.gmail.com:587";
        user = "sam@nixedge.com";
        password = "$__env{GF_SMTP_PASSWORD}";
        from_address = "grafana@nixedge.com";
        from_name = "Grafana";
      };
      security.secret_key = "$__env{GF_SECURITY_SECRET_KEY}";
      unified_alerting.enabled = true;
      alerting.enabled = false;
      metrics.enabled = true;
    };
    provision = {
      enable = true;
      dashboards.settings = {
        apiVersion = 1;
        providers = [{
          name = "provisioned";
          orgId = 1;
          folder = "Provisioned";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 30;
          options.path = ./grafana-dashboards;
        }];
      };
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://10.40.33.70:9090";
          isDefault = true;
        }
        {
          name = "rats";
          type = "prometheus";
          url = "http://10.42.1.1:9090";
        }
      ];
      alerting = {
        contactPoints.settings = {
          apiVersion = 1;
          contactPoints = [
            {
              orgId = 1;
              name = "Team Admins";
              receivers = [
                {
                  uid = "email-admin";
                  type = "email";
                  settings.addresses = "sam@nixedge.com";
                }
                {
                  uid = "pagerduty-admin";
                  type = "pagerduty";
                  settings.integrationKey = "$__env{GF_PAGERDUTY_KEY}";
                }
              ];
            }
          ];
        };
        policies.settings = {
          apiVersion = 1;
          policies = [
            {
              orgId = 1;
              receiver = "Team Admins";
              group_by = ["alertname" "alias"];
              group_wait = "30s";
              group_interval = "2m";
              repeat_interval = "4h";
            }
          ];
        };
      };
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.secrets."grafana-creds".path;

  # ── WEB APPS ────────────────────────────────────────────────────────────────
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.secrets."vaultwarden-env".path;
    config = {
      signupsAllowed = false;
      domain = "https://vw.lan.disasm.us";
      increase_note_size_limit = true;
      rocketAddress = "10.40.33.70";
      # Use the Unix socket — vaultwarden runs as 'vaultwarden', which matches
      # the postgres role created below, so no password is needed.
      databaseUrl = "postgresql:///vaultwarden?host=/run/postgresql";
    };
  };

  services.hledger-web = {
    enable = true;
    port = 8002;
    baseUrl = "https://hledger.lan.disasm.us/";
    allow = "edit";
  };

  services.gitea = {
    enable = true;
    appName = "Personal Git Server";
    settings.server = {
      ROOT_URL = "https://git.lan.disasm.us";
      HTTP_PORT = 3001;
      HTTP_ADDR = "127.0.0.1";
      DOMAIN = "git.lan.disasm.us";
    };
    settings.metrics.ENABLED = true;
    database = {
      type = "postgres";
      port = 5432;
      passwordFile = config.sops.secrets.gitea_dbpass.path;
    };
  };

  services.matterbridge = {
    enable = false;
    configPath = "/etc/nixos/matterbridge.toml";
  };

  services.bitlbee = {
    enable = true;
    libpurple_plugins = [pkgs.pidginPackages.purple-discord];
  };

  # ── DATABASE ─────────────────────────────────────────────────────────────────
  # Regular postgres for gitea and general use.
  # Data lives on a ZFS dataset tuned for OLTP (recordsize=8K) — see disko.nix.
  services.postgresql = {
    enable = true;
    ensureDatabases = ["gitea" "vaultwarden"];
    ensureUsers = [
      {
        name = "gitea";
        ensureDBOwnership = true;
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
    ];
    authentication = ''
      local gitea all ident map=gitea-users
    '';
    identMap = ''
      gitea-users gitea gitea
    '';
  };
  services.postgresqlBackup.enable = true;
}
