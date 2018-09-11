if builtins.pathExists ./secrets.nix then import ./secrets.nix else {
  prophet-openvpn-config = "";
  prophet-guest-openvpn-config = "";
  centrallake-openvpn-config = "";
  unifi_password_ro = "";
  alertmanager_smtp_pw = "";
  alertmanager_pushover_user = "";
  alertmanager_pushover_token = "";
  mpd_pw = "";
  mpd_icecast_pw = "";
  github_token = "";
}
