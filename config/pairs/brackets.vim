" Character pairs: (), [], {}, quotes.

function! Pairs_CharBefore()
  let pos = col('.') - 1
  return pos > 0 ? strpart(getline('.'), pos - 1, 1) : ''
endfunction

function! Pairs_CharAfter()
  return strpart(getline('.'), col('.') - 1, 1)
endfunction

function! Pairs_Open(open, close)
  return a:open.a:close."\<Left>"
endfunction

function! Pairs_Close(close)
  return Pairs_CharAfter() ==# a:close ? "\<Right>" : a:close
endfunction

function! Pairs_Quote(quote)
  if Pairs_CharAfter() ==# a:quote
    return "\<Right>"
  elseif Pairs_CharBefore() ==# '\'
    return a:quote
  elseif a:quote ==# "'" && Pairs_CharBefore() =~# '\k'
    return a:quote
  endif

  return a:quote.a:quote."\<Left>"
endfunction

function! Pairs_StructuralNewline()
  let base_indent = indent('.')
  let inner_indent = base_indent + shiftwidth()

  " d0 removes automatic indentation without joining an empty line upward.
  return "\<CR>\<C-o>d0"
        \ .repeat(' ', inner_indent)
        \ ."\<CR>\<C-o>d0"
        \ .repeat(' ', base_indent)
        \ ."\<Up>\<End>"
endfunction

function! Pairs_IsBracketPair()
  return index(['()', '[]', '{}'], Pairs_CharBefore().Pairs_CharAfter()) >= 0
endfunction
