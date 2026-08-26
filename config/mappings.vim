" Normal/visual mappings and plugin-free navigation replacements.

" Space-w writes the current buffer.
nnoremap <silent> <leader>w :write<CR>
" Space-q closes the current window, or Vim when it is the only window.
nnoremap <silent> <leader>q :quit<CR>
" Space-Shift-Q abandons changes and closes the current window.
nnoremap <silent> <leader>Q :quit!<CR>
" Space-d deletes without overwriting a register in normal mode.
nnoremap <leader>d "_d
" Space-d deletes without overwriting a register in visual mode.
xnoremap <leader>d "_d
" Visual J moves the selected lines downward and keeps them selected.
xnoremap J :move '>+1<CR>gv=gv
" Visual K moves the selected lines upward and keeps them selected.
xnoremap K :move '<-2<CR>gv=gv
" Y yanks from the cursor through the end of the line.
nnoremap Y yg$
" J joins lines without losing the current cursor position.
nnoremap J mzJ`z
" Ctrl-D scrolls down half a page and recenters the cursor.
nnoremap <C-d> <C-d>zz
" Ctrl-U scrolls up half a page and recenters the cursor.
nnoremap <C-u> <C-u>zz
" n finds the next match, centers it, and opens any containing fold.
nnoremap n nzzzv
" N finds the previous match, centers it, and opens any containing fold.
nnoremap N Nzzzv
" Q is disabled to prevent accidentally entering Ex mode.
nnoremap Q <Nop>
" Space-r prepares a whole-file replacement of the word under the cursor.
nnoremap <leader>r :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

if has('clipboard')
  set clipboard=unnamedplus
  " Space-y starts a normal-mode yank into the system clipboard.
  nnoremap <leader>y "+y
  " Space-y copies the visual selection into the system clipboard.
  xnoremap <leader>y "+y
  " Space-Shift-Y copies the entire current line into the system clipboard.
  nnoremap <leader>Y "+yy
  " Ctrl-V pastes the system clipboard after the cursor in normal mode.
  nnoremap <C-v> "+p
  " Ctrl-V replaces the visual selection with the system clipboard.
  xnoremap <C-v> "+p
  " Ctrl-V inserts the system clipboard in insert mode.
  inoremap <C-v> <C-r>+
  " Ctrl-C copies the current line to the system clipboard.
  nnoremap <C-c> "+yy
  " Ctrl-C copies the visual selection to the system clipboard.
  xnoremap <C-c> "+y
endif

" Space-f starts a recursive file search using the configured 'path'.
nnoremap <leader>f :find<Space>
" Space-b opens the buffer command with tab completion available.
nnoremap <leader>b :buffer<Space>
" Space-? opens the help command with tab completion available.
nnoremap <leader>? :help<Space>
" Space-e opens netrw in the current window.
nnoremap <silent> <leader>e :Explore<CR>
" Space-u displays the built-in undo history.
nnoremap <silent> <leader>u :undolist<CR>

function! s:LeaveNetrw()
  let netrw_buffer = bufnr('%')
  silent! Rexplore
  if &l:filetype ==# 'netrw' && bufnr('%') == netrw_buffer
    enew
  endif
endfunction

function! s:ConfigureNetrwKeys()
  " Escape returns from netrw to the previously edited file.
  nnoremap <buffer> <silent> <Esc> :call <SID>LeaveNetrw()<CR>
endfunction

augroup secure_vim_netrw_keys
  autocmd!
  autocmd FileType netrw call <SID>ConfigureNetrwKeys()
augroup END

" Space-I opens the quickfix list.
nnoremap <silent> <leader>I :copen<CR>
" ]i moves to the next quickfix result and recenters it.
nnoremap <silent> ]i :cnext<CR>zz
" [i moves to the previous quickfix result and recenters it.
nnoremap <silent> [i :cprevious<CR>zz
" ]I moves to the final quickfix result and recenters it.
nnoremap <silent> ]I :clast<CR>zz
" [I moves to the first quickfix result and recenters it.
nnoremap <silent> [I :cfirst<CR>zz
" Space-O opens the location list for the current window.
nnoremap <silent> <leader>O :lopen<CR>
" ]o moves to the next location-list result and recenters it.
nnoremap <silent> ]o :lnext<CR>zz
" [o moves to the previous location-list result and recenters it.
nnoremap <silent> [o :lprevious<CR>zz
" ]O moves to the final location-list result and recenters it.
nnoremap <silent> ]O :llast<CR>zz
" [O moves to the first location-list result and recenters it.
nnoremap <silent> [O :lfirst<CR>zz
" ]t searches forward for the next TODO-style annotation.
nnoremap <silent> ]t /\v<(TODO\|FIXME\|HACK\|WARN\|NOTE\|BUG)><CR>zz
" [t searches backward for the previous TODO-style annotation.
nnoremap <silent> [t ?\v<(TODO\|FIXME\|HACK\|WARN\|NOTE\|BUG)><CR>zz
" ]d moves to the next diff change and recenters it.
nnoremap <silent> ]d ]czz
" [d moves to the previous diff change and recenters it.
nnoremap <silent> [d [czz

" Local project search. git grep never contacts a remote.
if executable('git')
  set grepprg=git\ grep\ -n\ --no-color
  set grepformat=%f:%l:%m
endif
" Space-/ prompts for a project-local grep pattern.
nnoremap <leader>/ :grep!<Space>
" Space-i searches the project for the exact word under the cursor.
nnoremap <leader>i :execute 'silent grep! -w -- '.shellescape(expand('<cword>'))<CR>:copen<CR>

" gd jumps directly to the tag definition under the cursor.
nnoremap gd g<C-]>
" gD lists matching tag definitions when more than one exists.
nnoremap gD g]
" Space-l-f reindents the entire current buffer.
nnoremap <leader>lf mzgg=G`z
" Visual Space-l-f reindents only the selected lines.
xnoremap <leader>lf =

" mh stores the current exact location in cross-file global mark H.
nnoremap mh mH
" mj stores the current exact location in cross-file global mark J.
nnoremap mj mJ
" mk stores the current exact location in cross-file global mark K.
nnoremap mk mK
" ml stores the current exact location in cross-file global mark L.
nnoremap ml mL
" Space-h lists the four Harpoon-style global marks.
nnoremap <leader>h :marks H J K L<CR>
" Space-h-c clears all four Harpoon-style global marks.
nnoremap <silent> <leader>hc :delmarks HJKL<CR>
" Ctrl-H jumps to the exact location stored by mh and recenters it.
nnoremap <C-h> `Hzz
" Ctrl-J jumps to the exact location stored by mj and recenters it.
nnoremap <C-j> `Jzz
" Ctrl-K jumps to the exact location stored by mk and recenters it.
nnoremap <C-k> `Kzz
" Ctrl-L jumps to the exact location stored by ml and recenters it.
nnoremap <C-l> `Lzz

" Window-local project root: nearest .git, else the file's directory.
function! s:ProjectRoot()
  let dir = expand('%:p:h')
  let dotgit = finddir('.git', dir.';')
  if empty(dotgit) | let dotgit = findfile('.git', dir.';') | endif
  let root = empty(dotgit) ? dir : fnamemodify(dotgit, ':h')
  execute 'lcd '.fnameescape(root)
  pwd
endfunction
" Space-c-d changes this window to the current file's project root.
nnoremap <silent> <leader>cd :call <SID>ProjectRoot()<CR>
