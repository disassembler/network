{ lib, inputs, config, pkgs, fetchgit, ... }:

let
  shared = import ../../shared.nix;
  machine = "iviron";
  hostId = "7a6c1214";
  #isUnstable = config.boot.zfs.package == pkgs.zfsUnstable;
  #zfsCompatibleKernelPackages = lib.filterAttrs (
  #  name: kernelPackages:
  #  (builtins.match "linux_[0-9]+_[0-9]+" name) != null
  #  && (builtins.tryEval kernelPackages).success
  #  && (
  #    (!isUnstable && !kernelPackages.zfs.meta.broken)
  #    || (isUnstable && !kernelPackages.zfs_unstable.meta.broken)
  #    )
  #    ) pkgs.linuxKernel.packages;
  #    latestKernelPackage = lib.last (
  #      lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
  #        builtins.attrValues zfsCompatibleKernelPackages
  #        )
  #        );

in
  {
  #sops.defaultSopsFile = ./secrets.yaml;
  #sops.secrets.openvpn_prophet_ca = { };
  #sops.secrets.docker_auth = { };
  #sops.secrets.openvpn_prophet_cert = { };
  #sops.secrets.openvpn_prophet_key = { };
  #sops.secrets.openvpn_prophet_tls = { };
  #sops.secrets.openvpn_bower_ca = { };
  #sops.secrets.openvpn_bower_cert = { };
  #sops.secrets.openvpn_bower_key = { };
  _module.args = {
    inherit shared;
  };

  #Boot Config

  imports = [ ./hardware-configuration.nix ];



  # Uncomment to use grub boot loader
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    useOSProber = true;
    default = "saved";
    device = "nodev";
    theme = pkgs.nixos-grub2-theme;
    memtest86.enable = true;
  };
  #boot.blacklistedKernelModules = [ "amdgpu" ];
  #boot.kernelPackages = latestKernelPackage;
  #boot.zfs.package = pkgs.zfs_unstable;

  boot.supportedFilesystems = [ "exfat" "zfs" ];
  boot.tmp.cleanOnBoot = true;
  boot.zfs.devNodes = "/dev";

  boot.extraModprobeConfig = ''
  options v4l2loopback exclusive_caps=1 card_label="Virtual Webcam"
  '';
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];
  boot.kernelModules = [
    "v4l2loopback"
  ];

  # Splash screen to make boot look nice
  boot.plymouth.enable = false;

  console.keyMap = "us";
  console.packages = with pkgs; [ terminus_font ];
  console.font = "ter-i32b";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    powerUpCommands = ''
    echo XHC > /proc/acpi/wakeup
    '';
    powertop.enable = true;
  };
  time.timeZone = "America/New_York";
  #time.timeZone = "Asia/Dubai";

  networking = {
    hostName = machine;
    inherit hostId;
    tempAddresses = "disabled";
    #nameservers = [ "127.0.0.1" ];
    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.70.0.1/24" ];
        postSetup = ''
          ip link set mtu 1392 dev wg0
        '';
        privateKeyFile = "/var/lib/wg-keys/wg0.key";
        peers = [
          {
            publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
            allowedIPs = [
              "10.40.33.0/24"
              "10.40.9.0/24"
              #"192.168.0.0/24"
            ];
            endpoint = "prophet.samleathers.com:51820";
            persistentKeepalive = 30;
          }
        ];
      };
      wg1 = {
        ips = [ "10.250.192.2/32" ];
        mtu = 1280;
        privateKeyFile = "/var/lib/wg-keys/wg1.key";
        peers = [
          {
            publicKey = "W8Mqo7sGVNUVXe/+3Yb0DqiN/QPKGpc6BHB8H10jagE=";
            allowedIPs = [
              "10.200.128.0/24"
              "10.200.129.0/24"
              "10.160.0.0/22"
              "10.101.0.0/21"
              "10.140.0.0/24"
            ];
            endpoint = "64.78.224.166:51821";
            persistentKeepalive = 30;
          }
        ];
      };
      #wg2 = {
      #  ips = [ "10.44.2.3/32" ];
      #  listenPort = 52024;
      #  privateKeyFile = "/var/lib/wg-keys/wg2.key";
      #  peers = [
      #    {
      #      publicKey = "z9CFP9lxAJTHS7DsPcP9dv0Ll3qqUtR0dorlMVokQFw=";
      #      allowedIPs = [
      #        "10.44.2.1/32"
      #        "10.44.2.3/32"
      #        "10.44.1.0/24"
      #      ];
      #      endpoint = "8.42.79.100:52024";
      #      persistentKeepalive = 30;
      #    }
      #  ];
      #};
    };
    networkmanager.enable = true;
    networkmanager.unmanaged = [
      "interface-name:ve-*"
      #"ens9"
    ];
    extraHosts =
      ''
        # If DNS is broke, we still want to be able to deploy
        10.40.33.20 optina.wedlake.lan
        10.40.33.20 crate.wedlake.lan
        10.40.33.20 hydra.wedlake.lan
        10.40.33.1 portal.wedlake.lan
        127.0.0.1 wallet.samleathers.com
        127.0.0.1 dev.ocf.net
        127.0.0.1 explorer.jormungandr
        127.0.0.1 explorer.cardano
        127.0.0.1 wp.dev
        10.40.9.9 offline.doom.lan
        '';
        nat = {
          enable = true;
          internalInterfaces = [ "ve-+" ];
          externalInterface = "wlp195s0";
        };
        firewall = {
          enable = false;
          allowedUDPPorts = [ 53 4919 69 ];
          allowedTCPPorts = [ 4444 8081 3478 3000 8080 5900 3100 3001 ];
        };
      };

      nix =
        let
          buildMachines = import ../../build-machines.nix;
        in
        {
          settings.sandbox = true;
          settings.cores = 4;
      #settings.extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" "/etc/skopeo/auth.json=${config.sops.secrets.docker_auth.path}" ];
      #settings.extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
      settings.substituters = [ "https://cache.iog.io" ];
      settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
      distributedBuilds = true;
      buildMachines = [
      ];
      extraOptions = ''
      binary-caches-parallel-connections = 3
      connect-timeout = 5
        #allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive
        experimental-features = nix-command flakes fetch-closure
        '';
      };

      nixpkgs.overlays = [
        inputs.niri.overlays.niri
        #(self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; })
        #inputs.vivarium.overlay
      ];

      nixpkgs.config = {
        allowUnfree = true;
        allowBroken = false;
        android_sdk.accept_license = true;
        packageOverrides = super:
        let self = super.pkgs; in
        {
          manymans = with pkgs; buildEnv {
            name = "manymans";
            ignoreCollisions = true;
            paths = [
              man-pages
              man-pages-posix
              stdmanpages
              glibcInfo
            ];
          };
        };
      };

      users.groups.plugdev = { };
      users.extraUsers.sam = {
        isNormalUser = true;
        description = "Sam Leathers";
        uid = 1000;
        extraGroups = [ "wheel" "podman" "disk" "video" "libvirtd" "adbusers" "dialout" "plugdev" "cexplorer" ];
        openssh.authorizedKeys.keys = shared.sam_ssh_keys;
      };
  #users.users.cardano-node.isSystemUser = true;

  profiles.zsh = {
    enable = true;
    autosuggest = true;
  };
  programs.bash = {
    interactiveShellInit = ''
    eval "$(direnv hook bash)"
    eval "$(starship init bash)"
    '';
  };

  profiles.vim = {
    enable = true;
    dev = true;
  };
  #profiles.vivarium.enable = true;

  environment.pathsToLink = [
    "/share/nix-direnv"
  ];
  environment.systemPackages = with pkgs; let
    #startSway = pkgs.writeTextFile {
    #  name = "startsway";
    #  destination = "/bin/startsway";
    #  executable = true;
    #  text = ''
    #    #! ${pkgs.bash}/bin/bash

    #    # first import environment variables from the login manager
    #    systemctl --user import-environment
    #    # then start the service
    #    exec systemctl --user start sway.service
    #  '';
    #};
    obsStudio = pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        scrcpy
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    };
    #trezor = python3Packages.trezor.overrideAttrs (oldAttrs: {
    #  src = python3Packages.fetchPypi {
    #    pname = "trezor";
    #    version = "0.12.2";
    #    sha256 = "sha256:0r0j0y0ii62ppawc8qqjyaq0fkmmb0zk1xb3f9navxp556w2dljv";
    #  };
    #});
  in
  [

    inputs.home-manager.packages.x86_64-linux.home-manager
    polychromatic
    pciutils
    steamcmd
    wineWowPackages.waylandFull
    winetricks
    lshw
    kitty
    wofi
    obsStudio
    headscale
    gopass
    iamb
    starship
    direnv
    nix-direnv
    discord
    heimdall-gui
    ledger-live-desktop
    #trezor
    gopass
    arduino
    #startSway
    strace
    mplayer
    gpgme.dev
    yubioath-flutter
    yubikey-manager
    pinentry-gtk2
    bat
    slurp
    grim
    ripgrep
    opensc
    pavucontrol
    hledger
    psmisc
    #hie82
    sqlite-interactive
    manymans
    hlint
    gist
    dmenu
    google-chrome
    gnupg
    gnupg1compat
    podman-compose
    niff
    tmate
    htop
    feh
    imagemagick
    magic-wormhole
    weechat
    pv
    rxvt-unicode
    termite
    wezterm
    xsel
    tcpdump
    inetutils
    p11-kit
    openconnect
    openconnect_gnutls
    gnutls
    nix-prefetch-git
    gitAndTools.gitFull
    gitAndTools.hub
    tig
    unzip
    zip
    scrot
    tdesktop
    keybase
    keybase-gui
    slack
    signal-desktop
    neomutt
    notmuch
    taskwarrior3
    jq
    cabal2nix
    haskellPackages.ghcid
    virt-manager
    xdg-utils
    inotifyTools
    zoom-us
  ];

  hardware = {
    opentabletdriver.enable = true;
    openrazer = {
      enable = true;
      users = [ "sam" ];
    };
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [nvidia-vaapi-driver];
    };
    nvidia = {
      modesetting.enable = false;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #  version = "570.133.07"; # Replace with your desired version
      #  sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY="; # Replace with the correct SHA256
      #  sha256_aarch64 = "sha256-xcff4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM="; # Replace with the correct SHA256
      #  openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM="; # Optional: If using open source driver
      #  settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU="; # Optional: For settings package
      #  persistencedSha256 = lib.fakeSha256; # Use fakeSha256 for persistence
      #};
      nvidiaSettings = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:5:0:0";
        nvidiaBusId = "PCI:6:0:0";
      };
    };
    facetimehd.enable = true;
    bluetooth = {
      enable = true;
      settings = {
        general = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
  fonts.fontDir.enable = true;
  fonts.enableGhostscriptFonts = true;
  fonts.packages = with pkgs; [
    # Used by starship for fonts
    nerd-fonts.fira-code
    corefonts
    fira # monospaced
    fira-code
    powerline-fonts
    inconsolata
    liberation_ttf
    dejavu_fonts
    bakoma_ttf
    gentium
    ubuntu_font_family
    terminus_font
    unifont # some international languages
  ];
  programs = {
    mosh.enable = true;
    adb.enable = true;
    light.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
    sway = {
      enable = true;
    };

    #hyprland.package = inputs.hyprland.packages.x86_64-linux.hyprland;
    #sway = {
    #  enable = true;
    #  extraPackages = with pkgs; [
    #    swaylock
    #    swayidle
    #    xwayland
    #    waybar
    #    mako
    #    kanshi
    #  ];
    #};
    waybar.enable = true;
    ssh.startAgent = lib.mkForce false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };
  };


  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    #  enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = false;
      };
    };
    displayManager = {
      #sddm = {
      #  enable = true;
      #  wayland.enable = true;
      #};
      defaultSession = "niri";
    };
    pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull;
      extraConfig = "load-module module-switch-on-connect";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };
    tailscale.enable = false;
    # Better scheduling for CPU cycles - thanks System76!!!
    system76-scheduler.settings.cfsProfiles.enable = true;

    # Enable TLP (better than gnomes internal power manager)
    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };

    # Disable GNOMEs power management
    power-profiles-daemon.enable = false;


    # Enable thermald (only necessary if on Intel CPUs)
    thermald.enable = true;
    #rabbitmq = {
    #  enable = true;
    #  #listenAddress = "::1";
    #  managementPlugin.enable = true;
    #};
    tftpd.enable = true;
    tftpd.path = "/var/tftpd";
    zfs.trim.enable = true;
    zfs.autoScrub.enable = true;
    zfs.autoScrub.pools = [ "zpool" ];
    zfs.autoSnapshot = {
      enable = true;
      frequent = 8;
      monthly = 1;
    };
    lorri.enable = true;
    trezord.enable = true;
    resolved.enable = false;
    pcscd.enable = true;
    #cardano-node = {
    #  environment = "mainnet";
    #  enable = false;
    #  port = 3001;
    #  hostAddr = "0.0.0.0";
    #  systemdSocketActivation = true;
    #  environments = pkgs.cardanoLib.environments;
    #  package = pkgs.cardano-node;
    #  cardanoNodePkgs = pkgs;
    #};
    #cardano-db-sync = {
    #  cluster = "mainnet";
    #  enable = true;
    #  socketPath = "/run/cardano-node/node.socket";
    #  user = "cexplorer";
    #  extended = true;
    #  postgres = {
    #    database = "cexplorer";
    #  };
    #};
    #graphql-engine.enable = false;
    #cardano-graphql = {
    #  enable = false;
    #};
    #postgresql = {
    #  enable = true;
    #  enableTCPIP = false;
    #  settings = {
    #    max_connections = 200;
    #    shared_buffers = "2GB";
    #    effective_cache_size = "6GB";
    #    maintenance_work_mem = "512MB";
    #    checkpoint_completion_target = 0.7;
    #    wal_buffers = "16MB";
    #    default_statistics_target = 100;
    #    random_page_cost = 1.1;
    #    effective_io_concurrency = 200;
    #    work_mem = "10485kB";
    #    min_wal_size = "1GB";
    #    max_wal_size = "2GB";
    #  };
    #  identMap = ''
    #    #explorer-users /root cexplorer
    #    explorer-users /postgres postgres
    #    explorer-users /sam cexplorer
    #    explorer-users /smash smash
    #    explorer-users /cexplorer cexplorer
    #  '';
    #  authentication = ''
    #    local all all ident map=explorer-users
    #    local all all trust
    #  '';
    #  ensureDatabases = [
    #    "explorer_python_api"
    #    "cexplorer"
    #    "smash"
    #    "hdb_catalog"
    #  ];
    #  ensureUsers = [
    #    {
    #      name = "cexplorer";
    #      ensurePermissions = {
    #        "DATABASE explorer_python_api" = "ALL PRIVILEGES";
    #        "DATABASE cexplorer" = "ALL PRIVILEGES";
    #        "DATABASE hdb_catalog" = "ALL PRIVILEGES";
    #        "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
    #      };
    #    }
    #    {
    #      name = "smash";
    #      ensurePermissions = {
    #        "DATABASE smash" = "ALL PRIVILEGES";
    #        "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
    #      };
    #    }
    #    {
    #      name = "sam";
    #      ensurePermissions = {
    #        "DATABASE smash" = "ALL PRIVILEGES";
    #        #"DATABASE cexplorer" = "ALL PRIVILEGES";
    #        "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
    #      };
    #    }
    #  ];
    #};
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
      browsing = true;
    };
    dbus.enable = true;
    acpid.enable = true;
    upower.enable = true;

    udev.extraRules =
      let
        dependencies = with pkgs; [ coreutils gnupg gawk gnugrep ];
        clearYubikey = pkgs.writeScript "clear-yubikey" ''
          #!${pkgs.stdenv.shell}
          export PATH=${pkgs.lib.makeBinPath dependencies};
          keygrips=$(
            gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null \
            | grep -v OK \
            | awk '{if ($4 == "T") { print $3 ".key" }}')
            for f in $keygrips; do
            rm -v ~/.gnupg/private-keys-v1.d/$f
            done
            gpg --card-status 2>/dev/null 1>/dev/null || true
            '';
            clearYubikeySam = pkgs.writeScript "clear-yubikey-sam" ''
          #!${pkgs.stdenv.shell}
          ${pkgs.sudo}/bin/sudo -u sam ${clearYubikey}
          '';
      in
      ''
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", RUN+="${clearYubikeySam}"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="2b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="3b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="4b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1807", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1808", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0004", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2c97"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2581"
      '';
      udev.packages = [ pkgs.yubikey-personalization ];

      compton = {
        enable = true;
        shadowExclude = [ ''"_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"'' ];
        opacityRules = [
          "95:class_g = 'URxvt' && !_NET_WM_STATE@:32a"
          "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
        ];
      };
      dnsmasq = {
        enable = true;
        settings = {
          address = [
            "/portal.wedlake.lan/10.40.33.1"
            "/crate.wedlake.lan/10.40.33.20"
            "/hydra.wedlake.lan/10.40.33.20"
            "/unifi.wedlake.lan/10.40.33.20"
            "/server.lan.bower-law.com/192.168.0.254"
          ];
          server = [
            "8.8.4.4"
            "8.8.8.8"
            "/wedlake.lan/10.40.33.1"
            "/lan.centrallakerealty.com/10.37.3.2"
            "/lan.bower-law.com/192.168.0.254"
            "/bower.local/192.168.0.254"
            "/lan.centrallakerealty.com/10.37.3.2"
          ];
        };
        resolveLocalQueries = false;
      };

    #openvpn = {
    #  servers = {
    #    prophet = {
    #      autoStart = false;
    #      config = ''
    #        client
    #        dev tun
    #        proto udp
    #        remote prophet.samleathers.com 1195
    #        nobind
    #        persist-key
    #        persist-tun
    #        ca ${config.sops.secrets.openvpn_prophet_ca.path}
    #        cert ${config.sops.secrets.openvpn_prophet_cert.path}
    #        key ${config.sops.secrets.openvpn_prophet_key.path}
    #        tls-auth ${config.sops.secrets.openvpn_prophet_tls.path}
    #        key-direction 1
    #        comp-lzo
    #        verb 3
    #      '';
    #    };
    #    bower = {
    #      autoStart = false;
    #      config = ''
    #        client
    #        dev tun
    #        proto udp
    #        remote 73.230.94.119 1194
    #        nobind
    #        persist-key
    #        persist-tun
    #        cipher AES-256-CBC
    #        ca ${config.sops.secrets.openvpn_bower_ca.path}
    #        cert ${config.sops.secrets.openvpn_bower_cert.path}
    #        key ${config.sops.secrets.openvpn_bower_key.path}
    #        comp-lzo
    #        verb 3
    #        '';
    #    };
    #  };
    #};
    keybase.enable = true;
    kbfs = {
      enable = true;
      mountPoint = "/keybase";
    };
    redshift = {
      enable = false;
      package = pkgs.gammastep;
    };
  };
  location.provider = "geoclue2";
  #systemd.services.cardano-db-sync.serviceConfig = {
  #  SupplementaryGroups = "cardano-node";
  #  Restart = "always";
  #  RestartSec = "30s";
  #};
  #virtualisation.docker = {
  #  enable = true;
  #  storageDriver = "zfs";
  #};

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.settings.dnsenabled = true;
  systemd.services.podman.path = [pkgs.zfs];
  systemd.services.podman.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${config.virtualisation.podman.package}/bin/podman --storage-driver zfs $LOGGING system service"
  ];
  virtualisation.libvirtd.enable = true;
  security.sudo.wheelNeedsPassword = true;
  security.rtkit.enable = true;

  # Custom dotfiles for sam user
  environment = {
    etc = {
      "per-user/sam/gitconfig".text = import ../../sam-dotfiles/git-config.nix;
      "sway/config".source = ../../sam-dotfiles/sway/config;
      "per-user/sam/wezterm.lua".source = ../../sam-dotfiles/wezterm.lua;
      "xdg/waybar/config".source = ../../sam-dotfiles/waybar/config;
      "xdg/waybar/style.css".source = ../../sam-dotfiles/waybar/style.css;
      "sysconfig/lm_sensors".text = ''
        # Generated by sensors-detect on Tue Feb 15 13:12:56 2022
        # This file is sourced by /etc/init.d/lm_sensors and defines the modules to
        # be loaded/unloaded.
        #
        # The format of this file is a shell script that simply defines variables:
        # HWMON_MODULES for hardware monitoring driver modules, and optionally
        # BUS_MODULES for any required bus driver module (for example for I2C or SPI).

        HWMON_MODULES="coretemp"
        '';
      };

      shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
      '';
    };

    system.activationScripts.samdotfiles = {
      text = ''
      mkdir -p /home/sam/.config/sway
      mkdir -p /home/sam/.config/wezterm
      ln -sfn /etc/per-user/sam/gitconfig /home/sam/.gitconfig
      ln -sfn /etc/per-user/sam/wezterm.lua /home/sam/.config/wezterm/wezterm.lua
      ln -sfn /etc/xdg/waybar /home/sam/.config/waybar
      '';
      deps = [ ];
    };

    system.activationScripts.starship =
      let
        starshipConfig = pkgs.writeText "starship.toml" ''
        [username]
        show_always = true
        [hostname]
        ssh_only = true
        [git_commit]
        tag_disabled = false
        only_detached = false
        [memory_usage]
        format = "via $symbol[''${ram_pct}]($style) "
        disabled = false
        threshold = -1
        [time]
        format = '[\[ $time \]]($style) '
        disabled = false
        [[battery.display]]
        threshold = 100
        style = "bold green"
        [[battery.display]]
        threshold = 50
        style = "bold orange"
        [[battery.display]]
        threshold = 20
        style = "bold red"
        [status]
        map_symbol = true
        disabled = false
        '';
      in
      {
        text = ''
        mkdir -p /etc/per-user/shared
        cp ${starshipConfig} /etc/per-user/shared/starship.toml
        mkdir -p /home/sam/.config
        mkdir -p /root/.config
        chown sam:users /home/sam/.config
        chown root /root/.config
        ln -sf /etc/per-user/shared/starship.toml /home/sam/.config/starship.toml
        ln -sf /etc/per-user/shared/starship.toml /root/.config/starship.toml
        '';
        deps = [ ];
      };

      systemd.user.services = { };
      system.stateVersion = "23.05";
    }
