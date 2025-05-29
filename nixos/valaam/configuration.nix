# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.pool_opcert = { };
  sops.secrets.pool_vrf_skey = { };
  sops.secrets.pool_kes_skey = { };
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
      device = "nodev";
      efiSupport = true;
    };
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_acpi"];
      kernelModules = [];
    };
    kernelModules = [ "amdgpu" "kvm-amd" ];
    extraModulePackages = [];
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
  nixpkgs.config.allowUnfree = true;
  networking = {
    hostName = "valaam";
    hostId = "07c7b2e8";
    tempAddresses = "disabled";
    bridges = {
      br0 = {
        interfaces = [ "enp4s0" ];
      };
    };
    useDHCP = false;
    interfaces.br0.mtu = 1492;
    interfaces.br0.useDHCP = true;
    interfaces.wlp3s0.useDHCP = true;
    networkmanager.enable = false;
    # TODO: remove when working
    #nat = {
    #  enable = true;
    #  internalInterfaces = [ "ve-+" ];
    #  externalInterface = "mv-enp4s0-host";
    #};
    #wireless = {
    #  enable = true;
    #  networks = secrets.wifiNetworks;
    #};
  };

  time.timeZone = "GMT";

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

  environment.systemPackages = with pkgs; [
    wget
    vim
    screen
    gitMinimal
    pinentry
    gnupg
    python3Packages.ipython
    srm
    jq
    steamcmd
    wineWowPackages.waylandFull
    winetricks
    starship
  ];

  programs = {
    gnupg.agent = { enable = true; enableSSHSupport = false; };
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
    openssh = {
      settings.PasswordAuthentication = false;
      enable = true;
    };

    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 3001 9090 9093 3000 3100 7777 ];
  # TODO: pull users from secrets.nix instead
  users.users.sam = {
    uid = 10016;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q==" ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
    shell = pkgs.lib.mkOverride 50 "${pkgs.bashInteractive}/bin/bash";
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

  powerManagement.enable = false;
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "25.05"; # Did you read the comment?

}
