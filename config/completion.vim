" Unified built-in completion for modern Vim and the Vim 8/9.1 fallback.

if exists('*preinserted')
  set completeopt=menuone,preinsert
  highlight default link PreInsert Comment
else
  " Select the first item so Ctrl-f can accept it on Vim 8/9.1.
  set completeopt=menuone,noinsert
endif

function! s:PathToken(text)
  return substitute(matchstr(a:text, '\S\+$'), '^.*["''(=,]', '', '')
endfunction

function! s:LooksLikePath(text)
  if a:text =~# '<\/\?\k*$'
    return 0
  endif

  if a:text =~# '^\s*#\s*include\s*["<][^">]*$'
    return 1
  endif

  if a:text =~? '\<\%(src\|href\|action\|poster\|path\|file\|filename\)\s*=\s*["''][^"'']*$'
    return 1
  endif

  let token = s:PathToken(a:text)

  return token !~# '^\a\+://'
        \ && (
        \ token =~# '[/\\]'
        \ || token =~# '^\~'
        \ || token =~# '^\.\.\?$'
        \ || token =~# '^[A-Za-z]:'
        \ )
endfunction

" Adapter that lets modern Vim include filesystem paths in autocompletion.
function! s:PathComplete(findstart, base)
  if a:findstart
    let before = strpart(getline('.'), 0, col('.') - 1)
    let b:path_complete_active = s:LooksLikePath(before)

    return b:path_complete_active
          \ ? strlen(before) - strlen(s:PathToken(before))
          \ : col('.') - 1
  endif

  if !get(b:, 'path_complete_active', 0)
    return []
  endif

  let matches = getcompletion(a:base, 'file', 1)[0:19]

  return map(matches, '{"word": v:val, "kind": "F", "menu": "[path]"}')
endfunction

" Vim's bundled HTML completer returns uppercase tags directly after '<'.
function! s:HtmlOmniLower(findstart, base)
  if a:findstart
    let before = strpart(getline('.'), 0, col('.') - 1)
    let b:html_omni_tag_name = before =~# '<\/\?\k*$'

    return htmlcomplete#CompleteTags(a:findstart, a:base)
  endif

  let items = htmlcomplete#CompleteTags(a:findstart, a:base)

  if !get(b:, 'html_omni_tag_name', 0)
    return items
  endif

  let lowered = []

  for item in items
    if type(item) == type({})
      let out = copy(item)

      if get(out, 'word', '') !~# 'DOCTYPE'
        let out.word = tolower(out.word)

        if has_key(out, 'abbr')
          let out.abbr = tolower(out.abbr)
        endif
      endif

      call add(lowered, out)
    else
      call add(lowered, item =~# 'DOCTYPE' ? item : tolower(item))
    endif
  endfor

  return lowered
endfunction

function! s:UseLowerHtmlOmni()
  let &l:omnifunc = expand('<SID>').'HtmlOmniLower'
endfunction

augroup secure_vim_html_omni
  autocmd!
  autocmd FileType html,xhtml call <SID>UseLowerHtmlOmni()
augroup END

" Vim 9.2+: merge paths, omni, words, buffers, and tags automatically.
if exists('+autocomplete')
  set autocomplete
  set infercase
  set autocompletedelay=0

  let s:complete_sources =
        \ 'F'.expand('<SID>').'PathComplete,o^15,t^10,.^10,w^5,b^5,u^5'

  let &g:complete = s:complete_sources
  let &l:complete = s:complete_sources
endif

function! s:SmartComplete()
  if pumvisible()
    return "\<C-n>"
  elseif s:LooksLikePath(strpart(getline('.'), 0, col('.') - 1))
    return "\<C-x>\<C-f>"
  elseif !empty(&l:omnifunc)
    return "\<C-x>\<C-o>"
  endif

  return "\<C-n>"
endfunction

" Vim 8/9.1 fallback for Vim 9.2's native 'autocomplete' option.
let s:completion_timer = -1

function! s:LegacyAutoComplete(timer)
  let s:completion_timer = -1

  if mode() !=# 'i' || pumvisible()
    return
  endif

  " A failed completion can bump changedtick without changing visible text.
  let context = string([line('.'), col('.'), getline('.')])

  if get(b:, 'last_autocomplete_context', '') ==# context
    return
  endif

  let before = strpart(getline('.'), 0, col('.') - 1)

  if before =~# '\k$'
        \ || s:LooksLikePath(before)
        \ || !empty(&l:omnifunc)
    let b:last_autocomplete_context = context
    call feedkeys("\<C-n>", 'm')
  endif
endfunction

function! s:ScheduleLegacyComplete()
  if get(b:, 'suppress_autocomplete_once', 0)
    unlet b:suppress_autocomplete_once
    return
  endif

  if s:completion_timer != -1
    call timer_stop(s:completion_timer)
  endif

  " Zero-delay timer keeps completion immediate on Vim versions that
  " do not have the native 'autocomplete' option.
  let s:completion_timer = timer_start(
        \ 0,
        \ function('<SID>LegacyAutoComplete')
        \ )
endfunction

if !exists('+autocomplete') && has('timers')
  augroup secure_vim_legacy_autocomplete
    autocmd!
    autocmd TextChangedI * call <SID>ScheduleLegacyComplete()
  augroup END
endif

function! s:AcceptCompletion()
  if !pumvisible()
    return "\<C-f>"
  endif

  let b:suppress_autocomplete_once = 1

  if exists('*complete_info')
        \ && get(complete_info(), 'selected', -1) < 0
    return "\<C-n>\<C-y>"
  endif

  return "\<C-y>"
endfunction

" Ctrl-n opens contextual completion or selects the next visible candidate.
inoremap <expr> <C-n> <SID>SmartComplete()

" Ctrl-f accepts the selected candidate; otherwise it keeps Vim's default.
inoremap <expr> <C-f> <SID>AcceptCompletion()

" IMPORTANT:
" Do not map <Esc> in Insert mode.
"
" Terminal special keys such as arrows may be encoded as sequences beginning
" with Escape. Mapping raw <Esc> can cause Vim to consume the first byte and
" leave characters such as A/B/C/D behind as literal input.
