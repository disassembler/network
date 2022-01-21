{ self
, deploy
, ...
}:
let
  mkNode = server: ip: fast: {
    hostname = "${ip}:22";
    fastConnection = fast;
    profiles.system.path =
      deploy.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations.${server};
  };
in
{
  user = "root";
  sshUser = "root";
  nodes = {
    #optina = mkNode "optina" "10.40.33.20" true;
    portal = mkNode "portal" "10.40.33.1" true;
    #sarov  = mkNode "sarov" "10.40.33.189" true;
    #valaam = mkNode "valaam" "10.40.33.165" true;
    #prod01 = mkNode "prod01" "45.76.4.212" false;
  };
}
