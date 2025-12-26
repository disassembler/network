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
    neovim-flake.url = "github:disassembler/neovim-flake/sl/rust";
    wled-sequencer.url = "github:disassembler/wled-sequencer";
    vivarium.url = "github:nrdxp/vivarium";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
    };
    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.45.0";
    };

    # nix and nixpkgs pins
    nix.url = "github:NixOS/nix/2.29.0";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # used for unifi
    nixpkgsLegacy.url = "github:NixOS/nixpkgs/nixos-23.11";

    nixvim.url = "github:nix-community/nixvim/nixos-25.11";

    niri.url = "github:sodiboo/niri-flake";

    # cardano stuff
    cardano-parts.url = "github:input-output-hk/cardano-parts/next-2025-08-14";
    adawallet.url = "github:input-output-hk/adawallet";
    adawallet.inputs.cardano-parts.follows = "cardano-parts";
    shadowharvester.url = "github:disassembler/shadowharvester/sl/defensio";

    # Styx static site generator
    # TODO: migrate to docusaurus?
    styx.url = "github:disassembler/styx";
  };

  outputs = {
    self,
    flake-parts,
    nixpkgs,
    ...
  } @ inputs: let
    inherit ((import ./flake/lib.nix {inherit inputs;}).flake.lib) recursiveImports;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports =
        recursiveImports [
          ./flake
          ./perSystem
        ]
        ++ [
          inputs.treefmt-nix.flakeModule
        ];
      systems = [
        "x86_64-linux"
      ];
    }
    // {
      inherit inputs;
    };
}
