{
  description = "Disassembler Network";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix.url = "github:NixOS/nix/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cardano-node.url = "github:input-output-hk/cardano-node/master";
    haskellNix.url = "github:input-output-hk/haskell.nix";
    #cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";
    adawallet.url = "github:input-output-hk/adawallet";
    cncli.url = "github:AndrewWestberg/cncli";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    deploy.url = "github:input-output-hk/deploy-rs";
    deploy.inputs.nixpkgs.follows = "fenix/nixpkgs";
    deploy.inputs.fenix.follows = "fenix";
    sops-nix.url = "github:Mic92/sops-nix";
    fenix.url = "github:nix-community/fenix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    styx.url = "github:disassembler/styx";
    neovim-flake.url = "github:disassembler/neovim-flake";
  };
  outputs = { ... } @ args: import ./outputs.nix args;
}
