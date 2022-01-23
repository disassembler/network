{ lib, modulesPath, ... }:
let
  shared = import ../../shared.nix;

in {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    ./kexec.nix
    ./justdoit.nix
    ./autoreboot.nix
  ];

  kexec.autoReboot = true;

  kexec.justdoit = {
    rootDevice = "/dev/vda";
    bootSize = 1024;
    bootType = "zfs";
    swapSize = 2 * 1024;
    luksEncrypt = false;
    uefi = false;
    nvme = false;
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.enable = false;
  boot.kernelParams = [
    "panic=30" "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
  services.openssh.enable = true;
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  networking.hostName = "kexec";
}
