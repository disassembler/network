# Pechersk hardware verification

Status: console deployed; full USB archive, checksum verification and public library/save import completed. Final game/hardware acceptance remains in progress.

## SNES archive import and LOTR Multitap

2026-11-06 named presets (supersedes the earlier slot-3 reservation): packaged/deployed `LOTR - Single Player.rmp` and `LOTR - Multiplayer.rmp`, with default game remap initialized from multiplayer after backing up the user's partial settings. Single-player core devices are 1/0/0/0/0/0/0/0. Multiplayer core devices are 1/257/1/1/1/0/0/0 and frontend routing is 1/4/3/5/2, placing the Multitap reservation in frontend slot 5. Added a LOTR-only override disabling remap autosave; SNES config names its override directory explicitly. Other core append configs compare identical. Formatting/full build passed, reviewed host closure changes contained only the new remap assets/policy, Colmena activation succeeded; deployed closure `/nix/store/5gya49g5nv8450in3xg9kg4z1fks8d88-nixos-system-pechersk-26.05pre-git`.

Actual RetroArch menu loaded each named preset; screenshots show the selected active filename, and read-only inspection of core device state confirmed both arrays above. Then changed multiplayer controller 2's mapped port temporarily, exited normally, and verified all three remap files retained their original SHA-256 hashes. A second clean launch loaded the default multiplayer remap and LOTR policy automatically; clean exit and rendered screenshot passed. Tests used isolated save/state directories; all existing LOTR saves/state screenshots passed unchanged-file checks. No user game was running, no virtual controllers were needed, and ES-DE/menu music were restored with no failed system units. Evidence: `/var/lib/pechersk/verification/lotr-remap-profiles-20261106`; build/deploy logs under `/tmp/pechersk-batocera-audit/remap-profiles`. Five-character gameplay is not claimed; Sam/Merry/Aragorn assignments follow the manual pending recruitment.

Latest live routing check: the initial port 4 and port 3 tests failed because RetroArch disables any core port with no frontend slot mapped to it. Moving controller 2 away from core port 2 therefore disconnected the actual Multitap while its configured menu type remained 257. Verified this with read-only inspection of the running Snes9x `snes_devices` array (1/0 before, 1/257 after), resolving exact symbol offsets from the installed core; no process memory was modified. RetroArch's `setting_action_*_input_remap_port` calls `CMD_EVENT_CONTROLLER_INIT` specifically to disconnect unused ports.

Fixed the writable game remap live: frontend slots 1/2/3/4/5 now map to core ports 1/4/2/3/5. This keeps the Multitap connected and assigns the second Atari to Pippin. Injected input through both real Atari devices first proved both can control Frodo when routed to player 1. After the second pad disconnected, connected four temporary Rust uinput Atari fixtures, verified RetroArch recognized five inputs, and demonstrated Pippin movement through the virtual second controller on player port 4. Verified analog movement independently for Frodo and Pippin, with unchanged Frodo health 13/14. Status menu confirmed Frodo and Pippin are the only recruited characters. Thus pre-Aragorn Pippin is port 4, not the hypothesized port 3. Saved the existing game remap, removed all virtual controllers, and confirmed the core still has devices 1/257. Same user game PID 35315 throughout; no restart, reset, save-state load or save overwrite. Screenshots/logs are under `/var/lib/pechersk/verification/lotr-controller`. Characters not yet recruited cannot be verified in this session; five-character gameplay remains pending. Physical second-controller handoff requires waking that pad.

Imported 653 additional titles from the user-supplied encrypted SNES archive, selecting one ZIP per title and preferring unflagged/latest revisions. Prototype/sample/unlicensed/bad-dump labels are retained in frontend names. ZIP members passed decompression/CRC checks; all 653 transferred and installed ZIPs passed SHA-256 checks. Preserved existing catalog records, added 653 clean-title records, and verified existing files other than the authorized LOTR replacement remained unchanged. Existing save-file checksums passed again after testing. ES-DE shows 802 SNES entries; total library count increased by exactly 653 to 3484. Actual ES-DE launch of new 2020 Super Baseball rendered its attract mode, then returned to ES-DE/music. This is representative launch verification, not a claim that every prototype works.

LOTR was backed up and replaced at the same Lord of the Ring.SMC path, preserving save identity. Old/new headerless SHA-1 is identical: 030e314cba8faae4081f8056521126916e5e0ada. The old ROM merely had a 512-byte copier header. Snes9x reports valid cartridge checksum and CRC32 cd2150c8. No claim that ROM replacement fixes Sam. Import backups, save snapshots, checks and screenshots are under /var/lib/pechersk/verification/snes-import-20261104; selected files are recorded in scratch/snes-romset-comparison-2026-11-04/import-selected.json. SEXPIC remains absent.

At the user's request, configured a game-specific writable remap for LOTR: SNES port 1 joypad (device 1), port 2 Multitap (device 257). Pinned Snes9x libretro/libretro.cpp confirms CTL_MP5 and polling of five logical inputs, indices 0 through 4. Pinned RetroArch configuration.c confirms per-game remap selection by core name and content basename. The SNES append config explicitly sets the remap directory; other systems' append configs compare identical. The remap destination contains spaces, so corrected tmpfiles destination quoting after initial deployment failed to create it. Final full build and Colmena activation passed (console-deployment-lotr-multitap-final.log), current closure /nix/store/qqmy17v459a4rh6bn3k0xyx189phpf56-nixos-system-pechersk-26.05pre-git.

An actual LOTR launch using the production config/remap and isolated test saves/states logged the correct game-specific remap, valid ROM checksum and hardware-accelerated rendering; exit returned cleanly to ES-DE with music. Logs are under /var/lib/pechersk/verification/lotr-controller. RetroArch Quick Menu rendered, but UI navigation did not establish a reliable screenshot of its device setting. Five physical-controller gameplay, character assignments and Sam's behavior remain unverified. No single-player port-disable override was applied. For solo testing, the writable game remap can be changed through Quick Menu > Controls > Port 2 Controls > Device Type and saved with Manage Remap Files > Save Game Remap File.

The user subsequently confirmed the cause directly: turning on controller 2 controls Sam. Their normal LOTR session was running alongside the isolated checks and remains untouched; stopped menu music to respect active gameplay. The new Multitap remap applies on the next game launch. Five-player physical play remains pending, but Sam's player-2 assignment is now confirmed by the user.

Later, at the user's explicit request, changed physical controller 2 to mapped player port 4 in the running LOTR session through Quick Menu > Controls > Port 2 Controls > Mapped Port. Actual menu screenshots confirm Multitap was already enabled in the running session and Mapped Port changed from 2 to 4. Saved through Manage Remap Files > Save Remap File As with the existing exact basename; success notification and persisted input_remap_port_p2=3 verified. No restart or process replacement: PID 35315 retained. Other writable preferences remain saved as chosen by the user; no need to change Nix seed defaults for this live preference. Character assigned to slot 4 remains for the user to confirm.

Port 4 controlled nobody with only Frodo and Pippin recruited. After the user's explicit approval, changed controller 2 live to mapped port 3 and saved the existing game remap; persisted input_remap_port_p2=2 verified, same PID 35315, then resumed. Character confirmation pending. Located and read original manual pages 5–6: https://www.mikesrpgcenter.com/manuals/snes/Lord_of_the_Rings.pdf. Page 6 assigns the post-Aragorn Multitap layout Aragorn1/Frodo2/Sam3/Pippin4/Merry5 (Gimli replaces Merry). It explicitly allows switching Multitap during play. Pre-Aragorn shifting is a hypothesis being tested. Page 5 clarifies R alone controls other companions together and tapping R recalls them; prior generic L-or-R advice was imprecise.

## Rivendell theme and music

Replaced active monastery visuals with original generated Rivendell/Andúril artwork, forest-green/gold styling and editable leaf/foliage ornaments. Display name is Pechersk · Rivendell; internal ID pechersk-es-de preserves the selected theme. Artwork and the full built-in generation prompt are saved in theme/assets/anduril-reforged.png and theme/artwork-prompt.txt.

XML validation, formatting, full host build and Colmena deployment passed (console-deployment-rivendell.log). Live screenshots verify the main selection view, PC Games list with existing art/favorite, and the new fallback artwork. Navigation and return work; no theme parser errors or failed system units. Settings backup and screenshots are under /var/lib/pechersk/verification/rivendell.

At the user's follow-up request, replaced runtime menu audio with Howard Shore's Concerning Hobbits, from the official artist release https://www.youtube.com/watch?v=CL_3mlOPnGI (175.04 seconds). Audio and attribution remain on SATA, outside Git/store. The previous hymn is backed up in the private verification directory. Removed music-disabled after replacing the track. Verified active mpv left/right streams to HDMI, system volume 40%, and mpv volume increased to 90% at user request; game-start hook stops playback and game-end resumes it. Hearing/subjective volume remains a user check. Final documentation-only theme package update builds as /nix/store/sw7yk3c8jxdk4r28hzp0s0g61qs0gpn2-nixos-system-pechersk-26.05pre-git.

## PC Games consolidation

Follow-up correction: the initial empty-path overrides did not prevent bundled Ports from returning. The systems file now uses ES-DE's documented top-level `loadExclusive` directive, with retired overrides removed. Full host build and Colmena activation passed (`console-deployment-ports-exclusive.log`). The restarted frontend confirms it loads only our custom systems: 17 configured, 16 populated (one emulator is empty). Actual TV screenshots verify Ports is absent and PC Games contains 16 titles with its favorite preserved. Emulator definitions and game launchers are unchanged. The earlier 17-populated-system interpretation below was incorrect.

Consolidated 16 standalone titles into one flat PC Games catalog, covering native ports, Windows/Python games, StepMania, Doom, Minecraft and Steam. The allowlisted aliases in `pc-games-list.nix` dispatch to the same original targets through `pechersk-port`; game data and save paths stay in place. Doom's existing core/config is retained while its frontend entry joins PC Games. Old standalone system names are overridden with an empty path so ES-DE's bundled configuration cannot restore duplicates. Minecraft's generated Console tools launcher is removed.

Full host build, launcher/migration ShellCheck, Nix formatting and targeted whitespace checks passed. Compared all remaining emulator XML definitions before/after byte-for-byte; identical. A synthetic migration verified 16 flat records, favorite/playcount preservation, nested artwork copying and idempotence without replacing later edits. Reviewed closure changes and deployed via Colmena (`console-deployment-pc-games.log`, activation successful).

Stopped ES-DE normally while pausing its restart parent, backed up metadata/settings to `/var/lib/pechersk/verification/pc-games/before`, then ran the packaged migration as gamer. Source ROM metadata hashes remained unchanged. No custom collections were configured. Live PC Games XML contains 16 games and zero folders, preserves the Windows Tux Racer favorite and StepMania's play history, and matches copied artwork filenames. Source data/metadata is retained. ES-DE reload now reports 17 populated systems, matching 15 emulator categories plus PC Games and Console tools. Screenshots verified the flat list, readable titles, favorite indicator, Tux Racer artwork and StepMania artwork.

An actual PC Games → StepMania launch used the new alias dispatcher, stopped menu music and started the native game plus scoped mapper. Atari + Start closed it; the transient service reports `Result=success`, the mapper disappeared, ES-DE regained focus and music resumed. Failed system units remained empty. This verifies categorization/dispatch and representative integration; it does not newly validate every pre-existing game. Minecraft/Snake and other prior unsupported entries retain their existing status. Artifacts and checksums are in the same private verification directory.

## Console and hardware

Verified on the Atari VCS: NixOS 26.05, kernel 6.18.60, Nix 2.34.6, hostname pechersk, SATA EFI GRUB, accelerated AMD radeonsi OpenGL 4.6, X11 1920×1080, ES-DE autologin, NetworkManager WLAN at 10.40.33.22 and restored Bluetooth bonds. PipeWire exposes the HDMI stereo sink. Audible output, cold-boot autologin, two simultaneous controllers, rumble and long gameplay still need acceptance checks.

The USB SHARE and BATOCERA partitions were archived read only, then cleanly unmounted at the user's request. The Atari eMMC is untouched. Private source settings, WLAN credentials and Bluetooth keys are stored outside the repository and guest share.

## Controller repair

The user confirmed ES-DE navigation after correcting the current SDL mapping. Bottom physical Atari A is SDL button 0; actual Start is button 8. Preserve positions rather than printed Nintendo letters.

RetroArch's udev driver uses a different ordering from SDL. Its version 1.22.2 scans BTN_MISC and higher before older keyboard codes. The audited controller exposes an extra BTN_0, so the actual mapping is:

| Physical control | Linux event | SDL index | RetroArch udev index | Dolphin evdev index |
|---|---|---:|---:|---:|
| Bottom A | BTN_SOUTH | 0 | 1 | 4 |
| Right B | BTN_EAST | 1 | 2 | 5 |
| Left X | BTN_NORTH | 2 | 3 | 6 |
| Top Y | BTN_WEST | 3 | 4 | 7 |
| Left shoulder | BTN_TL | 4 | 5 | 8 |
| Right shoulder | BTN_TR | 5 | 6 | 9 |
| Left stick click | BTN_THUMBL | 6 | 7 | 10 |
| Right stick click | BTN_THUMBR | 7 | 8 | 11 |
| Start | KEY_MENU | 8 | 9 | 0 |
| Back | KEY_BACK | 9 | 10 | 1 |
| Atari/Guide | KEY_HOMEPAGE | 10 | 11 | 2 |

Nintendo SNES/Classic layout: bottom B, right A, left Y, top X. The current RetroArch autoconfig and existing writable hotkeys were both updated. Mupen uses its SDL mapping; Dolphin's separate evdev indices were already correct. Wii Classic face buttons were adjusted to the Nintendo positions.

Ordering references: [RetroArch 1.22.2 udev driver](https://github.com/libretro/RetroArch/blob/v1.22.2/input/drivers_joypad/udev_joypad.c), [Dolphin 2609a evdev driver](https://github.com/dolphin-emu/dolphin/blob/2609a/Source/Core/InputCommon/ControllerInterface/evdev/evdev.cpp).

A root-only Rust uinput fixture models these keys and axes. With production mappings and isolated save paths, holding Guide and pressing Start produced clean status-0 exits in:

- RetroArch/Snes9x running Mario Kart.
- Mupen64Plus running Super Mario 64.
- Dolphin running Super Mario Sunshine.

The virtual controller was removed after testing. The production frontend was left available for the user's SNES input check. These checks validate the configured event/chord path; they do not replace testing the physical controller or cover native ports/PPSSPP/Supermodel.

## Game loading

Actual content was rendered on the real AMD/X11 display, with screenshots retained privately under `/var/lib/pechersk/verification`:

| Engine/system | Content | Result |
|---|---|---|
| Stella / Atari 2600 | Miner 2049er | Screenshot and clean exit |
| Atari800 | Pac-Man | Screenshot and clean exit |
| VICE / C64 | Fix It Felix | Screenshot and clean exit |
| mGBA / GBA | Emerald collection ROM | Screenshot and clean exit |
| Genesis Plus GX / Mega Drive | 16 Ton | Screenshot and clean exit |
| Nestopia / NES | Super Mario Bros. 3 | Screenshot and clean exit |
| Snes9x / SNES | Mario Kart | Screenshot and clean exit |
| MAME2003 Plus | Arkanoid | Screenshot and clean exit |
| Mupen64Plus / N64 | Super Mario 64 | Mario title render |
| Dolphin / GameCube | Super Mario Sunshine | Title/intro render |
| Dolphin / Wii | Pokémon Red WAD | Title render |
| StepMania 5.1 | Restored collection of 269 songs | Fullscreen title, accelerated render, ALSA-sw audio initialized |

The `1943j.zip` clone set failed because required parent ROMs are absent. Arkanoid works using the same emulator. Keep the incomplete source set preserved; do not report it as playable.

Dolphin's first GameCube launch displayed an NKit warning. The warning was acknowledged during the isolated test; `SkipNKitWarning=True` is now set in the production defaults and writable configuration. Future disc conversion is separate work; source images were preserved.

Doom, PC Engine, PSX, PSP, Model 3 and native/Windows ports still need launch verification. Save compatibility is not assumed across emulator/core versions.

StepMania's existing Flatpak launcher entry appeared after refreshing ES-DE following the final import. Its native launcher now seeds songs/settings from the copied Flatpak data into `~/.stepmania-5.1` once, preserving existing files and later changes. The package's `bin/stepmania` symlink initially failed to locate `Songs`; starting its actual executable with the packaged `stepmania-5.1` data directory as cwd fixes this. The deployed launcher loaded all 269 songs with AMD rendering, and the preceding test closed cleanly with Alt+F4/status 0.

The user subsequently attached the EMS dual dance-pad adapter, VID:PID `0b43:0003`. Linux detects two `HID 0b43:0003` inputs. StepMania's Linux input driver scans at startup, so the application was restarted. Its built-in EMS USB2 automapping now assigns player 1 to Joy11 and player 2 to Joy12 with the Atari controller present. Arrows use B13/B14/B15/B16 plus B1/B2/B3/B4 alternatives; Start is B10 and Select B9. The launcher enables native remapping on device-list changes and resets the imported device cache once, rather than preserving stale Batocera joystick numbers. Original preferences/keymaps are backed up in the private verification directory. An initial redundant custom automap matched the same device twice; that rule was removed, and the final log confirms exactly one built-in mapping per pad. Physical arrow/Start presses and two-player gameplay remain pending the user's input sequence.

## Additional native games

Added pinned SuperTux 0.7.0, Sonic Robo Blast 2 2.2.15 and Neverball 1.6.0, with declarative `.port` entries under `/userdata/roms/native` and a shared scoped quit-mapper branch. Source inspection confirmed SuperTux's SDL GameController defaults already use bottom jump/select and left action; SRB2 uses raw one-based JOY names, native analog axes and gamepad slots 1/2; Neverball uses raw button indices and stick tilt. Writable defaults preserve future edits. SuperTux state is `~/.local/share/pechersk/supertux`, SRB2 `~/.srb2`, Neverball `~/.neverball`. Existing config backups precede seed-once updates. Neverball seeds player name Pechersk to avoid the initial name prompt.

Full host build, launcher ShellCheck, Nix formatting and targeted whitespace checks passed. Reviewed closure additions (the three games/assets, PhysFS and controller defaults) and deployed through Colmena. Host fetched assets from cache.nixos.org. An early SuperTux source extraction ran while its archive was still downloading and failed with EOF; repeated successfully after the download completed. An SRB2 config comment containing a semicolon caused `Unknown command 'raw'`; removed that punctuation, rebuilt and deployed the final closure (`console-deployment-native-games-final.log`, activation successful).

Real-display checks used native accelerated rendering. The uinput fixture initially became SuperTux player two and could not operate the primary menu, so primary-slot checks injected standard evdev events into the real Atari's event device with Nix-provided evemu. SuperTux passed Start Game selection, world-map navigation, first-level movement/jump/coin collection and Guide + Start exit/status 0. Start skipped its intro; a keyboard Escape attempt was also made during the cinematic. SuperTux's actual multiplayer gameplay remains untested.

SRB2 passed controller selection through its main/start/tutorial menus, tutorial advancement, native left-stick movement, Start opening its game menu and Guide + Start exit/status 0. Tutorial movement gates prevent treating the early jump/spin attempts as completed gameplay verification; bindings are confirmed in the saved config, but those actions still need normal-play acceptance. The first tutorial remains unfinished for the user. Initial raw-button defaults for Start were corrected from JOY8 to the measured JOY9 in the seed.

Neverball passed B back, stick menu navigation and A selection. A half-deflection test (16000) was below its menu's half-axis threshold; repeated at 24000. Mouse hover affected selection, so the initial name/level setup also used targeted keyboard/mouse input. Gameplay then visibly tilted the board and rolled the ball to a fall-out with native stick input. The first test exceeded its 180-second harness limit before quit (status 124); a separate brief launch verified Guide + Start exit/status 0. No claim of a completed level or pause check. User-facing player name is Pechersk. Logs/screenshots are in `/var/lib/pechersk/verification/native-games`.

All test game/mapper/virtual-pad processes were removed, injected buttons/axes released, and ES-DE refreshed for the new entries. Music resumed and system failed units were empty. Physical controller comfort, full action coverage, multiplayer and audible game audio remain acceptance checks.

## SuperTuxKart

Inspected pinned SuperTuxKart 1.5 `src/input/{sdl_controller.cpp,sdl_controller.hpp,gamepad_config.cpp}`: saved bindings use raw joystick button/axis indices, even when the device has an SDL GameController mapping. Existing defaults assigned top face button to acceleration and bottom to rear view. `controllers/supertuxkart-input.xsl` replaces only the named Atari gamepad, preserving keyboard and other controller nodes. The launcher backs up input XML and applies defaults once, leaving later user remaps writable. Analog steering remains native; the existing scoped quit profile handles Guide + Start and releases held modifiers before returning.

The full host build, launcher ShellCheck and Nix formatting passed. Transformed keyboard XML compared identical with `cmp` obtained through Nix (the initial shell lacked it); output contains one Atari profile with acceleration button 0 and pause button 8. The Rust input fixture was extended with held-A and half-deflection analog-stick commands; its temporary Nix environment required both rustc and a C linker. Closure comparison showed the launcher/profile and libxslt changes. Colmena activation completed successfully (`console-deployment-supertuxkart.log`). A broad whitespace check reported pre-existing blank context lines in the earlier Retro Trivia patch; affected SuperTuxKart files pass.

On the real AMD-accelerated display, fixture bottom A selected Story Mode and Guide + Start closed the production launcher with status 0, removing its mapper. The game's normal launch updated player metadata; high scores were unchanged. Racing checks used a separate `SUPERTUXKART_SAVEDIR` profile. The first copy was one directory too high, causing fresh defaults and rear-view on A; corrected the harness to include the game's appended `config-0.10` directory. The corrected Lighthouse race demonstrated bottom-A acceleration, half-deflection steering, Start opening the Paused menu, B resuming, and Guide + Start exiting with status 0. Production player/high-score hashes remained identical across the separate-profile race checks. Logs/screenshots are under `/var/lib/pechersk/verification/supertuxkart`. No test game, mapper or virtual pad remains; ES-DE/music restored. Physical controller feel, rumble and split-screen still need acceptance.

## Extreme Tux Racer and screen blanking

Deployed a patched Extreme Tux Racer with a scoped AntiMicroX keyboard profile. Native joystick forwarding is disabled because menus lack joystick handlers and racing interprets unrelated axes as throttle/brake. The profile supplies directional navigation/steering, bottom-button confirm/jump, right-button back, paddle, trick, brake, pause and the existing Guide + Start exit combination. Return also triggers jump in the patched game. Full host build, launcher shell checks, formatting and Colmena activation passed (`console-deployment-tux-screensaver.log`).

Controller fixture checks reached registration, main menu, Practice, course selection and downhill gameplay with steering/paddling. An initial separate-display software-rendering check increased fan speed while the frontend was stopped, leaving the TV black. Stopped that test immediately after the user reported it, removed the virtual controller and restored ES-DE/music. Avoid repeating heavy hidden rendering tests.

A subsequent lightweight 320×240 X11 event-capture check, using the production session's SDL mapping, verified bottom-button Return, Start sending P, and Guide + Start sending Alt+F4, including all key releases. Logs are `tux-racer/input-{keys,mapper,fixture}.log` under the private verification directory. Source inspection confirms P requests the paused state; its handler ignores release events and resumes on the next ordinary key press. A brief production-launcher check on the real display then verified Guide + Start exits Tux Racer with status 0, the scoped mapper disappears, and ES-DE/music resume (`exit-{game,fixture,status}.log`). No test processes remain. Physical-controller pause/gameplay feel still need acceptance.

ES-DE defaults and existing writable settings now use `ScreensaverTimer=0` and `ScreensaverControls=false`, disabling automatic and manual screensaver activation. After restarting the frontend, the live settings retained these values; X11 reports screen-saver timeout 0 and DPMS disabled. No failed system units remained.

## Migration and repeatable checks

### Retro Trivia input and exit

Closed the user's stuck upstream Retro Trivia process. The source ignored keyboard events whenever its joystick list was present, assumed instance IDs were player slots, mixed events from different pads, and hardcoded an unavailable 18-button hotkey layout. `retrotrivia.patch` fixes keyboard navigation/action, Escape (including loading), stable player slots/device routing, usable analog thresholds and face-button handling without out-of-range pad indices. The port launcher patches a cached copy, retains upstream assets/modules and invokes its executable dependency-aware Nix header against pinned Nixpkgs. The existing scoped AntiMicroX profile supplies Atari + Start and releases modifiers on cleanup.

Real-display verification with both Atari controllers connected recorded keyboard selection/answer and controller advancement. The first video-exit check exposed status 139 during interpreter shutdown; the patch now stops delayed SDL audio callbacks, joins threads, terminates decoder children and explicitly quits pygame. The final live Atari/Start event sequence exited with status 0. A separate-display check navigated by keyboard into a real pixel/video question and exited with Escape/status 0. No mapper/decoder was left running. The original upstream module still prints its pre-existing `VideoSprite.proc` warning during video updates; frames and questions continue and the clean exit test passed.

The launcher and full host closure built successfully; formatting and shell checks passed. Closure inspection showed only the port/patch integration and its Nix-shell runtime dependencies. Colmena activation completed (`console-deployment-retrotrivia.log`), with no failed system units. ES-DE was refreshed to use the new launcher.

### Child-oriented StepMania charts

Audited 269 directly loadable song directories; excluded four nested chart directories that StepMania ignores. Retained 127 songs with accessible existing single-pad charts. Added First Steps (estimated meter 1) and Easy Rhythm (estimated meter 3) to 142 songs, including single-pad options for the two songs previously offering only double charts. Additions use existing integer-beat onsets and original BPM/offset/split timing, simple alternating-foot patterns, phrase rests and single taps only. Minimum spacing is 0.85/0.55 seconds; source charts/audio remain unchanged. Difficulty-slot conflicts use named Edit charts to preserve existing chart identities. Three legacy DWI songs receive additions in their native format.

All three Rust format/timing tests passed. Additive generation verifies original bytes remain an exact prefix and chart counts grow as expected. StepMania's actual loader initially missed four charts because bundled Springtime and Mecha-Tribe Assault mask the writable SSCs. The user approved separate `.edit` files, one per chart, preserving their own timing. A private theme enumerated engine-loaded charts and radar tap counts; all 284 expected additions matched. The final check used Xvfb, Null audio and X11-only input, leaving the user's real StepMania session and pads alone. Earlier private test-screen metric errors were corrected in the harness.

Installed 140 appended song files and four new sidecars. Originals were checksum-checked before installation and archived at `/var/lib/pechersk/verification/easy-charts-v1/backup/original-charts.tar`; installed files match verified working-copy SHA-256 values. The two affected bundled-song cache entries were backed up and invalidated for the next launch. Reports, changed-file lists and logs are beside the backup. Child playability, interest and perceived music synchronization remain human acceptance checks. The user was directed to Legend of Zelda / Pechersk First Steps (1), with 77 single taps and a 1.40-second minimum gap, followed by Easy Rhythm (3).

A separate-display gameplay check selected that exact Zelda addition and rendered its arrows in Autoplay. The private harness initially bypassed the normal menu's Protiming preference initialization, causing judgment-display warnings. Initializing that private preference resolved them; the final gameplay check exited normally without Lua command errors. Its screenshot is `easy-charts-v1/zelda-first-steps.png`. The user's production StepMania process was left running throughout the separate-display checks.

The user requested USB removal after migration. Both `/mnt/batocera-share` and `/mnt/batocera-boot` were cleanly unmounted; `/dev/sdb1` and `/dev/sdb2` had no remaining mounts. Minecraft was confirmed broken before migration and is outside remaining acceptance.

### Lavra theme, background music and StepMania exit

The user selected Kyiv-Pechersk Lavra as the visual reference. The original `pechersk-es-de` XML/SVG theme and packaged DejaVu fonts were built/deployed through Colmena. XML validation passed, ES-DE 3.5 reported successful loading without theme errors, and real-display screenshots verified system navigation, game navigation, counts, missing-art fallback, existing NES 2048 artwork/description and StepMania artwork. A separate preview home was used before activating the production setting. The stock themes remain installed. Screenshots are retained in the private verification directory.

The user-selected hymn from YouTube `WbK6H9XTD0A` was downloaded as runtime audio to `/userdata/music/menu/pechersk.m4a` (approximately 217 seconds). A user mpv service loops it at 70% player volume through the current PipeWire HDMI sink. Startup/quit and game-start/game-end hooks manage playback. Console tools → Music persists an on/off marker. Direct hook tests verified stop/resume, disabling remaining effective after game return, and re-enabling.

The initial 18% player setting was inaudible despite an active, unmuted stream. HDMI monitor capture measured roughly −80 dB mean/−68 dB peak. After raising only mpv to 70%, capture measured −37 dB mean/−24 dB peak; system volume remained 40%. The user confirmed the hymn is audible at a comfortable volume. A running service alone was insufficient proof of audible playback.

End-to-end production check: launched StepMania from the themed ES-DE entry; the music service stopped while the game and scoped AntiMicroX quit mapper ran. A uinput Atari fixture held Guide + Start; StepMania exited cleanly, the mapper disappeared, ES-DE regained focus and the music service resumed. Start alone and Guide alone previously left the game running; holding Start through the exit also passed. The fixture was removed afterwards. No failed system or user units remained. Dance-pad gameplay and actual-controller confirmation remain manual checks.

The theme now generates original 85 ms wooden navigation taps, 120 ms back taps and a 340 ms soft bell. All seven ES-DE navigation sound events resolve to these samples with no stock fallback. Debug loading and rapid navigation passed; sample peaks range from approximately −16 to −17 dB, with means around −30 dB. Colmena deployment completed and the production frontend was restarted with the new cues.

### Dance-pad isolation and GBA exit

EMS `0b43:0003` event/joystick nodes belong to `stepmania-pads`, mode 0660, with desktop uaccess removed and `ID_SEAT=seat-stepmania`. Existing ACLs are cleared on activation. A group-only rule initially allowed logind to restore desktop access after device changes; the dedicated seat fixes that. A final udev change test preserved the restriction. As gamer, SDL lists only the Atari controller with both pads connected.

The fixed setgid StepMania executable is launched through a waiting transient user service outside ES-DE's container. A production frontend launch verified the game has effective group `stepmania-pads`, opens the Atari device and both pad event nodes, loads 269 songs and maps EMS players 1 and 2 separately. The service and quit mapper disappear when the game closes. Physical arrows/two-player play still need acceptance.

The user's stuck GBA session was closed with SIGTERM. A fresh mGBA/RetroArch test used separate verification saves/states and the production controller configuration, with both pads still attached. Its input log contained the real Atari controller and the temporary Atari uinput fixture, with no EMS devices. Guide + Start from the fixture exited RetroArch with status 0. The fixture was removed; no emulator or quit mapper remained running. The physical Atari chord needs the user's repeat test.

The importer synthetic suite passes unchanged source, existing-save protection, repeat imports, Nintendo sidecar SRAM, nested artwork/metadata conversion and external/overlapping-path rejection. NixOS closures and writeShellApplication checks pass; deployed through Colmena.

Completed migration services on SATA:

- `pechersk-usb-archive-v2`: complete private SHARE and boot file archive.
- `pechersk-save-import`: nonoverwriting live save import.
- `pechersk-usb-verify`: waits for archive completion, then full checksum dry-runs against both read-only source partitions.
- `pechersk-final-import`: waits for archive and save completion, then imports public data, converts ES-DE metadata/media and restores gamer ownership.

All four completion markers are present in `/var/lib/pechersk-migration`: `archive-complete`, `saves-import-complete`, `checksums-verified`, `library-import-complete`. Both checksum difference reports are empty. SHARE archive contains 104,236 entries; the boot archive contains 56 entries. Live ROMs occupy approximately 25 GiB; saves/archived Flatpak data occupy 6.7 GiB. ES-DE was refreshed after import and loaded 25 systems, including StepMania. USB/eMMC remain unchanged.
