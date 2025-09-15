{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-gnome.nix")
  ];

  boot.initrd.availableKernelModules = [
    # support for various usb hubs
    "ohci_pci"
    "ohci_hcd"
    "ehci_pci"
    "ehci_hcd"
    "xhci_pci"
    "xhci_hcd"

    "uas" # may be needed in some situations
    "usb-storage" # needed to mount usb as a storage device
  ];

  boot.kernelModules = ["kvm-intel"];
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.package = pkgs.zfs_unstable;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.adawallet.overlay
    (import ./overlay.nix)
  ];
  services.udev.extraRules = let
    dependencies = with pkgs; [coreutils gnupg gawk gnugrep];
    clearYubikey = pkgs.writeScript "clear-yubikey" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.lib.makeBinPath dependencies};
      keygrips=$(
        gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null \
          | grep -v OK \
          | awk '{if ($4 == "T") { print $3 ".key" }}')
      for f in $keygrips; do
        rm -v ~/.gnupg/private-keys-v1.d/$f
      done
      gpg --card-status 2>/dev/null 1>/dev/null || true
    '';
    clearYubikeyNixos = pkgs.writeScript "clear-yubikey-nixos" ''
      #!${pkgs.stdenv.shell}
      ${pkgs.sudo}/bin/sudo -u nixos ${clearYubikey}
    '';
  in ''
    # yubikey rules
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", RUN+="${clearYubikeyNixos}"

    # HW.1, Nano
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"

    # Blue, NanoS, Aramis, HW.2, Nano X, NanoSP, Stax, Ledger Test,
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"

    # Same, but with hidraw-based library (instead of libusb)
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"

    # Trezor
    SUBSYSTEM=="usb", ATTR{idVendor}=="534c", ATTR{idProduct}=="0001", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
    KERNEL=="hidraw*", ATTRS{idVendor}=="534c", ATTRS{idProduct}=="0001", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"

    # Trezor v2
    SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="53c0", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="53c1", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="trezor%n"
    KERNEL=="hidraw*", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="53c1", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"

    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';
  services.udev.packages = [pkgs.yubikey-personalization];
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.trezord.enable = true;
  networking = {
    #networkmanager.enable = lib.mkForce false;
    wireless.enable = lib.mkForce false;
    hostName = "cardano-airgapped";
    hostId = "ffffffff";
  };

  environment.systemPackages = with pkgs; [
    cardano-cli
    cardano-node
    inputs.cardano-parts.packages.x86_64-linux.run-process-compose-node-stack
    bech32
    cardano-address
    cardano-hw-cli
    adawallet
    airgapScripts.extractAccountKeys
    airgapScripts.instructions
    airgapScripts.extractAccountKeys
    airgapScripts.registerStakeKeys
    airgapScripts.delegateStakeKeys
    airgapScripts.witnessPoolTransactions
    airgapScripts.createWallet
    airgapScripts.restoreWallet
    airgapScripts.signPaymentTx
    airgapScripts.createTx
    kdePackages.kleopatra
    termite
    encfs
    chromium
    gnupg
    vim
    sqlite-interactive
    jq
  ];

  programs.dconf.enable = true;
  programs.gnupg.agent.enable = true;
  programs.bash = {
    completion.enable = true;
  };
  systemd.user.services.dconf-defaults = {
    script = let
      dconfDefaults = pkgs.writeText "dconf.defaults" ''

        [org/gnome/desktop/background]
        color-shading-type='solid'
        picture-options='zoom'
        picture-uri='${./cardano.png}'
        primary-color='#000000000000'
        secondary-color='#000000000000'

        [org/gnome/desktop/lockdown]
        disable-lock-screen=true
        disable-log-out=true
        disable-user-switching=true

        [org/gnome/desktop/notifications]
        show-in-lock-screen=false

        [org/gnome/desktop/screensaver]
        color-shading-type='solid'
        lock-delay=uint32 0
        lock-enabled=false
        picture-options='zoom'
        picture-uri='${./cardano.png}'
        primary-color='#000000000000'
        secondary-color='#000000000000'

        [org/gnome/settings-daemon/plugins/media-keys]
        custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
        binding='<Primary><Alt>t'
        command='gnome-terminal'
        name='terminal'

        [org/gnome/settings-daemon/plugins/power]
        idle-dim=false
        power-button-action='interactive'
        sleep-inactive-ac-type='nothing'

        [org/gnome/shell]
        welcome-dialog-last-shown-version='41.2'

        [org/gnome/terminal/legacy]
        theme-variant='dark'
      '';
    in ''
      ${pkgs.dconf}/bin/dconf load / < ${dconfDefaults}
    '';
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
  };

  #isoImage.splashImage = ./cardano.png;
  #isoImage.efiSplashImage = ./cardano.png;
  #isoImage.isoName = "cardano-airgap.iso";
  #isoImage.grubTheme = null;
}
