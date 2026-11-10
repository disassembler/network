# Pechersk console

The existing SATA installation now runs NixOS 26.05 with hostname `pechersk`, EFI GRUB and an X11/Openbox/ES-DE console. The full Colmena node is deployed and USB migration is complete. Acceptance checks remain; consult [verification.md](verification.md) for evidence and outstanding checks.

Work in `/home/sam/home/network` on the existing `master` checkout. No additional worktree or branch is needed.

## Build and deploy

```sh
nix build .#nixosConfigurations.pechersk.config.system.build.toplevel
nix develop -c just apply pechersk
```

Inspect the full host change first. Deploy only while the address runs SATA NixOS. The USB can still boot Batocera; never deploy to that session. The normal Nix daemon uses `cache.nixos.org`.

The host retains the existing Btrfs mounts, SATA ESP/swap, stateVersion 21.03 and atari/sam numeric IDs. Gamer's home is `/var/lib/pechersk`, UID1002; `/userdata` is writable SATA storage. The eMMC remains untouched. Boot0000 selects the SATA GRUB fallback loader; original systemd-boot recovery files and old generations are retained. See [upgrade.md](upgrade.md).

Administrator SSH uses authorized keys. The private temporary deployment key/config is in the workstation audit directory, outside Git. Runtime NetworkManager and BlueZ credentials are private host state, backed up under `/var/lib/pechersk-migration/private`. Never put them in Nix expressions, the store or the guest share.

## Migration status

The USB SHARE and boot partitions were archived read only and have now been cleanly unmounted for removal. The full private file archive under `/var/lib/pechersk-migration` is complete, and both checksum comparisons found no differences. Public library data and saves have been imported into `/userdata`; private Batocera system settings stay in the root-only archive.

All four completion markers described in [verification.md](verification.md) are present. Existing live saves were preserved. Original savestates are retained, but compatibility across emulator versions is not guaranteed.

The importer can be run explicitly against a completed archive:

```sh
pechersk-import-batocera /var/lib/pechersk-migration/userdata /userdata /var/lib/pechersk/ES-DE
```

Run it with permission to read the private archive; restore gamer ownership on the live destination afterwards. It never executes source game scripts. It preserves existing files, imports BIOS/ROMs/saves/public media, seeds Nintendo sidecar SRAM and converts supported artwork metadata. Refresh ES-DE after the final import.

## Controllers and console tools

Standalone titles now appear in one flat **PC Games** category: native games, Windows/Python ports, StepMania, Doom, Minecraft and Steam. The previous standalone-game categories are retired, and Minecraft is removed from Console tools. Emulator definitions are unchanged. The catalog has 16 entries; original game/save locations and launcher behavior are preserved, including the prior status of unsupported/broken entries.

SNES now includes the 653 imported archive additions. LOTR uses a game-specific five-player Multitap configuration; other SNES games retain standard controller devices. The archive LOTR copy has identical game data to the previous ROM, so Sam's behavior needs gameplay diagnosis. Its remap is writable under `~/.config/retroarch/remaps/Snes9x/Lord of the Ring.rmp`; controller device settings can be changed in RetroArch Quick Menu > Controls and saved as a game remap. Additional physical controllers are needed to test all five players.

LOTR has two named presets under `~/.config/retroarch/remaps/Snes9x`: **LOTR - Single Player.rmp** enables only player 1; **LOTR - Multiplayer.rmp** routes frontend controllers 1/2/3/4/5 to core ports 1/4/3/5/2. That keeps controller 2 on Pippin, controller 3 on Sam, controller 4 on Merry/Gimli, and controller 5 on Frodo after Aragorn joins. Controller 1 controls Frodo initially, then Aragorn. The Multitap reservation is now last, in **Port 5 Controls**. Keep that slot mapped to core port 2 even when its physical controller is absent: RetroArch otherwise disconnects the Multitap. Pippin on port 4 was verified before Aragorn; the remaining characters need gameplay acceptance as they join.

Switch during play through **Quick Menu → Controls → Manage Remap Files → Load Remap File**, then select either named preset and resume. No restart or manual device changes are needed. A LOTR-only override disables `remap_save_on_exit`, so temporary changes do not overwrite presets automatically. Normal startup uses the default multiplayer `Lord of the Ring.rmp`; loading the single-player preset applies for that session. Explicit **Save Game Remap File** can deliberately change the startup default. Old settings are backed up under `~/verification/lotr-remap-profiles-20261106/before`.

`nixos/pechersk/pc-games-list.nix` defines titles and original targets. Add a catalog record and supported launcher when adding a PC game. The one-time `pechersk-migrate-pc-games` command migrates metadata/artwork and preserves later catalog edits. Live metadata is `/userdata/roms/pcgames/gamelist.xml`; media is under `~/ES-DE/downloaded_media/pcgames`. Before-migration metadata is backed up in `~/verification/pc-games/before`.

The active theme is **Pechersk · Lavra**, inspired by Kyiv-Pechersk Lavra, with original editable SVG/XML assets. It covers system and game lists, artwork/description display, missing-art fallback and radio indicators. Select another theme under **UI Settings → Theme** to return to stock. Previous writable settings are backed up privately in the verification directory.

The selected hymn loops quietly while browsing. **Console tools → Music** toggles it persistently. Music stops when a game starts and resumes when it ends, unless disabled. Replace `/userdata/music/menu/pechersk.m4a` to change the track; its provenance is recorded alongside it. The audio is outside Git and the Nix store. The user confirmed comfortable volume through the TV. Navigation uses short wooden taps and a restrained bell for selection.

The EMS dance pads are available only through the fixed StepMania launcher. They stay plugged in without occupying controller slots in ES-DE or other emulators. A dedicated device group and seat prevent desktop ACLs from reopening access; StepMania gets the group through its fixed setgid executable, started outside ES-DE's container by a waiting user service.

StepMania now has a scoped Atari/Guide + Start close shortcut too. Its mapper exits before ES-DE regains focus, and held modifier keys are released. A full launch from ES-DE verified music stopping, clean controller-chord exit, mapper cleanup, frontend focus and music resuming.

The Atari VCS Modern controller mapping follows physical position. Bottom physical Atari A is Nintendo B; right Atari B is Nintendo A. ES-DE navigation is confirmed by the user. **Atari/Guide + Start** has clean-exit verification in RetroArch, Mupen64Plus and Dolphin. Native ports, PPSSPP and Supermodel still need the equivalent exit behavior checked.

RetroArch Guide combinations: bottom opens its menu, left saves state, top loads state, right resets and left shoulder takes a screenshot. Keyboard fallback is Shift+Escape to quit. Two-controller assignments, reconnect order, triggers and rumble need physical acceptance checks. Defaults are writable and seeded once, so later declarative defaults do not silently replace user settings.

Console tools include a controller-operated Bluetooth dialog (navigation/pairing acceptance pending), advanced Blueman, Wi-Fi/audio tools, Kodi and Prism Launcher. The advanced desktop tools may need a keyboard/mouse. Existing WLAN and controller bonds were restored for routine use.

Retro Trivia supports keyboard arrows and A/B/Enter/Space with controllers connected. Escape or Atari/Guide + Start exits. Its launcher applies a compatibility patch to a cached copy, preserving installed source/assets. The scoped quit mapper ends with the game. Keyboard answers with two Atari controllers connected, the controller exit chord, and Escape during a video question were verified; clean shutdown also stops delayed audio callbacks and decoder children.

Extreme Tux Racer uses the stick or D-pad for menus/steering, bottom Atari A to confirm/jump, right Atari B to go back, left face button to paddle, top face button for tricks, and left shoulder to brake. Start pauses; another ordinary button resumes. Atari + Start quits to ES-DE. Automated checks verified menu navigation, downhill play, pause-key generation and a clean game exit with mapper cleanup; physical pause and handling feel remain acceptance checks.

ES-DE's automatic and manual screensavers are disabled. X11 screen blanking and DPMS are disabled as well, so the selection screen stays visible.

SuperTuxKart uses the left stick for menu navigation and analog steering. Bottom Atari A selects/accelerates, right B goes back/brakes, left face button fires items, top face button looks back, left shoulder uses nitro and right shoulder drifts. Back rescues the kart, Start pauses, and B resumes from pause. Atari + Start quits to ES-DE. Menu selection, acceleration, steering, pause/resume and clean controller-chord exit passed fixture checks on the real accelerated display. Test actual controller feel and split-screen next. Input defaults are applied once with an `input.xml.before-pechersk-atari-v1` backup; later in-game remapping persists.

**PC Games** includes SuperTux 0.7.0, Sonic Robo Blast 2 2.2.15 and Neverball 1.6.0. All use **Atari + Start** to quit, with scoped mapper cleanup. SuperTux uses D-pad/stick movement, bottom A jump/select, left face button action/run, B back and Start menu/skip. Sonic uses left-stick movement, right-stick camera, bottom A jump/select, left face button spin, B back and Start menu. Neverball uses the left stick to tilt/navigate, bottom A select, B back and Start pause; its menu needs more than half-stick deflection. Its family player name is Pechersk. Saves/settings remain in gamer’s writable home; input defaults are seeded once. Physical handling and multiplayer remain manual checks.

## Remaining acceptance

- Archive, checksums and live import are complete; verify boot and operation independently of USB.
- Verify physical SNES input, two-player Nintendo gameplay, controller reconnects and sound.
- Test the remaining emulator and native/Windows port entries, including Doom and Tux Racer.
- StepMania is available with its restored 269-song collection; test dance pads and audible output. Its native launcher seeds the old Flatpak profile once without replacing existing edits.

StepMania now includes 284 child-oriented charts across 142 songs that lacked an accessible single-pad option. Try **Legend of Zelda → Pechersk First Steps (1)**, then **Pechersk Easy Rhythm (3)**. First Steps uses at least 0.85 seconds between taps; Easy Rhythm at least 0.55 seconds. Both avoid jumps, holds and mines. Existing difficulty slots are preserved, so some additions appear under **Edit** with these names. The three DWI songs show the meter-1 Beginner and meter-3 Easy/Edit options without the descriptive names. Springtime and Mecha-Tribe Assault use separate edits and need a fresh game launch after installation. These are generated starting points; children should playtest timing feel, variety and difficulty.

All changed song files were backed up under `/var/lib/pechersk/verification/easy-charts-v1/backup/original-charts.tar`. With StepMania stopped, rollback restores that archive to `~gamer/.stepmania-5.1/Songs`, removes the four paths in `chart-sidecar-files.nul` and invalidates the song cache. The adjacent reports/manifests/checksums record exactly what was installed; audio and originals in the migration archive are unchanged.
- Verify battery saves, Dolphin memory cards/Wii NAND and PPSSPP save paths with backed-up copies.
- Exercise Bluetooth menu navigation and pairing/forget confirmation with an intended controller.
- Verify cold-boot autologin, HDMI, WLAN/SSH, power controls, thermal behavior and failed services.

ES-DE themes differ from Batocera. Original themes/music remain archived; the old Batocera theme and background-music service are not reproduced. Classic-controller spinner conversion was not enabled because no Classic device was available. The user confirmed Minecraft was already broken and excluded it from remaining migration acceptance. See [research.md](research.md) for the parity decisions and package limitations.
