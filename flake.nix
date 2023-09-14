{
  description = "Disassembler Network";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix.url = "github:NixOS/nix/2.17-maintenance";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    #nixpkgs-2111.follows = "cardano-node/haskellNix/nixpkgs-2111";
    #nixpkgs-2105.follows = "cardano-node/haskellNix/nixpkgs-2105";
    cardano-node.url = "github:input-output-hk/cardano-node/8.1.2";
    #cardano-node.inputs.nixpkgs.follows = "haskellNix/nixpkgs-2105";
    #cardano-addresses.url = "github:input-output-hk/cardano-addresses";
    #haskellNix.url = "github:input-output-hk/haskell.nix/14f740c7c8f535581c30b1697018e389680e24cb";
    #cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";
    adawallet.url = "github:input-output-hk/adawallet";
    #cncli.url = "github:AndrewWestberg/cncli";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    deploy.url = "github:serokell/deploy-rs";
    colmena.url = "github:zhaofengli/colmena";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    styx.url = "github:disassembler/styx";
    neovim-flake.url = "github:disassembler/neovim-flake";
    vivarium.url = "github:nrdxp/vivarium";
  };
  outputs = { ... } @ args: import ./outputs.nix args;
}
