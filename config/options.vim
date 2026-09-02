" Core options, recovery, and built-in filetype support.

set nocompatible

let mapleader = " "

set number
set relativenumber

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

set autoindent
set smartindent

set nowrap
set sidescroll=1
set sidescrolloff=8
set scrolloff=8

set colorcolumn=80
set foldlevel=99
set foldlevelstart=99

set incsearch
set nohlsearch
set ignorecase
set smartcase

set hidden
set splitbelow
set splitright

set wildmenu
set wildmode=longest:full,full

set path+=**
set tags=./tags;,tags

set updatetime=250

" Allow terminal key sequences enough time to arrive intact over SSH/tmux.
" This does not control autocomplete delay.
set ttimeout
set ttimeoutlen=100

" Allow Backspace across indentation, line boundaries, and text inserted
" since entering Insert mode.
set backspace=indent,eol,start

if exists('+signcolumn')
  set signcolumn=yes
endif

" Recovery and history stay on the authorized workstation.
set swapfile
set nobackup
set writebackup
set modeline
set noexrc

if has('win32') || has('win64')
  let s:vimstate = get(g:, 'vimstate_dir', expand('~/vimfiles'))
else
  let s:vimstate = get(g:, 'vimstate_dir', expand('~/.vim'))
endif

call mkdir(s:vimstate.'/swap', 'p')
let &directory = s:vimstate.'/swap//'

if has('persistent_undo')
  call mkdir(s:vimstate.'/undo', 'p')
  let &undodir = s:vimstate.'/undo//'
  set undofile
endif

unlet s:vimstate

" The palette is embedded in theme.vim, not installed as a colorscheme.
unlet! g:colors_name

syntax enable
filetype plugin indent on
