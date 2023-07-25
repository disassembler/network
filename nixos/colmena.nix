{ self
, nixpkgs
, deploy
, ...
}:
let
  mkNode = server: ip: fast: {
    imports = [self.nixosConfigurations."${server}".config];
    deployment.targetHost = ip;
    deployment.targetPort = 22;
    deployment.targetUser = "root";
    };
in
{
  meta = {
    nixpkgs = import nixpkgs {
      system = "x86_64-linux";
    };
  };
  portal = mkNode "portal" "10.40.33.1" true;
  sarov  = mkNode "sarov" "10.40.33.183" true;
  valaam = mkNode "valaam" "10.40.33.21" true;
  prod01 = mkNode "prod01" "45.76.4.212" false;
  prod03 = mkNode "prod03" "45.63.23.13" false;
}
