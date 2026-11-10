# Tasks: Pechersk Atari VCS console

## Discovery and design

- [x] T001 Inspect repository conventions, branch/spec numbers, constitution and project memory; work in the existing master checkout at /home/sam/home/network.
- [x] T002 Inspect Batocera hardware, services, frontend, controller mappings, populated systems, custom scripts and storage without mutations.
- [x] T003 Resolve frontend package removal and storage decisions with user; write spec, plan and parity research.

## Host and hardware — US2, US3

- [x] T004 Register `pechersk` in `flake/colmena.nix` and define existing SATA filesystem layout in `nixos/pechersk/hardware-configuration.nix`.
- [x] T005 Configure runtime WLAN, firmware, Bluetooth, controller permissions, audio, graphics, power controls and administrator access in `nixos/pechersk/{configuration,hardware-configuration}.nix`.

## Console experience — US1

- [x] T006 Package pinned upstream ES-DE in `nixos/pechersk/es-de.nix` and define fullscreen autologin session in `console.nix`.
- [x] T007 Define native emulator launch commands for populated systems, two-player Atari mappings, save locations and hotkeys in `console.nix` and `controllers/`.
- [x] T008 Package the explicit Batocera data/media importer and preserve writable user settings and existing saves.
- [x] T009 Add accessible console tools, Kodi and LAN data sharing; document third-party ports and theme limitations.

## Verification and handoff — all stories

- [x] T010 Run Spec Kit prerequisites and consistency review before implementation; keep task coverage and checklist current.
- [x] T011 Format, evaluate host/deployment configuration, inspect generated files and build the complete host closure.
- [x] T012 Test importer against representative synthetic data and run shell checks; document commands and results.
- [x] T013 Finish `quickstart.md` with credential/bond migration, safe first upgrade, backup, deployment and hardware acceptance steps.
- [ ] T014 Hardware acceptance: finish authorized SATA NixOS checks for reboot/autologin, audible HDMI, two controllers, each populated platform and saves. See verification.md for completed hardware checks; do not perform mutations on read-only Batocera.

Dependencies: T004–T009 follow T001–T003 and T010; T011–T013 follow implementation. T014 follows user-authorized installation/switch and data transfer.

Validation: the initial Xvfb server lacked GLX; subsequent real AMD/X11 hardware tests verified frontend and representative emulator rendering. Build, XML parsing, generated executables/plugins and importer tests pass. Full console is deployed; T014 remains open for the outstanding acceptance checks in verification.md.

## Minimal OS upgrade requested before gaming setup

- [x] T015 Add `pechersk-upgrade` maintenance Colmena node and runtime WLAN configuration; build and inspect the complete host changes.
- [x] T016 Back up SATA NixOS configuration, account/SSH state and boot files; preserve active Wi-Fi configuration privately.
- [x] T017 Copy the maintenance closure and stage the 26.05 boot generation, preserving rollback entries.
- [x] T018 Reboot and verify running version, kernel, Nix, Wi-Fi, SSH, mounts and failed services.
- [x] T019 Record the upgrade result and next console-deployment steps without deploying the full gaming configuration.
- [x] T020 Replace systemd-boot with user-approved EFI GRUB in the shared hardware module; build, inspect, deploy and verify the selected EFI boot route while retaining recovery files.
- [x] T021 Archive all files from both USB partitions privately on SATA and verify checksums without modifying the source.
- [ ] T022 Inventory and support the installed native ports, including Doom, Tux Racer and other populated entries; cover launcher and save paths.
- [x] T023 Prepare runtime WLAN/Bluetooth state and verified deployment-key access, preserve account IDs, build and deploy the full console node.
- [ ] T024 Import the complete playable library and metadata to SATA, then verify actual frontend/GPU/audio/controller/service startup and representative emulator/port content loading.
- [ ] T025 Record automated verification evidence, fixes and a focused manual hardware test list; leave the console ready for testing.
- [ ] T026 Add controller-operated Bluetooth management to Console tools, verify menu rendering/navigation and cleanup, and test pairing operations where hardware permits.
- [ ] T027 Detect both attached dance pads, restore StepMania mappings by adapter identity across Atari controller reconnects, and verify physical arrow/Start input.
- [x] T028 Add an application-scoped Atari+Start quit binding to StepMania, verify clean exit and remove the input mapper before returning to ES-DE.
- [x] T029 Specify and implement a monastery-inspired ES-DE theme with original XML/SVG assets, readable system/game views and declarative font/theme packaging.
- [x] T030 Build and preview the custom theme in ES-DE 3.5, inspect parser logs/screenshots and navigation, then activate it with an easy stock-theme rollback.
- [x] T031 Add managed ES-DE menu music, game/start/exit hooks and a persistent controller-operated toggle; place the user's selected hymn on SATA outside Git/store.
- [x] T032 Verify music playback, stop/resume hooks, toggle persistence and HDMI output, and document the theme/music controls.
- [x] T033 Generate restrained original wooden/bell navigation cues, cover all ES-DE sound events, deploy the theme and verify sample levels/duration, loading and fast navigation.
- [x] T034 Restrict dance-pad devices to the fixed StepMania launcher, clear old ACLs, verify frontend/emulator exclusion and two-pad StepMania access, and repeat the GBA exit test with pads plugged in.
- [x] T035 Audit StepMania chart difficulty, density and timing; identify songs lacking accessible single-pad charts.
- [x] T036 Generate conservative Beginner/Easy additions in a private working copy; preserve originals and verify timing, note constraints and coverage.
- [x] T037 Back up and install validated additions on SATA, verify StepMania loads them and document child playtesting/rollback.
- [x] T038 Close stuck Retro Trivia, patch keyboard/controller compatibility and scoped exit, deploy and verify real game navigation and both exit methods.
- [x] T039 Fix Extreme Tux Racer controller menus/racing/quit, deploy and verify actual game behavior and mapper cleanup.
- [x] T040 Disable ES-DE idle screensaver in defaults and live settings; verify loaded configuration and X11 no-blanking state.
- [x] T041 Configure SuperTuxKart Atari menu/driving controls and scoped quit, preserve progress, deploy and verify input, racing and ES-DE return.
- [x] T042 Add SuperTux with Atari controls and scoped quit; verify menu, gameplay and frontend return.
- [x] T043 Add Sonic Robo Blast 2 with Atari controls and scoped quit; verify menu, gameplay and frontend return.
- [x] T044 Add Neverball with Atari controls and scoped quit; verify menu, gameplay and frontend return.
- [x] T045 Consolidate standalone games into flat PC Games, preserve metadata/media and emulator categories, deploy and verify catalog and dispatch.
- [ ] T046 Add Tick Tock Trivia kiosk, controller navigation/text entry and scoped exit; verify isolated gameplay, live read-only navigation and PC Games return.
- [x] T047 Replace monastery styling with original uplifting Rivendell/Andúril artwork and matching LOTR music; deploy and verify both ES-DE views, navigation and music hooks.
- [x] T048 Import all 653 additional SNES archive titles, preserve existing games/saves, replace LOTR from the archive after backup and verify hashes, frontend discovery and representative launch.
- [x] T049 Configure LOTR-specific five-player SNES Multitap, inspect pinned core behavior and verify device loading and save/frontend preservation.
- [x] T050 Add separate LOTR single-player/multiplayer remaps with the Multitap reservation last; protect against exit autosave, deploy, verify both presets/core devices and document switching.
