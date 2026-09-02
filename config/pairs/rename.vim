" Rename the matching tag while a tag name is edited.

let s:renaming_tag = 0

function! s:SameTagName(a, b)
  return &l:filetype ==# 'xml' ? a:a ==# a:b : a:a ==? a:b
endfunction

function! s:FindGt(lnum, startcol)
  let lnum = a:lnum
  let col = a:startcol
  let quote = ''

  while lnum <= line('$')
    let line = getline(lnum)
    let i = col

    while i < strlen(line)
      let ch = line[i]

      if !empty(quote)
        if ch ==# quote
          let quote = ''
        endif
      elseif ch ==# '"' || ch ==# "'"
        let quote = ch
      elseif ch ==# '>'
        return [lnum, i]
      endif

      let i += 1
    endwhile

    let lnum += 1
    let col = 0
  endwhile

  return []
endfunction

function! s:ParseTagAt(lnum, idx)
  let line = getline(a:lnum)
  let rest = strpart(line, a:idx)

  if rest =~# '^<[!/?]' && rest !~# '^</'
    return {}
  endif

  let closing = rest =~# '^</'
  let name = matchstr(rest, '^</\?\zs[A-Za-z][A-Za-z0-9:_-]*')

  if empty(name)
    return {}
  endif

  let name_start = a:idx + (closing ? 2 : 1)
  let name_end = name_start + strlen(name)
  let gt = s:FindGt(a:lnum, name_end)

  if empty(gt)
    return {}
  endif

  let between = gt[0] == a:lnum
        \ ? strpart(line, name_end, gt[1] - name_end)
        \ : strpart(line, name_end)

  return {
        \ 'lnum': a:lnum,
        \ 'lt': a:idx,
        \ 'name': name,
        \ 'closing': closing,
        \ 'selfclose': between =~# '/\s*$',
        \ 'name_start': name_start,
        \ 'name_end': name_end,
        \ 'after_lnum': gt[0],
        \ 'after_col': gt[1] + 1
        \ }
endfunction

function! s:NextTag(lnum, col)
  let lnum = a:lnum
  let from = a:col

  while lnum <= line('$')
    let line = getline(lnum)
    let idx = match(line, '<[/]\?[A-Za-z]', from)

    while idx >= 0
      let tag = s:ParseTagAt(lnum, idx)

      if !empty(tag)
        return tag
      endif

      let from = idx + 1
      let idx = match(line, '<[/]\?[A-Za-z]', from)
    endwhile

    let lnum += 1
    let from = 0
  endwhile

  return {}
endfunction

function! s:PrevTag(lnum, col)
  let lnum = a:lnum
  let limit = a:col

  while lnum >= 1
    let line = getline(lnum)
    let from = 0
    let last = {}
    let idx = match(line, '<[/]\?[A-Za-z]', from)

    while idx >= 0 && idx < limit
      let tag = s:ParseTagAt(lnum, idx)

      if !empty(tag)
        let last = tag
      endif

      let from = idx + 1
      let idx = match(line, '<[/]\?[A-Za-z]', from)
    endwhile

    if !empty(last)
      return last
    endif

    let lnum -= 1
    let limit = lnum >= 1 ? strlen(getline(lnum)) : 0
  endwhile

  return {}
endfunction

function! s:FindClosing(info)
  if Pairs_IsVoid(a:info.name)
    return {}
  endif

  let gt = s:FindGt(a:info.lnum, a:info.name_end)

  if empty(gt)
    return {}
  endif

  let lnum = gt[0]
  let col = gt[1] + 1
  let depth = 1

  while 1
    let tag = s:NextTag(lnum, col)

    if empty(tag)
      return {}
    endif

    if s:SameTagName(tag.name, a:info.name) && !tag.selfclose
      if tag.closing
        let depth -= 1

        if depth == 0
          return tag
        endif
      else
        let depth += 1
      endif
    endif

    let lnum = tag.after_lnum
    let col = tag.after_col
  endwhile
endfunction

function! s:FindOpening(info)
  let lnum = a:info.lnum
  let col = a:info.lt
  let depth = 1

  while 1
    let tag = s:PrevTag(lnum, col)

    if empty(tag)
      return {}
    endif

    if s:SameTagName(tag.name, a:info.name) && !tag.selfclose
      if tag.closing
        let depth += 1
      else
        let depth -= 1

        if depth == 0
          return tag
        endif
      endif
    endif

    let lnum = tag.lnum
    let col = tag.lt
  endwhile
endfunction

function! s:EditedTag()
  if &paste || index(g:tag_autoclose_blacklist, &l:filetype) >= 0
    return {}
  endif

  let line = getline('.')
  let cursor = col('.')
  let prefix = strpart(line, 0, cursor)
  let lt = strridx(prefix, '<')

  if lt < 0
    return {}
  endif

  let rest = strpart(line, lt)

  if rest =~# '^<[!/?]' && rest !~# '^</'
    return {}
  endif

  if Pairs_InsideTagQuote(strpart(line, lt, cursor - lt))
    return {}
  endif

  let closing = rest =~# '^</'
  let name = matchstr(rest, '^</\?\zs[A-Za-z][A-Za-z0-9:_-]*')

  if empty(name)
    return {}
  endif

  let name_start = lt + (closing ? 2 : 1)
  let name_end = name_start + strlen(name)

  if cursor <= name_start || cursor > name_end + 1
    return {}
  endif

  return {
        \ 'closing': closing,
        \ 'name': name,
        \ 'lnum': line('.'),
        \ 'lt': lt,
        \ 'name_start': name_start,
        \ 'name_end': name_end
        \ }
endfunction

function! Pairs_RenameMatch()
  if s:renaming_tag || mode() !=# 'i'
    return
  endif

  let info = s:EditedTag()

  if empty(info)
    return
  endif

  let other = info.closing ? s:FindOpening(info) : s:FindClosing(info)

  if empty(other) || s:SameTagName(info.name, other.name)
    return
  endif

  let line = getline(other.lnum)
  let newline = strpart(line, 0, other.name_start)
        \ .info.name
        \ .strpart(line, other.name_end)
  let pos = getcurpos()
  let s:renaming_tag = 1
  silent! undojoin
  call setline(other.lnum, newline)
  call setpos('.', pos)
  let s:renaming_tag = 0
endfunction
