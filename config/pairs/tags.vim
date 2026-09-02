" Close tags on > and detect an adjacent opener/closer on one line.

let g:tag_autoclose_blacklist = get(
      \ g:,
      \ 'tag_autoclose_blacklist',
      \ ['c', 'cpp']
      \ )

let s:html_void = [
      \ 'area',
      \ 'base',
      \ 'br',
      \ 'col',
      \ 'embed',
      \ 'hr',
      \ 'img',
      \ 'input',
      \ 'link',
      \ 'meta',
      \ 'param',
      \ 'source',
      \ 'track',
      \ 'wbr'
      \ ]

function! Pairs_IsVoid(tag)
  return &l:filetype !=# 'xml' && index(s:html_void, tolower(a:tag)) >= 0
endfunction

function! Pairs_InsideTagQuote(fragment)
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

function! Pairs_MatchingTagPairWidths()
  let before = strpart(getline('.'), 0, col('.') - 1)
  let after = strpart(getline('.'), col('.') - 1)
  let opening = matchstr(
        \ before,
        \ "<[A-Za-z]\\%([^<>\"']\\|\"[^\"]*\"\\|'[^']*'\\)*>\\s*$"
        \ )

  if empty(opening) || opening =~# '/>\s*$'
    return []
  endif

  let tag = matchstr(opening, '^<\zs[A-Za-z][A-Za-z0-9:_-]*')

  if empty(tag)
    return []
  endif

  let closing = matchstr(
        \ after,
        \ (&l:filetype ==# 'xml' ? '\C' : '\c')
        \ .'^\s*</'.escape(tag, '\').'\s*>'
        \ )

  return empty(closing) ? [] : [strchars(opening), strchars(closing)]
endfunction

function! Pairs_IsMatchingTagPair()
  return !empty(Pairs_MatchingTagPairWidths())
endfunction

function! Pairs_CloseTag()
  if index(g:tag_autoclose_blacklist, &l:filetype) >= 0
    return '>'
  endif

  let line = getline('.')
  let split_at = col('.') - 1
  let before = strpart(line, 0, split_at)
  let after = strpart(line, split_at)
  let fragment = matchstr(before, '<[^<>]*$')

  if empty(fragment)
        \ || fragment =~# '^<\s*[!/?]'
        \ || fragment =~# '/\s*$'
        \ || Pairs_InsideTagQuote(fragment)
    return '>'
  endif

  let tag = matchstr(fragment, '^<\zs[A-Za-z][A-Za-z0-9:_-]*')

  if empty(tag)
    return '>'
  endif

  let existing_delimiter = strpart(after, 0, 1) ==# '>'
  let insert_delimiter = existing_delimiter ? "\<Right>" : "\<Char-62>"
  let after_delimiter = existing_delimiter ? strpart(after, 1) : after

  if Pairs_IsVoid(tag)
    return insert_delimiter
  endif

  if after_delimiter =~? '^\s*</'.escape(tag, '\').'\%([[:space:]>]\)'
    return insert_delimiter
  endif

  let closing = "\<Char-60>/".tag."\<Char-62>"
  return insert_delimiter.closing.repeat("\<Left>", strlen(tag) + 3)
endfunction
