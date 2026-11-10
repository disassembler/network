# Temporary first stage: upgrade the existing SATA OS before the console rollout.
{
  pkgs,
  lib,
  ...
}: let
  adminKeys = lib.filter (key: key != "") (lib.splitString "\n" (builtins.readFile ./authorized_keys));
in {
  imports = [./hardware-configuration.nix];
  deployment = {
    targetHost = "10.40.33.22";
    targetUser = "root";
    tags = ["maintenance"];
  };
  networking = {
    hostName = "atari";
    hostId = "48ef9cb3";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    interfaces.wlp1s0.useDHCP = true;
    networkmanager.enable = false;
    wireless = {
      enable = true;
      interfaces = ["wlp1s0"];
      extraConfigFiles = ["/var/lib/pechersk-wireless/wpa_supplicant.conf"];
    };
  };
  services.openssh = {
    enable = true;
    settings = {
      # The user enabled this explicitly to allow the initial jailed upgrade.
      PermitRootLogin = lib.mkForce "yes";
      PasswordAuthentication = lib.mkForce true;
    };
  };
  users.mutableUsers = true;
  users.users = {
    root.openssh.authorizedKeys.keys = adminKeys;
    sam = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = adminKeys;
    };
    atari = {
      isNormalUser = true;
      uid = 1000;
      openssh.authorizedKeys.keys = adminKeys;
    };
  };
  environment.systemPackages = with pkgs; [vim gitMinimal pciutils usbutils];
  systemd.tmpfiles.rules = [
    "d /var/lib/pechersk-wireless 0750 root wpa_supplicant -"
    "z /var/lib/pechersk-wireless/wpa_supplicant.conf 0640 root wpa_supplicant -"
  ];
  system.stateVersion = "21.03";
}
