{ config, pkgs, lib, inputs, ... }:
let
  inherit (inputs) styx;
  styxOverlay = prev: final: {
    inherit (styx.packages.x86_64-linux) styx;
    nixedge_site = (final.callPackage ./nixedge/site.nix { styx = final.styx; styx-themes = styx.styx-themes.x86_64-linux; styxLib = styx.lib.x86_64-linux; }).site;
    blog_site = (final.callPackage ./blog/site.nix { styx = final.styx; styx-themes = styx.styx-themes.x86_64-linux; styxLib = styx.lib.x86_64-linux; }).site;
  };

in
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.prod01_wg0_private = { };
  sops.secrets.prod01_wg1_private = { };

  imports = [
    ./modules/network.nix
    ./modules/knot
  ];

  nixpkgs.overlays = [ styxOverlay ];
  security.polkit.enable = lib.mkForce false;

  security.acme.defaults.email = "disasm@gmail.com";
  security.acme = {
    acceptTerms = true;
  };

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "btrfs";
  };
  fileSystems."/data" = {
    device = "/dev/vdb";
    fsType = "btrfs";
  };
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.loader.grub.device = "/dev/vda";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  nix = {
    settings.sandbox = true;
    settings.cores = 4;
    settings.extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
    settings.substituters = [ "https://cache.nixos.org" "https://cache.iog.io" ];
    settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    distributedBuilds = true;
    extraOptions = ''
      allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive
    '';
  };
  swapDevices = [{ device = "/dev/vda2"; }];
  environment.systemPackages = with pkgs; [
    wget
    vim
    tmux
    git
    nix-index
  ];
  services.fail2ban.enable = true;
  services.nginx = {
    enable = true;
    virtualHosts = {
      "nixedge.com" = {
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.nixedge.com" ];
        root = pkgs.nixedge_site;
      };
      "rats.fail" =
        let
          metadata = ''
            {
              "name": "RATS Pool",
              "ticker": "RATS",
              "description": "RATS pool is ran by Charles Hoskinson and Samuel Leathers",
              "homepage": "https://rats.fail"
            }
          '';
          metadata-testnet = ''
            {
              "name": "MICE Pool",
              "ticker": "MICE",
              "description": "MICE pool is RATS testnet sibling, an IPv6 only pool ran by Samuel Leathers",
              "homepage": "https://rats.fail"
            }
          '';
          metadataJson = pkgs.writeText "pool.json" metadata;
          metadataTestnetJson = pkgs.writeText "pool.json" metadata-testnet;
          index = ''
            Future home of Cardano RATS Stake Pool
          '';
          index-html = pkgs.writeText "index.html" index;
          ratsRoot = pkgs.runCommandNoCC "rats-root" { } ''
            mkdir -p $out/testnet
            cp ${metadataJson} $out/pool.json
            cp ${metadataTestnetJson} $out/testnet/pool.json
            cp ${index-html} $out/index.html
          '';
        in
        {
          enableACME = true;
          forceSSL = true;
          serverAliases = [ "www.rats.fail" ];
          root = ratsRoot;
        };
      "samleathers.com" = {
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.samleathers.com" ];
        root = pkgs.blog_site;
      };
      "util.samleathers.com" = {
        enableACME = true;
        forceSSL = true;
        root = "/data/web/vhosts/samleathers/util";
      };
      "centrallakerealty.com" = {
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.centrallakerealty.com" ];
        globalRedirect = "www.facebook.com/MarieLeathersRealtor?mibextid=2JQ9oc";
      };
    };
  };
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.journald = {
    rateLimitBurst = 0;
    extraConfig = "SystemMaxUse=50M";
  };
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "tcpstat"
      "conntrack"
      "diskstats"
      "entropy"
      "filefd"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "vmstat"
      "logind"
      "interrupts"
      "ksmd"
    ];
  };

  users.users.sam = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
  ];
}
