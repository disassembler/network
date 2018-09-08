let
  nixosFuncStable = (import <nixpkgs-stable/nixos>);
  nixosFuncUnstable = (import <nixpkgs-unstable/nixos>);
  nixDarwinFuncUnstable = (import <nixdarwin-unstable>);
  #nix-darwin-tools = import ./.;

in {
  #inherit nix-darwin-tools;
  optina = (nixosFuncStable { configuration = ./optina; }).system;
  portal = (nixosFuncStable { configuration = ./portal; }).system;
  sarov  = (nixosFuncUnstable { configuration = ./machines/sarov.nix; }).system;
  ohrid  = (nixDarwinFuncUnstable { configuration = ./ohrid; }).system;
}
