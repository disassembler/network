{
  stdenv,
  lib,
  fetchurl,
  mongodb,
  commonsDaemon,
}: let
  version = "6.1.0.19";
  url = "https://static.tp-link.com/upload/software/2026/202601/20260121/Omada_Network_Application_v${version}_linux_x64_20260117100056.tar.gz";
  src = fetchurl {
    inherit url;
    sha256 = "sha256-iF6yrq7RazAOYYKXryEy1OAVx/m8XtziuoG4zbGB4SY=";
  };
in
  stdenv.mkDerivation rec {
    pname = "omadad";

    inherit version src;

    dontConfigure = true;
    dontBuild = true;

    sourceRoot = "Omada_Network_Application_v${version}_linux_x64";

    installPhase = ''
      mkdir -p $out/properties
      mkdir -p $out/bin
      ln -s ${mongodb}/bin/mongod $out/bin/mongod
      cp ${./omada.properties} $out/properties/omada.properties
      cp ${./log4j2.properties} $out/properties/log4j2.properties

      mv lib $out/
      # commons-daemon.jar is required in classpath but not bundled; add it from nixpkgs
      ln -s ${commonsDaemon}/share/java/commons-daemon-${commonsDaemon.version}.jar $out/lib/

      # Static web assets
      mv data $out/data
    '';

    # Note, no start script included here.  See options in nixos/modules/services/networking/omadad.nix

    meta = with lib; {
      description = "Controller for TP-Link wifi access points";
      homepage = "https://www.tp-link.com/us/support/download/omada-software-controller";
      license = licenses.unfreeRedistributable;
      platforms = with platforms; linux;
    };
  }
