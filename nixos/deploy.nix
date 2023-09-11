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
    portal = mkNode "portal" "prophet.samleathers.com" true;
    sarov  = mkNode "sarov" "10.40.33.183" true;
    valaam = mkNode "valaam" "10.40.33.21" true;
    prod01 = mkNode "prod01" "45.76.4.212" false;
    prod03 = mkNode "prod03" "45.63.23.13" false;
  };
}
