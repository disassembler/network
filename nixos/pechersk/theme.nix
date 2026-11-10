{pkgs, ...}: let
  theme = pkgs.runCommand "pechersk-es-de" {nativeBuildInputs = [pkgs.ffmpeg-headless];} ''
    mkdir -p "$out/fonts" "$out/sounds"
    cp -r ${./theme}/. "$out/"
    ln -s ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSerif.ttf "$out/fonts/serif.ttf"
    ln -s ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf "$out/fonts/sans.ttf"
    test -r "$out/fonts/serif.ttf"
    test -r "$out/fonts/sans.ttf"
    # Original modal percussion: short attacks with no hard digital transient.
    ffmpeg -hide_banner -loglevel error -f lavfi \
      -i 'aevalsrc=0.15*(1-exp(-1800*t))*(sin(2*PI*470*t)*exp(-65*t)+0.3*sin(2*PI*1137*t)*exp(-105*t)):s=48000:d=0.085' \
      -af 'afade=t=out:st=0.06:d=0.025' -c:a pcm_s16le "$out/sounds/wood.wav"
    ffmpeg -hide_banner -loglevel error -f lavfi \
      -i 'aevalsrc=0.14*(1-exp(-1400*t))*(sin(2*PI*330*t)*exp(-40*t)+0.24*sin(2*PI*841*t)*exp(-75*t)):s=48000:d=0.12' \
      -af 'afade=t=out:st=0.09:d=0.03' -c:a pcm_s16le "$out/sounds/back.wav"
    ffmpeg -hide_banner -loglevel error -f lavfi \
      -i 'aevalsrc=(1-exp(-650*t))*(0.12*sin(2*PI*660*t)*exp(-13*t)+0.035*sin(2*PI*1351*t)*exp(-19*t)+0.012*sin(2*PI*1835*t)*exp(-27*t)):s=48000:d=0.34' \
      -af 'afade=t=out:st=0.26:d=0.08' -c:a pcm_s16le "$out/sounds/bell.wav"
  '';
in {
  system.build.pecherskTheme = theme;
  systemd.tmpfiles.rules = [
    "d /var/lib/pechersk/ES-DE/themes 0755 gamer gamer -"
    "L+ /var/lib/pechersk/ES-DE/themes/pechersk-es-de - gamer gamer - ${theme}"
  ];
}
