# Neovim quick guide

Common commands for everyday work with this config, grouped by task. The leader is **Space**:
press it and wait, and a popup lists what comes next. For the full key reference and how the
config works, see [README.md](README.md).

Notation: `<C-x>` is Ctrl+x, `<A-x>` is Alt+x, `<leader>` is Space. Keys are typed in normal mode
unless a section says otherwise.

## Contents

- [The essentials](#the-essentials)
- [Opening files](#opening-files)
- [The file explorer](#the-file-explorer)
- [Moving around](#moving-around)
- [Editing](#editing)
- [Search and replace](#search-and-replace)
- [Windows, buffers and tabs](#windows-buffers-and-tabs)
- [Code navigation and refactoring](#code-navigation-and-refactoring)
- [Diagnostics](#diagnostics)
- [Completion and snippets](#completion-and-snippets)
- [Formatting](#formatting)
- [Git](#git)
- [Terminal](#terminal)
- [Markdown](#markdown)
- [Maintenance](#maintenance)
- [When something's wrong](#when-somethings-wrong)

## The essentials

| Do this | Keys |
|---------|------|
| Save | `:w` |
| Quit (asks about unsaved changes) | `:q` |
| Save and quit | `:wq` or `ZZ` |
| Quit everything, discarding changes | `:qa!` |
| Undo / redo | `u` / `<C-r>` |
| Repeat the last change | `.` |
| Back to normal mode | `<Esc>` |
| Clear search highlighting | `<Esc>` in normal mode |
| See what a key prefix does | type the prefix (`<leader>`, `g`, `]`, `z`...) and wait |
| Search all keymaps | `<leader>sk` |
| Search help | `<leader>sh`, or `:help <topic>` |
| Restart Neovim, keeping the session | `:restart` |

Undo history survives restarts. For a visual undo history, run `:packadd nvim.undotree`, then
`:Undotree`.

## Opening files

| Do this | Keys |
|---------|------|
| Find a file by name | `<C-p>` |
| Find a file, an open buffer or a recent file | `<leader><space>` |
| Switch between open buffers | `<leader>,` |
| Recent files | `<leader>fr` |
| Toggle the file explorer | `<C-n>` |
| Open the path under the cursor | `gf` |
| Open the URL under the cursor in the browser | `gx` |
| Open a file by path | `:e path/to/file` (`<Tab>` completes) |
| Go back to the previous file | `<C-^>` |

**In any picker:**
- Type to filter, `<CR>` opens, and `<C-v>`/`<C-s>` open in a split.
- `<Tab>` selects several files, `<A-h>` shows hidden files, and `<C-n>`/`<C-p>` or the arrow
  keys move up and down.
- `<Esc>` leaves the prompt, `?` then lists every key, and a second `<Esc>` closes the picker.
- `<leader>sr` reopens the last picker where you left it.

## The file explorer

`<C-n>` opens the explorer on the left, and `<C-n>` again closes it, from the explorer or from the
editor. It opens on its own when you start Neovim with a folder (`nvim .`).

| Do this | Keys |
|---------|------|
| Move | `j` / `k` |
| Open a file, or expand a folder | `l` or `<CR>` |
| Collapse a folder | `h` |
| Collapse everything | `Z` |
| Go up to the parent folder | `<BS>` |
| Make this folder the root (and the working directory) | `.` |
| Open in a vertical / horizontal split | `<C-v>` / `<C-s>` |
| Open with the system's default app | `o` |
| Filter the tree | `i`, then type; `<Esc>` to stop typing |
| New file | `a`, then the name |
| New folder | `a`, then the name ending in `/` (`a` `lib/util/` makes both) |
| Rename | `r` |
| Delete (to the trash) | `d` |
| Select several | `<Tab>` on each, or `V` and move |
| Move selected files here | select them, go to the target folder, `m` |
| Copy selected files here | select them, go to the target folder, `c` |
| Copy / paste file paths | `y`, then `p` in the target folder |
| Show hidden / git-ignored files | `H` / `I` |
| Preview the file under the cursor | `P` |
| Refresh | `u` |
| Next / previous file with git changes | `]g` / `[g` |
| Next / previous file with errors | `]e` / `[e` |
| Grep inside this folder | `<leader>/` |
| Terminal in this folder | `<C-t>` |
| List every key | `<Esc>` (if you're typing), then `?` |

`:q` in your last editor window closes the explorer too, so Neovim exits.

## Moving around

| Do this | Keys |
|---------|------|
| Word forward / back / to its end | `w` / `b` / `e` |
| Start / end of line | `0` or `^` / `$` |
| Top / bottom of file | `gg` / `G` |
| Go to line 42 | `42G` or `:42` |
| Half a page down / up | `<C-d>` / `<C-u>` |
| Centre the cursor line on screen | `zz` |
| Matching bracket | `%` |
| To the next `x` on the line / just before it | `fx` / `tx`; `;` repeats |
| Back / forward through jump history | `<C-o>` / `<C-i>` |
| Set a mark / jump back to it | `ma` / `'a` (capital letters work across files) |
| Next / previous changed git hunk | `]c` / `[c` |
| Next / previous diagnostic | `]d` / `[d` |

## Editing

| Do this | Keys |
|---------|------|
| Insert before / after the cursor | `i` / `a` |
| Insert at the start / end of the line | `I` / `A` |
| New line below / above | `o` / `O` |
| Delete / change / yank a word | `diw` / `ciw` / `yiw` |
| Delete a line / yank a line | `dd` / `yy` |
| Change to the end of the line | `C` |
| Paste after / before | `p` / `P` |
| Join the next line onto this one | `J` |
| Indent / unindent (visual mode) | `>` / `<` |
| Re-indent a block | `=` plus a motion, e.g. `=ap` |
| Toggle a comment on a line / selection | `gcc` / `gc` |
| Comment a paragraph | `gcap` |
| Visual / line / block selection | `v` / `V` / `<C-v>` |
| Reselect the last selection | `gv` |
| Record a macro into `q` / play it / replay | `qq` ... `q` / `@q` / `@@` |
| Upper / lower case (visual mode) | `U` / `u` |

**Inside and around:** `i` means inside and `a` means around (including the delimiters). They work
with `d`, `c`, `y` and `v`.

| Object | Example |
|--------|---------|
| Word | `ciw` |
| Quotes (any kind) | `ciq`, or `ci"` for a specific kind |
| Brackets (any kind) | `dib`, or `di(` for a specific kind |
| Function argument | `daa` deletes an argument and its comma |
| Function call | `yaf` |
| HTML/XML tag | `cit` |
| Paragraph | `dap` |
| Git hunk | `dih` |
| The *next* or *last* one | add `n` or `l`: `cina` changes the next argument, `dilq` deletes the last quotes |

**Surroundings:**

| Do this | Keys |
|---------|------|
| Quote a word | `saiw"` |
| Wrap a selection in parentheses | select it, then `sa)` |
| Delete surrounding quotes | `sd"` |
| Change `"..."` to `'...'` | `sr"'` |
| Change `(...)` to `[...]` | `sr)]` |

`)` and `]` add the bracket on its own; `(` and `[` add it with a space inside.

**File operations** (commands for the current file):

| Do this | Keys |
|---------|------|
| Rename the file | `:Rename newname` |
| Move the file | `:Move path/newname` |
| Delete the file and its buffer | `:Delete` |
| Make the file executable | `:Chmod +x` |
| Save a file you need root for | `:SudoWrite` |

## Search and replace

| Do this | Keys |
|---------|------|
| Search forward / backward in the file | `/text` / `?text`, then `n` / `N` |
| Search for the word under the cursor | `*` (forward), `#` (backward) |
| Grep the project | `<leader>/` |
| Grep for the word under the cursor, or the selection | `<leader>sw` |
| Replace in the whole file | `:%s/old/new/g` |
| Replace, confirming each match | `:%s/old/new/gc` |
| Replace in the selection | select, then `:s/old/new/g` |
| Rename a symbol everywhere (code) | `<F2>` |

Search ignores case unless the pattern contains a capital letter. While you type a `:s` command,
the replacements preview live, with a split listing the matches.

**Replace across files:**
1. `<leader>/` and search.
2. `<C-q>` sends the results to the quickfix list.
3. `:cdo s/old/new/g | update` replaces in every result and saves.

## Windows, buffers and tabs

| Do this | Keys |
|---------|------|
| Split vertically / horizontally | `:vs` / `:sp` (`<C-w>v` / `<C-w>s`) |
| Move between windows | `<C-w>h`, `<C-w>j`, `<C-w>k`, `<C-w>l` (or `<C-w>w` to cycle) |
| Close the window | `<C-w>q` or `:q` |
| Keep only this window | `<C-w>o` |
| Make windows equal size | `<C-w>=` |
| Resize | `<C-w>+`, `<C-w>-`, `<C-w>>`, `<C-w><` (with a count: `10<C-w>>`) |
| List and switch buffers | `<leader>,` |
| Next / previous buffer | `]b` / `[b` |
| Close the buffer | `:bd` |
| New tab / next tab / previous tab | `:tabnew` / `gt` / `gT` |

New vertical splits open to the right, and horizontal splits open below.

## Code navigation and refactoring

These work when a language server is attached (C/C++, Lua, Python, Rust, and anything else Mason
has installed). `:LspInfo` shows which servers are attached.

| Do this | Keys |
|---------|------|
| Documentation for the symbol | `K` (twice to enter the popup) |
| Signature help | `<C-k>` (normal mode), `<C-s>` (insert mode) |
| Go to definition | `gd` |
| Go to declaration | `gD` |
| Go to type definition | `go` |
| List implementations | `gi` |
| List references | `gr` |
| Symbols in this file | `<leader>ss` |
| Rename the symbol | `<F2>` |
| Code actions (fixes, refactors, imports) | `<F4>` (also on a selection) |
| Back to where you jumped from | `<C-o>` |
| Restart the language server | `:lsp restart` |

When a jump has several results, they open in a picker; with one result it jumps straight there.

## Diagnostics

| Do this | Keys |
|---------|------|
| Show the message(s) on this line | `gl` |
| Next / previous diagnostic (shows its message) | `]d` / `[d` |
| First / last diagnostic in the file | `[D` / `]D` |
| All diagnostics in a picker | `<leader>sd` |
| Fix it | `<F4>` on the line, if the server offers a fix |

Messages also appear at the end of the line. The coloured sign in the left column marks the line.

## Completion and snippets

The menu opens as you type. Nothing is selected until you choose something.

| Do this | Keys |
|---------|------|
| Next / previous item | `<Tab>` / `<S-Tab>` |
| Accept | `<CR>` (or `<C-y>`) |
| Close the menu | `<C-e>` |
| Open the menu by hand | `<C-Space>` |
| Scroll the documentation popup | `<C-f>` / `<C-b>` |
| Next / previous snippet placeholder | `<Tab>` / `<S-Tab>` (when the menu is closed) |

Snippets show in the menu like any other item (e.g. `for`, `fn`, `main`). Brackets and quotes close
themselves as you type.

## Formatting

| Do this | Keys |
|---------|------|
| Format the file, or the selection | `<leader>cf` |
| Turn format on save off/on (this session) | `<leader>uf` |
| See which formatter applies here | `:ConformInfo` |

Format on save is careful. C/C++, Lua, Python and shell files only format on save when the project
has a formatter config file (`.clang-format`, `stylua.toml`, `ruff.toml` or `pyproject.toml`,
`.editorconfig`). Rust always formats. `<leader>cf` formats regardless.

## Git

The left column marks changed lines in files in a git repo: added, changed and deleted.

| Do this | Keys |
|---------|------|
| Next / previous change (hunk) | `]c` / `[c` |
| Preview the change | `<leader>hp` |
| Stage the change / the selected lines | `<leader>hs` |
| Undo the change / the selected lines | `<leader>hr` |
| Who changed this line, and why | `<leader>hb` |
| Diff the file against what's staged | `<leader>hd` (`:q` to close) |
| Select the change as text | `vih` (also `dih`, `yih`) |
| Changed files (git status) | `<leader>gs` |
| Commit log | `<leader>gl` |

For committing and pushing, use the terminal (`<C-Space>`).

## Terminal

| Do this | Keys |
|---------|------|
| Open / hide the floating terminal | `<C-Space>` (from inside it too) |
| Scroll or copy in the terminal | `<Esc><Esc>` to normal mode, move and `y`, then `i` to type again |
| Hide it from normal mode | `q` |
| Open a terminal in the explorer's folder | `<C-t>` in the explorer |

The terminal keeps running while hidden, so `<C-Space>` brings back the same shell.

## Markdown

Markdown files render in the buffer: headings, lists, checkboxes, tables and code blocks. The line
under the cursor shows the raw text so you can edit it.

| Do this | Keys |
|---------|------|
| Toggle rendering | `<leader>um` |
| Open a link | `gx` |

## Maintenance

| Do this | Command |
|---------|---------|
| Plugin manager | `:Lazy` (`U` updates, `S` syncs, `X` cleans, `?` help) |
| Update plugins | `:Lazy update`, then commit `dot_config/nvim/.lazy-lock.json` in the chezmoi repo |
| Match the plugin versions in the lockfile | `:Lazy restore` |
| Rebuild treesitter parsers | `:TSUpdate` |
| Language servers and formatters | `:Mason` (`i` install, `X` uninstall, `U` update all) |
| Check everything | `:checkhealth` |
| Check one area | `:checkhealth vim.lsp`, `:checkhealth snacks`, ... |
| Show recent messages and errors | `:messages` |

The config lives in the chezmoi repo. To change it:
1. `chezmoi edit ~/.config/nvim/lua/plugins/<file>.lua`, or edit the file in
   `~/.local/share/chezmoi/dot_config/nvim/`.
2. `chezmoi apply`.
3. Restart Neovim (`:restart`).

Edits made directly in `~/.config/nvim` are overwritten by the next `chezmoi apply`.

## When something's wrong

| Problem | Try |
|---------|-----|
| `Query error ... Invalid node type` | `:TSUpdate` |
| No go-to-definition or completions from the server | `:LspInfo`, then `:Mason` to check the server installed; `:lsp restart` |
| A file didn't format on save | `:ConformInfo`; does the project have the formatter's config file? |
| A key does something unexpected | `:verbose nmap <key>` shows what set it |
| An error popped up and vanished | `:messages` |
| Icons show as boxes | Use a Nerd Font in the terminal |
| Everything is broken after an update | Check out the previous `.lazy-lock.json` from git, then `:Lazy restore` |
