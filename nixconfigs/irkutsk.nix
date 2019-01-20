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
  };

  boot.supportedFilesystems = [ "exfat" ];

  # Splash screen to make boot look nice
  boot.plymouth.enable = true;

  i18n = {
    consoleFont = "sun12x22";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };


  # Luks support
  boot.initrd.luks.devices = [{
    name = "linuxroot";
    device = "/dev/disk/by-uuid/45c5626d-228b-41a2-8f2b-7d1e941332ec";
  }];
  systemd.additionalUpstreamSystemUnits = [
    "debug-shell.service"
  ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
    powerUpCommands = ''
      echo XHC > /proc/acpi/wakeup
    '';
  };

  networking = {
    hostName = machine;
    hostId = hostId;
    #nameservers = [ "127.0.0.1" ];
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:ve-*" "ens9" ];
    extraHosts =
    ''
      # If DNS is broke, we still want to be able to deploy
      10.40.33.20 optina.wedlake.lan
      10.40.33.20 hydra.wedlake.lan
      10.40.33.1 portal.wedlake.lan
      127.0.0.1 wallet.samleathers.com
    '';
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlp2s0";
    };
    vlans = {
      lan = {
        interface = "ens9";
        id = 33;
      };
      mgmt = {
        interface = "ens9";
        id = 3;
      };
      guest = {
        interface = "ens9";
        id = 9;
      };
      voip = {
        interface = "ens9";
        id = 40;
      };
    };
    interfaces = {
      lan = {
        useDHCP = true;
      };
      voip = {
        useDHCP = true;
      };
      mgmt = {
        useDHCP = true;
      };
      guest = {
        useDHCP = true;
      };
    };
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 4919 ];
      allowedTCPPorts = [ 4444 8081 3478 3000 8080 5900 ];
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
      "https://snack.cachix.org" ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      #"hydra.wedlake.lan:C3xufTQ7w2Y6VHtf+dyA6NmQPiQjwIDEavJNmr97Loo="
      "snack.cachix.org-1:yWpdDCWeJzVAQUSM1Ol0E3PCVbG4k2wRAsZ/b5L3huc="
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
    android_sdk.accept_license = true;
    packageOverrides = super: let self = super.pkgs; in {
      nixops = super.nixops.overrideDerivation (
      old: {
        patchPhase = ''
            substituteInPlace nix/eval-machine-info.nix \
                --replace 'system.nixosVersion' 'system.nixos.version'
        '';
      }
      );
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
    extraGroups = [ "wheel" "docker" "disk" "video" "libvirtd" "adbusers" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };

  # move to host system
  profiles.zsh.enable = true;
  profiles.zsh.autosuggest = true;
  profiles.vim = {
      enable = true;
      dev = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    hledger
    teamspeak_client
    psmisc
    sway-beta
    #hie82
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
    i3-gaps
    xlockmore
    i3status
    feh
    imagemagick
    weechat
    rxvt_unicode-with-plugins
    xsel
    keepassx2
    tcpdump
    telnet
    xclip
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
    aws_shell
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
  ];

  hardware = {
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      extraConfig = "load-module module-switch-on-connect";

    };
    opengl.enable = true;
    opengl.extraPackages = [ pkgs.vaapiIntel ];
    facetimehd.enable = true;
    bluetooth = {
      enable = true;
      extraConfig = ''
        [general]
        Enable=Source,Sink,Media,Socket
      '';
    };
  };
  fonts.enableFontDir = true;
  fonts.enableCoreFonts = true;
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
  programs.adb.enable = true;
  programs.sway-beta = {
    enable = true;
  };

  services = {
    toxvpn = {
      enable = false;
      localip = "10.40.13.3";
    };

    postgresql = {
      enable = true;
      authentication = ''
        local all all trust
        host  all all 127.0.0.1/32 trust
      '';
  };
    influxdb.enable = true;
    grafana = {
      enable = false;
      addr = "0.0.0.0";
    };

    #zfs.autoSnapshot.enable = true;
    #grafana_reporter = {
    #  enable = true;
    #  grafana = {
    #    addr = "optina.wedlake.lan";
    #  };
    #};
    offlineimap = {
      enable = true;
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

    udev.extraRules = ''
      ATTR{idVendor}=="1d50", ATTR{idProduct}=="6089", SYMLINK+="hackrf-one-%k", MODE="660", GROUP="plugdev"
    '';

    compton = {
      enable = true;
      shadowExclude = [''"_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"''];
      extraOptions = ''
        opacity-rule = [
        "95:class_g = 'URxvt' && !_NET_WM_STATE@:32a",
        "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
        ];
      '';
    };
    #xserver = {
    #  #xautolock = {
    #  #  enable = true;
    #  #  time = 5;
    #  #  locker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #  #  nowlocker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #  #  #killer = "${pkgs.systemd}/bin/systemctl suspend";
    #  #  #killtime = 30;
    #  #  extraOptions = [ "-detectsleep" ];
    #  #};
    #  libinput = {
    #    enable = true;
    #    tapping = true;
    #    disableWhileTyping = true;
    #    scrollMethod = "twofinger";
    #    naturalScrolling = false;
    #  };
    #  #autorun = true;
    #  enable = true;
    #  #layout = "us";
    #  desktopManager = {
    #    gnome3.enable = true;
    #    #default = "gnome3";
    #  };
    #  windowManager.i3 = {
    #    enable = true;
    #    extraSessionCommands = ''
    #      ${pkgs.xlibs.xset}/bin/xset r rate 200 60 # set keyboard repeat
    #      ${pkgs.feh} --bg-scale /home/sam/photos/20170503_183237.jpg
    #    '';
    #  };
    #  windowManager.i3.package = pkgs.i3-gaps;
    #  #windowManager.i3.configFile = import ../i3config.nix { inherit config; inherit pkgs; inherit parameters; };
    #  #windowManager.default = "i3";
    #  displayManager.gdm = {
    #    enable = true;
    #  };
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
  environment.etc."per-user/sam/gitconfig".text = import ../sam-dotfiles/git-config.nix;

  system.activationScripts.samdotfiles = {
    text = "ln -sfn /etc/per-user/sam/gitconfig /home/sam/.gitconfig";
    deps = [];
  };

}
