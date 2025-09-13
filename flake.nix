{
  description = "Home Network Deployment";
  inputs = {
    # scaffolding for flake-parts and deployment
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    colmena.url = "github:zhaofengli/colmena";

    # personal configs
    neovim-flake.url = "github:disassembler/neovim-flake/sl/ollama";
    vivarium.url = "github:nrdxp/vivarium";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/d0bbd221482c2713cccb80220f3c9d16a6e20a33";
      inputs.nixpkgs.follows =
        "nixpkgs"; # Use system packages list where available
    };
    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.45.0";
    };

    # nix and nixpkgs pins
    nix.url = "github:NixOS/nix/2.29.0";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # used for unifi
    nixpkgsLegacy.url = "github:NixOS/nixpkgs/nixos-23.11";

    niri.url = "github:sodiboo/niri-flake/d5ccd8c5e6198bdac760ea65dd6c46e83a55b6f6?";

    # cardano stuff
    cardano-parts.url = "github:input-output-hk/cardano-parts/v2025-08-14";
    adawallet.url = "github:input-output-hk/adawallet";
    adawallet.inputs.cardano-parts.follows = "cardano-parts";

    # Styx static site generator
    # TODO: migrate to docusaurus?
    styx.url = "github:disassembler/styx";
  };

  outputs = { self, flake-parts, nixpkgs, ... }@ inputs: let
    inherit ((import ./flake/lib.nix {inherit inputs;}).flake.lib) recursiveImports;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = recursiveImports [
        ./flake
        ./perSystem
      ] ++ [
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
      ];
    };
}
