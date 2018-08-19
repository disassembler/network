syntax enable
colorscheme Atelier_SeasideDark
hi Normal ctermbg=none

""" My settings:
" tab with two spaces
set nobackup
set noswapfile
set modeline
set modelines=2
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set smartcase
set autoindent
set nostartofline
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
set colorcolumn=85
set visualbell
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
" Change current directory to files directory
nnoremap ,cd :cd %:p:h<CR>:pwd<CR>
" Split window settings
" Map ,ev to open vimrc in split
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" Open new split with ,w
nnoremap <leader>n <C-w>v<C-w>l

" Movement around splits
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Map jj to esc key
inoremap jj <ESC>
let mapleader = ","    " Change leader key to ,

set mouse-=a
set cmdheight=2

set wildmenu
set showcmd

set number
set ruler
set backspace=indent,eol,start " Allows backspace on these character
set clipboard=unnamedplus

" Map esc to exit terminal mode
:tnoremap <Esc> <C-\><C-n>

" php
autocmd Filetype php setlocal tabstop=4 shiftwidth=4 softtabstop=4

" ruby
autocmd FileType ruby compiler ruby
filetype plugin on    " Enable filetype-specific plugins

" sshconfig
au BufNewFile,BufRead ssh_config,*/.ssh/config,*/.ssh/config.d/*.conf	setf sshconfig


" Those types
if has("user_commands")
command! -bang -nargs=? -complete=file E e<bang> <args>
command! -bang -nargs=? -complete=file W w<bang> <args>
command! -bang -nargs=? -complete=file Wq wq<bang> <args>
command! -bang -nargs=? -complete=file WQ wq<bang> <args>
command! -bang Wa wa<bang>
command! -bang WA wa<bang>
command! -bang Q q<bang>
command! -bang QA qa<bang>
command! -bang Qa qa<bang>
endif

" Relative numbering
function! NumberToggle()
if(&relativenumber == 1)
set nornu
set number
else
set rnu
endif
endfunc

" Toggle between normal and relative numbering.
nnoremap <leader>r :call NumberToggle()<cr>

" gitgutter settings
let g:gitgutter_max_signs = 2000

 " deoplete.
let g:deoplete#sources = {}
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#sources._ = ['buffer', 'file', 'omni', 'ultisnips']

" Highlight trailing whitespace, remove on save/quit
highlight ExtraWhitespace ctermbg=red guibg=red
au ColorScheme * highlight ExtraWhitespace guibg=red
au BufEnter * match ExtraWhitespace /\s\+$/
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhiteSpace /\s\+$/
au BufWritePre * %s/\s\+$//e
