{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.niri.homeModules.niri
    inputs.nixvim.homeModules.nixvim
    ./niri.nix
    ./hyprland.nix
    ./waybar.nix
    ./apps.nix
    ./cli.nix
    ./vim.nix
    ./gpg.nix
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
