{ pkgs, dev }:

let
  # this is the vimrc.nix from above
  vimrc   = pkgs.callPackage ./vimrc.nix { inherit dev;};

  # and the plugins.nix from above
  plugins = pkgs.callPackage ./plugins.nix { };
  dev_plugin_names = [
          "ale"
          #"deoplete-go"
          #"deoplete-rust"
          "vim-go"
          "vim_jsx"
          "vim_javascript"
          "vim-docbk"
          "vim-hoogle"
          "vim-docbk-snippets"
          "vim_stylish_haskell"
          #"haskell_vim"
          #"wakatime"
          "LanguageClient-neovim"
  ];
in
{
  customRC = vimrc;
  vam = {
    knownPlugins = pkgs.vimPlugins // plugins;
    pluginDictionaries = [
      {
        names = [
          "ctrlp"
          "fugitive"
          "surround"
          "vim-markdown"
          "gitgutter"
          "vim-nix"
          #"deoplete_nvim"
          "repeat"
          "nerdtree"
          "UltiSnips"
          #"vim-colorschemes"
          "vim-colors_atelier-schemes"
          "vim-lastplace"
          #"yankring"
          "splice_vim"
          "markdown_wiki"
          "tagbar"
          "confluence"
        ] ++ (pkgs.lib.optionals dev dev_plugin_names);
      }
    ];
  };
}
