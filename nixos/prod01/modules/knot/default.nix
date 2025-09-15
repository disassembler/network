{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  ip4 = config.networking.prod01.ipv4.address;
  ip6 = lib.head config.networking.prod01.ipv6.addresses;
  acmeChallenge = domain:
    pkgs.writeText "_acme-challenge.${domain}.zone" ''
      @ 3600 IN SOA _acme-challenge.${domain}. root.disasm.us. 2022012801 7200 3600 86400 3600

      $TTL 30

      @ IN NS ns1.disasm.us.
    '';
  dyndns = domain:
    pkgs.writeText "${domain}.zone" ''
      @ 3600 IN SOA ${domain}. root.disasm.us. 2022012101 7200 3600 86400 3600

      $TTL 300

      @ IN NS ns1.disasm.us.
    '';
in {
  sops.secrets."knot-keys.conf".owner = "knot";

  services.knot = {
    enable = true;
    keyFiles = [
      # TODO this doesn't work with settingsFile
      config.sops.secrets."knot-keys.conf".path
    ];
    settingsFile = pkgs.writeText "knot.conf" ''
      include: ${config.sops.secrets."knot-keys.conf".path}
      server:
        listen: ${ip4}@53
        listen: ${ip6}@53

      remote:
        - id: prod03
          key: prod03
          address: 45.63.23.13

      acl:
        - id: pskov_acl
          address: 2601:98a:4100:3567:8a18:511a:31ad:95b5
          action: [transfer, notify]

        - id: prod03_acl
          address: 45.63.23.13
          key: prod03
          action: [transfer, notify]

        - id: optina_acl
          key: optina
          action: update

        - id: portal_acl
          key: portal
          action: update

        - id: valaam_acl
          key: valaam
          action: update

        - id: acme_acl
          key: acme
          action: update


      mod-rrl:
        - id: default
          rate-limit: 200   # Allow 200 resp/s for each flow
          slip: 2           # Every other response slips

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
          acl: [ prod03_acl, pskov_acl ]

        - id: dyndns
          semantic-checks: on
          dnssec-signing: on
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
          notify: prod03
          acl: [ acme_acl, prod03_acl, pskov_acl ]

        - id: acme
          semantic-checks: on
          dnssec-signing: on
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
          notify: prod03
          acl: [ acme_acl, prod03_acl, pskov_acl ]


      zone:
        - domain: disasm.us
          file: "${./disasm.us.zone}"
          template: master
        - domain: samleathers.com
          file: "${./samleathers.com.zone}"
          template: master
        - domain: marieleathers.com
          file: "${./marieleathers.com.zone}"
          template: master
        - domain: bower-law.com
          file: "${./bower-law.com.zone}"
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
        - domain: _acme-challenge.lan.disasm.us
          file: "${acmeChallenge "lan.disasm.us"}"
          template: acme
    '';
  };

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];
}
