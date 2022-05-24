{
  description = "Disassembler Network";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix.url = "github:NixOS/nix/2.8.0";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-2111.follows = "cardano-node/haskellNix/nixpkgs-2111";
    nixpkgs-2105.follows = "cardano-node/haskellNix/nixpkgs-2105";
    cardano-node.url = "github:input-output-hk/cardano-node/karknu/fix_localrootpeers";
    #cardano-node.inputs.nixpkgs.follows = "haskellNix/nixpkgs-2105";
    #cardano-addresses.url = "github:input-output-hk/cardano-addresses";
    haskellNix.url = "github:input-output-hk/haskell.nix/14f740c7c8f535581c30b1697018e389680e24cb";
    #cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";
    #adawallet.url = "github:input-output-hk/adawallet";
    #adawallet.inputs.cardano-addresses.follows = "cardano-addresses";
    #adawallet.inputs.haskellNix.follows = "haskellNix";
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
