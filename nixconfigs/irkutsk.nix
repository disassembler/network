{ lib, config, pkgs, fetchgit, ... }:

let
  secrets = import ../load-secrets.nix;
  shared = import ../shared.nix;
  machine = "irkutsk";
  hostId = "e66682e1";

in {
  _module.args = {
    inherit secrets shared;
  };

  #Boot Config

  # Uncomment to use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;

  # Uncomment to use grub boot loader
  boot.loader.grub = {
    efiSupport = true;
    gfxmodeEfi = "1024x768";
    device = "nodev";
    memtest86.enable = true;
  };
  boot.zfs.enableUnstable = true;

  boot.supportedFilesystems = [ "exfat" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Splash screen to make boot look nice
  boot.plymouth.enable = true;

  console.keyMap = "us";
  console.packages = with pkgs; [ terminus_font ];
  console.font = "ter-i32b";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # Luks support
  boot.initrd.luks.devices = {
    linuxroot = {
      device = "/dev/disk/by-uuid/47a5b911-4dfe-4bf5-8a5c-c911e211cda0";
    };
  };
  systemd.additionalUpstreamSystemUnits = [
    "debug-shell.service"
  ];

  location = {
    latitude = 40.8681;
    longitude = -77.9574;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
    powerUpCommands = ''
      echo XHC > /proc/acpi/wakeup
    '';
  };
  time.timeZone = "America/New_York";

  networking = {
    hostName = machine;
    hostId = hostId;
    nameservers = [ "127.0.0.1" ];
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:ve-*" "ens9" ];
    extraHosts =
    ''
      # If DNS is broke, we still want to be able to deploy
      10.40.33.20 optina.wedlake.lan
      10.40.33.20 hydra.wedlake.lan
      10.40.33.1 portal.wedlake.lan
      127.0.0.1 wallet.samleathers.com
      127.0.0.1 dev.ocf.net
      127.0.0.1 explorer.jormungandr
      127.0.0.1 explorer.cardano
      127.0.0.1 wp.dev
    '';
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlp2s0";
    };
    #vlans = {
    #  lan = {
    #    interface = "ens9";
    #    id = 33;
    #  };
    #  mgmt = {
    #    interface = "ens9";
    #    id = 3;
    #  };
    #  guest = {
    #    interface = "ens9";
    #    id = 9;
    #  };
    #  voip = {
    #    interface = "ens9";
    #    id = 40;
    #  };
    #};
    #interfaces = {
    #  lan = {
    #    useDHCP = true;
    #  };
    #  voip = {
    #    useDHCP = true;
    #  };
    #  mgmt = {
    #    useDHCP = true;
    #  };
    #  guest = {
    #    useDHCP = true;
    #  };
    #};
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 4919 ];
      allowedTCPPorts = [ 4444 8081 3478 3000 8080 5900 3100 ];
    };
    #bridges = {
    #  cbr0.interfaces = [ ];
    #};
    #interfaces = {
    #  cbr0 = {
    #    ipv4.addresses = [
    #      {
    #        address = "10.38.0.1";
    #        prefixLength = 24;
    #      }
    #    ];
    #  };
    #};
  };

  security.pki.certificates = [ shared.wedlake_ca_cert ];

  nix = let
    buildMachines = import ../build-machines.nix;
  in {
    useSandbox = true;
    buildCores = 4;
    sandboxPaths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io"
      #"https://hydra.wedlake.lan"
      #"https://snack.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      #"hydra.wedlake.lan:C3xufTQ7w2Y6VHtf+dyA6NmQPiQjwIDEavJNmr97Loo="
      #"snack.cachix.org-1:yWpdDCWeJzVAQUSM1Ol0E3PCVbG4k2wRAsZ/b5L3huc="
    ];
    distributedBuilds = true;
    buildMachines = [
      buildMachines.darwin.ohrid
      #buildMachines.darwin.macvm
      #buildMachines.linux.optina
    ];
    #nixPath = [ "nixpkgs=/home/sam/nixpkgs/custom" "nixos-config=/etc/nixos/configuration.nix" ];
    extraOptions = ''
      binary-caches-parallel-connections = 3
      connect-timeout = 5
      #allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive
    '';
  };

  nixpkgs.overlays = [
    (self: super:
    let
      hie = import (super.fetchFromGitHub {
        owner = "domenkozar";
        repo = "hie-nix";
        rev = "dbb89939da8997cc6d863705387ce7783d8b6958";
        sha256 = "1bcw59zwf788wg686p3qmcq03fr7bvgbcaa83vq8gvg231bgid4m";
      }) {};
      hnix-lsp = import (super.fetchFromGitHub {
        owner = "domenkozar";
        repo = "hnix-lsp";
        rev = "c69b4bdd46e7eb652f13c13e01d0da44a1491d39";
        sha256 = "16w1197yl6x06a06c2x30rycgllf6r67w0b38fcia2c4cnigzalg";
    });
    in
    { inherit (hie) hie82; inherit hnix-lsp; })
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    android_sdk.accept_license = true;
    packageOverrides = super: let self = super.pkgs; in {
      #nixops = super.nixops.overrideDerivation (
      #old: {
      #  patchPhase = ''
      #      substituteInPlace nix/eval-machine-info.nix \
      #          --replace 'system.nixosVersion' 'system.nixos.version'
      #  '';
      #}
      #);
      manymans = with pkgs; buildEnv {
        name = "manymans";
        ignoreCollisions = true;
        paths = [
          man-pages posix_man_pages stdmanpages glibcInfo
        ];
      };
    };
  };

  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" "docker" "disk" "video" "libvirtd" "adbusers" "dialout" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };

  # move to host system
  profiles.zsh.enable = true;
  profiles.zsh.autosuggest = true;
  profiles.vim = {
      enable = true;
      dev = true;
  };

  environment.systemPackages = with pkgs; let
    startSway = pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash

          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start sway.service
        '';
      };
    #nixopsSrc = pkgs.fetchFromGitHub {
    #  owner = "input-output-hk";
    #  repo = "nixops";
    #  rev = "dba45d750199147f857b14dadbb29811c9baf97d";
    #  sha256 = "0z9w66vwlr7l6qvyj2p1lv98k3f8h3jd4dzxmwhqmln2py8wq4zb";
    #};
    #nixopsSrc = /home/sam/nixops;
    #packet = "/home/sam/nixops-packet";
    #nixops = (import (nixopsSrc + "/release.nix") {
    #  p = (p: [ packet ]);
    #}).build.x86_64-linux;
  in [
    heimdall-gui
    #dnscontrol
    gopass
    arduino
    startSway
    avidemux
    mplayer
    gpgme.dev
    yubioath-desktop
    yubikey-manager
    bat
    slurp
    grim
    ripgrep
    opensc
    pavucontrol
    hledger
    psmisc
    hie82
    sqliteInteractive
    manymans
    hlint
    dysnomia
    disnix
    disnixos
    nixops
    dropbox
    gist
    dropbox-cli
    dmenu
    chromium
    #vimb
    gnupg
    gnupg1compat
    docker_compose
    niff
    #androidsdk
    tmate
    htop
    feh
    imagemagick
    magic-wormhole
    weechat
    rxvt_unicode-with-plugins
    xsel
    keepassx2
    tcpdump
    telnet
    p11_kit
    openconnect
    openconnect_gnutls
    gnutls
    nix-prefetch-git
    gitAndTools.gitFull
    gitAndTools.hub
    tig
    python27Packages.gnutls
    unzip
    aws
    awscli
    #aws_shell
    p7zip
    zip
    scrot
    remmina
    tdesktop
    keybase
    keybase-gui
    slack
    neomutt
    notmuch
    #python3Packages.goobook
    taskwarrior
    jq
    cabal2nix
    #nodePackages.eslint
    #nodejs
    haskellPackages.ghcid
    virtmanager
    xdg_utils
    termite
    #wine-staging
    inotifyTools
    #(import (builtins.fetchTarball "https://github.com/hercules-ci/ghcide-nix/tarball/master") {}).ghcide-ghc865
  ];

  hardware = {
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      extraConfig = "load-module module-switch-on-connect";

    };
    opengl.enable = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages = [ pkgs.vaapiIntel ];
    facetimehd.enable = true;
    bluetooth = {
      enable = true;
      config = {
        general = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.fontconfig.dpi=150;
  fonts.fonts = with pkgs; [
    corefonts
    fira # monospaced
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
    sway = {
      enable = true;
      extraPackages = with pkgs; [
        swaylock
        swayidle
        xwayland
        waybar
        mako
        kanshi
      ];
    };
    waybar.enable = true;
    ssh.startAgent = lib.mkForce false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };


  services = {
    resolved.enable = false;
    pcscd.enable = true;
    #jormungandr-explorer = {
    #  #package = (import /home/sam/work/iohk/shelley-testnet-explorer/override.nix {}).overrideAttrs (oldAttrs: {
    #  #  GATSBY_JORMUNGANDR_URL = "http://explorer.jormungandr";
    #  #  GATSBY_URL = "http://explorer.jormungandr";
    #  #});
    #  enable = true;
    #  virtualHost = "explorer.jormungandr";
    #  enableSSL = false;
    #  jormungandrApi = "http://explorer.jormungandr:3101/explorer/graphql";
    #};
    #jormungandr = {
    #  enable = false;
    #  environment = "itn_rewards_v1";
    #  enableExplorer = true;
    #  rest.listenAddress = "127.0.0.1:3201";
    #  rest.cors.allowedOrigins = [ "http://127.0.0.1:3201" ];
    #};
    #byron-proxy = {
    #  environment = "mainnet";
    #  enable = false;
    #};
    #cardano-node = {
    #  environment = "mainnet";
    #  enable = false;
    #};
    #cardano-cluster = {
    #  enable = true;
    #  node-count = 1;
    #};
    prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "byron-proxy";
          scrape_interval = "5s";
          static_configs = [
            {
              targets = [
                "localhost:12799"
              ];

            }
          ];
        }
      ];
    };
    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
    phpfpm = {
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
          display_errors = On
          [opcache]
          opcache.enable=0
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
        "explorer.cardano" = {
          locations."/" = {
            proxyPass = "http://localhost:4000";
          };
          locations."/graphql" = {
            proxyPass = "https://explorer.staging-shelley.dev.iohkdev.io/graphql";
          };
        };
      };
    };
    toxvpn = {
      enable = false;
      localip = "10.40.13.3";
    };

    postgresql = {
      enable = true;
      enableTCPIP = false;
      extraConfig = ''
        max_connections = 200
        shared_buffers = 2GB
        effective_cache_size = 6GB
        maintenance_work_mem = 512MB
        checkpoint_completion_target = 0.7
        wal_buffers = 16MB
        default_statistics_target = 100
        random_page_cost = 1.1
        effective_io_concurrency = 200
        work_mem = 10485kB
        min_wal_size = 1GB
        max_wal_size = 2GB
      '';
      identMap = ''
        explorer-users /root cexplorer
        explorer-users /postgres postgres
        explorer-users /sam cexplorer
      '';
      authentication = ''
        local all all ident map=explorer-users
        local all all trust
      '';
      ensureDatabases = [
        "explorer_python_api"
        "cexplorer"
        "hdb_catalog"
      ];
      ensureUsers = [
        {
          name = "cexplorer";
          ensurePermissions = {
            "DATABASE explorer_python_api" = "ALL PRIVILEGES";
            "DATABASE cexplorer" = "ALL PRIVILEGES";
            "DATABASE hdb_catalog" = "ALL PRIVILEGES";
            "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
            #"ALL TABLES IN SCHEMA scraper" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    influxdb.enable = true;
    grafana = {
      enable = true;
      addr = "0.0.0.0";
      port = 8085;
    };

    #zfs.autoSnapshot.enable = true;
    #grafana_reporter = {
    #  enable = true;
    #  grafana = {
    #    addr = "optina.wedlake.lan";
    #  };
    #};
    offlineimap = {
      enable = false;
      path = [ pkgs.notmuch ];
    };
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
      browsing = true;
    };
    dbus.enable = true;
    acpid.enable = true;
    upower.enable = true;

    udev.extraRules = let
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
    in ''
      ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", RUN+="${clearYubikeySam}"

    '';
    udev.packages = [ pkgs.yubikey-personalization ];

    compton = {
      enable = true;
      shadowExclude = [''"_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"''];
      opacityRules = [
        "95:class_g = 'URxvt' && !_NET_WM_STATE@:32a"
        "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
      ];
    };
    #xserver = {
    #  xautolock = {
    #    enable = true;
    #    time = 5;
    #    locker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #    nowlocker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #    #killer = "${pkgs.systemd}/bin/systemctl suspend";
    #    #killtime = 30;
    #    extraOptions = [ "-detectsleep" ];
    #  };
    #  libinput = {
    #    enable = true;
    #    tapping = true;
    #    disableWhileTyping = true;
    #    scrollMethod = "twofinger";
    #    naturalScrolling = false;
    #  };
    #  #autorun = true;
    #  enable = false;
    #  #layout = "us";
    #  desktopManager = {
    #    default = "none";
    #  };
    #  #windowManager.i3 = {
    #  #  enable = true;
    #  #  extraSessionCommands = ''
    #  #    ${pkgs.xlibs.xset}/bin/xset r rate 200 60 # set keyboard repeat
    #  #    ${pkgs.feh} --bg-scale /home/sam/photos/20170503_183237.jpg
    #  #  '';
    #  #};
    #  #windowManager.i3.package = pkgs.i3-gaps;
    #  #windowManager.i3.configFile = "/home/sam/.config/i3/config";
    #  #windowManager.default = "i3";
    #  #displayManager.lightdm = {
    #  #  enable = false;
    #  #};
    #};
    dnsmasq = {
      enable = true;
      extraConfig = ''
        address=/portal.wedlake.lan/10.40.33.1
        address=/crate.wedlake.lan/10.40.33.20
        address=/hydra.wedlake.lan/10.40.33.20
        address=/unifi.wedlake.lan/10.40.33.20
        address=/server.lan.bower-law.com/192.168.0.254
        server=/wedlake.lan/10.40.33.1
        server=/lan.centrallakerealty.com/10.37.3.2
        server=/lan.bower-law.com/192.168.0.254
        server=/bower.local/192.168.0.254
        server=/lan.centrallakerealty.com/10.37.3.2
      '';
      servers = [
        "8.8.4.4"
        "8.8.8.8"
      ];
      resolveLocalQueries = false;
    };

    openvpn = {
      servers = {
        prophet = {
          autoStart = false;
          config = secrets.prophet-openvpn-config;
        };
        prophet-guest = {
          autoStart = false;
          config = secrets.prophet-guest-openvpn-config;
        };
        centrallake = {
          autoStart = false;
          config = secrets.centrallake-openvpn-config;
        };
        bower = {
          autoStart = false;
          config = secrets.bower-openvpn-config;
        };
      };
    };
    keybase.enable = true;
    kbfs = {
      enable = true;
      mountPoint = "/keybase";
    };
    redshift = {
      enable = true;
      package = pkgs.redshift-wlr;
    };
  };
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    #extraOptions = "--iptables=false --ip-masq=false -b cbr0";
    #extraOptions = "--insecure-registry 10.80.0.49:5000";
  };
  virtualisation.libvirtd.enable = false;
  #virtualisation.virtualbox.host.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Custom dotfiles for sam user
  environment = {
    etc = {
      "per-user/sam/gitconfig".text = import ../sam-dotfiles/git-config.nix;
      "sway/config".source = ../sam-dotfiles/sway/config;
      "xdg/waybar/config".source = ../sam-dotfiles/waybar/config;
      "xdg/waybar/style.css".source = ../sam-dotfiles/waybar/style.css;
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
      ln -sfn /etc/per-user/sam/gitconfig /home/sam/.gitconfig
      ln -sfn /etc/xdg/waybar /home/sam/.config/waybar
    '';
    deps = [];
  };

  systemd.user.services = {
    #mbsync = {
    #  description = "IMAP mailbox sync";
    #  path = [ pkgs.isync ];
    #  script = "mbsync -c /home/sam/.mutt/mbsyncrc -q -a";
    #  startAt = "*:0/3";
    #  wantedBy = [ "timers.target" ];
    #  serviceConfig = {
    #    TimeoutStartSec = "2min";
    #  };
    #  preStart = ''
    #    mkdir -p /home/sam/mail/EEVA
    #    mkdir -p /home/sam/mail/MPO
    #    mkdir -p /home/sam/mail/LACL
    #  '';
    #};

    #mu = {
    #  description = "Updating mail database";
    #  path = [ mu-light ];
    #  script = "mu index --quiet -m ~/mail";
    #  startAt = "daily";
    #  wantedBy = [ "timers.target" ];
    #};

    #msmtp-runqueue = {
    #  description = "Flushing mail queue";
    #  script = builtins.readFile "/home/sam/prefix/bin/msmtp-runqueue";
    #  preStart = "mkdir -p /home/sam/.msmtpqueue";
    #  postStop = "rm -f /home/sam/.msmtpqueue/.lock";
    #  startAt = "*:0/10";
    #  serviceConfig = {
    #    TimeoutStartSec = "2min";
    #  };
    #  path = [ pkgs.msmtp ];
    #};
    #sway = {
    #  description = "Sway - Wayland window manager";
    #  documentation = [ "man:sway(5)" ];
    #  bindsTo = [ "graphical-session.target" ];
    #  wants = [ "graphical-session-pre.target" ];
    #  after = [ "graphical-session-pre.target" ];
    #  # We explicitly unset PATH here, as we want it to be set by
    #  # systemctl --user import-environment in startsway
    #  environment.PATH = lib.mkForce null;
    #  serviceConfig = {
    #    Type = "simple";
    #    ExecStart = ''
    #      ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug --config /etc/sway/config
    #    '';
    #    Restart = "on-failure";
    #    RestartSec = 1;
    #    TimeoutStopSec = 10;
    #  };
    #};
    #kanshi = {
    #  description = "Kanshi output autoconfig ";
    #  wantedBy = [ "graphical-session.target" ];
    #  partOf = [ "graphical-session.target" ];
    #  serviceConfig = {
    #    # kanshi doesn't have an option to specifiy config file yet, so it looks
    #    # at .config/kanshi/config
    #    ExecStart = ''
    #      ${pkgs.kanshi}/bin/kanshi
    #    '';
    #    RestartSec = 5;
    #    Restart = "always";
    #  };
    #};
  };
  #systemd.user.targets.sway-session = {
  #  description = "Sway compositor session";
  #  documentation = [ "man:systemd.special(7)" ];
  #  bindsTo = [ "graphical-session.target" ];
  #  wants = [ "graphical-session-pre.target" ];
  #  after = [ "graphical-session-pre.target" ];
  #};


}
