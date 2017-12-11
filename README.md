# Home Network

* secrets.nix is just an attribute set that isn't committed to the repo

## Portal

* Portal is an apu.2c4 https://pcengines.ch/apu2c4.htm

* USB disk to initially boot:

```
{
  imports = [<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>];
  boot.supportedFilesystems = [ "zfs" ]; # Not needed, was originally trying to use zfs but went with ext4
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
}
```

To build: `nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=/home/sam/nixos-vm-config/usb.nix`

To create USB disk: `dd if=/nix/store/23vl3hllb7gyfsgdrbzcyx8gjk75yimm-nixos-17.09.git.d9d1469b813-x86_64-linux.iso/iso/nixos-17.09.git.d9d1469b813-x86_64-linux.iso of=/dev/sdb`. Make sure to use the hash path output from previous command.

* The apu.2c4 has 3 ethernet interfaces:
  1) Cable Modem
  2) untagged LAN
  3) tagged everything else (including LAN)
