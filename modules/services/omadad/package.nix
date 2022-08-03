{ stdenv, lib, fetchurl, mongodb }:

stdenv.mkDerivation rec {
  pname = "omadad";

  # version = "3.2.10";
  # src = fetchurl {
  #   url = "https://static.tp-link.com/2020/202004/20200420/Omada_Controller_v3.2.10_linux_x64.tar.gz";
  #   sha256 = "0y0kx00wgws918wz76ldpvz340aid0ay5nckkg8x38yclx929qgh";
  # };

  version = "5.3.1";
  src = fetchurl {
    url = "https://static.tp-link.com/upload/software/2022/202205/20220507/Omada_SDN_Controller_v${version}_Linux_x64.tar.gz";
    sha256 = "sha256-b2T7prvomBpyVhNHC7jTIBm3E2uergYGYcpIZ8tOD2Q=";
  };

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
    license = licenses.publicDomain;  # no license specified
    maintainers = [ maintainers.goertzenator ];
    platforms = with platforms; linux;
  };
}
