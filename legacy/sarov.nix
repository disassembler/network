{ lib, config, pkgs, ... }:

  let
    secrets = import ../load-secrets.nix;

  in {
  environment.systemPackages = with pkgs; [
    sway-beta
    xdg_utils
    hledger
    teamspeak_client
    psmisc
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
    androidsdk_9_0
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
    python3Packages.goobook
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
      support32Bit = true;
      package = pkgs.pulseaudioFull;
      #      configFile = pkgs.writeText "default.pa" ''
      #        load-module module-bluetooth-policy
      #        load-module module-bluetooth-discover
      #        load-module module-bluez5-device
      #        load-module module-bluez5-discover
      #'';

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

  powerManagement.enable = true;

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
    #  xautolock = {
    #    enable = true;
    #    time = 5;
    #    locker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #    nowlocker = "${pkgs.xtrlock-pam}/bin/xtrlock-pam";
    #    #killer = "${pkgs.systemd}/bin/systemctl suspend";
    #    #killtime = 30;
    #    extraOptions = [ "-detectsleep" ];
    #  };
    #  videoDrivers = [ "intel" ];
    #  #multitouch = {
    #  #  enable = true;
    #  #  invertScroll = false;
    #  #  buttonsMap = [1 3 2];
    #  #  ignorePalm = true;
    #  #};
    #  synaptics.additionalOptions = ''
    #    Option "VertScrollDelta" "100"
    #    Option "HorizScrollDelta" "100"
    #  '';
    #  synaptics.enable = true;
    #  synaptics.tapButtons = true;
    #  synaptics.fingersMap = [ 0 0 0 ];
    #  synaptics.buttonsMap = [ 1 3 2 ];
    #  synaptics.twoFingerScroll = true;
    #  #libinput = {
    #  #  enable = true;
    #  #  disableWhileTyping = true;
    #  #};
    #  autorun = true;
    #  enable = true;
    #  layout = "us";
    #  windowManager.i3 = {
    #    enable = true;
    #    extraSessionCommands = ''
    #      ${pkgs.xlibs.xset}/bin/xset r rate 200 60 # set keyboard repeat
    #      ${pkgs.feh} --bg-scale /home/sam/photos/20170503_183237.jpg
    #    '';
    #  };
    #  windowManager.i3.package = pkgs.i3-gaps;
    #  #windowManager.i3.configFile = import ../i3config.nix { inherit config; inherit pkgs; inherit parameters; };
    #  windowManager.default = "i3";
    #  displayManager.slim = {
    #    enable = true;
    #    defaultUser = "sam";
    #    theme = pkgs.fetchurl {
    #      url    = "https://github.com/nickjanus/nixos-slim-theme/archive/2.1.tar.gz";
    #      sha256 = "8b587bd6a3621b0f0bc2d653be4e2c1947ac2d64443935af32384bf1312841d7";
    #    };
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
  system.stateVersion = "17.09";

}
