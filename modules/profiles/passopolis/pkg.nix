{ antBuild }:
with import <nixpkgs> {}; # bring all of Nixpkgs into scope

antBuild {
  name = "passopolis-unstable-2016-05-07";

  src = fetchgit {
    url = "https://github.com/WeAreWizards/passopolis-server";
    sha256 = "0ywmymbjcfsxv1p1j0l0lw9cb7f79h23ic1c4b5w5nb0k9f4zvfq";
    rev = "b827b3a6176e050deb729009676fad7e86e5393a";
    leaveDotGit = true;
  };

  buildInputs = [ git python ];
  antTargets = [ "jar" ];

  meta = {
    homepage = "https://github.com/WeAreWizards/passopolis-server";
    description = "A well-designed, well-functioning and secure secret manager.";
    license = stdenv.lib.licenses.gpl3;
  };
}
