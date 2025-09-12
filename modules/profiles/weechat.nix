{ config, pkgs, lib, ... }:

let
  cfg = config.profiles.weechat;
in
{
  options.profiles.weechat = with lib; {
    enable = mkEnableOption "enable weechat profile";
    user = mkOption {
      type = types.str;
      description = "User to run weechat tmux session as (must exist)";
    };
    tmux-session = mkOption {
      type = types.str;
      default = "weechat";
      description = "session name of tmux";
    };
    configs = mkOption {
      type = with types; attrsOf (submodule ({ name, ... }: {
        options = {
          directory = mkOption {
            type = str;
            default = "${config.users.users.${cfg.user}.home}/.weechat-${name}";
            description = "Path for weechat config";
          };
        };
      }));
      default = [ ];
      description = "List of configs";
    };

  };
  config =
    let
      weechat = pkgs.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with pkgs.weechatScripts; [
            #weechat-otr
          ];
        };
      };

    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [ pkgs.tmux ];
      systemd.services.weechat = {
        description = "weechat tmux session";
        wantedBy = [ "multi-user.target" ];
        path = [ weechat pkgs.tmux pkgs.conky pkgs.curl pkgs.aspell  ];
        environment."ASPELL_CONF" = "dict-dir ${pkgs.aspellDicts.en}/lib/aspell";
        script = let
            makeWeechatDir = directory: "mkdir -p ${directory}";
            startTmuxWindow = session: name: directory: "tmux new-window -d -t ${session} -n ${name} 'weechat -d ${directory}'";
            weechat-start-all = lib.concatStringsSep "\n" (lib.mapAttrsToList ( name: value: ''
              ${makeWeechatDir value.directory}
              ${startTmuxWindow cfg.tmux-session name value.directory}'') cfg.configs);
          in ''
          tmux new-session -d -s ${cfg.tmux-session}
          ${weechat-start-all}
        '';
        preStop = ''
          tmux kill-session -t ${cfg.tmux-session}
        '';
        serviceConfig = {
          User = cfg.user;
          KillMode = "process";
          Restart = "always";
          RemainAfterExit = "yes";
        };
      };

    };
}
