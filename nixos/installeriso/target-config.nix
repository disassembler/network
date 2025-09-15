{lib, ...}:
# This is a minimal nixos configuration for ssh and wireguard management
{
  imports = [./hardware-configuration.nix ./generated.nix];

  boot = {
    loader.grub = {
      enable = true;
    };
  };
  nix = {
    settings.sandbox = true;
    settings.cores = 4;
    settings.extra-sandbox-paths = ["/etc/nsswitch.conf" "/etc/protocols"];
    settings.substituters = ["https://cache.nixos.org" "https://cache.iog.io"];
    settings.trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    extraOptions = ''
      binary-caches-parallel-connections = 3
      connect-timeout = 5
      experimental-features = nix-command flakes
    '';
  };

  networking.wireguard.interfaces.wg0 = {
    ips = ["10.40.9.5/24" "fd00::5"];
    listenPort = 51820;
    # generate a private key with "wg genkey" and put it in this string
    # DO NOT COMMIT the privateKey
    privateKey = "";
    peers = [
      {
        publicKey = "RtwIQ8Ni8q+/E5tgYPFUnHrOhwAnkGOEe98h+vUYmyg=";
        allowedIPs = ["10.40.33.0/24" "10.40.9.1/32"];
        endpoint = "prophet.samleathers.com:51820";
        persistentKeepalive = 30;
      }
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "without-password";
    };
  };
  systemd.services.sshd.wantedBy = lib.mkForce ["multi-user.target"];
  users.users.root.openssh.authorizedKeys.keys = [
    # we hard-code this because it runs on the system itself
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEPOLnk4+mWNGOXd309PPxal8wgMzKXHnn7Jbu/SpSUYEc1EmjgnrVBcR0eDxgDmGD9zJ69wEH/zLQLPWjaTusiuF+bqAM/x7z7wwy1nZ48SYJw3Q+Xsgzeb0nvmNsPzb0mfnpI6av8MTHNt+xOqDnpC5B82h/voQ4m5DGMQz60ok2hMeh+sy4VIvX5zOVTOFPQqFR6BGDwtALiP5PwMfyScYXlebWHhDRdX9B0j9t+cqiy5utBUsl4cIUInE0KW7Z8Kf6gIsmQnfSZadqI857kdozU3IbaLoJc1C6LyVjzPFyC4+KUC11BmemTGdCjwcoqEZ0k5XtJaKFXacYYXi1l5MS7VdfHldFDZmMEMvfJG/PwvXN4prfOIjpy1521MJHGBNXRktvWhlNBgI1NUQlx7rGmPZmtrYdeclVnnY9Y4HIpkhm0iEt/XUZTMQpXhedd1BozpMp0h135an4uorIEUQnotkaGDwZIV3mSL8x4n6V02Qe2CYvqf4DcCSBv7D91N3JplJJKt7vV4ltwrseDPxDtCxXrQfSIQd0VGmwu1D9FzzDOuk/MGCiCMFCKIKngxZLzajjgfc9+rGLZ94iDz90jfk6GF4hgF78oFNfPEwoGl0soyZM7960QdBcHgB5QF9+9Yd6QhCb/6+ENM9sz6VLdAY7f/9hj/3Aq0Lm4Q== samuel.leathers@iohk.io"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATbejW2TmxxkzFxDzU0Lw2S4Lig0UdSgl8xO761WVtd Adam Key"
  ];
}
