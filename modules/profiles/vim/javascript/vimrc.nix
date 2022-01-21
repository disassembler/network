{ pkgs }:
''
  let g:ale_linters = { 'javascript': ['eslint'] }
  let g:ale_fixers = { 'javascript': ['eslint'] }
  let g:ale_fix_on_save = 1
  let g:ale_javascript_eslint_executable = '${pkgs.nodePackages.eslint}/bin/eslint'
  let g:airline#extensions#ale#enabled = 1
''
