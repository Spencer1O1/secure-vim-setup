" Core options, recovery, and built-in filetype support.

set nocompatible
let mapleader = " "

set number relativenumber
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set autoindent smartindent
set nowrap sidescroll=1 sidescrolloff=8 scrolloff=8
set colorcolumn=80 foldlevel=99 foldlevelstart=99
set incsearch nohlsearch ignorecase smartcase
set hidden splitbelow splitright
set wildmenu wildmode=longest:full,full
set path+=**
set tags=./tags;,tags
set updatetime=250
" Do not delay a literal Escape while waiting for terminal keycode bytes.
set ttimeout ttimeoutlen=10
if exists('+signcolumn') | set signcolumn=yes | endif

" Recovery and history stay on the authorized workstation.
set swapfile nobackup writebackup modeline noexrc
let s:vimstate = get(g:, 'vimstate_dir', expand('~/.vim'))
call mkdir(s:vimstate.'/swap', 'p')
let &directory = s:vimstate.'/swap//'
if has('persistent_undo')
  call mkdir(s:vimstate.'/undo', 'p')
  let &undodir = s:vimstate.'/undo//'
  set undofile
endif

" The palette is embedded in theme.vim, not installed as a colorscheme.
unlet! g:colors_name
syntax enable
filetype plugin indent on
