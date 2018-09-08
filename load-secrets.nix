if builtins.pathExists ./secrets.nix then import ./secrets.nix else {
  prophet-openvpn-config = "";
  prophet-guest-openvpn-config = "";
  centrallake-openvpn-config = "";
}
