{ pkgs, fetchgit }:

let
  buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
in {

  "vim-colors_atelier-schemes" = buildVimPlugin {
    name = "vim-colors_atelier-schemes";
    src = fetchgit {
      url = "https://github.com/atelierbram/vim-colors_atelier-schemes";
      rev = "633e723c4f2844dcf9437cb2275f1593fad9d608";
      sha256 = "1icv8zk6bkdicmi9nq9dg564d0d35mz5j7p4ax8q790mgq9i692l";
    };
    dependencies = [];
  };
  "vim-lastplace" = buildVimPlugin {
    name = "vim-lastplace";
    src = fetchgit {
      url = "https://github.com/farmergreg/vim-lastplace";
      rev = "36c4ae38130232134ece7bdd0e844d8034b585ab";
      sha256 = "09s0yvs8ylmj6zpp6k7nw4cric2flcdpy6k3i67nwm699lnd2f7i";
    };
    dependencies = [];
  };
  "splice_vim" = buildVimPlugin {
    name = "splice.vim";
    src = fetchgit {
      url = "https://github.com/sjl/splice.vim";
      rev = "c500afa9eed8c69527cd2b24401d12afb654d992";
      sha256 = "1697qfahs7y8yhh7kkfmhmq7n564cssb2i7w43gkc1ai5bp3llfa";
    };
    dependencies = [];
  };
  "vim_jsx" = buildVimPlugin {
    name = "vim-jsx";
    src = fetchgit {
      url = "https://github.com/mxw/vim-jsx";
      rev = "eb656ed96435ccf985668ebd7bb6ceb34b736213";
      sha256 = "1ydyifnfk5jfnyi4a1yc7g3b19aqi6ajddn12gjhi8v02z30vm65";
    };
    dependencies = [];
  };
  "vim_javascript" = buildVimPlugin {
    name = "vim-javascript";
    src = fetchgit {
      url = "https://github.com/pangloss/vim-javascript";
      rev = "2bca9c6f603a5bcdf6e7494158d178fb48c13f24";
      sha256 = "067iwsxmvz47fv8k0p4dzwaisnwx2xshzkvi81c85ma193wsn8ml";
    };
    dependencies = [];
  };
  "vimwiki" = buildVimPlugin {
    name = "vimwiki";
    src = fetchgit {
      url = "https://github.com/vimwiki/vimwiki";
      rev = "129c2818106bdb9230bbd99ee8eb81fa47c7a414";
      sha256 = "0ypm54h23sy5lyjj85q82z26xk88mqvyfhxw3zdrdxxjks68vi4b";
    };
    dependencies = [];
  };
  "vim_ps1" = buildVimPlugin {
    name = "vim-ps1";
    src = fetchgit {
      url = "https://github.com/PProvost/vim-ps1";
      rev = "dcdca6abb4db10fb6e7597d2e21a4a99952134ab";
      sha256 = "1ynkvgdwxjl9ci5bm3gm25kzzb3akff53mky0ssjyxj306r25wjp";
    };
    dependencies = [];
  };
  "vim_docbk" = buildVimPlugin {
    name = "vim-docbk";
    src = fetchgit {
      url = "https://github.com/jhradilek/vim-docbk";
      rev = "6ac0346ce96dbefe982b9e765a81c072997f2e9e";
      sha256 = "1jnx39m152hf9j620ygagaydg6h8m8gxkr1fmxj6kgqf71jr0n9d";
    };
    dependencies = [];
  };
  "jhradilek_snippets" = buildVimPlugin {
    name = "jhradilek_snippets";
    src = fetchgit {
      url = "https://github.com/jhradilek/vim-snippets";
      rev = "bf7e6742ac0a2ddc6bab5593bd2a2c6b75269bb8";
      sha256 = "1h7cp0p1z8r7w9bg2l79n5gg047xp8j8kg1xnn0finxqyb45lqif";
    };
    dependencies = [];
  };
}
