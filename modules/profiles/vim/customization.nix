{ pkgs }:

let
  # this is the vimrc.nix from above
  vimrc   = pkgs.callPackage ./vimrc.nix {};

  # and the plugins.nix from above
  plugins = pkgs.callPackage ./plugins.nix {};
in
{
  customRC = vimrc;
  vam = {
    knownPlugins = pkgs.vimPlugins // plugins;
    pluginDictionaries = [
      {
        names = [
          "vim-airline-themes"
          "ctrlp"
          "fugitive"
          "surround"
          "vim-markdown"
          "multiple-cursors"
          "syntastic"
          "gitgutter"
          "vim-nix"
          #"youcompleteme"
          "repeat"
          "nerdtree"
          "UltiSnips"
          "vimwiki"
          "vim-colorschemes"
          "vim-colors_atelier-schemes"
          "vim-lastplace"
          "vim-go"
          "yankring"
          "splice_vim"
          "vim_jsx"
          "vim_javascript"
          "vim_ps1"
          "vim-docbk"
          "vim-docbk-snippets"
        ];
      }
    ];
  };
}
