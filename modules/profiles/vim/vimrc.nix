{ stdenv, writeText }:

let
    generic = builtins.readFile ./vimrc/general.vim;
    plug = import ./vimrc/pluginconfigurations.nix;
in

''
    ${generic}

    " ... more here

    ${plug}
''
