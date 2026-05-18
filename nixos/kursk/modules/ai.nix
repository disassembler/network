{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  # pg_search (ParadeDB) and pgvector may lag or be broken in nixos-25.11;
  # pull postgresql_16 + extensions from unstable to stay current.
  pkgsUnstable = import inputs.nixpkgsUnstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  pgAiPackage = pkgsUnstable.postgresql_17.withPackages (ps: [
    ps.pg_search # ParadeDB BM25 / full-text search
    ps.pgvector # Vector similarity — shared library loaded as 'vector'
  ]);
  dataDir = "/var/lib/postgresql-ai";

  pgHbaConf = pkgs.writeText "postgresql-ai-pg_hba.conf" ''
    # unix socket — used by ExecStartPre init scripts
    local all all trust
    # LAN clients
    host  all all 10.40.33.0/24 trust
  '';
in {
  # ── NVIDIA ──────────────────────────────────────────────────────────────────
  # services.xserver.videoDrivers activates the nvidia driver (kernel modules +
  # userspace libs) even on a headless server with no X running.
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = false;
    modesetting.enable = false;
    powerManagement.enable = true;
  };

  boot.blacklistedKernelModules = ["nouveau"];

  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    cudaPackages.cudatoolkit
    config.boot.kernelPackages.nvidiaPackages.stable
  ];

  # ── OLLAMA ──────────────────────────────────────────────────────────────────
  services.ollama = {
    enable = true;
    package = pkgsUnstable.ollama-cuda;
    acceleration = "cuda";
    host = "10.40.33.71";
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
    };
    loadModels = [
      "phi4-mini"
      "gemma4:26b"
      "hf.co/jinaai/jina-code-embeddings-1.5b-GGUF:Q8_0"
    ];
  };

  # ollama binds to 10.40.33.71 which networkd assigns after the default
  # network.target; restart on failure so it recovers if it loses the race.
  systemd.services.ollama = {
    after = ["network-addresses-enp11s0.service"];
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = "5s";
  };

  # ── POSTGRESQL-AI (isolated instance for ParadeDB + pgvector) ───────────────
  # Runs on port 5432 on dedicated IP 10.40.33.71, data on a separate ZFS dataset
  # tuned for large sequential vector scans (recordsize=128K).
  # NOTE: pg_search shared library is 'pg_search'; pgvector loads as 'vector'.
  users.users.postgres-ai = {
    isSystemUser = true;
    group = "postgres-ai";
    description = "PostgreSQL AI instance service user";
  };
  users.groups.postgres-ai = {};

  systemd.services.postgresql-ai = {
    description = "Isolated PostgreSQL for AI workloads (ParadeDB + pgvector)";
    after = ["local-fs.target" "network-addresses-enp11s0.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "postgres-ai";
      Group = "postgres-ai";

      # ZFS dataset mounted at ${dataDir} via fileSystems (from disko).
      # StateDirectory just ensures correct ownership before ExecStartPre runs.
      StateDirectory = "postgresql-ai";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "postgresql-ai";
      RuntimeDirectoryMode = "0755";

      ExecStartPre = pkgs.writeShellScript "init-postgresql-ai" ''
        if [ ! -f ${dataDir}/PG_VERSION ]; then
          ${pgAiPackage}/bin/initdb \
            -D ${dataDir} \
            -E UTF8 \
            --locale=C
        fi
      '';

      ExecStart = pkgs.writeShellScript "start-postgresql-ai" ''
        exec ${pgAiPackage}/bin/postgres \
          -D ${dataDir} \
          -c listen_addresses=10.40.33.71 \
          -c port=5432 \
          -c unix_socket_directories=/run/postgresql-ai \
          -c hba_file=${pgHbaConf} \
          -c shared_preload_libraries=pg_search,vector \
          -c shared_buffers=16GB \
          -c work_mem=1GB \
          -c effective_cache_size=48GB \
          -c random_page_cost=1.1 \
          -c max_parallel_workers_per_gather=8 \
          -c max_parallel_workers=8 \
          -c max_worker_processes=16 \
          -c maintenance_work_mem=2GB \
          -c max_wal_size=4GB \
          -c wal_buffers=64MB \
          -c effective_io_concurrency=200 \
          -c huge_pages=try \
          -c pg_search.enable_telemetry=false
      '';

      MemoryHigh = "64G";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
