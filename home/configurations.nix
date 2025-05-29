{ self
, nixpkgs
, home-manager
, inputs
, ...
}:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system; };
in
{
  sam = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      inputs.niri.homeModules.niri
      ./home.nix
      ./niri.nix
      ./hyprland.nix
      ./waybar.nix
    ];
  };
}
