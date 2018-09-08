if builtins.pathExists ./secrets.nix then import ./secrets.nix else {
  prophet-openvpn-config = "";
  prophet-gueest-openvpn-config = "";
  centrallake-openvpn-config = "";
}
