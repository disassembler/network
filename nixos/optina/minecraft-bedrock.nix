{ stdenv, fetchurl, patchelf, openssl, unzip, lib, zlib, curl }:

let
  version = "1.21.60.10";
  sha256 = "sha256-HeZAIlBKXBOPmMQQ5Ba9e08zvuIwkG2tP/EkCjtlWqw=";
  rpath = lib.makeLibraryPath [ zlib openssl stdenv.cc.cc curl ];
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "minecraft-bedrock-server";
  inherit version;
  src = fetchurl {
    url = "https://util.samleathers.com/bedrock-server-${version}.zip";
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
