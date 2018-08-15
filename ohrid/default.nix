{ config, pkgs, ... }:
let
  secrets = import ./../secrets.nix;
  custom_modules = (import ./modules-list.nix);

in {
  imports = custom_modules;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nix-repl
    screen
    ncdu
    git
    tmux
  ] ++ (if pkgs.stdenv.isDarwin then [
    darwin.cctools
  ] else []);

  profiles.vim.enable = true;
  #profiles.zsh.enable = true;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  # programs.zsh.enable = true;
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 3;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 4;
  nix.buildCores = 0;
  nix.useSandbox = false;  # this seems to break things when enabled
  nix.extraOptions = ''
    gc-keep-derivations = true
    gc-keep-outputs = true
  '';

  nix.binaryCachePublicKeys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  nix.binaryCaches = [ "https://hydra.iohk.io" ];
  nix.trustedUsers = [ "sam" ];

  #nix.nixPath = [
  #  "nixpkgs=UNSET"
  #  "darwin=UNSET"
  #  "darwin-config=UNSET"
  #];

  ########################################################################

  # try to ensure 25G of free space
  nix.gc.automatic = true;
  nix.gc.options = "--max-freed $((25 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  ########################################################################

  services.nix-daemon.enable = true;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"
  '';

  ########################################################################
}
