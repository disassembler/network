{ stdenv, antBuild, fetchgit, git, python }:

let
  version = "unstable-2016-05-07";
in antBuild {
  name = "passopolis-${version}";

  src = fetchgit {
    url = "https://github.com/WeAreWizards/passopolis-server";
    sha256 = "1gnksrc06j3sk8yg85ydk1b8vv0bwrmryxsldgiclc5i7lfs0x7s";
    rev = "b827b3a6176e050deb729009676fad7e86e5393a";
    leaveDotGit = true;
  };

  buildInputs = [ git python ];
  antTargets = [ "jar" ];

  postPatch = ''
    patchShebangs .
  '';

  meta = {
    homepage = "https://github.com/WeAreWizards/passopolis-server";
    description = "A well-designed, well-functioning and secure secret manager.";
    license = stdenv.lib.licenses.gpl3;
    maintainers = with stdenv.lib.maintainers; [ disassembler ];
  };
}
