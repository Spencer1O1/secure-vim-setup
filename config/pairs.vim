" Load pair modules, then bind insert-mode keys.

let s:dir = expand('<sfile>:p:h').'/pairs'

for s:name in ['brackets.vim', 'tags.vim', 'rename.vim']
  let s:path = s:dir.'/'.s:name

  if filereadable(s:path)
    execute 'source '.fnameescape(s:path)
  else
    echoerr 'Missing Vim config module: '.s:path
  endif
endfor

unlet s:path
unlet s:name
unlet s:dir

function! s:ApplyCollapse(bufnr, row, joined, col)
  if bufnr('%') != a:bufnr || mode() !=# 'i'
    return
  endif

  silent! undojoin
  execute a:row.',' . (a:row + 1) . 'delete _'
  call setline(a:row - 1, a:joined)
  call cursor(a:row - 1, a:col)
endfunction

function! Pairs_CollapseMultiline()
  let row = line('.')
  let cur = getline('.')

  if cur =~# '\S' || row < 2 || row >= line('$')
    return 0
  endif

  let prev = getline(row - 1)
  let nxt = getline(row + 1)
  let ok = 0

  if prev =~# '[(\[{]\s*$'
    let open = matchstr(prev, '[(\[{]\s*$')
    let open = open[0]
    let closers = {'(': ')', '[': ']', '{': '}'}

    if nxt =~# '^\s*'.escape(closers[open], ']').'\s*$'
      let ok = 1
    endif
  endif

  if !ok
    let opening = matchstr(
          \ prev,
          \ "<[A-Za-z]\\%([^<>\"']\\|\"[^\"]*\"\\|'[^']*'\\)*>\\s*$"
          \ )

    if empty(opening) || opening =~# '/>\s*$'
      return 0
    endif

    let tag = matchstr(opening, '^<\zs[A-Za-z][A-Za-z0-9:_-]*')
    let icase = &l:filetype ==# 'xml' ? '\C' : '\c'

    if nxt !~# icase.'^\s*</'.escape(tag, '\').'\s*>\s*$'
      return 0
    endif
  endif

  let prev_r = substitute(prev, '\s\+$', '', '')
  let next_l = substitute(substitute(nxt, '^\s*', '', ''), '\s\+$', '', '')
  let joined = prev_r.next_l
  let col = strlen(prev_r) + 1
  let bufnr = bufnr('%')

  if exists('*timer_start')
    call timer_start(0, {-> s:ApplyCollapse(bufnr, row, joined, col)})
    return ''
  endif

  return "\<C-o>dd\<C-o>0\<BS>"
endfunction

function! Pairs_Backspace()
  let collapse = Pairs_CollapseMultiline()

  if type(collapse) == type('')
    return collapse
  endif

  let pair = Pairs_CharBefore().Pairs_CharAfter()

  if index(['()', '[]', '{}', '""', "''"], pair) >= 0
    return "\<BS>\<Del>"
  endif

  let tag_widths = Pairs_MatchingTagPairWidths()

  if !empty(tag_widths)
    return repeat("\<BS>", tag_widths[0]).repeat("\<Del>", tag_widths[1])
  endif

  return "\<BS>"
endfunction

function! Pairs_Enter()
  let cancel = ''

  if pumvisible()
    let b:suppress_autocomplete_once = 1
    let cancel = "\<C-e>"
  endif

  let expand = Pairs_IsBracketPair()
        \ || (Pairs_CharBefore() ==# '>'
        \ && Pairs_CharAfter() ==# '<'
        \ && Pairs_IsMatchingTagPair())

  return cancel.(expand ? Pairs_StructuralNewline() : "\<CR>")
endfunction

inoremap <expr> ( Pairs_Open('(', ')')
inoremap <expr> [ Pairs_Open('[', ']')
inoremap <expr> { Pairs_Open('{', '}')
inoremap <expr> ) Pairs_Close(')')
inoremap <expr> ] Pairs_Close(']')
inoremap <expr> } Pairs_Close('}')
inoremap <expr> <Char-34> Pairs_Quote('"')
inoremap <expr> ' Pairs_Quote("'")
inoremap <expr> <BS> Pairs_Backspace()
inoremap <expr> > Pairs_CloseTag()
inoremap <expr> <CR> Pairs_Enter()

augroup secure_vim_tag_rename
  autocmd!
  autocmd TextChangedI * call Pairs_RenameMatch()
augroup END
