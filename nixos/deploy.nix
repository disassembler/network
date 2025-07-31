{ self
, deploy
, ...
}:
let
  mkNode = server: ip: fast: {
    hostname = "${ip}";
    fastConnection = fast;
    profiles.system.path =
      deploy.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations."${server}";
  };
in
{
  user = "root";
  sshUser = "root";
  nodes = {
    optina = mkNode "optina" "10.40.33.20" true;
    iviron = mkNode "iviron" "10.40.33.133" true;
    irkutsk = mkNode "irkutsk" "10.40.33.191" true;
    #portal = mkNode "portal" "portal.lan.disasm.us" true;
    portal = mkNode "portal" "10.40.33.1" false;
    sarov  = mkNode "sarov" "10.40.33.40" true;
    valaam = mkNode "valaam" "10.40.33.21" true;
    prod01 = mkNode "prod01" "prod01.samleathers.com" false;
    prod03 = mkNode "prod03" "45.63.23.13" false;
  };
}
