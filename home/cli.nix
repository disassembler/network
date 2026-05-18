{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;

      # Porting your specific red-background warning for rm -rf
      syntaxHighlighting = {
        enable = true;
        highlighters = ["main" "pattern"];
        patterns = {
          "rm -rf *" = "fg=white,bold,bg=red";
        };
      };

      history = {
        size = 10000;
        path = "$HOME/.zsh_history";
      };

      # Direct aliases from your previous module
      shellAliases = {
        vi = "nvim";
        jvim = "${pkgs.vim}/bin/vim";
        cpf = "${pkgs.coreutils}/bin/cp";
        sprunge = "curl -F 'sprunge=<-' http://sprunge.us";
        nixpaste = "curl -F 'text=<-' http://nixpaste.lbr.uno";
        ssht = "TERM=screen-256color ssh";
        nshell = "nix-shell --run zsh";
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
        cat = "bat";

        # Fasd shortcuts
        a = "fasd -a";
        s = "fasd -si";
        d = "fasd -d";
        f = "fasd -f";
        z = "fasd_cd -d";
        zz = "fasd_cd -d -i";

        # Git & zmv safety
        git = "noglob git";
        zmv = "noglob zmv -W";
      };

      # Global pipe aliases (like | L for less)
      dirHashes = {
        C = "| wc -l";
        G = "| grep";
        H = "| head";
        L = "| less";
        N = "| /dev/null";
        S = "| sort";
      };

      # Custom Vim bindings and environment variables
      initContent = ''
        export PAGER='${pkgs.less}/bin/less -R'
        export EDITOR='nvim'
        export VISUAL='nvim'
        export KEYTIMEOUT=1

        # Enable Vim mode and command-line editing
        bindkey -v
        autoload -U edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd "^v" edit-command-line

        # Navigation and history search
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey -M vicmd k up-line-or-beginning-search
        bindkey -M vicmd j down-line-or-beginning-search

        # Fasd initialization
        eval "$(fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install)"

        autoload -U zmv
      '';
    };
    bash = {
      enable = true;
      # You can share aliases between shells easily in Nix
      shellAliases = {
        ll = "ls -l";
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true; # Highly recommended for Nix users!

      # These are true by default, but you can be explicit:
      enableBashIntegration = true;
      enableZshIntegration = true;

      # Optional: make direnv less "chatty" when entering a directory
      silent = true;
    };
    starship = {
      enable = true;
      settings = {
        username.show_always = true;
        hostname.ssh_only = true;
        git_commit = {
          tag_disabled = false;
          only_detached = false;
        };
        memory_usage = {
          format = "via $symbol[\${ram_pct}]($style) ";
          disabled = false;
          threshold = -1;
        };
        time = {
          format = "[[ $time ]($style)▓▒░]($style inverted)";
          disabled = false;
        };
        battery.display = [
          {
            threshold = 100;
            style = "bold green";
          }
          {
            threshold = 50;
            style = "bold orange";
          }
          {
            threshold = 20;
            style = "bold red";
          }
        ];
        status = {
          map_symbol = true;
          disabled = false;
        };
      };
    };
    git = {
      enable = true;

      signing = {
        key = "754C09A672D83CAF499542D9F919BF40EACEF923";
        signByDefault = true;
      };

      settings = {
        user.name = "Samuel Leathers";
        user.email = "samuel.leathers@iohk.io";
        github.user = "disassembler";
        color.ui = true;
        aliases = {
          # add
          a = "add";
          chunkyadd = "add --patch";
          # branch
          b = "branch -v";
          # commit
          c = "commit -m";
          ca = "commit -am";
          ci = "commit";
          amend = "commit --amend";
          ammend = "commit --amend";
          # checkout
          co = "checkout";
          nb = "checkout -b";
          # cherry-pick
          cp = "cherry-pick -x";
          # diff
          d = "diff";
          dc = "diff --cached";
          last = "diff HEAD^";
          # log
          l = "log --graph --date=short";
          changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
          short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
          changelog = "log --pretty=format:\" * %s\"";
          shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";
          # pull/push
          pl = "pull";
          ps = "push";
          # rebase
          rc = "rebase --continue";
          rs = "rebase --skip";
          # remote
          r = "remote -v";
          # reset
          unstage = "reset HEAD";
          uncommit = "reset --soft HEAD^";
          filelog = "log -u";
          mt = "mergetool";
          # stash
          ss = "stash";
          sl = "stash list";
          sa = "stash apply";
          sd = "stash drop";
          su = "stash --include-untracked --keep-index";
          # status
          s = "status";
          st = "status";
          stat = "status";
          # tag
          t = "tag -n";
          # svn helpers
          svnr = "svn rebase";
          svnd = "svn dcommit";
          svnl = "svn log --oneline --show-commit";
        };

        "color \"branch\"" = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };

        "color \"diff\"" = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red bold";
          new = "green bold";
        };

        format.pretty = "format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";

        mergetool.prompt = false;
        merge = {
          summary = true;
          verbosity = 1;
          tool = "splice";
        };

        "mergetool \"splice\"" = {
          cmd = "vim -f $BASE $LOCAL $REMOTE $MERGED -c 'SpliceInit'";
          trustExitCode = true;
        };

        apply.whitespace = "nowarn";
        branch.autosetuprebase = "always";
        push.default = "tracking";

        core = {
          autocrlf = false;
          editor = "vim";
          excludesfile = "~/.gitignore";
        };

        advice.statusHints = false;
        diff.mnemonicprefix = true;
      };
    };
  };
  home.packages = with pkgs; [
    # --- System Monitoring & Information ---
    htop # Interactive process viewer and system monitor
    btop # Modern, visually appealing resource monitor
    neofetch # System information tool with ASCII distro logo
    lshw # Detailed hardware configuration lister
    pciutils # Programs for inspecting and configuring PCI devices
    psmisc # Small utilities that manage processes (killall, pstree)

    # --- File & Search Utilities ---
    ripgrep # Extremely fast recursive line-oriented search tool
    fd # Simple, fast and user-friendly alternative to 'find'
    bat # A cat(1) clone with syntax highlighting and Git integration
    unzip # Extraction utility for .zip compressed files
    zip # Package and compress (archive) files into zip format
    jq # Lightweight and flexible command-line JSON processor
    pv # Monitor the progress of data through a pipe

    # --- Networking & Secure Transfer ---
    wget # Non-interactive network downloader
    inetutils # Common network programs (ftp, telnet, hostname)
    tcpdump # Command-line network packet analyzer
    tmate # Instant terminal sharing (fork of tmux)
    magic-wormhole # Get things from one computer to another, safely
    mitmproxy # Interactive TLS-capable intercepting HTTP proxy

    # --- Development & Nix Ecosystem ---
    alejandra # The uncompromised Nix code formatter
    nix-tree # Interactively browse dependency graphs of Nix derivations
    nh # Yet another Nix CLI helper (cleaner rebuild output)
    nix-index # Quickly locate Nix packages containing specific files
    niff # Script to compare Nix expressions and detect attribute changes
    nix-prefetch-git # Prefetch source code from Git for Nix expressions
    code-cursor # AI-powered code editor (VS Code fork)
    nix-direnv
    inputs.llm-agents.packages.x86_64-linux.gemini-cli
    inputs.llm-agents.packages.x86_64-linux.claude-code
    inputs.llm-agents.packages.x86_64-linux.code
    inputs.llm-agents.packages.x86_64-linux.opencode
    inputs.agentix.packages.x86_64-linux.claude-jail
    inputs.agentix.packages.x86_64-linux.mcp-server
    inputs.agentix.packages.x86_64-linux.ingest

    # --- Git & Version Control ---
    tig # Text-mode interface for Git
    hub # Command-line wrapper for Git that makes GitHub easier
    gist # Command-line tool for uploading to GitHub Gists

    # --- Security & Cryptography ---
    gnupg # The GNU Privacy Guard (encryption and signing)
    gnupg1compat # Compatibility symlinks for older gpg/gpgv commands
    strace # Diagnostic, debugging and instructional userspace utility

    # --- Hardware ---
    platformio # Ecosystem for IoT and embedded development

    # --- Specialized Tools ---
    hledger # Lightweight, plain-text accounting tool
    taskwarrior3 # Open-source, command-line todo list manager
    hlint # Tool for suggesting improvements to Haskell code
    sqlite-interactive # Interactive command-line interface for SQLite databases
    heimdall-gui # GUI for flashing firmware on Samsung devices
    podman-compose # Tool for running multi-container applications with Podman
  ];
}
