{ stdenv, writeText, python, pkgs, dev }:

let
  generic = builtins.readFile ./vimrc/general.vim;
  haskell = pkgs.callPackage haskell/vimrc.nix { };
  javascript = pkgs.callPackage javascript/vimrc.nix { };
in

generic +
(pkgs.lib.optionalString dev ''
  " wakatime
  let g:wakatime_Binary = "${pkgs.wakatime}/bin/wakatime"
  let g:confluence_url = "https://input-output.atlassian.net/wiki/rest/api/content"
  let g:confluence_user = "samuel.leathers@iohk.io"
  let g:confluence_apikey = "fLo3kHsKgBitys99G3pCCEE2"

  ${haskell}
  ${javascript}
'')
