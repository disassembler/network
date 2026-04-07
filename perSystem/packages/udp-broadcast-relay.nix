{...}: {
  perSystem = {pkgs, lib, ...}: {
    packages.udp-broadcast-relay = pkgs.stdenv.mkDerivation {
      pname = "udp-broadcast-relay";
      version = "unstable-2025-07-15";

      src = pkgs.fetchFromGitHub {
        owner = "vyos";
        repo = "udp-broadcast-relay";
        rev = "44166bca5fb470b0f020be6372043dece3c46cb8";
        hash = "sha256-eedgiHtmt4/ETGQya7giW86zUmTw9Rs4kGYKQax08Do=";
      };

      buildPhase = "gcc -O2 udp-broadcast-relay.c -o udp-broadcast-relay";

      installPhase = ''
        mkdir -p $out/bin
        cp udp-broadcast-relay $out/bin/
      '';

      meta = with lib; {
        description = "Relay UDP broadcast packets between network interfaces";
        homepage = "https://github.com/vyos/udp-broadcast-relay";
        license = licenses.gpl2Only;
        platforms = platforms.linux;
        mainProgram = "udp-broadcast-relay";
      };
    };
  };
}
