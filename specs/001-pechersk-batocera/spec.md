# Feature Specification: Pechersk Atari VCS console

**Feature Branch**: `master` (existing branch; specification ID retained)
**Created**: 2026-11-02
**Status**: Implementation
**Input**: Add pechersk to Colmena as a NixOS replacement closely matching the Atari VCS Batocera system at 10.40.33.22. Treat the source as read only.

## User Scenarios & Testing

### User Story 1 — Boot into a game console (P1)

The family powers on the VCS and browses and launches the existing library with a controller, returning to the frontend when a game exits.

**Independent Test**: Boot NixOS on the VCS; launch one game per populated supported platform; exit using the controller.

**Acceptance Scenarios**:
1. Given the library has been copied to separate NixOS storage, when the machine boots, then its frontend appears without a keyboard or login prompt.
2. Given a supported controller, when a user launches and exits a game, then graphics, sound, saves and hotkeys work and the frontend regains focus.
3. Given existing artwork and metadata, when the library is opened, then those assets and favorites remain available where the chosen frontend supports them.

### User Story 2 — Use the VCS hardware (P1)

The family uses Bluetooth and USB gamepads, Wi-Fi, HDMI video and audio, and power controls.

**Independent Test**: Reconnect both known Atari controllers after reboot; play simultaneously; test wired input, Wi-Fi and HDMI sound.

**Acceptance Scenarios**:
1. Given imported Bluetooth bonds for the same physical adapter, when paired controllers wake, then they reconnect without pairing again.
2. Given a Wi-Fi profile installed outside the Nix store, when the system boots, then it joins the existing WLAN and obtains its network configuration.
3. Given the detected HDMI television, when a game launches, then it displays at 1920×1080/60 Hz with sound through HDMI.
4. Given a new input device, when it is paired or plugged in, then it is available to the frontend and supported emulators.

### User Story 3 — Manage pechersk declaratively (P2)

The administrator builds and later deploys pechersk using this repository, transfers game data and manages wireless devices without depending on Batocera startup scripts.

**Independent Test**: Evaluate the Colmena node, build its system closure, and follow the documented migration and hardware acceptance steps.

**Acceptance Scenarios**:
1. Given this flake, when pechersk is evaluated, then both `colmena` and `nixosConfigurations` expose the host.
2. Given existing Batocera data, when preparing the replacement, then the original USB installation and eMMC remain unmodified.
3. Given sensitive network profiles and Bluetooth keys, when configuration is built, then those secrets remain outside Git and the Nix store.

### Edge Cases

- NixOS installation disk and filesystem layout must be confirmed; do not repurpose a Batocera partition as a NixOS root.
- A disconnected controller, changed connection order, or USB versus Bluetooth identity may change input indexes.
- Savestates may be incompatible across emulator versions; preserve originals and test native battery saves first.
- Batocera-specific theme/menu extensions may require a custom frontend port.
- Classic Atari spinner conversion is a Batocera userspace feature; generic joystick support alone does not reproduce it.
- The source contains third-party Minecraft startup scripts that mutate system libraries; inspect them but never execute or transplant them verbatim.

## Requirements

- **FR-001**: Add a `pechersk` Colmena node targeting 10.40.33.22 after NixOS installation, with key-based administration.
- **FR-002**: Provide automatic controller-oriented frontend startup and reliable return from emulators.
- **FR-003**: Cover the populated Atari 2600/800, C64, arcade, Mega Drive, NES, SNES, GBA, PC Engine, N64, PlayStation, GameCube and Wii library; document any unsupported ports and data-only entries explicitly.
- **FR-004**: Keep ROMs, BIOS, saves, screenshots, themes and user settings in persistent writable storage outside the Nix store.
- **FR-005**: Reproduce the measured Atari modern-controller mapping and emulator exit/save/load hotkeys, with support for two players.
- **FR-006**: Enable the detected AMD graphics/audio, RTL8822CE WLAN, r8169 Ethernet, Realtek Bluetooth, firmware, and relevant input devices.
- **FR-007**: Preserve the measured Wi-Fi and Bluetooth power-saving workarounds and performance CPU governor.
- **FR-008**: Provide wireless management and a data share for the home network; restrict exposed shares to the intended LAN.
- **FR-009**: Supply a private-data migration procedure, a Batocera-to-NixOS parity matrix, and explicit post-boot validation steps.
- **FR-010**: Do not change, deploy to, reboot, mount new filesystems on, or run custom startup/management scripts on the Batocera source.
- **FR-011**: Verify formatting, affected configuration evaluation and host build; record failures honestly and ask before changing implementation approach.

## Success Criteria

### Monastery-inspired frontend appearance — user refinement

- **FR-013**: Provide a custom ES-DE theme inspired by an Orthodox Pechersk monastery, using original architectural ornament, warm ivory, burgundy and muted gold, with readable controller-first system and game selection at 1080p.
- **FR-014**: Package theme assets declaratively, preserve game artwork and metadata, retain an easy return to the stock theme, and verify the actual ES-DE 3.5 theme parser and TV rendering before activation.
- **FR-015**: Loop the user-selected Orthodox hymn quietly while browsing ES-DE, stop it for games and resume it on return. Store downloaded audio outside Git/the Nix store and expose a controller-operated on/off control.
- **FR-016**: Replace stock navigation clicks with restrained, short wooden taps and soft bell-like selection cues that suit the Lavra theme, remain comfortable during fast scrolling and do not overpower background music.
- **FR-017**: Restrict both EMS dance-pad interfaces to StepMania. ES-DE and other emulators must not open them or assign them player slots, including after reconnect. Preserve ordinary Atari controller access and StepMania's two-pad input/quit shortcut.

- **SC-001**: `pechersk` evaluates through both deployment interfaces and its system closure builds successfully.
- **SC-002**: On hardware, each supported populated platform launches, produces sound, accepts input and returns to the frontend.
- **SC-003**: Both paired Atari controllers reconnect after two cold boots and work together in a multiplayer game.
- **SC-004**: WLAN reconnects after reboot; HDMI outputs 1080p/60 with audio; power-button shutdown is clean.
- **SC-005**: Source remains unchanged by administrative actions; no credentials or game content enter tracked files.

## Assumptions and Open Decisions

- **FR-027**: Enable game-specific SNES Multitap emulation for LOTR, supporting up to five controller slots without changing other games' controls. Verify the pinned core's device configuration, preserve saves and expose the difference between emulated slots and physical controllers. Investigate idle companion behavior without claiming that Multitap fixes it.
- **FR-026**: Import all 653 additional titles from the user-supplied SNES archive, including flagged releases, with one suitable revision per title. Preserve the existing library, metadata and saves. Back up and replace the existing LOTR ROM from the archive at its current path; disclose that the game data is identical and investigate the reported idle-party-member behavior without altering user progress.
- **FR-025**: Replace the Orthodox monastery console theme with an uplifting Lord of the Rings theme inspired by Rivendell and the reforging of Andúril. Use original artwork, readable controller-first system/game views and a warm hopeful palette; remove religious imagery and replace the hymn with cheerful Lord of the Rings menu music. Preserve the comfortable volume, launch/return audio hooks, library metadata, controls and game behavior.
- **FR-020**: Extreme Tux Racer must support controller menu navigation, steering/racing actions and Atari/Guide + Start exit, with mapper cleanup on return. Disable the ES-DE idle screensaver and retain the current screen indefinitely; X11 blanking/DPMS must remain disabled.
- **FR-021**: SuperTuxKart must support positional Atari controller menu navigation and driving controls, retaining analog steering where supported, plus scoped Atari/Guide + Start exit and mapper cleanup. Preserve player progress and settings unrelated to input.
- **FR-022**: Add native SuperTux, Sonic Robo Blast 2 and Neverball to ES-DE with persistent saves/settings, positional Atari controller defaults and Atari/Guide + Start exit. Verify each game's actual menu/gameplay and clean return without exposing dance pads outside StepMania.
- **FR-023**: Present all standalone PC games in one flat PC Games category, including native ports, Windows/Python games, StepMania and Doom. Preserve emulator categories, game data, saves, artwork, favorites and play history. Remove duplicated game entries from Console tools and retire the old standalone-game categories.
- **FR-024**: Integrate the hosted Tick Tock Trivia site in PC Games with controller-only quiz/player selection, text entry, answering, next-question navigation and Atari + Start exit. Persist remembered players in a dedicated browser profile, retain the hosted service's shared quizzes/scores, and verify without publishing test scores to the live service.

- **FR-019**: Retro Trivia must accept keyboard navigation/action with controllers connected, use stable player slots, ignore dance pads and support Escape plus scoped Atari/Guide + Start exit. Preserve the archived upstream game and keep the compatibility patch declarative.

- **FR-018**: Add rhythm-aligned single-pad Beginner/Easy charts for songs lacking a genuinely accessible option for children aged 7–11. Preserve original charts, audio and timing; avoid jumps, holds, mines, crossovers and rapid stepping in generated charts. Back up changed files, report coverage and validate in StepMania before handing over for playtesting. Existing genuinely easy charts need no duplicate.

- This request authorizes local implementation and builds, not installation or deployment onto the read-only source.
- Retain America/New_York timezone and initial 40% audio volume.
- Reuse the existing SATA installation and use ES-DE, as confirmed by the user. Hardware acceptance remains pending until an explicitly authorized NixOS boot.

- **FR-028**: Provide separate named LOTR single-player and multiplayer remaps. Single-player exposes only player 1; multiplayer retains controller 2 for Pippin and places the Multitap reservation in frontend slot 5, allowing controllers 3/4 to control Sam/Merry. Preserve saves, disable LOTR remap autosaving to protect presets, and verify preset selection and core devices without interrupting an active game.

## Authorized first upgrade — 2026-11-03

The user booted the SATA installation, enabled root password SSH, and requested getting it onto 26.05 first. This authorizes a separate minimal maintenance generation and reboot on SATA NixOS. Batocera USB/eMMC remain outside the write scope. Preserve root password access temporarily, existing sam/atari UIDs, working wpa_supplicant network, all filesystems and stateVersion 21.03. Full console deployment and library migration follow separately. A maintenance text console is sufficient for this stage; do not deploy ES-DE/emulators yet.

- **FR-012**: A separate maintenance node MUST boot 26.05 with SSH/WLAN and existing data intact, leaving the old generation available and keeping Wi-Fi secrets outside new store outputs.
