{pkgs, ...}: {
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    # --- System Defaults ---
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    BROWSER = "google-chrome-stable";

    # --- Wayland & Graphics ---
    # Forces Electron apps to use Wayland (Slack, Discord, etc.)
    NIXOS_OZONE_WL = "1";
    # Ensures Firefox and others pick up the right toolkit
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    GDK_BACKEND = "wayland,x11";

    # --- Hardware & Security (Yubikey/GPG) ---
    # Points to the socket managed by the gpg-agent service we moved
    SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
    GPG_TTY = "$(tty)";

    # --- Clean Home Directory ---
    # Moves annoying config folders out of your root ~ folder
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    GTK_USE_PORTAL = "1";
    XDG_OPEN_PORTAL = "1";
  };
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "*"; # Tells portals to use GTK for everything
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # The fix for your current problem (File Manager)
      "inode/directory" = ["nautilus.desktop"];

      # Messaging Apps (Keep these!)
      "x-scheme-handler/tg" = ["org.telegram.desktop.desktop"];
      "x-scheme-handler/tonsite" = ["org.telegram.desktop.desktop"];
      "x-scheme-handler/sgnl" = ["signal.desktop"];
      "x-scheme-handler/signalcaptcha" = ["signal.desktop"];

      # Web & Browser (Switched from Brave to Chrome)
      "text/html" = ["google-chrome.desktop"];
      "x-scheme-handler/http" = ["google-chrome.desktop"];
      "x-scheme-handler/https" = ["google-chrome.desktop"];
      "x-scheme-handler/about" = ["google-chrome.desktop"];
      "x-scheme-handler/unknown" = ["google-chrome.desktop"];
      "x-scheme-handler/webcal" = ["google-chrome.desktop"];

      # PDF (Your config shows you prefer Chrome for this)
      "application/pdf" = ["google-chrome.desktop"];
    };
  };
  programs = {
    ghostty = {
      enable = true;
      # Use 'pkgs.ghostty' or 'pkgs.ghostty-bin' depending on your nixpkgs version
      package = pkgs.ghostty;

      # Key/Value settings based on Ghostty's documentation
      settings = {
        #theme = "Gruvbox Dark Hard"; # Ghostty has hundreds built-in
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;

        # Transparency & Style
        background-opacity = 0.9;
        background-blur-radius = 20;
        background = "#282828";
        window-decoration = false; # Let Niri handle borders

        # Niri/Wayland specific
        command = "${pkgs.zsh}/bin/zsh"; # Or your preferred shell
        confirm-close-surface = false; # Don't ask to close
      };
    };
    chromium = {
      enable = true;
      package = pkgs.google-chrome;
      extensions = [
        {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
        {id = "kmhcihpebfmpgmihbkipmjlmmioameka";} # Eternl (Cardano)
        {id = "gafhhkghbfjjkeiendhlofajokpaflmk";} # Lace (Cardano)
        {id = "lpfcbjknijpeeillifnkikgncikgfhdo";} # Nami (Cardano)
        {id = "kfdniefadaanbjodldohaedphafoffoh";} # Typhon Wallet (Cardano)
      ];

      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-features=WebRTCPipeWireCapturer" # Good for Niri screen sharing too
        "--password-store=gnome-libsecret" # Securely uses your Linux keyring
      ];
    };
    rbw = {
      enable = true;
      settings = {
        email = "disasm@gmail.com"; # Replace with your Vaultwarden email
        base_url = "https://vw.lan.disasm.us"; # Replace with your Vaultwarden URL
        lock_timeout = 3600; # Vault locks after 1 hour (in seconds)
        pinentry = pkgs.pinentry-gnome3; # Or pinentry-qt / pinentry-curses depending on your DE
      };
    };
    fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "${pkgs.ghostty}/bin/ghostty";
          layer = "overlay";
        };
        colors = {
          background = "282828ff"; # Gruvbox-style background
          text = "ebdbb2ff";
          match = "fb4934ff";
          selection = "504945ff";
          selection-text = "ebdbb2ff";
          border = "fb4934ff";
        };
      };
    };
  };
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300; # 5 minutes
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 330; # 5.5 minutes
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };
  home.packages = with pkgs; [
    # --- Desktop Environment & GUI Utilities ---
    obsidian # Markdown-based knowledge base
    gimp # GNU Image Manipulation Program
    wofi # Wayland-native application launcher and menu
    slurp # Select a region in a Wayland compositor
    grim # Grab images from a Wayland compositor
    dmenu # Dynamic menu for X11 (fallback)
    scrot # Command-line screen capture utility
    xdg-utils # Desktop integration utilities (e.g., xdg-open)
    wl-clipboard # Command-line copy/paste utilities for Wayland
    inotify-tools # Command-line utilities for inotify (file watching)
    swww

    # --- Hardware & Security Managers ---
    ledger-live-desktop # Desktop wallet for Ledger hardware
    keybase # Cryptographic identity and chat platform
    keybase-gui # Graphical interface for Keybase
    p11-kit # Middleware for loading PKCS#11 modules (YubiKey integration)
    arduino # Open-source electronics prototyping platform
    heimdall-gui # GUI for flashing firmware on Samsung devices

    # --- Audio, Video & Imaging ---
    xlights # Christmas light show sequencer
    mplayer # Classic command-line media player
    pavucontrol # PulseAudio volume control (GUI)
    imagemagick # Software suite to create, edit, or convert images
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        scrcpy
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })

    # --- Gaming ---
    steamcmd # Command-line version of the Steam client
    wineWowPackages.waylandFull # Run Windows apps on Wayland via Wine
    winetricks # Helper script to download/install Wine runtime libraries
    mcpelauncher-client # Minecraft: Bedrock Edition Linux launcher
    mcpelauncher-ui-qt # GUI for the Bedrock Edition launcher

    # --- Communication & Media ---
    slack # Team communication and collaboration platform
    discord # Voice, video, and text chat for communities
    zoom-us # Video conferencing and online meetings
    weechat # Extensible chat client (CLI)
    telegram-desktop # Fast and secure mobile and desktop messaging app
    iamb # Matrix client for the terminal

    # Custom Signal Wrapper for Wayland & Secure Passwords
    (signal-desktop.overrideAttrs (oldAttrs: {
      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags "--password-store=gnome-libsecret" \
            --add-flags "--enable-features=UseOzonePlatform" \
            --add-flags "--ozone-platform=wayland"
        '';
    }))
    # --- Fonts ---
    nerd-fonts.jetbrains-mono # Great readability for coding
    nerd-fonts.iosevka # Narrow font, perfect for split screens
    inter # Best for Waybar/UI text
    font-awesome # Essential icons for status bars
    noto-fonts-color-emoji # Ensures emojis don't show up as boxes
    nerd-fonts.fira-code # Required for your Starship prompt symbols
    fira # Monospaced font
    fira-code # Fira Code with ligatures
    corefonts # Microsoft core fonts
    powerline-fonts # Glyphs for powerline-style prompts
    inconsolata # High-quality monospaced font
    liberation_ttf # Open-source replacements for standard fonts
    dejavu_fonts # Wide character coverage
    bakoma_ttf # TeX fonts
    gentium # Specialized font for international languages
    ubuntu-classic # Ubuntu branding fonts
    terminus_font # Clean bitmap font for the terminal
    unifont # Universal bitmap font for broad language support
    fuzzel
  ];
}
