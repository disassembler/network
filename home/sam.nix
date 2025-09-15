{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.niri.homeModules.niri
    ./niri.nix
    ./hyprland.nix
    ./waybar.nix
  ];
  programs = {
  };
  home = {
    packages = with pkgs; [
      hello
      cowsay
      ghostty
      fuzzel
      swaylock
      rofi
    ];

    username = "sam";
    homeDirectory = "/home/sam";

    stateVersion = "25.05";
  };
}
