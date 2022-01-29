{ pkgs, config, lib, ... }:
let
  ip4 = config.networking.prod03.ipv4.address;
  ip6 = lib.head config.networking.prod03.ipv6.addresses;
in {
  sops.secrets."knot-keys.conf".owner = "knot";

  services.knot = {
    enable = true;
    keyFiles = [
      config.sops.secrets."knot-keys.conf".path
    ];
    extraConfig = ''
      server:
        listen: ${ip4}@53
        listen: ${ip6}@53

      mod-rrl:
        - id: default
          rate-limit: 200   # Allow 200 resp/s for each flow
          slip: 2           # Every other response slips

      remote:
        - id: prod01
          key: prod03
          address: 45.76.4.212

      acl:
        - id: prod01_acl
          address: 45.76.4.212
          key: prod03
          action: [transfer, notify]

      template:
        - id: default
          semantic-checks: on
          global-module: mod-rrl/default

        - id: slave
          master: prod01
          acl: [ prod01_acl ]

      zone:
        - domain: disasm.us
          template: slave
        - domain: samleathers.com
          template: slave
        - domain: marieleathers.com
          template: slave
        - domain: bower-law.com
          template: slave
        - domain: centrallakerealty.com
          template: slave
        - domain: theleathers.net
          template: slave
        - domain: centrefiber.us
          template: slave
        - domain: gentux.org
          template: slave
        - domain: meadowsinternet.us
          template: slave
        - domain: tracipropst.com
          template: slave
        - domain: themillennialhustle.com
          template: slave
        - domain: nixedge.com
          template: slave
        - domain: rats.fail
          template: slave
        - domain: _acme-challenge.lan.disasm.us
          template: slave
    '';
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
