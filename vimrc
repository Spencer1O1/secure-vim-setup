" Plugin-free Vim setup for a trusted, closed development environment.
" No downloads, telemetry, AI, or third-party dependencies.

" In the repository, modules may sit beside vimrc.
" After installation they live under ~/.vim/config on Unix-like systems
" or ~/vimfiles/config on Windows.

let s:vimrc_dir = expand('<sfile>:p:h')
let s:adjacent_config = s:vimrc_dir.'/config'

if has('win32') || has('win64')
  let s:user_config = expand('~/vimfiles/config')
else
  let s:user_config = expand('~/.vim/config')
endif

if filereadable(s:adjacent_config.'/options.vim')
  let s:config_dir = s:adjacent_config
else
  let s:config_dir = s:user_config
endif

for s:module in [
      \ 'options.vim',
      \ 'theme.vim',
      \ 'mappings.vim',
      \ 'completion.vim',
      \ 'pairs.vim'
      \ ]
  let s:module_path = s:config_dir.'/'.s:module

  if filereadable(s:module_path)
    execute 'source '.fnameescape(s:module_path)
  else
    echoerr 'Missing Vim config module: '.s:module_path
  endif
endfor

unlet s:module_path
unlet s:module
unlet s:config_dir
unlet s:user_config
unlet s:adjacent_config
unlet s:vimrc_dir
