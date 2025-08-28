{ lib, pkgs, ... }: {
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
