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
          chat-type = mkOption {
            type = enum [ "default" "slack" ];
            default = "default";
            description = "Whether slack gateway module should be included";
          };
        };
      }));
      default = [ ];
      description = "List of configs";
    };

  };
  config =
    let
      pkgs2_src = pkgs.fetchFromGitHub {
        owner = "nixos";
        repo = "nixpkgs";
        rev = "831ef4756e3";
        sha256 = "1rbfgfp9y2wqn1k0q00363hrb6dc0jbqm7nmnnmi9az3sw55q0rv";
      };
      pkgs2 = import pkgs2_src { config = { }; overlays = [ ]; };
      weechat = pkgs2.weechat.override {
        configure = { availablePlugins, ... }: {
          plugins = with availablePlugins; [
            (python.withPackages (ps: with ps; [ websocket_client ]))
            perl
            ruby
          ];
        };
      };
      slack_plugin_src = pkgs.fetchFromGitHub {
        owner = "cleverca22";
        repo = "slack-irc-gateway";
        rev = "eb4b3ca";
        sha256 = "1xvwrd59a0xj0jhk0y61fwvzfzf51s95haqykk14gb3d49w3hx88";
      };
      #wee-slack = import "${slack_plugin_src}/wee-slack.nix";

    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [ pkgs.tmux ];
      #systemd.services.weechat = {
      #  description = "weechat tmux session";
      #  wantedBy = [ "multi-user.target" ];
      #  path = [ weechat pkgs.tmux pkgs.conky pkgs.curl pkgs.aspell  ];
      #  environment."ASPELL_CONF" = "dict-dir ${pkgs.aspellDicts.en}/lib/aspell";
      #  script = let
      #      makeWeechatDir = directory: "mkdir -p ${directory}";
      #      enableWeeSlack = chat-type: directory: ''
      #        mkdir -p ${directory}/python/autoload
      #        cp -vf ${wee-slack}/wee_slack.py ${directory}/python/autoload/wee_slack.py
      #        '';
      #      startTmuxWindow = session: name: chat-type: directory: "tmux new-window -d -t ${session} -n ${lib.optionalString (chat-type != "default") "${chat-type}-"}${name} 'weechat -d ${directory}'";
      #      weechat-start-all = lib.concatStringsSep "\n" (lib.mapAttrsToList ( name: value: ''
      #        ${makeWeechatDir value.directory}
      #        ${lib.optionalString (value.chat-type == "slack") (enableWeeSlack value.chat-type value.directory)}
      #        ${startTmuxWindow cfg.tmux-session name value.chat-type value.directory}'') cfg.configs);
      #    in ''
      #    tmux new-session -d -s ${cfg.tmux-session}
      #    ${weechat-start-all}
      #  '';
      #  preStop = ''
      #    tmux kill-session -t ${cfg.tmux-session}
      #  '';
      #  serviceConfig = {
      #    User = cfg.user;
      #    KillMode = "process";
      #    Restart = "always";
      #    RemainAfterExit = "yes";
      #  };
      #};

    };
}
