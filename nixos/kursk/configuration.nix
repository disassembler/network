{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
with lib; let
  shared = import ../../shared.nix;
in {
  deployment = {
    # NOTE: first deploy must target the old IP (10.40.33.26) until the new
    # static networking config takes effect:
    #   colmena apply --on kursk --override-target 10.40.33.26
    targetHost = "10.40.33.70";
    targetPort = 22;
    targetUser = "root";
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "vaultwarden-env".owner = "vaultwarden";
    gitea_dbpass.owner = "gitea";
    "lego-knot-credentials".owner = "acme";
    #mpd_pw = {};
    #mpd_icecast_pw = {};
    #alertmanager = {};
  };

  imports = [
    ./modules/network.nix
    ./modules/ai.nix
    ./modules/home-automation.nix
    ./modules/webservices.nix
  ];

  _module.args = {
    inherit shared;
  };

  nix = let
    buildMachines = import ../../build-machines.nix;
  in {
    settings.substituters = ["https://cache.nixos.org" "https://cache.iog.io"];
    settings.trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
  };

  boot.loader = {
    grub = {
      efiSupport = true;
      device = "nodev";
      memtest86.enable = true;
      efiInstallAsRemovable = true;
    };
    efi.canTouchEfiVariables = false;
  };
  boot.supportedFilesystems = ["zfs"];

  profiles.vim.enable = lib.mkForce false;
  profiles.zsh.enable = true;
  profiles.tmux.enable = true;
  profiles.weechat = {
    enable = true;
    user = "samchat";
    configs.default = {};
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  security.pki.certificates = [shared.wedlake_ca_cert];

  hardware = {
    gpgSmartcards.enable = true;
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  environment.systemPackages = with pkgs; [
    inputs.home-manager.packages.x86_64-linux.home-manager
    neovim
    direnv
    qemu_kvm
    aspell
    aspellDicts.en
    ncdu
    unrar
    unzip
    zip
    gnupg
    gnupg1compat
    tcpdump
    nix-prefetch-git
    git
    fasd
    dnsutils
  ];

  virtualisation.libvirtd.enable = false;

  containers.rtorrent = {
    privateNetwork = true;
    hostAddress = "10.233.1.1";
    localAddress = "10.233.1.2";
    enableTun = true;
    bindMounts."/opt/rtorrent" = {
      hostPath = "/data/rtorrent";
      isReadOnly = false;
    };
    config = {
      config,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs; [rtorrent openvpn tmux sudo];
      users.users.rtorrent = {
        isNormalUser = true;
        uid = 10001;
      };
      system.stateVersion = "25.05";
    };
  };

  containers.wifiController = {
    privateNetwork = true;
    hostAddress = "10.233.1.3";
    localAddress = "10.233.1.4";
    config = {
      config,
      pkgs,
      ...
    }: {
      environment.systemPackages = with pkgs; [tmux sudo];
      system.stateVersion = "25.05";
    };
  };

  users.users.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = ["wheel" "libvirtd"];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.users.samchat = {
    isNormalUser = true;
    description = "Sam Leathers (chat)";
    uid = 1001;
    extraGroups = [];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };
  users.users.megan = {
    isNormalUser = true;
    uid = 1002;
  };

  system.activationScripts.samchat-tmp = let
    bashrc = builtins.toFile "samchat-bashrc" "export TMUX_TMPDIR=/tmp";
  in "ln -svf ${bashrc} ${config.users.users.samchat.home}/.bash_profile";

  programs.ssh.startAgent = lib.mkForce false;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {hostname = "kursk";};
  home-manager.users.sam = ../../home/sam-server.nix;

  # don't change this without reading release notes
  system.stateVersion = "25.11";
}
