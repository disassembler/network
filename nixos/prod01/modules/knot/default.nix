{
  pkgs,
  config,
  lib,
  ...
}: let
  ip4 = config.networking.prod01.ipv4.address;
  ip6 = lib.head config.networking.prod01.ipv6.addresses;
in {
  sops.secrets."knot-keys.conf".owner = "knot";

  services.knot = {
    enable = true;
    keyFiles = [
      config.sops.secrets."knot-keys.conf".path
    ];
    settingsFile = pkgs.writeText "knot.conf" ''
      include: ${config.sops.secrets."knot-keys.conf".path}
      server:
        listen: ${ip4}@53
        listen: ${ip6}@53

      log:
        - target: syslog
          any: info
          server: debug
          zone: debug

      remote:
        - id: prod03
          key: prod03
          address: 45.63.23.13

      acl:
        - id: admin_xfr_acl
          address: 2601:985:4c82:4950:225e:5fbf:15ec:741e
          action: [transfer, notify]

        - id: prod03_acl
          address: 45.63.23.13
          key: prod03
          action: [transfer, notify]

        # ACME ACL for disasm.us - Strictly limited to its specific TXT record
        - id: acme_disasm_limited
          key: acme
          action: update
          update-type: [TXT]
          update-owner: name
          update-owner-match: equal
          update-owner-name: [_acme-challenge.lan.disasm.us.]

        # ACME ACL for bower-law.com - Strictly limited to its specific TXT record
        - id: acme_bower_limited
          key: bower-acme
          action: update
          update-type: [TXT]
          update-owner: name
          update-owner-match: equal
          update-owner-name: [_acme-challenge.lan.bower-law.com., _acme-challenge.udm.lan.bower-law.com.]

        # DDNS ACL for vpn.bower-law.com - Strictly limited to its specific A record
        - id: acl_udm_bridge_limited
          key: bower-udm
          action: update
          update-type: [A]
          update-owner: name
          update-owner-match: equal
          update-owner-name: [vpn.bower-law.com.]

      mod-rrl:
        - id: default
          rate-limit: 200
          slip: 2

      template:
        - id: default
          semantic-checks: on
          global-module: mod-rrl/default

        - id: master
          semantic-checks: on
          dnssec-signing: on
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
          notify: prod03
          acl: [ prod03_acl, admin_xfr_acl ]

        # Domains controlled by disasm
        - id: domain-disasm
          semantic-checks: on
          dnssec-signing: on
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
          notify: prod03
          acl: [ acme_disasm_limited, prod03_acl, admin_xfr_acl ]

        - id: domain-bower
          semantic-checks: on
          dnssec-signing: on
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
          notify: prod03
          acl: [ acme_bower_limited, acl_udm_bridge_limited, prod03_acl, admin_xfr_acl ]

      zone:
        - domain: disasm.us
          file: "${./disasm.us.zone}"
          template: domain-disasm

        - domain: bower-law.com
          file: "${./bower-law.com.zone}"
          template: domain-bower

        - domain: samleathers.com
          file: "${./samleathers.com.zone}"
          template: master

        - domain: marieleathers.com
          file: "${./marieleathers.com.zone}"
          template: master

        - domain: centrallakerealty.com
          file: "${./centrallakerealty.com.zone}"
          template: master

        - domain: theleathers.net
          file: "${./theleathers.net.zone}"
          template: master

        - domain: centrefiber.us
          file: "${./centrefiber.us.zone}"
          template: master

        - domain: gentux.org
          file: "${./gentux.org.zone}"
          template: master

        - domain: meadowsinternet.us
          file: "${./meadowsinternet.us.zone}"
          template: master

        - domain: tracipropst.com
          file: "${./tracipropst.com.zone}"
          template: master

        - domain: themillennialhustle.com
          file: "${./themillennialhustle.com.zone}"
          template: master

        - domain: nixedge.com
          file: "${./nixedge.com.zone}"
          template: master

        - domain: rats.fail
          file: "${./rats.fail.zone}"
          template: master
    '';
  };

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];
}
