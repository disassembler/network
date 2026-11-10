{
  appimageTools,
  fetchurl,
  lib,
}:
appimageTools.wrapType2 {
  pname = "es-de";
  version = "3.5.0";
  src = fetchurl {
    url = "https://packages.es-de.org/release/3.5.0/ES-DE_x64.AppImage";
    hash = "sha256-q8KZmhI4X4V3W9P5hvqJHHa2nfN5H3wS5MeDzzw2MPU=";
  };
  # ES-DE and child processes must see the host's declarative launcher configs.
  extraBwrapArgs = ["--ro-bind /etc/pechersk /etc/pechersk"];
  # Upstream binary dependencies are bundled. This is deliberately separate from
  # the removed Nixpkgs package; it does not fix that package's FreeImage issue.
  meta = {
    description = "Pinned upstream ES-DE console frontend";
    homepage = "https://es-de.org/";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "es-de";
  };
}
