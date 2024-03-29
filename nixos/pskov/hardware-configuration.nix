# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "zpool/nixos/root";
      fsType = "zfs";
    };

  fileSystems."/etc" =
    {
      device = "zpool/nixos/etc";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/nix" =
    {
      device = "zpool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/var" =
    {
      device = "zpool/nixos/var";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/var/lib" =
    {
      device = "zpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/var/log" =
    {
      device = "zpool/nixos/var/log";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/var/spool" =
    {
      device = "zpool/nixos/var/spool";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/3A77-2E7B";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/dbbb1887-5623-4ac0-819f-b7e04d6b2d43"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
