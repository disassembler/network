# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  #sops.defaultSopsFile = ./secrets.yaml;
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
    };
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      useOSProber = true;
      default = "saved";
      device = "nodev";
      theme = pkgs.nixos-grub2-theme;
      memtest86.enable = true;
    };
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_acpi"];
      kernelModules = [];
    };
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Webcam"
      '';
    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];
    kernelModules = [
      "v4l2loopback"
      "amdgpu"
      "kvm-amd"
    ];
    tmp.cleanOnBoot = true;
  };


  nix = {
    settings.sandbox = true;
    settings.cores = 4;
    settings.substituters = [ "https://cache.nixos.org" "https://cache.iog.io" ];
    settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    extraOptions = ''
      experimental-features = nix-command flakes fetch-closure
    '';
  };

  nixpkgs.overlays = [
    inputs.niri.overlays.niri
  ];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    android_sdk.accept_license = true;
    packageOverrides = super: {
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
  networking = {
    hostName = "silouan";
    hostId = "3443dfc0";
    tempAddresses = "disabled";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

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

  environment = {
    etc = {
      "per-user/sam/gitconfig".text = import ../../sam-dotfiles/git-config.nix;
      "sway/config".source = ../../sam-dotfiles/sway/config;
      "per-user/sam/wezterm.lua".source = ../../sam-dotfiles/wezterm.lua;
      "xdg/waybar/config".source = ../../sam-dotfiles/waybar/config;
      "xdg/waybar/style.css".source = ../../sam-dotfiles/waybar/style.css;
    };

    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
  };

  environment.systemPackages = with pkgs; [
    inputs.home-manager.packages.x86_64-linux.home-manager
    pciutils
    google-chrome
    wget
    vim
    screen
    gitMinimal
    pinentry-gtk2
    gnupg
    python3Packages.ipython
    srm
    jq
    steamcmd
    wineWowPackages.waylandFull
    winetricks
    starship
    mesa-demos
  ];

  hardware = {
    opentabletdriver.enable = true;
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
        amdgpuBusId = "PCI:100:0:0";
        nvidiaBusId = "PCI:1:0:0";
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

  programs = {
    ssh.startAgent = lib.mkForce false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };
    mosh.enable = true;
    bash = {
      interactiveShellInit = ''
      eval "$(direnv hook bash)"
      eval "$(starship init bash)"
      '';
    };
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


  };

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    libinput.enable = true;

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
    openssh = {
      settings.PasswordAuthentication = false;
      enable = true;
    };

    xserver = {
      videoDrivers = [ "amdgpu" "nvidia" ];
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.allowedUDPPorts = [];

  users.users.sam = {
    uid = 1000;
    isNormalUser = true;
    description = "Sam Leathers";
    extraGroups = [ "wheel" "podman" "disk" "video" "libvirtd" "adbusers" "dialout" "plugdev" "cexplorer" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q==" ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
    shell = pkgs.lib.mkOverride 50 "${pkgs.bashInteractive}/bin/bash";
  };

  users.users.jacob = {
        isNormalUser = true;
        description = "Jacob Leathers";
        uid = 1001;
        extraGroups = [ "disk" "video" "libvirtd" "adbusers" "dialout" "plugdev" ];
        openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io" ] ;
  };
  users.users.aidan = {
        isNormalUser = true;
        description = "Aidan Leathers";
        uid = 1002;
        extraGroups = [ "disk" "video" "libvirtd" "adbusers" "dialout" "plugdev" ];
        openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io" ] ;
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';

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

  powerManagement.enable = true;
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "25.05"; # Did you read the comment?

}
