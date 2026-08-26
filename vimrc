" Plugin-free Vim setup for a trusted, closed development environment.
" No downloads, telemetry, AI, or third-party dependencies.

" In this repository modules sit beside vimrc. After installation they live
" under ~/.vim/config, next to ~/.vimrc rather than beneath it.
let s:vimrc_dir = expand('<sfile>:p:h')
let s:adjacent_config = s:vimrc_dir.'/config'
let s:user_config = has('win32') || has('win64')
      \ ? expand('~/vimfiles/config') : expand('~/.vim/config')
let s:config_dir = filereadable(s:adjacent_config.'/options.vim')
      \ ? s:adjacent_config : s:user_config

for s:module in ['options.vim', 'theme.vim', 'mappings.vim',
      \ 'completion.vim', 'pairs.vim']
  let s:module_path = s:config_dir.'/'.s:module
  if filereadable(s:module_path)
    execute 'source '.fnameescape(s:module_path)
  else
    echoerr 'Missing Vim config module: '.s:module_path
  endif
endfor

unlet s:module_path s:module s:config_dir s:user_config s:adjacent_config s:vimrc_dir
