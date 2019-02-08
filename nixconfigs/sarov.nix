{ lib, config, pkgs, fetchgit, ... }:

let
  secrets = import ../load-secrets.nix;
  shared = import ../shared.nix;
  machine = "sarov";
  hostId = "523b4cab";

in {
  _module.args = {
    inherit secrets shared;
  };

  #Boot Config

  # Uncomment to use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;

  # Uncomment to use grub boot loader
  boot.loader.grub = {
    efiSupport = true;
    gfxmodeEfi = "1024x768";
    device = "nodev";
    efiInstallAsRemovable = true;
  };

  boot.supportedFilesystems = [ "exfat" ];
  # Uncomment to allow efi to write variables
  #boot.loader.efi.canTouchEfiVariables = true;

  # Splash screen to make boot look nice
  boot.plymouth.enable = true;

  # Apple specific modprobe configuration
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=mbp5
    options hid_apple fnmode=2
  '';

  # Pretty broken, WiFi Crashes
  #boot.extraModulePackages = [ config.boot.kernelPackages.rtlwifi_new ];

  # Luks support
  boot.initrd.luks.devices = [{
    name = "linuxroot";
    device = "/dev/disk/by-uuid/9a7fe0b1-0f54-40d3-8aae-e083f8859ebe";
  }];
  systemd.additionalUpstreamSystemUnits = [
    "debug-shell.service"
  ];

  networking = {
    hostName = machine;
    hostId = hostId;
    nameservers = [ "127.0.0.1" ];
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "interface-name:ve-*" "ens9" ];
    extraHosts =
    ''
      # If DNS is broke, we still want to be able to deploy
      10.40.33.20 optina.wedlake.lan
      10.40.33.20 hydra.wedlake.lan
      10.40.33.1 portal.wedlake.lan
      127.0.0.1 wallet.samleathers.com
    '';
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "wlp3s0";
    };
    vlans = {
      lan = {
        interface = "ens9";
        id = 33;
      };
      mgmt = {
        interface = "ens9";
        id = 3;
      };
      guest = {
        interface = "ens9";
        id = 9;
      };
      voip = {
        interface = "ens9";
        id = 40;
      };
    };
    interfaces = {
      lan = {
        useDHCP = true;
      };
      voip = {
        useDHCP = true;
      };
      mgmt = {
        useDHCP = true;
      };
      guest = {
        useDHCP = true;
      };
    };
    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 4919 ];
      allowedTCPPorts = [ 4444 8081 3478 3000 8080 5900 ];
    };
    #bridges = {
    #  cbr0.interfaces = [ ];
    #};
    #interfaces = {
    #  cbr0 = {
    #    ipv4.addresses = [
    #      {
    #        address = "10.38.0.1";
    #        prefixLength = 24;
    #      }
    #    ];
    #  };
    #};
  };

  security.pki.certificates = [ shared.wedlake_ca_cert ];

  nix = let
    buildMachines = import ../build-machines.nix;
  in {
    useSandbox = true;
    buildCores = 4;
    sandboxPaths = [ "/etc/nsswitch.conf" "/etc/protocols" ];
    binaryCaches = [
      "https://cache.nixos.org"
      "https://hydra.iohk.io"
      #"https://hydra.wedlake.lan"
      "https://snack.cachix.org" ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      #"hydra.wedlake.lan:C3xufTQ7w2Y6VHtf+dyA6NmQPiQjwIDEavJNmr97Loo="
      "snack.cachix.org-1:yWpdDCWeJzVAQUSM1Ol0E3PCVbG4k2wRAsZ/b5L3huc="
    ];
    distributedBuilds = true;
    buildMachines = [
      buildMachines.darwin.ohrid
      #buildMachines.darwin.macvm
      #buildMachines.linux.optina
    ];
    nixPath = [ "nixpkgs=/home/sam/nixpkgs/custom" "nixos-config=/etc/nixos/configuration.nix" ];
    extraOptions = ''
      #allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive
    '';
  };

  nixpkgs.overlays = [
    (self: super:
    let
      hie = import (super.fetchFromGitHub {
        owner = "domenkozar";
        repo = "hie-nix";
        rev = "dbb89939da8997cc6d863705387ce7783d8b6958";
        sha256 = "1bcw59zwf788wg686p3qmcq03fr7bvgbcaa83vq8gvg231bgid4m";
      }) {};
      hnix-lsp = import (super.fetchFromGitHub {
        owner = "domenkozar";
        repo = "hnix-lsp";
        rev = "c69b4bdd46e7eb652f13c13e01d0da44a1491d39";
        sha256 = "16w1197yl6x06a06c2x30rycgllf6r67w0b38fcia2c4cnigzalg";
    });
    in
    { inherit (hie) hie82; inherit hnix-lsp; })
  ];

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
    packageOverrides = super: let self = super.pkgs; in {
      nixops = super.nixops.overrideDerivation (
      old: {
        patchPhase = ''
            substituteInPlace nix/eval-machine-info.nix \
                --replace 'system.nixosVersion' 'system.nixos.version'
        '';
      }
      );
      manymans = with pkgs; buildEnv {
        name = "manymans";
        ignoreCollisions = true;
        paths = [
          man-pages posix_man_pages stdmanpages glibcInfo
        ];
      };
    };
  };

  users.extraUsers.sam = {
    isNormalUser = true;
    description = "Sam Leathers";
    uid = 1000;
    extraGroups = [ "wheel" "docker" "disk" "video" "libvirtd" "adbusers" ];
    openssh.authorizedKeys.keys = shared.sam_ssh_keys;
  };

  # move to host system
  profiles.zsh.enable = true;
  profiles.zsh.autosuggest = true;
  profiles.vim = {
      enable = true;
      dev = false;
  };

}
