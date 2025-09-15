{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options.themes.numix-solarized.enable = mkEnableOption "solarized";

  config =
    mkIf
    (
      config.themes.numix-solarized.enable
      && config.profiles.x11.enable
    )
    {
      # extra fonts
      fonts.fonts = [pkgs.source-code-pro pkgs.font-awesome-ttf pkgs.powerline-fonts];

      programs.bash.promptInit = "source ${./bashrc}";

      profiles.x11 = {
        gtk2.theme = "NumixSolarizedDark";
        gtk3.theme = "NumixSolarizedDark";

        qt = {
          theme = "Breeze";

          # solarized colors for qt
          settings = ''
            customColors\0=4278201142
            customColors\1=4278662722
            customColors\10=4285297092
            customColors\11=4292032130
            customColors\12=4287865249
            customColors\13=4280983960
            customColors\14=4294833891
            customColors\15=4293847253
            customColors\2=4291513110
            customColors\3=4292620847
            customColors\4=4283985525
            customColors\5=4286945536
            customColors\6=4284840835
            customColors\7=4290087168
            customColors\8=4286813334
            customColors\9=4280716242
            Palette\active=#839496, #002b36, #004051, #003543, #00151b, #001c24, #839496, #93a1a1, #839496, #002b36, #002b36, #000000, #073642, #93a1a1, #0000ff, #ff00ff, #101010, #000000, #ffffdc, #ffffff
            Palette\inactive=#839496, #002b36, #004051, #00313e, #00151b, #001c24, #839496, #93a1a1, #839496, #002b36, #002b36, #000000, #073642, #93a1a1, #0000ff, #ff00ff, #101010, #000000, #ffffdc, #ffffff
            Palette\disabled=#808080, #002b36, #004051, #00313e, #00151b, #001c24, #808080, #93a1a1, #808080, #002b36, #002b36, #000000, #073642, #808080, #0000ff, #ff00ff, #101010, #000000, #ffffdc, #ffffff
          '';
        };

        iconTheme = "Numix";

        Xresources = ''
          /* colors */
          #define U_window_transparent    argb:00000000
          #define U_window_highlight_on    #066999
          #define U_window_highlight_on_a    argb:cc066999
          #define U_window_highlight_off    #B0C4DE
          #define U_window_highlight_off_a  argb:ccB0C4DE
          #define U_window_background    #263238
          #define U_window_background_a    argb:96263238
          #define U_window_urgent      #dc322f
          #define U_window_inactive    #B0C4DE
          #define U_text_color      #eceff1
          #define U_text_color_alt    #3f3f3f

          !
          !   ├────────────────────rofi.width──────────────────────┤
          ! ┬ ╔════════════════════════════════════════════════════╗
          ! │ ║run:query                                           ║ ◀- rofi.color-window[0]
          ! │ ║====================================================║ ◀- rofi.separator-style
          ! │ ║item1░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█║ ◀- rofi.color-normal[0]
          ! │ ╟───────────────────────────────────────────────────█╢
          ! │ ║item2▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█║ ◀- selected line
          ! │ ╟───────────────────────────────────────────────────█╢
          ! │ ║item3░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█║
          ! │ ╟───────────────────────────────────────────────────█╢
          ! │ ║item4▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█║ ◀- rofi.color-normal[2]
          ! │ ╟───────────────────────────────────────────────────█╢
          ! │ ║item5░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█║
          ! ┴ ╚════════════════════════════════════════════════════╝
          ! ▲                                                     ▲
          ! │                                                     │
          ! rofi.lines                                            rofi.hide-scrollbar
          !
          !     main background,    main border color,    separator color
          rofi.color-window:  U_window_background_a,    U_window_background_a,    #26a69a

          !     line background,    text foreground,    alt line background,    highlighted background,   highlighted foreground
          rofi.color-normal:  U_window_transparent,   U_text_color,     U_window_transparent,   U_window_highlight_on_a,  U_text_color

          !       active window                     text on selected line
          rofi.color-active:  U_window_highlight_off,   #268bd2,      #eee8d5,      #268bd2,      #FDF6E3

          !     #fdf6e3,
          rofi.color-urgent:  #00ff00,      #dc322f,      #eee8d5,      #dc322f,      #fdf6e3

          rofi.bw:              0
          rofi.color-enabled:   true
          rofi.columns:         1
          rofi.eh:              1
          rofi.hide-scrollbar:  true
          rofi.line-margin:     5
          rofi.lines:           5
          rofi.location:        0
          rofi.padding:         30
          rofi.separator-style: none
          rofi.sidebar-mode:    false
          rofi.terminal:        st
        '';
      };

      environment.systemPackages = with pkgs; [
        # gtk theme
        numix-solarized-gtk-theme

        # qt theme
        breeze-qt4
        breeze-qt5

        # icon theme
        pkgs.numix-icon-theme

        # cursor theme
        pkgs.numix-cursor-theme
      ];
    };
}
