{
  config,
  inputs,
  ...
}: {
  # ── SYNAPTEX-CORE ────────────────────────────────────────────────────────────
  services.synaptex-core = {
    enable = true;
    package = inputs.synaptex.packages.x86_64-linux.synaptex-core;
    httpPort = 8765;
    routerUrl = "https://10.40.33.1:50052";
    routerCertFile = config.sops.secrets."synaptex-router-cert".path;
    logLevel = "synaptex_core=debug,synaptex_mysa=debug,info";
  };

  # ── NGINX ───────────────────────────────────────────────────────────────────
  services.nginx.virtualHosts."iot.lan.disasm.us" = {
    useACMEHost = "lan.disasm.us";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8765";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
