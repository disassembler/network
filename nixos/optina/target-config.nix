{...}: {
  imports = [./hardware-configuration.nix ./generated.nix];
  boot.loader.grub.enable = true;
  services.openssh.enable = true;
  boot.zfs.devNodes = "/dev"; # fixes some virtualmachine issues
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = false;
  boot.kernelParams = [
    "boot.shell_on_fail"
    "panic=30"
    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
}
