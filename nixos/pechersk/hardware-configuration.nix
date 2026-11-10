# Observed from Batocera on 2026-11-02. Existing SATA installation only;
# root/nix/var were also verified against its generation-3 initrd fsinfo.
{
  config,
  lib,
  ...
}: let
  sata = "/dev/disk/by-uuid/08fb2488-9ee2-45b4-8155-eb125c72a77c";
  subvolume = name: {
    device = sata;
    fsType = "btrfs";
    options = ["subvol=${name}"];
  };
in {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot = {
    initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_acpi"];
    initrd.kernelModules = ["amdgpu"];
    kernelModules = ["kvm-amd" "joydev" "uhid" "uinput"];
    extraModprobeConfig = ''
      options rtw88_core disable_lps_deep=y
      options rtw88_pci disable_aspm=y
      options btusb enable_autosuspend=0
    '';
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
    loader.efi.canTouchEfiVariables = false;
  };

  fileSystems = {
    "/" = subvolume "nixos";
    "/nix" = subvolume "nix";
    "/var" = subvolume "var";
    "/home" = subvolume "home";
    "/games" = subvolume "games";
    "/tmp" = subvolume "tmp";
    "/boot" = {
      device = "/dev/disk/by-uuid/E5E5-D361";
      fsType = "vfat";
      options = ["umask=0077"];
    };
  };
  swapDevices = [{device = "/dev/disk/by-uuid/deea0381-9c12-4781-b557-3e07883d89c4";}];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  powerManagement.cpuFreqGovernor = "performance";
}
