# First OS upgrade: SATA NixOS 21.03 to 26.05

The user requested upgrading the existing SATA OS before the gaming deployment. `pechersk-upgrade` is a separate Colmena maintenance node targeting 10.40.33.22 and retaining hostname `atari`. It has no desktop or emulator services; the full `pechersk` node remains a later step.

## Prepared and inspected

- Old system: NixOS 21.03pre-git, kernel 5.4.93, Nix 2.3.10, systemd 247; current profile generation 4 after the user enabled root password login.
- Maintenance build: NixOS release 26.05 (Yarara), kernel 6.18.60, systemd 260.5, repository-pinned Nix; stateVersion remains 21.03.
- Existing SATA mount UUIDs/subvolumes and swap preserved. No Batocera USB/eMMC changes.
- Existing sam UID 1001 and atari UID 1000 preserved; mutable user/password state retained. Root password SSH explicitly remains enabled for this transitional stage because the jail has no SSH agent.
- WLAN remains wpa_supplicant on wlp1s0 with DHCP, Ethernet DHCP on enp2s0. The exact active old WLAN configuration is copied to `/var/lib/pechersk-wireless/wpa_supplicant.conf`; only root and the new wpa_supplicant service account receive access (directory 0750, file 0640 after tmpfiles). No credentials are rendered into new store files.
- Full backup of `/etc/nixos`, SSH/account files and `/boot`: `/var/lib/pechersk-upgrade/pre-26.05.tar.gz`, mode 0600. Previous system path: `/var/lib/pechersk-upgrade/previous-system`. The first archive attempt included absent `/etc/gshadow`; its incomplete archive was retained separately and a corrected archive passed listing validation.
- Local build, formatting and NixOS assertions pass. Generated fstab, bootspec, SSH settings, WLAN service and user IDs inspected.

## Deployment

Colmena uses a private local SSH config selecting the already authenticated master socket and the user-authorized known-host bypass. Passwords are not put in environment variables or command-line arguments.

```sh
nix develop -c env SSH_CONFIG_FILE=/tmp/pechersk-batocera-audit/upgrade-ssh-config \
  colmena apply boot --on pechersk-upgrade --no-keys --verbose
```

Exact built path is recorded in `/tmp/pechersk-batocera-audit/upgrade-toplevel-path`; deployment log is `upgrade-deployment.log` beside it. Stage the boot generation first, inspect the new entry and preserved old entries, then reboot. After reconnecting, verify os-release, running kernel, Nix, root/profile paths, WLAN/DHCP, all mounts, user IDs and failed services. Do not deploy the full console node as part of this stage.

## Transfer blocker and repository correction

The user confirmed that Colmena should use destination substitution. The first invocation unnecessarily disabled substitution; the default retry still copied through SSH with the old daemon. A user-approved direct cache prefetch exposed the actual compatibility error: Nix 2.3.10 reports `unknown compression method 'zstd'` for modern cache objects. The incompatible prefetch was stopped.

The user directed a static Nix bootstrap. The pinned Nix input's `nix-cli-static` provides Nix 2.34.6, fetched from cache.nixos.org. Its executable was copied to `/var/lib/pechersk-upgrade/static-nix/nix`. After stopping the old socket/service and remaining stdio daemon, the entire store database was archived consistently to `/var/lib/pechersk-upgrade/nix-db-before-static.tar` (0600). A transient `pechersk-static-nix-daemon-v2.service` runs the static binary through its `nix-daemon --daemon` compatibility entry point; the first launch through `nix daemon` required the disabled nix-command feature and exited before opening the store. The replacement responds as Nix 2.34.6 over the daemon socket.

The original dangling `/root/.nix-profile` link was moved to `/var/lib/pechersk-upgrade/root-nix-profile-original`; temporary client symlinks at the original profile path expose the static tools to SSH/Colmena. Restore that original link after staging the new generation, before reboot. Signed cache dependency prefetch completed successfully, and Colmena copied the full maintenance closure and created system profile generation 5.

Boot staging then failed: systemd 260.5's `bootctl status` returns `Protocol driver not attached` accessing `/boot` under the running kernel 5.4.93. The existing systemd 247 bootctl reads the same ESP successfully. `/run/current-system` remains 21.03, the system profile points at 26.05 generation 5, and the ESP still has generations 1–4 with generation 4 the default. No reboot has occurred.

The user instead approved switching to EFI GRUB, matching the other hosts. Use `efiSupport = true`, `efiInstallAsRemovable = true`, `device = "nodev"`, ten generations and disabled automatic EFI-variable writes. Rebuild the maintenance node and deploy through Colmena. Preserve the existing systemd-boot files and verify the actual firmware boot route before reboot; the existing firmware entry specifically names systemd-boot, so merely installing the fallback GRUB executable does not prove it will be selected. The manual generation-5 entry prepared locally was not installed.

The GRUB maintenance build passed with no failed assertions. Colmena `apply boot` succeeded and created generation 6 at `/nix/store/g5i4flx6vxlvk1rgg06xnbll2q95bapz-nixos-system-atari-26.05pre-git`. GRUB configuration syntax passed; the first menu entry targets that system, rollback generations 1–5 remain, and the ESP kernel/initrd compare exactly with the built files. The old systemd-boot executable and entries remain intact.

The user explicitly authorized `efibootmgr` to set the default loader. Created Boot0000, `Pechersk NixOS GRUB`, on SATA partition 1 at `\EFI\BOOT\BOOTX64.EFI`. Before reboot BootOrder was `0000,0001,0003,0002`; the original Boot0003 systemd-boot entry remains. Before/after EFI listings are backed up privately in `/var/lib/pechersk-upgrade/efi-{before,after}-grub.txt`. Automatic firmware writes stay disabled declaratively. The original root profile symlink was restored, files synced, and reboot requested.

The reboot returned to Batocera/Buildroot on USB, not NixOS. Read-only inspection reports BootCurrent `0004` (EFI USB Samsung Flash Drive); BootOrder is now `0005,0000,0001,0003,0002,0004`, with a new Boot0005 Batocera entry. The cause of USB selection is not yet established. Boot0000 still correctly names SATA GRUB, and its executable/configuration remain on the auto-mounted SATA ESP. No mutations were made in this Batocera session. Post-boot NixOS verification is pending user-approved one-shot BootNext/reboot or manual selection of Pechersk NixOS GRUB, respecting the read-only Batocera boundary.

## Verified result

The user corrected the USB boot selection manually. SSH reconnected to the maintenance NixOS system, and the following checks passed:

- Running release: NixOS 26.05 (Yarara), kernel 6.18.60, Nix 2.34.6. Current system and system profile both resolve to the GRUB generation-6 path above.
- Firmware BootCurrent is `0000`, Pechersk NixOS GRUB. BootOrder is `0000,0001,0003,0002`. GRUB is first and the original Boot0003 recovery entry remains.
- WLAN wlp1s0 is up at 10.40.33.22/24, with DHCP default route through 10.40.33.1. wpa_supplicant, dhcpcd and SSH are active. Runtime WLAN directory/file permissions are 0750/0640 root:wpa_supplicant.
- All six existing Btrfs subvolumes mount correctly: root=nixos, /nix=nix, /var=var, /home=home, /games=games, /tmp=tmp. /boot is SATA partition 1; swap is SATA partition 4. Existing root/sam/atari IDs are preserved.
- The normal generation-managed Nix daemon and socket are active, answer as 2.34.6, and use `https://cache.nixos.org/`. The temporary static daemon is no longer needed; its executable/database backup are retained privately for recovery. The original root profile link is restored.
- No failed systemd units. Boot logs report unavailable AMD SVM/KVM and an HDA function without codecs, plus duplicate wpa_supplicant D-Bus metadata; these did not prevent boot/network access. HDMI audio/controller acceptance belongs to the full console rollout and remains unverified.

The first OS upgrade is complete. The machine intentionally remains the minimal text-console maintenance node with hostname `atari` and stateVersion 21.03. Next is deploying the full `pechersk` console configuration, migrating private wireless/Bluetooth and game data using the documented procedure, and completing hardware acceptance. No full console deployment or Batocera/eMMC file changes were performed during this stage.

All task changes now live in the original `/home/sam/home/network` checkout on `master`. The incorrectly created sibling worktree and its empty feature branch were removed after verifying an exact binary-patch transfer. Existing unrelated backup files and scratch data were left intact. Continue all repository work in this single checkout.
