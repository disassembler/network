let
  nixosFunc = (import <nixpkgs/nixos>);

in {
  #optina = (nixosFunc { configuration = ./optina; }).system;
  #portal = (nixosFunc { configuration = ./portal; }).system;
  sarov  = (nixosFunc { configuration = ./machines/sarov.nix; }).system;
}
