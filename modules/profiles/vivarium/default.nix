{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.profiles.vivarium;
  configFile = pkgs.writeText "config.toml" ''
    ${builtins.readFile ./config.toml}

    ### BACKGROUND ###
    # The background options are displayed using `swaybg`. Make sure you have this installed
    # if you want to use them.
    [background]
    colour = "#bbbbbb"
    image = "/home/sam/photos/20170503_183237.jpg"
    mode = "fill"
  '';

  vivarium =
    pkgs.vivarium.overrideAttrs
    (self: {
      nativeBuildInputs = self.nativeBuildInputs ++ [pkgs.makeWrapper];
      postInstall =
        self.postInstall
        + ''
          wrapProgram "$out/bin/vivarium" \
           --add-flags '--config ${configFile}'
        '';
    });
in {
  options.profiles.vivarium = with lib; {
    enable = mkEnableOption "enable vivarium profile";
    dev = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable development plugins like haskell/js";
    };
  };
  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      vivarium
      pkgs.swaybg
      pkgs.bemenu
      pkgs.wofi
      pkgs.wofi-emoji
    ];

    nixpkgs.overlays = [inputs.vivarium.overlay];

    #services.xserver.displayManager.sessionPackages = [vivarium];

    services.blueman.enable = true;
  };
}
