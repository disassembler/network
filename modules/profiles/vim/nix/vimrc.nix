{ pkgs }:

let
  #hnix-lsp = "${pkgs.hnix-lsp}/bin/hnix-lsp";
  hnix-lsp = "/bin/false";
in
''
  let g:LanguageClient_serverCommands = {
  \ 'nix': ['${hnix-lsp}', '-d', '--lsp'],
  \ }
''
