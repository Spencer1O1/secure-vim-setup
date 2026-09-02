# Closed-intranet Vim setup

This is a plugin-free translation of the Neovim setup in
`dotfiles`. It targets ordinary Vim 8/9 and does not
download anything, run telemetry, call AI services, or invoke shell commands at
startup.

It assumes the workstation, user profile, repositories, and system clipboard
are all inside the authorized environment. Normal Vim recovery and history are
therefore enabled. Software approval still governs third-party plugins and
external tools.

Key notation uses `<Leader>` rather than hardcoding its physical key. This
configuration currently sets Leader to Space with `let mapleader = " "`.

## Retype it safely

1. Create the module directory with `:call mkdir(expand('~/.vim/config'), 'p')`
   from inside Vim. On native Windows Vim, create `~/vimfiles/config` instead;
   [`vimrc`](./vimrc) selects the appropriate location automatically.
2. Retype [`vimrc`](./vimrc) as `~/.vimrc` (or `$HOME/_vimrc` on Windows).
3. Retype the files under [`config`](./config) into `~/.vim/config`, preserving
   these names: `options.vim`, `theme.vim`, `mappings.vim`, `completion.vim`,
   `pairs.vim`, and the `pairs/` directory (`brackets.vim`, `tags.vim`,
   `rename.vim`). Comments beginning with `"` are optional.
4. After completing each module, open it in Vim and run `:source %`. After the
   top-level modules exist, run `:source ~/.vimrc`. Fix the first reported line
   before continuing. `pairs.vim` sources `pairs/` itself.
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
| Telescope files/buffers/help | `:find`, `:buffer`, `:help` with tab completion | `<Leader>f`, `<Leader>b`, `<Leader>?` |
| Telescope live grep | approved local `git grep` through quickfix | `<Leader>/`, `<Leader>i`, `[i`, `]i`, `<Leader>I` |
| Oil | bundled netrw | `<Leader>e` |
| Harpoon | global marks H/J/K/L | `mh/mj/mk/ml`, `<C-h/j/k/l>`, `<Leader>h`, `<Leader>hc` |
| Trouble | quickfix and location-list windows | `<Leader>I`, `<Leader>O`, `[i/o`, `]i/o` |
| todo-comments | forward/backward regex search | `[t`, `]t` |
| Undotree | built-in undo list | `<Leader>u`, then normal `:earlier`/`:later` |
| LSP definitions | generated tags | `gd`, `gD`, `<C-t>` to return |
| LSP references | exact-word local grep | `<Leader>i` |
| cmp path/buffer completion | Unified built-in completion UI | `<C-n>/<C-p>` navigate, `<C-f>` accept |
| Conform formatting | Vim's indent expression | `<Leader>lf` |
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
- A self-contained Tokyo Night-style palette needs no colorscheme files.
- The cursor is a block in normal/visual mode, a bar in insert mode, and an
  underline in replace mode when the terminal supports cursor-shape escapes.

## Yank and clipboard

- `y` yanks a motion or visual selection, `yy` yanks the whole line, and `Y`
  yanks from the cursor through line end.
- Add `<Leader>` before any of those three commands to perform the same yank
  using the system clipboard. With `-clipboard`, they use Vim's normal register
  instead.
- `<Leader><C-y>` yanks the entire file without moving the cursor. It uses the
  system clipboard with `+clipboard` and Vim's normal register with
  `-clipboard`. Plain `<C-y>` remains Vim's native scroll command because it is
  a different key sequence.
- On `+clipboard` builds, `Ctrl-c` copies a line/visual selection and `Ctrl-v`
  pastes from the system clipboard. Native system-clipboard access still
  requires a Vim build with `+clipboard`.

## Useful stock-Vim capabilities

- `:make` populates quickfix when the project's approved build tool and
  `makeprg` are configured.
- `:copen`, `:colder`, and `:cnewer` inspect and move between result sets.
- `:set omnifunc?` shows whether the bundled filetype runtime provides omni
  completion. Vim 9.2+ opens a single menu with no configured delay, combining
  paths, omni results, tags, and buffer words in that priority order. Path
  entries are marked `[path]`. `<C-n>` and `<C-p>` open the menu on the first
  item, or move when it is already open. `<C-f>` accepts. `<Esc>` dismisses
  the menu and stays in insert; with no menu, it leaves insert. Highlighted
  preinserted text provides a ghost-text-like preview.
- Vim 8 and 9.1 use a zero-delay timer fallback to open the same contextual
  menu automatically. These versions cannot show native ghost text. If Vim was
  built without timers, `<C-n>` opens it manually. For ambiguous bare
  filenames, `<C-x><C-f>` remains an explicit fallback.
- HTML and XHTML use their bundled omni completer with standard tag-name
  results normalized to lowercase. XML remains case-sensitive and unchanged.
- `<Leader>e` opens netrw in the current window. Inside netrw, `<Enter>` opens a
  file or enters a directory, `-` goes to the parent, and `<Esc>` returns to the
  previously edited file without selecting an entry. `%`/`d` create a file or
  directory, `R`/`D` rename or delete, `i` cycles layouts, `s`/`r` change or
  reverse sorting, and `gh` toggles dotfiles. `mf` marks a file, `mu` clears all
  marks, `mt` sets the target directory, and `mc`/`mm` copy or move marked files.
- Insert mode automatically pairs `()`, `[]`, `{}`, `""`, and `''`. Typing an
  existing closer moves over it, and Backspace inside an empty pair removes both
  characters. Backspace between adjacent matching tags such as
  `<div>|</div>` removes both complete tags. On the empty line between a
  split pair (`<div>` / `</div>` or `{` / `}`), Backspace joins them back
  onto one line. Typing `>` after a tag-shaped `<name...` inserts
  its matching closing tag in every filetype except `c` and `cpp`; edit
  `g:tag_autoclose_blacklist` to add exclusions. Closing tags, self-closing
  tags, quoted attribute values, and HTML void elements are left alone.
  Editing a tag name updates its matching partner (`<div>` ↔ `</div>`),
  including nested tags of the same name.
- Pressing Enter between `()`, `[]`, `{}`, or matching opening/closing tags
  expands them to three lines, indents the cursor one `shiftwidth`, and aligns
  the closer with the opener. If completion is visible, Enter cancels it first.
- `mh`, `mj`, `mk`, and `ml` set cross-file global marks H/J/K/L. The matching
  Ctrl key jumps to the exact stored location; `<Leader>h` lists them and
  `<Leader>hc` clears them.
- A project-generated `tags` file is a static index from symbol names to source
  locations. Vim searches for `tags` in the file's directory and its ancestors;
  it does not create the index. `gd` jumps immediately when one definition
  matches and prompts when several match, while `gD` always shows the match list
  first. `<C-t>` returns from either jump. These preserve the home LSP muscle
  memory; Git remains a separate `<Leader>g` namespace in the home setup. Do not
  add a tag generator unless that executable and workflow are approved.
- `:set paste` can help when pasting is permitted; turn it back off with
  `:set nopaste` immediately afterward.

## Environment assumptions

The Vim runtime, user profile, repositories, clipboard, local Git commands,
source-derived tag files, and build artifacts are assumed to remain inside the
approved workstation boundary. Anything that communicates outside that boundary
still needs explicit approval.
