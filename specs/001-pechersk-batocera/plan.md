# Implementation Plan: Pechersk Atari VCS console

## Extreme Tux Racer and idle display

Check the installed game's native joystick support and documented keyboard controls. Use a scoped game-specific AntiMicroX profile where native input cannot supply both menus/racing and the standard quit chord, retaining standard keyboard bindings and preventing duplicate native input. Verify actual controller navigation/racing/exit with the pads excluded. Seed the correct ES-DE screensaver settings declaratively and update the existing writable settings while ES-DE is stopped; confirm the loaded timer is disabled and X11 reports no blanking or DPMS.

## Retro Trivia input compatibility

Apply a focused patch to a writable cached copy of the installed upstream game at launch, preserving source assets/modules and the migration archive. Give the adapted script a dependency-aware Nix shell header and invoke it directly with pinned Nixpkgs. Handle keyboard navigation/action even with pads attached, keyboard Escape, joystick events by originating device and stable player slots, and face buttons before unsupported pad indices. Reuse the scoped AntiMicroX quit profile and modifier cleanup around Retro Trivia. Build/deploy through Colmena and exercise actual game input and exit before handing back.

## Accessible StepMania charts

Runtime verification found the packaged Springtime and Mecha-Tribe Assault sources mask the writable copies. The user approved separate add-on charts after this check failed. For these two, install four SSC-format `.edit` files containing chart timing and notes, with no cached radar placeholders. The engine loads one chart per edit file and preserves all packaged originals. Exclude deeper nested folders from the song inventory because the engine does not load them.

Audit all writable SATA song simfiles, using SSC where present because StepMania prefers it over SM. Classify actual note density/gaps rather than trusting chart labels alone. Add a child-friendly Beginner chart to songs without a sufficiently gentle chart; add Easy only where no suitable Easy-or-lower option exists. Derive onsets from existing chart notes on strong beats, preserving timing, delays/stops and song metadata. Use sparse single taps, simple alternating-foot patterns and phrase rests, with a BPM-aware minimum time gap. Keep content outside Git; a focused Rust utility records inventory, generated statistics and exact changed files. Use a private working copy, back up originals, validate preservation/constraints and load changed charts in the installed StepMania before applying to the live library. Human rhythm/playability remains a playtest check rather than a claim based on note counts alone.

## Custom monastery theme refinement

For dance-pad isolation, use an input-device group dedicated to VID:PID 0b43:0003. A udev rule before seat ACL processing removes uaccess and assigns final group/mode; the gamer account is not a member of that group. Grant only the fixed StepMania executable that group through a setgid NixOS wrapper. Launch it through a waiting user systemd transient unit outside ES-DE's AppImage namespace, preserving X11/controller environment and the existing scoped quit mapper. Clear old device ACLs and restart the idle frontend to close previously opened pad descriptors. Verify ordinary gamer/SDL/RetroArch access excludes pads, actual StepMania process has group access and two mappings, and GBA quit works with pads connected.

For the requested sound refinement, synthesize original short PCM WAV cues reproducibly with FFmpeg in the theme derivation: a damped wooden tap for scrolling/system browsing, a lower tap for back, and a soft briefly decaying bell for select/favorite/launch. Map all seven ES-DE navigation sound events through the theme's `all` view so no stock electronic clicks remain as fallbacks. Verify durations, levels, actual ES-DE loading and rapid navigation without changing the now-confirmed hymn/system volume.

The user selected Kyiv-Pechersk Lavra specifically. Include original vector interpretations of its golden domes, white walls and bell tower. For the requested background hymn (YouTube WbK6H9XTD0A), obtain audio into SATA public music storage, never a Nix derivation or tracked asset. Use a managed user mpv service, frontend startup/quit and game-start/game-end hooks, and a persistent on/off marker exposed through Console tools. Verify playback uses the HDMI sound server and that hooks silence music while games run and restore it afterwards.

Extend the existing console feature in this checkout. Build an original `pechersk-es-de` theme using the pinned ES-DE 3.5 theme API, local XML/SVG artwork and packaged serif/sans fonts. Use a restrained Orthodox cross ornament and monastery-inspired architectural illustration, warm ivory panels, burgundy selection and muted gold rules. Keep system names, counts, game names, artwork, descriptions and controller hints legible from the TV. Install immutable assets through Nix and expose them in the user's ES-DE themes directory; seed the theme setting and explicitly update the existing writable setting only after a private preview passes. Validate XML/assets, build through Colmena, preview with a separate ES-DE home on the real display, inspect theme logs/screenshots and exercise both system and gamelist views. Keep the stock theme and previous settings available for rollback.

**Branch**: `master` | **Date**: 2026-11-02 | **Spec**: [spec.md](spec.md)

## Summary

Reuse the confirmed SATA NixOS installation, expose it as a Colmena node, and build a fullscreen ES-DE console session with native emulators. The user selected ES-DE and reuse of SATA. Do not install, switch, reboot or change the source. Package the official ES-DE 3.5.0 x86_64 AppImage with a fixed hash, because both EmulationStation packages were removed from pinned Nixpkgs. Its bundled libraries remain upstream's responsibility; wrapping the AppImage does not resolve the FreeImage issue or make it equivalent to a maintained native Nixpkgs package.

## Technical Context

- Language: Nix modules and host-specific shell launch/import scripts; no Python or agent automation framework.
- Platform: x86_64 Atari VCS 800 Black Walnut, Ryzen Embedded R1606G, 2 cores/4 threads, about 30 GiB usable RAM, AMD Vega graphics.
- Dependencies: locked Nixpkgs 26.05, Colmena, upstream ES-DE 3.5.0, RetroArch with selected cores, standalone Mupen64Plus and Dolphin, Kodi, NetworkManager and BlueZ.
- Session: X11 modesetting/Openbox, LightDM autologin as unprivileged `gamer`, no display blanking; restart frontend after exit; graphical WLAN/Bluetooth tools accessible from a console tools system.
- The user explicitly confirmed X11 for this rollout; plan Wayland separately later, without changing this deployment's display stack.
- Storage: keep Btrfs UUID and existing root/nix/var/home/games/tmp subvolumes; EFI UUID E5E5-D361; existing SATA swap UUID. Persistent frontend home and `/userdata` on SATA, independent of USB SHARE and eMMC.
- Bootloader: user approved replacing systemd-boot with EFI GRUB after the first upgrade's bootctl failure. Match kursk's EFI removable installation (`nodev`, EFI support, no automatic firmware-variable writes), retain ten generations and existing systemd-boot recovery files. Inspect the firmware boot route before reboot so installation at the fallback EFI path is actually selected.
- Networking: WLAN DHCP, permanent MAC preserved for current lease/reservation; Ethernet DHCP; firmware and measured driver power settings. Install credentials at runtime in root-only NetworkManager profiles.
- Controller support: BlueZ bonds imported at runtime for the same adapter; udev input access, joydev/uhid, game device rules, xpadneo, joycond. Atari modern gamepad profile duplicated for both players. Classic spinner is not currently connected and needs a separately validated conversion implementation if requested/required.
- Data: copy ROMs/BIOS/saves/screenshots/music/themes with explicit source-path argument to an idempotent host-specific importer; never run Batocera startup scripts. Preserve metadata and convert artwork names into ES-DE media conventions. Treat save states as version-dependent backups.

## Constitution Check

1. Declarative pinned configuration: pass; upstream AppImage also fixed by hash.
2. Existing changes/services preserved: existing single checkout on master; preserve unrelated files.
3. Persistent data outside store: pass; credentials and pairing keys never generated as Nix text.
4. Spec, plan, tasks before code: pass once tasks are written; evaluation/build and hardware quickstart required.
5. No store enumeration: exact Nix-resolved files only. Stop and ask before an implementation strategy change after a failed check.

Recheck after design: the binary frontend is an explicit compatibility tradeoff, not a claim of Batocera service/menu parity. No web applications are introduced. No unrelated host changes are needed.

## Project Structure

- `flake/colmena.nix`: node registration.
- `nixos/pechersk/configuration.nix`: deployment, users, networking and base services.
- `nixos/pechersk/hardware-configuration.nix`: observed SATA mounts, AMD hardware and radio quirks.
- `nixos/pechersk/console.nix`: session, emulators, generated system definitions, defaults and tools.
- `nixos/pechersk/es-de.nix`: fixed-output upstream AppImage package.
- `nixos/pechersk/controllers/`: measured non-secret Atari profiles.
- `nixos/pechersk/import-batocera.sh`: explicit local data import and media conversion, packaged with dependencies by Nix.
- `specs/001-pechersk-batocera/{research,quickstart,tasks}.md`: evidence, migration and acceptance.

## Verification

Inspect the pinned Snes9x and RetroArch sources for Multitap device IDs, logical controller slots and per-game remap loading. Package a writable LOTR-only remap using the existing filename identity; leave other SNES games at their defaults. Verify the remap in an isolated save/state environment, confirm device loading in logs/UI and retain rollback. Five-player physical play and companion behavior require gameplay acceptance; do not infer success merely from the configuration.

Follow-up presets: seed named single-player/multiplayer remaps plus the normal automatic game remap. Route multiplayer frontend slots 1–5 to core ports 1/4/3/5/2, reserving the Multitap last. Add a LOTR-only config override disabling remap autosave and make its lookup directory explicit for SNES. Back up existing runtime files before installing presets; retain other game preferences and saves. Verify actual remap loading, core devices and preset hashes across clean exits with isolated saves/states, then return to ES-DE. Named presets are manually selected; normal LOTR startup uses its default multiplayer remap.

Import the compared SNES archive additions as one ZIP per new title, selecting an unflagged/latest revision where alternatives exist. Preserve flagged releases as labeled in filenames. Back up LOTR and related save data, replace its ROM at the same path to retain save identity, and record that the archive's headerless game data is identical. Verify incoming ZIP CRCs and transfer hashes, preserve existing files and frontend metadata, refresh ES-DE and smoke-test a representative new game without changing progress.

Replace the current theme artwork and styling with original Rivendell/Andúril imagery, warm parchment, forest green and gold. Keep the working system/game list structure and metadata bindings. Package artwork/fonts declaratively and retain restrained navigation cues. Replace the runtime hymn with Concerning Hobbits from the official artist release, retain a backup and source attribution, and reuse existing volume and game-launch/return hooks. Build and review host changes, deploy, inspect both system and game views on the actual console and verify parser logs, input navigation and music state.

Run Tick Tock Trivia in a dedicated X11 Chromium kiosk profile at its existing HTTPS origin. Add a narrowly scoped content-script extension for spatial keyboard focus, select controls, an on-screen text keyboard and Start/next actions. A scoped AntiMicroX profile translates audited Atari inputs to navigation keys and retains Guide + Start close; avoid app/server changes. Persist browser identity outside the store. Verify against an isolated local app/fixture before read-only live-page navigation and a production PC Games launch/quit check. Never log player phrases or submit test scores to the hosted service.

Consolidate standalone games into a generated flat `pcgames` catalog with allowlisted dispatcher entries pointing to existing launcher targets. Keep all original game data/save locations. Use ES-DE's `loadExclusive` directive so bundled definitions cannot restore duplicate categories; retain emulator definitions. Package a one-time metadata/media migration preserving source records, rewrite only catalog paths/titles and copy filename-matched media to the new system. Back up live metadata before stopping ES-DE for migration, deploy, and verify category counts, catalog entries/artwork and representative dispatch/quit behavior.

Add SuperTux, Sonic Robo Blast 2 and Neverball using the pinned native packages and declarative ES-DE launcher entries. Inspect each pinned game's input configuration and seed writable controller defaults once, preserving later changes. Reuse the scoped quit mapper, retaining native controller input where practical. Build/deploy the full host, then verify menu navigation, representative play, controller exit, mapper cleanup and frontend/music restoration with brief accelerated tests.

For SuperTuxKart, inspect the pinned game's SDL controller index translation and existing input XML before changing controls. Prefer its native gamepad configuration for analog steering; add the proven scoped quit mapper around its launcher. Back up and update existing writable input settings without replacing player progress. Verify input generation, actual menu/race behavior, clean controller-chord exit and ES-DE/music return using brief GPU-accelerated tests.

Run Spec Kit prerequisites and consistency review; format through `nix fmt`; evaluate both Colmena and NixOS node plus assertions, target settings, mounts, session commands and core paths; build `nixosConfigurations.pechersk.config.system.build.toplevel`; exercise importer against a synthetic library (spaces, nested paths, existing save preservation and media conversion), run shell syntax/static checks, and inspect full host configuration changes. Hardware behavior is an explicit post-boot acceptance gate. No automatic deployment, commit or push.

## First upgrade stage requested by user

Add transient Colmena node `pechersk-upgrade` importing the verified hardware layout and `nixos/pechersk/upgrade.nix`. Build locally against the locked 26.05 inputs. Retain hostname atari/hostId, wpa_supplicant on wlp1s0 with DHCP on both known interfaces, root password login as explicitly enabled by the user, mutable users with existing UIDs sam=1001 and atari=1000. The generated WLAN service loads a root-only runtime copy of the exact active old wpa_supplicant configuration; no credentials are interpolated into Nix. This is a text-console maintenance generation without desktop/emulators or library transfer. Back up /etc/nixos, account/SSH state and /boot privately before deployment. Copy closure using the established SSH master to accommodate old Nix, stage a boot generation, inspect boot entries, reboot and verify 26.05, network, mounts and services. Preserve rollback generations. If old tooling or activation fails, report and ask before selecting a different upgrade method.

## Authorized console rollout and complete USB migration

The maintenance upgrade is complete. The user now authorizes full migration, deployment and extensive automated verification before manual testing, explicitly including installed ports such as Doom and Tux Racer. Copy every file from both USB partitions to a private SATA archive, preserving source metadata and keeping the source mounted ro/noload. Check the copy with a checksum dry run. Import playable data into the console's writable library while retaining all original scripts/configs privately. Inventory installed ports and replace launchers with supported native packages or explicitly packaged compatible engines. Prepare runtime NetworkManager and BlueZ state; establish and verify a temporary deployment SSH key before switching off password authentication. Preserve existing numeric accounts. Deploy the full node via Colmena, boot without USB dependency, then test real GPU rendering, frontend autostart, audio enumeration, controller discovery, representative content loading for every populated system, ports, saves and service health. Record precise results and remaining physical-input/audio checks.

The user prioritizes all populated Nintendo platforms: NES, SNES, GBA, N64, GameCube and Wii. The user also explicitly requires controller-operated Bluetooth management. Provide a fullscreen, large-font dialog menu launched from Console tools, using a scoped AntiMicroX SDL controller profile for D-pad/stick navigation, A/Start select and B/Back return. The menu uses the existing active user's BlueZ access to scan and explicitly pair/trust/connect, disconnect or forget selected devices. Require confirmation for disconnect/forget, show command failures, and stop the input mapper when the screen exits. Keep keyboard/mouse Blueman available separately; do not leave the menu profile active during games. PIN-less gamepads are the primary pairing target.
