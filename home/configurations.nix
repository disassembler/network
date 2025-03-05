{ self
, nixpkgs
, home-manager
, hy3
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
      #hyprland.homeManagerModules.default
      {
        wayland.windowManager.hyprland = {
          enable = true;
          #plugins = [ hy3.packages.x86_64-linux.hy3 ];
        };
      }
      ./home.nix
    ];
  };
}
