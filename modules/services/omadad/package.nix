{
  stdenv,
  lib,
  fetchurl,
  mongodb,
}: let
  version = "5.9.31";
  year = "2023";
  month = "03";
  day = "21";
  url = "https://static.tp-link.com/upload/software/${year}/${year}${month}/${year}${month}${day}/Omada_SDN_Controller_v${version}_Linux_x64.tar.gz";
  src = fetchurl {
    inherit url;
    sha256 = "sha256-rSrioNDgzCJES5YneklHIYpropgvNsU141cqNZAghww=";
  };
in
  stdenv.mkDerivation rec {
    pname = "omadad";

    inherit version src;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      # Use heavily parameterized property files to support separate data dir and various NixOS option config
      mkdir -p $out/properties
      mkdir -p $out/bin
      mkdir -p $out/data
      ln -s ${mongodb}/bin/mongod $out/bin/mongod
      cp ${./omada.properties} $out/properties/omada.properties
      cp ${./log4j2.properties} $out/properties/log4j2.properties

      mv lib $out/
      mv data/html $out/data/html
    '';

    # Note, no start script included here.  See options in nixos/modules/services/networking/omadad.nix

    meta = with lib; {
      description = "Controller for TP-Link wifi access points";
      homepage = "https://www.tp-link.com/us/support/download/omada-software-controller";
      license = licenses.publicDomain; # no license specified
      maintainers = [maintainers.goertzenator];
      platforms = with platforms; linux;
    };
  }
