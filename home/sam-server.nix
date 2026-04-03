{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./cli.nix
    ./vim.nix
    ./gpg.nix
  ];
  home = {
    username = "sam";
    homeDirectory = "/home/sam";

    stateVersion = "25.05";
  };
}
