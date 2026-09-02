" Transparent Tokyo Night palette and terminal UI.

if exists('+termguicolors')
  set termguicolors
endif

set background=dark

highlight clear

highlight Normal        guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE
highlight Comment       guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE cterm=italic gui=italic
highlight Constant      guifg=#ff9e64 guibg=NONE    ctermfg=215 ctermbg=NONE
highlight String        guifg=#9ece6a guibg=NONE    ctermfg=149 ctermbg=NONE
highlight Identifier    guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE
highlight Function      guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE
highlight Statement     guifg=#bb9af7 guibg=NONE    ctermfg=141 ctermbg=NONE
highlight Operator      guifg=#89ddff guibg=NONE    ctermfg=117 ctermbg=NONE
highlight PreProc       guifg=#7dcfff guibg=NONE    ctermfg=117 ctermbg=NONE
highlight Type          guifg=#2ac3de guibg=NONE    ctermfg=80  ctermbg=NONE
highlight Special       guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE
highlight Underlined    guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE cterm=underline gui=underline
highlight Error         guifg=#f7768e guibg=NONE    ctermfg=203 ctermbg=NONE
highlight Todo          guifg=#1a1b26 guibg=#e0af68 ctermfg=234 ctermbg=179 cterm=bold gui=bold

highlight LineNr        guifg=#3b4261 guibg=NONE    ctermfg=60  ctermbg=NONE
highlight CursorLineNr  guifg=#ff9e64 guibg=NONE    ctermfg=215 ctermbg=NONE cterm=bold gui=bold

highlight NonText       guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE term=NONE cterm=NONE gui=NONE
highlight EndOfBuffer   guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE term=NONE cterm=NONE gui=NONE

highlight CursorLine    guibg=#1f2335                ctermbg=235
highlight ColorColumn   guibg=#292e42                ctermbg=236
highlight Visual        guibg=#33467c                ctermbg=24

highlight Search        guifg=#c0caf5 guibg=#3d59a1 ctermfg=189 ctermbg=25
highlight IncSearch     guifg=#1a1b26 guibg=#ff9e64 ctermfg=234 ctermbg=215

highlight clear MatchParen
highlight MatchParen    guibg=#3b4261 ctermbg=60 cterm=bold gui=bold

highlight Pmenu         guifg=#c0caf5 guibg=#24283b ctermfg=189 ctermbg=235
highlight PmenuSel      guifg=#c0caf5 guibg=#33467c ctermfg=189 ctermbg=24 cterm=bold gui=bold
highlight PmenuSbar     guibg=#292e42                ctermbg=236
highlight PmenuThumb    guibg=#565f89                ctermbg=60

highlight StatusLine    guifg=#7aa2f7 guibg=#24283b ctermfg=111 ctermbg=235 cterm=bold gui=bold
highlight StatusLineNC  guifg=#565f89 guibg=#1f2335 ctermfg=60  ctermbg=235

highlight VertSplit     guifg=#292e42 guibg=NONE    ctermfg=236 ctermbg=NONE
highlight FoldColumn    guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE
highlight SignColumn    guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE
highlight Directory     guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE
highlight PreInsert     guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE cterm=italic gui=italic

highlight! link Character String
highlight! link Number Constant
highlight! link Boolean Constant
highlight! link Float Constant

highlight! link Conditional Statement
highlight! link Repeat Statement
highlight! link Keyword Statement
highlight! link Exception Statement

highlight! link Include PreProc
highlight! link Define PreProc
highlight! link Macro PreProc

highlight! link StorageClass Type
highlight! link Structure Type
highlight! link Typedef Type

highlight! link htmlSpecialTagName htmlTagName
highlight! link htmlEndTag htmlTag
highlight! link vimAugroupEnd Statement

" Normal/Visual: block; Insert: bar; Replace: underline.
"
" Do not manually override t_SI, t_SR, t_EI, t_ti, t_te, t_TI, t_TE,
" t_ks, or t_ke. Let Vim and the terminal negotiate those capabilities.
if exists('+guicursor')
  set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50,sm:block
endif

set laststatus=2
set statusline=%f\ %m%r%h%w%=%y\ %l:%c\ %p%%
