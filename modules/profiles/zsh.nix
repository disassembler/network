{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.profiles.zsh;
in
{
  options.profiles.zsh = {
    enable = mkEnableOption "enable zsh profile";
    autosuggest = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable autosuggest";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.starship
    ];
    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;
        enableBashCompletion = true;
        syntaxHighlighting = {
          enable = true;
          highlighters = [ "main" "pattern" ];
          patterns = {
            "rm -rf *" = "fg=white,bold,bg=red";
          };
        };
        histSize = 10000;
        promptInit = ''
          eval "$(starship init zsh)"
        '';
        shellInit = ''
          export PAGER='${pkgs.less}/bin/less -R'
          export EDITOR='nvim'
          export VISUAL='nvim'
          export KEYTIMEOUT=1
          case $TERM in
            xterm*)
               precmd () {print -Pn "\e]0;%n@%m: %~\a"}
            ;;
          esac
          eval "$(direnv hook zsh)"
          # ctrl-v to edit command-line in vim
          autoload edit-command-line
          bindkey -v
          zle -N edit-command-line
          bindkey -M vicmd "^v" edit-command-line
          # j/k to search history
          autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
          zle -N up-line-or-beginning-search
          zle -N down-line-or-beginning-search
          bindkey -M vicmd k up-line-or-beginning-search
          bindkey -M vicmd j down-line-or-beginning-search
          alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
          alias nixpaste="curl -F 'text=<-' http://nixpaste.lbr.uno"
          alias ssht="TERM=screen-256color ssh"
          alias nshell="nix-shell --run zsh"
          alias vi="nvim"
          alias cpf="${pkgs.coreutils}/bin/cp"
          fasd_cache="$HOME/.fasd-init-bash"
          if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
            eval "$(fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install)" >| "$fasd_cache"
          fi
          source "$fasd_cache"
          unset fasd_cache
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
          alias -g C='| wc -l'
          alias -g H='| head'
          alias -g L="| less"
          alias -g N="| /dev/null"
          alias -g S='| sort'
          alias -g G='| grep' # now you can do: ls foo G something
        '';

      } // optionalAttrs cfg.autosuggest { autosuggestions.enable = true; };
    };
    users.defaultUserShell = pkgs.zsh;
  };
}
