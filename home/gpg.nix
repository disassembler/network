{pkgs, ...}: {
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Automatically manages the GPG/SSH agent sockets
    pinentry.package = pkgs.pinentry-gnome3;
  };

  # Keep your Yubikey GUI tools here
  home.packages = with pkgs; [
    yubioath-flutter # YubiKey Authenticator (GUI)
    yubikey-manager # Tool for configuring YubiKey hardware
    pinentry-gnome3
  ];
}
