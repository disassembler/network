{ lib, pkgs, ... }: {
  programs = {
  };
  home = {
    packages = with pkgs; [
      hello
      cowsay
    ];

    username = "sam";
    homeDirectory = "/home/sam";

    stateVersion = "25.05";
  };
}
