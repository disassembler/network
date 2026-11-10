# Accessible StepMania charts

`easy-charts.rs` is a dependency-free Rust utility for the Pechersk song library.
Song content stays on SATA, outside Git and the Nix store. Run it on a private
working copy, never directly on the live library. `generate` appends charts and
refuses to regenerate a song containing its version marker. It does not deploy.

From this checkout, obtain tools from the pinned Nixpkgs:

```sh
nix shell --impure --expr 'let p=(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.x86_64-linux; in [p.rustc p.gcc]' -c bash
rustc --edition=2024 nixos/pechersk/tools/easy-charts.rs -o /tmp/easy-charts
rustc --edition=2024 --test nixos/pechersk/tools/easy-charts.rs -o /tmp/easy-charts-tests
/tmp/easy-charts-tests
/tmp/easy-charts audit /private/copy/Songs > audit.tsv
/tmp/easy-charts generate /private/copy/Songs > generated.tsv
```

The root must have `group/song/simfile` layout. Nested directories that StepMania
does not load are excluded. SSC takes precedence over SM, then DWI. The tool
uses actual onsets and timing, including tempo changes, positive stops/delays
and SSC chart timing. Warps, fake ranges, nonpositive BPMs and unsupported DWI
syntax require manual review. Double/couple charts can supply onsets for a new
single-pad chart without changing the originals.

Existing accessible single charts (meter ≤4, ≤1.5 events/second, minimum spacing
0.35 seconds, no mines and ≤15% jumps) are retained without additions. Songs
lacking one receive First Steps (estimated meter 1) and Easy Rhythm (estimated
meter 3). New charts have only single taps, alternating feet with sparse centre
arrows, phrase rests, and minimum gaps of 0.85/0.55 seconds respectively. Their
onsets come from integer-beat source notes; fast songs use wider beat spacing.
The original song bytes remain an exact prefix, with an optional terminating
semicolon for legacy files missing one. Source audio and timing are unchanged.
These constraints provide a conservative starting point for children aged 7–11;
rhythm feel, interest and age suitability still require playing/listening.

When a difficulty slot already exists, the addition uses Edit with a descriptive
name, preserving the original chart's difficulty and score identity. DWI does
not support the same descriptive chart names; choose its meter-1 Beginner or
meter-3 Edit/Easy option.

The installed StepMania bundles Springtime and Mecha-Tribe Assault, masking the
same-named writable SSC files. For those two, create separate SSC-format edits
from the generated working copy instead of replacing their source files:

```sh
/tmp/easy-charts sidecars '/private/copy/Songs/StepMania 5/Springtime/Springtime.ssc'
```

This writes one `.edit` per added chart, preserves split timing, omits cached
radar placeholders so the engine recalculates them, and refuses overwrites.
Verify the installed engine loads every addition with the expected note count,
not merely that the utility can parse its own output. Keep the live chart backup,
changed-file manifest and checksum report before installing; invalidate the song
cache while the game is stopped. Never replace live files during gameplay.
