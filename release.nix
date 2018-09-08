let
  nixosFuncStable = (import <nixpkgs-stable/nixos>);
  nixosFuncUnstable = (import <nixpkgs-unstable/nixos>);

in {
  optina = (nixosFuncStable { configuration = ./optina; }).system;
  portal = (nixosFuncStable { configuration = ./portal; }).system;
  sarov  = (nixosFuncUnstable { configuration = ./machines/sarov.nix; }).system;
}
