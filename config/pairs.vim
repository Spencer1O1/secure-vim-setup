" Bracket/quote pairs and universal tag closing.

function! s:CharBefore()
  let pos = col('.') - 1
  return pos > 0 ? strpart(getline('.'), pos - 1, 1) : ''
endfunction

function! s:CharAfter()
  return strpart(getline('.'), col('.') - 1, 1)
endfunction

function! s:OpenPair(open, close)
  return a:open.a:close."\<Left>"
endfunction

function! s:ClosePair(close)
  return s:CharAfter() ==# a:close ? "\<Right>" : a:close
endfunction

function! s:QuotePair(quote)
  if s:CharAfter() ==# a:quote
    return "\<Right>"
  elseif s:CharBefore() ==# '\'
    return a:quote
  elseif a:quote ==# "'" && s:CharBefore() =~# '\k'
    return a:quote
  endif
  return a:quote.a:quote."\<Left>"
endfunction

function! s:MatchingTagPairWidths()
  let before = strpart(getline('.'), 0, col('.') - 1)
  let after = strpart(getline('.'), col('.') - 1)
  " Attribute values may themselves contain < or > (common in templates).
  let opening = matchstr(before,
        \ "<[A-Za-z]\\%([^<>\"']\\|\"[^\"]*\"\\|'[^']*'\\)*>\\s*$")
  if empty(opening) || opening =~# '/>\s*$'
    return []
  endif
  let tag = matchstr(opening, '^<\zs[A-Za-z][A-Za-z0-9:_-]*')
  if empty(tag)
    return []
  endif
  let closing_pattern = '^\s*</'.escape(tag, '\').'\s*>'
  " XML names are case-sensitive; HTML-like names are not.
  let closing = matchstr(after,
        \ (&l:filetype ==# 'xml' ? '\C' : '\c').closing_pattern)
  return empty(closing) ? [] : [strchars(opening), strchars(closing)]
endfunction

function! s:PairBackspace()
  let pair = s:CharBefore().s:CharAfter()
  if index(['()', '[]', '{}', '""', "''"], pair) >= 0
    return "\<BS>\<Del>"
  endif
  let tag_widths = s:MatchingTagPairWidths()
  if !empty(tag_widths)
    return repeat("\<BS>", tag_widths[0]).repeat("\<Del>", tag_widths[1])
  endif
  return "\<BS>"
endfunction

function! s:IsMatchingTagPair()
  return !empty(s:MatchingTagPairWidths())
endfunction

function! s:IsStructuralPair()
  if index(['()', '[]', '{}'], s:CharBefore().s:CharAfter()) >= 0
    return 1
  endif
  return s:CharBefore() ==# '>' && s:CharAfter() ==# '<'
        \ && s:IsMatchingTagPair()
endfunction

function! s:StructuralNewline()
  let base_indent = indent('.')
  let inner_indent = base_indent + shiftwidth()
  " d0 removes automatic indentation without joining an empty line upward.
  return "\<CR>\<C-o>d0".repeat(' ', inner_indent)
        \ ."\<CR>\<C-o>d0".repeat(' ', base_indent)."\<Up>\<End>"
endfunction

function! s:SmartEnter()
  let cancel = ''
  if pumvisible()
    let b:suppress_autocomplete_once = 1
    let cancel = "\<C-e>"
  endif
  return cancel.(s:IsStructuralPair() ? s:StructuralNewline() : "\<CR>")
endfunction

function! s:InsideTagQuote(fragment)
  let quote = ''
  let escaped = 0
  for char in split(a:fragment, '\zs')
    if escaped
      let escaped = 0
    elseif char ==# '\'
      let escaped = 1
    elseif empty(quote) && (char ==# '"' || char ==# "'")
      let quote = char
    elseif char ==# quote
      let quote = ''
    endif
  endfor
  return !empty(quote)
endfunction

" Tag closing is universal by default; exclude ambiguous language grammars.
let g:tag_autoclose_blacklist = get(g:, 'tag_autoclose_blacklist', ['c', 'cpp'])

function! s:CloseTag()
  if index(g:tag_autoclose_blacklist, &l:filetype) >= 0
    return '>'
  endif
  let line = getline('.')
  let split_at = col('.') - 1
  let before = strpart(line, 0, split_at)
  let after = strpart(line, split_at)
  let fragment = matchstr(before, '<[^<>]*$')
  if empty(fragment) || fragment =~# '^<\s*[!/?]'
        \ || fragment =~# '/\s*$' || s:InsideTagQuote(fragment)
    return '>'
  endif
  " No whitespace after '<': avoids treating ordinary `a < b` as markup.
  let tag = matchstr(fragment, '^<\zs[A-Za-z][A-Za-z0-9:_-]*')
  if empty(tag)
    return '>'
  endif
  let html_void = ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
        \ 'link', 'meta', 'param', 'source', 'track', 'wbr']
  let existing_delimiter = strpart(after, 0, 1) ==# '>'
  let insert_delimiter = existing_delimiter ? "\<Right>" : "\<Char-62>"
  let after_delimiter = existing_delimiter ? strpart(after, 1) : after
  if &l:filetype !=# 'xml' && index(html_void, tolower(tag)) >= 0
    return insert_delimiter
  endif
  if after_delimiter =~? '^\s*</'.escape(tag, '\'). '\%([[:space:]>]\)'
    return insert_delimiter
  endif
  let closing = "\<Char-60>/".tag."\<Char-62>"
  let closing_width = strlen(tag) + 3
  return insert_delimiter.closing.repeat("\<Left>", closing_width)
endfunction

" ( inserts a matching parenthesis and leaves the cursor between the pair.
inoremap <expr> ( <SID>OpenPair('(', ')')
" [ inserts a matching bracket and leaves the cursor between the pair.
inoremap <expr> [ <SID>OpenPair('[', ']')
" { inserts a matching brace and leaves the cursor between the pair.
inoremap <expr> { <SID>OpenPair('{', '}')
" ) moves over an existing paired parenthesis instead of duplicating it.
inoremap <expr> ) <SID>ClosePair(')')
" ] moves over an existing paired bracket instead of duplicating it.
inoremap <expr> ] <SID>ClosePair(']')
" } moves over an existing paired brace instead of duplicating it.
inoremap <expr> } <SID>ClosePair('}')
" Double quote inserts or moves over a context-aware matching quote.
inoremap <expr> <Char-34> <SID>QuotePair('"')
" Single quote inserts or moves over a context-aware matching quote.
inoremap <expr> ' <SID>QuotePair("'")
" Backspace removes both sides of an empty character pair or adjacent tag pair.
inoremap <expr> <BS> <SID>PairBackspace()
" > closes tag-shaped text or moves over an existing tag delimiter.
inoremap <expr> > <SID>CloseTag()
" Enter expands an empty structural pair and cancels completion if necessary.
inoremap <expr> <CR> <SID>SmartEnter()
