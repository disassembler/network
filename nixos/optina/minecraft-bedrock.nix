{ stdenv, fetchurl, patchelf, openssl, unzip, lib, zlib }:

let
  version = "1.18.32.02";
  sha256 = "sha256-rp7lEqloNcYl6YnXKK06+UDU9xgWtEcZDeCNzsoxPe8=";
  rpath = lib.makeLibraryPath [ zlib openssl stdenv.cc.cc ];
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "minecraft-bedrock-server";
  inherit version;
  src = fetchurl {
    url = "https://minecraft.azureedge.net/bin-linux/bedrock-server-${version}.zip";
    inherit sha256;
  };
  postPatch = ''
    rm -f Makefile cmake_install.cmake *.debug
  '';
  sourceRoot = ".";
  nativeBuildInputs = [
    unzip
  ];
  installPhase = ''
    install -m755 -D bedrock_server $out/bin/bedrock_server
    rm bedrock_server
    rm server.properties
    mkdir -p $out/var
    cp -a . $out/var/lib
  '';
  fixupPhase = ''
    echo RPATH: ${rpath}
    patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) --set-rpath "${rpath}" $out/bin/bedrock_server
  '';
}
