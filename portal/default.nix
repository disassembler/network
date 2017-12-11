{ secrets }:
{ config, pkgs, ... }:
let
  externalInterface = "enp1s0";
  internalInterfaces = [
    "br0"
    "enp3s0.3"
    "enp3s0.9"
    "enp3s0.12"
    "enp3s0.40"
  ];


in {
  imports =
    [
      ./hardware.nix
    ];


  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking = {
    hostName = "portal";
    hostId = "fa4b7394";
    vlans = {
      lan_port = {
        interface = "enp3s0";
        id = 33;
      };
      voip = {
        interface = "enp3s0";
        id = 40;
      };
    };
    bridges = {
      br0.interfaces = [ "lan_port" "enp2s0" ];
    };
    interfaces = {
      ${externalInterface} = {
        useDHCP = true;
      };
      br0 = {
        ipAddress = "10.40.33.1";
        prefixLength = 24;
      };
      voip = {
        ipAddress = "10.40.40.1";
        prefixLength = 24;
      };
    };
    nat = {
      enable = true;
      externalInterface = "${externalInterface}";
      internalIPs = [ "10.40.33.0/24" "10.40.40.0/24" ];
      internalInterfaces = [ "voip" "br0" ];
    };
    enableIPv6 = true;
    dhcpcd.persistent = true;
    dhcpcd.extraConfig = ''
      noipv6rs
      interface ${externalInterface}
      ia_na 1
      ia_pd 2/::/60 br0/0 voip/1
    '';
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 53 5353 546 547 ];
      allowedUDPPorts = [ 5353 53 67 546 547 ];
    };
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    wget
    vim
    tmux
    git
  ];

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "without-password";
      passwordAuthentication = false;
    };
    dhcpd4 = {
      interfaces = [ "br0" "voip" ];
      enable = true;
      machines = [
        { hostName = "crate"; ethernetAddress = "d4:3d:7e:4d:c4:7f"; ipAddress = "10.40.33.20"; }
      ];
      extraConfig = ''
        subnet 10.40.33.0 netmask 255.255.255.0 {
          option domain-search "wedlake.lan";
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.33.255;
          option routers 10.40.33.1;
          option domain-name-servers 10.40.33.20;
          range 10.40.33.100 10.40.33.200;
        }
        subnet 10.40.40.0 netmask 255.255.255.0 {
          option subnet-mask 255.255.255.0;
          option broadcast-address 10.40.40.255;
          option routers 10.40.40.1;
          option domain-name-servers 8.8.8.8;
          range 10.40.40.100 10.40.40.200;
        }
      '';
    };
    radvd = {
      enable = true;
      config = ''
        interface br0
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
        interface voip
        {
           AdvSendAdvert on;
           prefix ::/64
           {
                AdvOnLink on;
                AdvAutonomous on;
           };
        };
      '';
    };
  };

  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = secrets.sam_ssh_keys;
  };
  system.stateVersion = "17.09";

}

