{
  lib,
  config,
  pkgs,
  ...
}: {
  networking = {
    hostName = "kursk";
    domain = "lan.disasm.us";
    hostId = "3543f7b0"; # required for ZFS
    useDHCP = false;
    useNetworkd = true;
    nameservers = ["10.40.33.1" "8.8.8.8"];
    extraHosts = ''
      10.233.1.2 rtorrent.kursk.local
    '';
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "enp11s0";
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
        5432 # postgresql-ai (ai.lan)
        9200 # elasticsearch
        11434 # ollama (ai.lan)
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
      allowedUDPPorts = [53 137 138 1194 500 4500 5353 19132 29810 27001];
    };
  };

  # Rename the NIC by MAC address so the interface name is stable regardless of
  # kernel enumeration order.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="74:d4:35:9b:84:62", NAME="enp11s0"
  '';

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp11s0";
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = false;
      };
      addresses = [
        # .70 — primary; default listen address for all services until segregated
        {Address = "10.40.33.70/24";}
        # .71 — AI service tier (ollama, postgresql-ai)
        {Address = "10.40.33.71/24";}
        # .72–.79 reserved for future service segregation
      ];
      routes = [
        {Gateway = "10.40.33.1";}
      ];
      dns = ["10.40.33.1" "8.8.8.8"];
      # IPv6 tokens paired with the 10.40.33.70–79 range.
      # Token suffix matches the IPv4 last octet directly (e.g. .70 → ::70),
      # so with portal's delegated /64 the addresses are e.g. 2601:xxxx:yyyy:zzzz::70
      extraConfig = ''
        [IPv6AcceptRA]
        Token=::70
        Token=::71
        Token=::72
        Token=::73
        Token=::74
        Token=::75
        Token=::76
        Token=::77
        Token=::78
        Token=::79
      '';
    };
  };

  services.avahi = {
    enable = true;
    allowInterfaces = ["enp11s0"];
    reflector = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
