{
  pkgs,
  lib,
  ...
}: let
  adminKeys = lib.filter (key: key != "") (lib.splitString "\n" (builtins.readFile ./authorized_keys));
in {
  imports = [./hardware-configuration.nix ./console.nix ./ports.nix ./pc-games.nix ./bluetooth-menu.nix ./theme.nix ./music.nix ./dance-pads.nix];

  deployment = {
    targetHost = "10.40.33.22";
    targetUser = "root";
    tags = ["home" "console"];
    # First activation is a separate, explicit upgrade from the old SATA NixOS.
    allowLocalDeployment = false;
  };
  networking = {
    hostName = "pechersk";
    useDHCP = false;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      wifi.macAddress = "permanent";
      ethernet.macAddress = "permanent";
    };
    firewall = {
      enable = true;
      # Guest data sharing/discovery is limited to the home client subnet.
      extraCommands = ''
        iptables -A nixos-fw -s 10.40.33.0/24 -p tcp -m multiport --dports 139,445,5357 -j nixos-fw-accept
        iptables -A nixos-fw -s 10.40.33.0/24 -p udp -m multiport --dports 137,138,3702 -j nixos-fw-accept
      '';
    };
  };
  time.timeZone = "America/New_York";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  users.groups.gamer = {};
  users.users = {
    gamer = {
      isNormalUser = true;
      group = "gamer";
      home = "/var/lib/pechersk";
      createHome = true;
      extraGroups = ["audio" "video" "render" "input" "networkmanager"];
    };
    sam = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = ["wheel" "networkmanager" "gamer"];
      openssh.authorizedKeys.keys = adminKeys;
    };
    atari = {
      isNormalUser = true;
      uid = 1000;
    };
    root.openssh.authorizedKeys.keys = adminKeys;
  };
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Name = "pechersk";
        ControllerMode = "dual";
        FastConnectable = true;
        JustWorksRepairing = "always";
        MultiProfile = "multiple";
      };
      Policy.AutoEnable = true;
    };
    # Matches the source's PS3 compatibility setting.
    input.General.ClassicBondedOnly = false;
  };
  hardware.xpadneo = {
    enable = true;
    settings.disable_shift_mode = 1;
  };
  services = {
    joycond.enable = true;
    blueman.enable = true;
    udev.packages = [pkgs.game-devices-udev-rules];
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish.enable = true;
      publish.userServices = true;
    };
    samba = {
      enable = true;
      openFirewall = false;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "Pechersk game library";
          "map to guest" = "Bad User";
          "guest account" = "gamer";
          "hosts allow" = "10.40.33.0/24 127.0.0.1";
          "hosts deny" = "ALL";
        };
        share = {
          path = "/userdata";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = "gamer";
          "create mask" = "0664";
          "directory mask" = "0775";
          "wide links" = "no";
        };
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = false;
    };
    logind.settings.Login = {
      HandlePowerKey = "poweroff";
      IdleAction = "ignore";
    };
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;
  systemd.services.pechersk-power-limits = {
    description = "Restore measured Batocera Atari VCS power limits";
    wantedBy = ["multi-user.target"];
    unitConfig.ConditionPathExists = "/sys/class/dmi/id/product_name";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=30000 --fast-limit=30000 --slow-limit=24000 --tctl-temp=95";
    };
  };

  environment.systemPackages = with pkgs; [gitMinimal pciutils usbutils evtest bluez networkmanagerapplet pavucontrol mesa-demos xdotool xorg.xwininfo xorg.xdpyinfo];
  # Existing installation was built as 21.03pre in July 2021.
  system.stateVersion = "21.03";
}
