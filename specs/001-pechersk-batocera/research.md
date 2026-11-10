# Batocera audit and parity decisions

Inspected 2026-11-02 over SSH using commands that read files, hardware status and block metadata. No installation, pairing, scanning, service restarts, new filesystem mounts or custom script execution occurred. SSH itself produces ordinary access logs. A private configuration archive is at `/tmp/pechersk-batocera-audit/configs.tar.gz` on the development workstation (mode 0600); it contains credentials and pairing keys and must never be committed. It is temporary, not a durable backup.

## Direct observations

| Area | Batocera observation | NixOS disposition |
|---|---|---|
| OS | Batocera 41, 2025-01-06, Linux 6.11.10 | Locked repository NixOS 26.05 packages; preserve the recovered original stateVersion 21.03 |
| Machine | Atari VCS 800 Black Walnut; Ryzen Embedded R1606G, 2 cores / 4 threads; 30,740,812 KiB usable memory | AMD microcode, amdgpu/Mesa, 32-bit graphics for compatibility |
| Display | X11/Openbox, 1920×1080 at 60 Hz, X output HDMI-A-0; kernel connector HDMI-A-1 | X11 modesetting/Openbox, prefer 1080p/60; keep automatic fallback for other displays |
| Sound | PipeWire/WirePlumber, Pulse compatibility; `alsa_output.pci-0000_03_00.1.hdmi-stereo`, 40% volume | PipeWire, same HDMI sink selection when available, initial 40% only |
| WLAN | RTL8822CE [10ec:c822], rtw88_8822ce; MAC 94:08:53:84:9b:9d; DHCP 10.40.33.22 | Linux firmware, NetworkManager, permanent MAC, DHCP |
| WLAN tuning | live `disable_lps_deep=Y`, `disable_aspm=Y` | Preserve both settings and disable WLAN powersave |
| Ethernet | RTL8111/8168 [10ec:8168], r8169; MAC 44:03:77:10:6d:14; currently down | In-kernel r8169, DHCP |
| Bluetooth | Realtek USB 0bda:c822; adapter 94:08:53:84:9B:9E, dual mode, powered, fast connectable | BlueZ; preserve bond store at runtime and adapter settings |
| BT tuning | live btusb autosuspend=N; live bluetooth disable_ertm=N despite a file suggesting 1 | Preserve effective autosuspend setting; do not force ERTM off on modern kernel |
| Input | Two bonded Game Controller devices; one active PID 3250:1002, GUID 05000000503200000210000000000000 | Atari modern controller SDL mapping + RetroArch autoconfig; two-player Mupen and Dolphin mappings |
| Other controller support | joycond active; PS3 BlueZ enabled; xpadneo/xpad replacements present in distribution | Standard game-device udev rules, joycond, xpadneo; retain in-kernel USB drivers |
| CPU | performance governor; Batocera sets fast/STAPM 30 W, slow 24 W, thermal limit 95 C using ryzenadj | performance governor; preserve measured power limits with host-only service; validate thermals |
| USB | 59.8 GiB Batocera USB; SHARE UUID d9095a04-2660-469b-87e4-eedf37d9856d | Never use as NixOS root or auto-mount writable |
| SATA | 931.5 GiB; 1 GiB EFI UUID E5E5-D361; Btrfs root UUID 08fb2488-9ee2-45b4-8155-eb125c72a77c | Reuse existing NixOS; no formatting |
| SATA subvolumes | nixos, nix, var, home, games, tmp; root-tree evidence | Preserve mounts; all mounts verified from recovered original hardware configuration; root/nix/var also from old initrd |
| SATA other | ext4 SOMETHING (10 GiB), swap UUID deea0381-9c12-4781-b557-3e07883d89c4 | Leave ext4 untouched; reuse existing swap |
| eMMC | 29.2 GiB Atari OS with verity/rootfs slots | Leave untouched |
| Sharing | Guest writable SMB `/userdata`, force root; wsdd and Avahi | LAN-restricted guest SMB game data as gamer, wsdd/Avahi discovery; never share system home or pairing keys |
| NFS | nfsd running, `/etc/exports` empty | No exports to reproduce |
| Frontend | Batocera ES, Super Retroboy theme, enabled sounds/music | User selected ES-DE; its own bundled theme; preserve old theme as data only |
| Custom startup | `custom.sh` -> `pro-custom.sh` -> Minecraft library-copy/symlink/delete script | Do not execute; provide packaged Prism Launcher separately |
| Kodi | Enabled, not autostarted, X-button shortcut enabled | Installed and reachable through console tools; shortcut integration differs |

## Library

Approximate sizes: ROM tree 25 GiB, BIOS 617 MiB, saves 3.7 GiB, themes 258 MiB, third-party `system/pro` 1.2 GiB. The directory inventory includes Batocera's empty default directories; directory presence alone does not prove games exist. Top-level content-file counts excluding `_info.txt`, gamelist.xml and PNG/JPEG: Atari800 386, GBA 60, MAME 298, Mega Drive 941, N64 376, NES 788, PC Engine 4, PSX 41, SNES 201, Wii 6, C64 3, GameCube 1. Some additional single-file systems are download/readme placeholders, not established playable games.

- Cover Atari 2600, Atari 800, C64, arcade/MAME (plus mame2003-plus alternative), GBA, Mega Drive, NES, PC Engine, PSX and SNES with selected native RetroArch cores.
- N64 currently launches standalone Mupen64Plus with glide64mk2; preserve that renderer, measured input bindings and core hotkeys, and use the Nix package's plugin paths.
- GameCube/Wii use standalone Dolphin OpenGL with 1× internal resolution and VSync. Preserve GameCube pad inputs, seed hotkeys, and leave Wii remote setup adjustable. Original Wii config is keyboard/mouse with Nunchuk; physical Wiimotes and gamepad-emulated Wii controls require hardware setup.
- Include model3 via Supermodel, PSP via PPSSPP, Doom WADs via libretro prboom, and Kodi/Prism as separate tools. Shell-based ports, Minecraft add-ons, Steam/Flatpak shortcuts and arbitrary downloads are not automatically trusted or launched.
- Keep save directory per Batocera system. Battery save formats need validation; emulator-version-specific states must not be treated as compatible. PSX BIOS and Atari800 OS paths must be checked after import.

## Frontend and source references

Both `emulationstation` and `emulationstation-de` throw removal errors in locked Nixpkgs fa1373130d5a21c040a47c5dbe1913d59ed91808 due to FreeImage vulnerabilities. User selected ES-DE after this finding. Upstream [ES-DE](https://es-de.org/) provides 3.5.0 (2026-09-30); pin official AppImage URL and SHA-256. This uses bundled dependencies and carries their update/security burden; it does not repair FreeImage.

Read upstream v3.5.0 [installation reference](https://gitlab.com/es-de/emulationstation-de/-/blob/v3.5.0/INSTALL.md) and [user guide](https://gitlab.com/es-de/emulationstation-de/-/blob/v3.5.0/USERGUIDE.md). Settings live in ES-DE/settings; enable reading source-style gamelists while keeping newly written metadata in ES-DE's tree. ES-DE uses filename-based media lookup, so convert imported artwork to its media layout. Use custom system definitions with absolute native executable/core paths rather than rely on distro discovery heuristics. Preserve Batocera folder names while selecting appropriate ES-DE theme identifiers.

Batocera's [frontend source](https://github.com/batocera-linux/batocera-emulationstation) documents that its administration and emulator-launch services depend on the distribution; transplanting its frontend alone would leave those features incomplete. ES-DE does not promise theme compatibility with Batocera.

## Limits requiring hardware validation

No Atari Classic Controller is currently connected; the inspected distribution has a Python evdev virtual-spinner converter triggered by an Atari-specific udev rule. Do not claim the generic Linux joystick driver supplies that conversion. No converter is enabled in this implementation. Classic spinner and force feedback remain pending hardware-specific work. Broad controller compatibility, Wii remote pairing, audio routing, thermal behavior and game launch/save compatibility cannot be proven by a Nix build.

## Final storage and validation findings

Recovered the original SATA `/etc/nixos/hardware-configuration.nix` and `configuration.nix` without mounting it: Btrfs root/chunk metadata identified the exact inline extent and uncompressed data extent; targeted block reads retrieved only those files. The original configuration confirms every mount and `system.stateVersion = "21.03"`. No filesystem replay or restoration occurred on the machine. Preserve that version; do not infer it from the installer build label.

The router already reserves 10.40.33.22 for the WLAN MAC under the old `atari` label. No router edits are part of this feature. Current BlueZ bonds and a private runtime NetworkManager profile are prepared separately on the workstation.

The complete closure and generated executable/plugin paths validate. An optional graphical frontend smoke test reached SDL window creation and failed because the local Xvfb exposes no GLX extension (confirmed with xdpyinfo). Directory generation and system-XML parsing pass. This is a local test-environment limitation; graphics on the VCS still require direct validation.
