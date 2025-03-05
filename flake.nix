{
  description = "Disassembler Network";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix.url = "github:NixOS/nix/2.18-maintenance";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # used for unifi and omadad
    nixpkgsLegacy.url = "github:NixOS/nixpkgs/nixos-23.11";
    #nixpkgs-2111.follows = "cardano-node/haskellNix/nixpkgs-2111";
    #nixpkgs-2105.follows = "cardano-node/haskellNix/nixpkgs-2105";
    cardano-node.url = "github:intersectmbo/cardano-node/10.1.4";
    credential-manager.url = "github:intersectmbo/credential-manager/0.1.0.0";
    hydra-doom.url = "github:cardano-scaling/hydra-doom";
    #cardano-node.inputs.nixpkgs.follows = "haskellNix/nixpkgs-2105";
    #cardano-addresses.url = "github:input-output-hk/cardano-addresses";
    #haskellNix.url = "github:input-output-hk/haskell.nix/14f740c7c8f535581c30b1697018e389680e24cb";
    #cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";
    adawallet.url = "github:input-output-hk/adawallet/node-8.10.0-pre";
    #cncli.url = "github:AndrewWestberg/cncli";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    deploy.url = "github:serokell/deploy-rs";
    colmena.url = "github:zhaofengli/colmena";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    styx.url = "github:disassembler/styx";
    neovim-flake.url = "github:johnalotoski/neovim-flake/autocmd-highlighting";
    vivarium.url = "github:nrdxp/vivarium";
    # Used for user packages and dotfiles
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows =
        "nixpkgs"; # Use system packages list where available
    };
    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.45.0";
    };
  };
  outputs = { ... } @ args: import ./outputs.nix args;
}
