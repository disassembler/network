{inputs, ...}: {
  perSystem = {pkgs, lib, ...}: let
    craneLib = inputs.crane.mkLib pkgs;
    src = craneLib.cleanCargoSource (pkgs.fetchFromGitHub {
      owner = "BlackHoleFox";
      repo = "udp-broadcast-relay-rs";
      rev = "1701e1b1bfded2961f9e9f437f0d9a784d25c871";
      hash = "sha256-Q86ia5Q/d9Jjb/VGKu/5N7lfvSO8r4ctRWYQ+0J4/gE=";
    });
  in {
    packages.udp-broadcast-relay = craneLib.buildPackage {
      inherit src;
      strictDeps = true;
      meta = with lib; {
        description = "Relay UDP broadcast packets between network interfaces";
        homepage = "https://github.com/BlackHoleFox/udp-broadcast-relay-rs";
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = "udp-broadcast-relay-rs";
      };
    };
  };
}
