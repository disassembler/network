# Home Network

## Secrets

* secrets are stored encrypted based on host SSH key
* Following command allows you to add a key:
```
ssh root@host "cat /etc/ssh/ssh_host_rsa_key" | ssh-to-pgp -o nixos/secrets/keys/host.asc
```



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


## Darwin

Preliminary darwin support has been added. It's a three step process:

1) Install Nix

    curl https://nixos.org/nix/install | sh


2) Preparation

    nix-build -I network=https://github.com/disassembler/network/archive/master.tar.gz <network>
    result/bin/prepare

2) Deployment

    ./deploy.hs --role ohrid/default.nix <IP>

# NixOS Configs

NixOS machines not managed by nixops are in `machines/hostname.nix`. Symlink that
file to `/etc/nixos/configuration.nix`.
