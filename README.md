# Closed-intranet Vim setup

This is a plugin-free translation of the Neovim setup in
`C:\Users\spencerls\dotfiles\nvim`. It targets ordinary Vim 8/9 and does not
download anything, run telemetry, call AI services, or invoke shell commands at
startup.

It assumes the workstation, user profile, repositories, and system clipboard
are all inside the authorized environment. Normal Vim recovery and history are
therefore enabled. Software approval still governs third-party plugins and
external tools.

## Retype it safely

1. Create the module directory with `:call mkdir(expand('~/.vim/config'), 'p')`
   from inside Vim. On native Windows Vim, create `~/vimfiles/config` instead;
   [`vimrc`](./vimrc) selects the appropriate location automatically.
2. Retype [`vimrc`](./vimrc) as `~/.vimrc` (or `$HOME/_vimrc` on Windows).
3. Retype the files under [`config`](./config) into `~/.vim/config`, preserving
   these names: `options.vim`, `theme.vim`, `mappings.vim`, `completion.vim`,
   and `pairs.vim`. Comments beginning with `"` are optional.
4. After completing each module, open it in Vim and run `:source %`. After all
   five exist, run `:source ~/.vimrc`. Fix the first reported line before
   continuing.
5. Run `:version`, `:scriptnames`, and `:checkhealth` only if available.
   (`:checkhealth` is normally Neovim-only.)
6. Open a disposable file and test save, search, quickfix, explorer, pins, and
   indentation before using the config on controlled source.

For a short first session, create only `options.vim` and `theme.vim`; the loader
will report the other missing modules until they are added. Those first two
provide editing defaults, recovery/history, syntax, indentation, and UI.

## What carries over

| Neovim feature | Stock Vim replacement | Main keys |
| --- | --- | --- |
| Telescope files/buffers/help | `:find`, `:buffer`, `:help` with tab completion | `<Space>f`, `<Space>b`, `<Space>?` |
| Telescope live grep | approved local `git grep` through quickfix | `<Space>/`, `<Space>i`, `[i`, `]i`, `<Space>I` |
| Oil | bundled netrw | `<Space>e` |
| Harpoon | global marks H/J/K/L | `mh/mj/mk/ml`, `<C-h/j/k/l>`, `<Space>h`, `<Space>hc` |
| Trouble | quickfix and location-list windows | `<Space>I`, `<Space>O`, `[i/o`, `]i/o` |
| todo-comments | forward/backward regex search | `[t`, `]t` |
| Undotree | built-in undo list | `<Space>u`, then normal `:earlier`/`:later` |
| LSP definitions | generated tags | `gd`, `gD`, `<C-t>` to return |
| LSP references | exact-word local grep | `<Space>i` |
| cmp path/buffer completion | Unified built-in completion UI | `<C-n>/<C-p>` navigate, `<C-f>` accept |
| Conform formatting | Vim's indent expression | `<Space>lf` |
| Treesitter highlighting/indent | bundled syntax and filetype scripts | automatic |
| diff navigation | Vim diff navigation | `[d`, `]d` |

## Deliberately not carried over

- `99`, Supermaven, and WakaTime: external data/telemetry boundaries.
- lazy.nvim and every third-party plugin: supply-chain and installation scope.
- Automatic format-on-save: it requires separately installed executables and
  can make broad changes. Use an approved project formatter through the build
  system when available.

## Local state

- Swap files live under `~/.vim/swap` for crash recovery.
- Persistent undo lives under `~/.vim/undo`.
- Viminfo and netrw history use their normal locations and preserve useful
  commands, searches, marks, registers, and recently visited directories.
- `clipboard=unnamedplus` matches the home setup when Vim has clipboard support.
  On such builds, `<Space>y` yanks a motion/selection and `<Space>Y` yanks the
  current line directly to the system clipboard. Builds reporting `-clipboard`
  cannot provide these mappings natively.
- A self-contained Tokyo Night-style palette needs no colorscheme files.
- The cursor is a block in normal/visual mode, a bar in insert mode, and an
  underline in replace mode when the terminal supports cursor-shape escapes.

## Useful stock-Vim capabilities

- `:make` populates quickfix when the project's approved build tool and
  `makeprg` are configured.
- `:copen`, `:colder`, and `:cnewer` inspect and move between result sets.
- `:set omnifunc?` shows whether the bundled filetype runtime provides omni
  completion. Vim 9.2+ opens a single menu with no configured delay, combining
  paths, omni results, tags, and buffer words in that priority order. Path
  entries are marked `[path]`. Use `<C-n>/<C-p>` to
  navigate, `<C-f>` to accept, and `<C-e>` or `<Esc>` to dismiss while staying
  in insert mode. With no menu visible, `<Esc>` leaves insert mode. Highlighted
  preinserted text provides a ghost-text-like preview.
- Vim 8 and 9.1 use a zero-delay timer fallback to open the same contextual
  menu automatically. These versions cannot show native ghost text. If Vim was
  built without timers, `<C-n>` opens it manually. For ambiguous bare
  filenames, `<C-x><C-f>` remains an explicit fallback.
- HTML and XHTML use their bundled omni completer with standard tag-name
  results normalized to lowercase. XML remains case-sensitive and unchanged.
- `<Space>e` opens netrw in the current window. Inside netrw, `<Esc>` returns
  to the previously edited file without selecting an entry.
- Insert mode automatically pairs `()`, `[]`, `{}`, `""`, and `''`. Typing an
  existing closer moves over it, and Backspace inside an empty pair removes both
  characters. Typing `>` after a tag-shaped `<name...` inserts its matching
  closing tag in every filetype except `c` and `cpp`; edit
  `g:tag_autoclose_blacklist` to add exclusions. Closing tags, self-closing
  tags, quoted attribute values, and HTML void elements are left alone.
- Pressing Enter between `()`, `[]`, `{}`, or matching opening/closing tags
  expands them to three lines, indents the cursor one `shiftwidth`, and aligns
  the closer with the opener. If completion is visible, Enter cancels it first.
- `mh`, `mj`, `mk`, and `ml` set cross-file global marks H/J/K/L. The matching
  Ctrl key jumps to the exact stored location; `<Space>h` lists them and
  `<Space>hc` clears them.
- A project-generated `tags` file enables `gd`/`gD`. Do not add a tag generator
  unless that executable and workflow are approved.
- `:set paste` can help when pasting is permitted; turn it back off with
  `:set nopaste` immediately afterward.

## Environment assumptions

The Vim runtime, user profile, repositories, clipboard, local Git commands,
source-derived tag files, and build artifacts are assumed to remain inside the
approved workstation boundary. Anything that communicates outside that boundary
still needs explicit approval.
