{ lib, modulesPath, ... }:
let
  shared = import ../../shared.nix;

in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-gnome.nix")
    ./kexec.nix
    ./justdoit.nix
  ];

  kexec.justdoit = {
    bootSize = 1024;
    bootType = "zfs";
    swapSize = 1 * 1024;
    luksEncrypt = false;
    uefi = true;
    nvme = false;
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.enable = false;
  nix = {
    settings.sandbox = true;
    settings.cores = 4;
    settings.extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
    settings.substituters = [ "https://cache.nixos.org" "https://cache.iog.io" ];
    settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    extraOptions = ''
      binary-caches-parallel-connections = 3
      connect-timeout = 5
      experimental-features = nix-command flakes
    '';
  };
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.40.9.5/24" "fd00::5" ];
    listenPort = 51820;
    # generate a private key with "wg genkey" and put it in this string
    # DO NOT COMMIT the privateKey
    privateKey = "";
    peers = [
      {
        publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
        allowedIPs = [ "10.40.33.0/24" "10.40.9.1/32" ];
        endpoint = "prophet.samleathers.com:51820";
        persistentKeepalive = 30;
      }
    ];
  };
  services.openssh.enable = true;
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  networking.hostName = "kexec";
}
