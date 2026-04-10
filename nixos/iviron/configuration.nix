{
  self,
  lib,
  inputs,
  config,
  pkgs,
  ...
}: let
  shared = import ../../shared.nix;
  machine = "iviron";
  hostId = "7a6c1214";
in {
  deployment = {
    targetHost = "127.0.0.1";
    #targetHost = "10.40.33.60"; when deploying remotely
    targetPort = 22;
    targetUser = "root";
  };
  #sops.defaultSopsFile = ./secrets.yaml;
  #sops.secrets.docker_auth = { };

  _module.args = {
    inherit shared;
  };

  #Boot Config

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

  boot.supportedFilesystems = ["exfat" "zfs"];
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
  boot.blacklistedKernelModules = ["nouveau"];

  # Splash screen to make boot look nice
  boot.plymouth.enable = false;

  console.keyMap = "us";
  console.packages = with pkgs; [terminus_font];
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
      #wg0 = {
      #  ips = ["10.70.0.1/24"];
      #  postSetup = ''
      #    ip link set mtu 1392 dev wg0
      #  '';
      #  privateKeyFile = "/var/lib/wg-keys/wg0.key";
      #  peers = [
      #    {
      #      publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
      #      allowedIPs = [
      #        "10.40.33.0/24"
      #        "10.40.9.0/24"
      #        #"192.168.0.0/24"
      #      ];
      #      endpoint = "prophet.samleathers.com:51820";
      #      persistentKeepalive = 30;
      #    }
      #  ];
      #};
      #wg1 = {
      #  ips = [ "10.250.192.2/32" ];
      #  mtu = 1280;
      #  privateKeyFile = "/var/lib/wg-keys/wg1.key";
      #  peers = [
      #    {
      #      publicKey = "W8Mqo7sGVNUVXe/+3Yb0DqiN/QPKGpc6BHB8H10jagE=";
      #      allowedIPs = [
      #        "10.200.128.0/24"
      #        "10.200.129.0/24"
      #        "10.160.0.0/22"
      #        "10.101.0.0/21"
      #        "10.140.0.0/24"
      #      ];
      #      endpoint = "64.78.224.166:51821";
      #      persistentKeepalive = 30;
      #    }
      #  ];
      #};
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
    extraHosts = ''
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
    firewall = {
      enable = true;
      allowedUDPPorts = [53 4919 69 6666 6667 6668];
      allowedTCPPorts = [4444 8081 3478 3000 8080 5900 3100 3001];
    };
  };

  nix = let
    buildMachines = import ../../build-machines.nix;
  in {
    settings.sandbox = true;
    settings.cores = 4;
    settings.substituters = ["https://cache.iog.io"];
    settings.trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    settings.trusted-users = ["sam"];
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

  nixpkgs.overlays = [];

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  users.groups.plugdev = {};
  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = ["wheel" "podman" "disk" "video" "libvirtd" "adbusers" "dialout" "plugdev" "cexplorer" "input"];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  #users.users.cardano-node.isSystemUser = true;

  programs.zsh = {
    enable = true;
  };
  programs.bash = {
    enable = true;
  };

  environment.systemPackages = with pkgs; let
  in [
    nvtopPackages.nvidia
    cudaPackages.cudatoolkit
    config.boot.kernelPackages.nvidiaPackages.stable
    inputs.home-manager.packages.x86_64-linux.home-manager
    polychromatic
    libfido2
    yubikey-manager
  ];

  hardware = {
    sane.enable = true;
    gpgSmartcards.enable = true;
    opentabletdriver.enable = true;
    openrazer = {
      enable = true;
      users = ["sam"];
    };
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [nvidia-vaapi-driver];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
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
    ubuntu-classic
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
      package = inputs.niri.packages.x86_64-linux.niri-unstable;
    };
    sway = {
      enable = true;
      extraOptions = ["--unsupported-gpu"];
    };

    waybar.enable = true;
    ssh.startAgent = lib.mkForce false;
  };

  services = {
    picom.enable = lib.mkForce false;
    desktopManager.cosmic.enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false;
    };
    xserver = {
      videoDrivers = ["nvidia"];
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

    flatpak.enable = true;

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
    zfs.autoScrub.pools = ["zpool"];
    zfs.autoSnapshot = {
      enable = true;
      frequent = 8;
      monthly = 1;
    };
    trezord.enable = true;
    resolved.enable = false;
    pcscd.enable = true;
    printing = {
      enable = true;
      browsing = true;
      drivers = [pkgs.cnijfilter2];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    dbus.enable = true;
    acpid.enable = true;
    upower.enable = true;

    udev.extraRules = let
      dependencies = with pkgs; [coreutils gnupg gawk gnugrep];
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
      # Allow user access to Yubikey HIDRAW nodes for FIDO2
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0666", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", GROUP="plugdev", MODE="0660"
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
    udev.packages = with pkgs; [yubikey-personalization platformio-core.udev libfido2];

    compton = {
      enable = true;
      shadowExclude = [''"_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"''];
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
  security.polkit.enable = true;
  security.pki.certificates = [
    "/etc/ssl/certs/mitm-proxy.crt"
  ];
  security.pam.u2f.enable = true;

  environment = {
    etc = {
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
  };

  systemd.user.services = {};
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    hostname = "iviron";
  };
  home-manager.users.sam = ../../home/sam.nix;
  system.stateVersion = "23.05";
}
