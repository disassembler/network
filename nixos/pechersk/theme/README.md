# Pechersk · Rivendell

An uplifting Lord of the Rings inspired ES-DE 3.5 theme: warm parchment, forest green, muted gold and the hopeful reforging of Andúril in a sunlit Rivendell smithy. The original illustration was generated with the built-in image-generation tool; its full prompt is recorded in `artwork-prompt.txt`. It is illustrative fan art, not a film still. Editable SVG leaf and foliage ornaments complement the artwork. The previous monastery imagery is no longer referenced by the theme.

The generic theme supports every configured system, including collections and Console tools. Game views retain available artwork, descriptions, favorites/folder indicators and controller hints. Fonts are supplied by the Nix DejaVu package.

Original navigation sounds are synthesized during the Nix build: an 85 ms wooden tap for browsing, a lower 120 ms tap for back, and a restrained 340 ms bell for selection. All seven navigation events are covered. Short fades avoid hard clicks, and no long reverberation accumulates during fast scrolling.

Select **Pechersk · Rivendell** under **UI Settings → Theme**. The internal theme directory remains `pechersk-es-de` to preserve the selected theme across deployment. The stock theme remains available there for rollback. Menu music is now Howard Shore's Concerning Hobbits, stored on SATA outside Git/store with attribution. The existing volume, music toggle and game-launch/return hooks remain in use; navigation cues remain enabled.
