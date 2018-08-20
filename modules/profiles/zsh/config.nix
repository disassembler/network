{ writeText, zsh-prezto, less }:

let
  self = writeText "zsh-config"
    ''
      # Color output (auto set to 'no' on dumb terminals).
      zstyle ':prezto:*:*' color 'yes'

      # Set the Prezto modules to load (browse modules).
      # The order matters.
      zstyle ':prezto:load' pmodule \
        'environment' \
        'terminal' \
        'editor' \
        'history' \
        'history-substring-search'\
        'directory' \
        'spectrum' \
        'utility' \
        'git' \
        'completion' \
        'syntax-highlighting' \
        'prompt' \
        'fasd' \
        'ssh' \
        'tmux' \
        #'python'

      # Set the key mapping style to 'emacs' or 'vi'.
      zstyle ':prezto:module:editor' key-bindings 'vi'
      zstyle ':prezto:module:editor:info:keymap:primary' format '>>>'
      zstyle ':prezto:module:editor:info:keymap:primary:insert' format 'I'
      zstyle ':prezto:module:editor:info:keymap:primary:overwrite' format 'O'

      # Ignore submodules when they are 'dirty', 'untracked', 'all', or 'none'.
      #zstyle ':prezto:module:git:status:ignore' submodules 'all'

      # History Substring Search
      #
      zstyle ‘:prezto:module:history-substring-search’ color ‘yes’
      # Set the query found color.
      zstyle ‘:prezto:module:history-substring-search:color’ found ‘bg=green,fg=white,bold’
      # Set the query not found color.
      zstyle ‘:prezto:module:history-substring-search:color’ not-found ‘bg=red,fg=white,bold’

      # Set the prompt theme to load.
      # Setting it to 'random' loads a random theme.
      # Auto set to 'off' on dumb terminals.
      zstyle ':prezto:module:prompt' theme 'steeef'

      # Set the SSH identities to load into the agent.
      zstyle ':prezto:module:ssh:load' identities 'id_rsa'

      # Set syntax highlighters.
      # By default, only the main highlighter is enabled.
      zstyle ':prezto:module:syntax-highlighting' highlighters \
        'main' \
        'brackets' \
        'pattern' \
        'cursor' \
        'root'

      # Set syntax highlighting styles.
      zstyle ':prezto:module:syntax-highlighting' styles \
        'builtin' 'bg=blue' \
        'command' 'bg=blue' \
        'function' 'bg=blue'

      # Auto set the tab and window titles.
      zstyle ':prezto:module:terminal' auto-title 'yes'

      # Set the window title format.
      zstyle ':prezto:module:terminal:window-title' format '%n@%m: %s'

      # Auto start tmux sessions locally and in ssh sessions
      zstyle ':prezto:module:tmux:auto-start' remote 'yes'

      # Auto convert .... to ../..
      zstyle ':prezto:module:editor' dot-expansion 'yes'

      # -------------------------------------------------

      export PAGER='${less}/bin/less -R'
      export EDITOR='nvim'
      export VISUAL='nvim'
      export KEYTIMEOUT=1
      # SSH Completion
      zstyle ':completion:*:scp:*' tag-order \
         files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
      zstyle ':completion:*:scp:*' group-order \
         files all-files users hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' tag-order \
         users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
      zstyle ':completion:*:ssh:*' group-order \
         hosts-domain hosts-host users hosts-ipaddr
      zstyle '*' single-ignored show
      alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
      alias nixpaste="curl -F 'text=<-' http://nixpaste.lbr.uno"
      alias nixpaste="curl -F 'text=<-' http://nixpaste.lbr.uno"
      alias ssht="TERM=screen-256color ssh"
      alias nshell="nix-shell --run zsh"
      alias vi="nvim"
      # only init if installed.
      fasd_cache="$HOME/.fasd-init-bash"
      if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
        eval "$(fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install)" >| "$fasd_cache"
      fi
      source "$fasd_cache"
      unset fasd_cache

      # custom key bindings
      bindkey -M vicmd "^v" edit-command-line


      # jump to recently used items
      alias a='fasd -a' # any
      alias s='fasd -si' # show / search / select
      alias d='fasd -d' # directory
      alias f='fasd -f' # file
      alias z='fasd_cd -d' # cd, same functionality as j in autojump
      alias zz='fasd_cd -d -i' # interactive directory jump
      # Makes git auto completion faster favouring for local completions
      __git_files () {
          _wanted files expl 'local files' _files
      }
      alias git='noglob git'
      autoload -U zmv
      alias zmv="noglob zmv -W"
      alias -g ...='../..'
      alias -g ....='../../..'
      alias -g .....='../../../..'
      alias -g C='| wc -l'
      alias -g H='| head'
      alias -g L="| less"
      alias -g N="| /dev/null"
      alias -g S='| sort'
      alias -g G='| grep' # now you can do: ls foo G something
    '';
in {
  environment_etc =
    [ { source = "${zsh-prezto}/runcoms/zlogin";
        target = "zlogin";
      }
      { source = "${zsh-prezto}/runcoms/zlogout";
        target = "zlogout";
      }
      { source = self;
        target = "zpreztorc";
      }
      { source = "${zsh-prezto}/runcoms/zprofile";
        target = "zprofile.local";
      }
      { source = "${zsh-prezto}/runcoms/zshenv";
        target = "zshenv.local";
      }
      { source = "${zsh-prezto}/runcoms/zshrc";
        target = "zshrc.local";
      }
    ];
}
