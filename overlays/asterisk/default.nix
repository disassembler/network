{ stdenv, pkgs, lib, fetchurl, fetchFromGitHub, fetchsvn, fetchpatch,
jansson, libxml2, libxslt, ncurses, openssl, sqlite,
utillinux, dmidecode, libuuid, newt,
lua, speex, alsaLib,
srtp, wget, curl, pkgconfig, libedit, pjsip
}:
let
  mp3-202 = fetchsvn {
    url = http://svn.digium.com/svn/thirdparty/mp3/trunk;
    rev = 202;
    sha256 = "1s9idx2miwk178sa731ig9r4fzx4gy1q8xazfqyd7q4lfd70s1cy";
  };
  externals = {
    # Note that these sounds are included with the release tarball. They are
    # provided here verbatim for the convenience of anyone wanting to build
    # Asterisk from other sources. Include in externals.
    "sounds/asterisk-core-sounds-en-gsm-1.6.1.tar.gz" = fetchurl {
      url = http://downloads.asterisk.org/pub/telephony/sounds/releases/asterisk-core-sounds-en-gsm-1.6.1.tar.gz;
      sha256 = "0bagy99dm00alsjiq6y4zjs8dgj0q76dyiy4cgrsh7fl8hh3v76p";
    };
    "sounds/asterisk-moh-opsound-wav-2.03.tar.gz" = fetchurl {
      url = http://downloads.asterisk.org/pub/telephony/sounds/releases/asterisk-moh-opsound-wav-2.03.tar.gz;
      sha256 = "449fb810d16502c3052fedf02f7e77b36206ac5a145f3dacf4177843a2fcb538";
    };
    "addons/mp3" = mp3-202;
  };
  copyExternalsMap = lib.mapAttrsToList (dst: src: "cp -rv --no-preserve=mode ${src} ${dst}") externals;

in stdenv.mkDerivation rec {
  name = "asterisk-custom";

  buildInputs = [ jansson libxml2 libxslt ncurses openssl sqlite utillinux dmidecode libuuid newt lua speex srtp wget curl libedit pjsip alsaLib ];

  nativeBuildInputs = [ pkgconfig ];

  patches = [
      # We want the Makefile to install the default /var skeleton
      # under ${out}/var but we also want to use /var at runtime.
      # This patch changes the runtime behavior to look for state
      # directories in /var rather than ${out}/var.
      ./runtime-vardirs.patch
      ./gvsip-changes.patch
    ];

  src = fetchFromGitHub {
    owner = "naf419";
    repo = "asterisk";
    rev = "6457379f7460f5011676b95cf4a74d7c43432b9b";
    sha256 = "02h2d4smh4fhxn6qh4fv5al7qk68glhs5vx7k0hrhpkkbjjsgnl6";
  };


  # The default libdir is $PREFIX/usr/lib, which causes problems when paths
  # compiled into Asterisk expect ${out}/usr/lib rather than ${out}/lib.

  # Copy in externals to avoid them being downloaded;
  # they have to be copied, because the modification date is checked.
  # If you are getting a permission denied error on this dir,
  # you're likely missing an automatically downloaded dependency
  preConfigure = ''
  mkdir externals_cache
  '' + (lib.concatStringsSep "\n" copyExternalsMap) + ''

  chmod -w externals_cache
  sed -i -e '/#include "asterisk.h"/i#define ASTMM_LIBC ASTMM_REDIRECT' \
    addons/mp3/interface.c
  '';
  configureFlags = [
    "--libdir=\${out}/lib"
    "--with-lua=${lua}/lib"
    "--without-pjproject-bundled"
    "--with-externals-cache=externals_cache"
  ];

  preBuild = ''
    make menuselect.makeopts
    substituteInPlace menuselect.makeopts --replace 'format_mp3 ' ""
  '';

  postInstall = ''
  # Install sample configuration files for this version of Asterisk
    make samples
  '';

  meta = with stdenv.lib; {
    description = "Software implementation of a telephone private branch exchange (PBX)";
    homepage = http://www.asterisk.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [ auntie DerTim1 yorickvp ];
  };

}
