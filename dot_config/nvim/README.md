# Neovim config

Neovim 0.12+ with [lazy.nvim](https://github.com/folke/lazy.nvim). It's deployed by chezmoi to
`~/.config/nvim` on every machine (desktop, macOS, WSL). Edit it here in the source repo, not in
`~/.config/nvim`.

- [GUIDE.md](GUIDE.md): a quick, task-by-task guide to common commands; start here
- [Usage](#usage): setup, keys, everyday tasks, updating, troubleshooting
- [Implementation](#implementation): layout, load order, how each part works, how to change it

---

# Usage

## Requirements

| What | Why |
|------|-----|
| Neovim **0.12** or newer | nvim-treesitter's main branch, `winborder`, the `vim.diagnostic.jump` options |
| `git`, `curl` | lazy.nvim, Mason, parser downloads |
| `tree-sitter` CLI and a C compiler | building treesitter parsers |
| `rg` (ripgrep), `fd` | the snacks grep and file pickers |
| A Nerd Font in the terminal | icons in the picker, explorer, statusline and completion menu |
| `clang-format`, `rustfmt` (optional) | C/C++ and Rust formatting; they come from the system toolchains |

Everything else installs itself: lazy.nvim installs the plugins, and Mason installs the language
servers (clangd, lua_ls, basedpyright, rust-analyzer) and formatters (stylua, ruff, shfmt).

## Setting up a machine

```sh
chezmoi apply      # deploys ~/.config/nvim, including the lazy-lock.json symlink
nvim               # lazy.nvim bootstraps itself and installs plugins at the locked commits
```

Then, inside Neovim:

1. `:Lazy restore` makes sure every plugin is at the commit in the lockfile.
2. `:TSUpdate` builds the treesitter parsers against the current queries.
3. `:Mason` shows the servers and formatters installing. Wait for them to finish.
4. `:checkhealth` checks for missing tools.

## Keys

The leader is **Space**. Press it and wait to see every leader key; which-key does the same after
`g`, `]`, `[`, `z` and friends.

### Files, search and windows

| Key | Action |
|-----|--------|
| `<C-p>` | Find files |
| `<leader><space>` | Smart find: buffers, recent files and project files together |
| `<leader>,` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>/` | Grep the project |
| `<leader>sw` | Grep the word under the cursor, or the selection |
| `<leader>sh` | Help pages |
| `<leader>sk` | Keymaps |
| `<leader>sd` | Diagnostics |
| `<leader>ss` | LSP symbols in the buffer |
| `<leader>sr` | Reopen the last picker where you left it |
| `<C-n>` | Toggle the file explorer (from inside it too) |
| `<C-Space>` | Toggle the floating terminal (works from inside it too) |
| `<Esc>` | Clear search highlighting |

In a picker:
- Type to filter, and `<CR>` opens.
- `<C-v>`/`<C-s>` open in a vertical/horizontal split.
- `<Tab>` selects several.
- `<A-h>` shows hidden files.
- `<Esc>` once leaves the prompt; there, `?` lists every key, and a second `<Esc>` closes the
  picker.

In the explorer: `l`/`<CR>` open, `h` closes a folder, `a` adds a file (end with `/` for a folder),
`r` renames, `d` deletes (to the trash), `m`/`c` move/copy, `y`/`p` yank and paste files, `H` shows
hidden files, `I` shows git-ignored files, `<BS>` goes up a folder.

### Code (when a language server is attached)

| Key | Action |
|-----|--------|
| `gd` | Go to definition (a picker if there are several) |
| `gD` | Go to declaration |
| `gi` | Implementations |
| `go` | Type definition |
| `gr` | References |
| `K` | Hover documentation (Neovim default) |
| `<C-k>` | Signature help (`<C-s>` in insert mode, Neovim default) |
| `<F2>` | Rename symbol |
| `<F4>` | Code actions, for the cursor or the selection |
| `gl` | Show the diagnostics on this line |
| `[d` / `]d` | Previous/next diagnostic, with its message in a float (Neovim default) |
| `<leader>cf` | Format the buffer, or the selection |
| `<leader>uf` | Turn format on save off/on |

Because `gr` opens references immediately, Neovim's built-in `grn`, `gra`, `grr`, `gri` and `grt`
aren't reachable in LSP buffers; `<F2>`, `<F4>`, `gr`, `gi` and `go` cover them.

### Completion

The menu appears as you type. Nothing is selected until you press `<Tab>`.

| Key | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Next/previous item; with no menu open, next/previous snippet placeholder |
| `<CR>` | Accept the selected item |
| `<C-Space>` | Open the menu |
| `<C-e>` | Close the menu |
| `<C-y>` | Accept (the default key) |

Brackets and quotes close themselves (nvim-autopairs).

### Editing

| Key | Action |
|-----|--------|
| `gcc` / `gc{motion}` / `gc` in visual | Toggle comments (built into Neovim) |
| `sa{motion}{char}` | Add a surrounding: `saiw"` quotes a word, `sa$)` wraps to the end of the line |
| `sd{char}` | Delete a surrounding: `sd"`, `sd)` |
| `sr{old}{new}` | Replace a surrounding: `sr"'`, `sr)]` |
| `sf` / `sF` / `sh` | Find the next/previous surrounding, highlight it |

Text objects (with `d`, `c`, `y`, `v`, ...), on top of Neovim's built-in ones:

| Object | Meaning |
|--------|---------|
| `ia` / `aa` | A function argument, with or without its comma: `daa`, `cia` |
| `if` / `af` | A function call |
| `it` / `at` | An HTML/XML tag |
| `iq` / `aq` | Any quotes |
| `ib` / `ab` | Any brackets |
| `in…` / `il…` | The next/last one of any of these: `cina` changes the next argument |
| `ih` | A git hunk: `dih`, `yih` |

`s` on its own (substitute a character) now waits briefly for a possible `sa`/`sd`/...; use `cl`
instead.

Commands from vim-eunuch: `:Rename`, `:Move`, `:Delete`, `:Chmod`, `:Mkdir`, `:SudoWrite`.

### Git

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next/previous changed hunk (in diff mode, the usual next/previous change) |
| `<leader>hs` | Stage the hunk, or the selected lines |
| `<leader>hr` | Reset the hunk, or the selected lines |
| `<leader>hp` | Preview the hunk |
| `<leader>hb` | Blame the line, with the full commit message |
| `<leader>hd` | Diff the file against the index |
| `<leader>gs` | Git status picker |
| `<leader>gl` | Git log picker |

### Markdown

Markdown buffers are rendered in place: headings, bullets, checkboxes, tables, code blocks and
callouts. The raw text shows on the cursor line. `<leader>um` toggles rendering for the buffer.

## Formatting

`<leader>cf` always formats. Format on save is more careful, because clang-format, stylua and
shfmt would otherwise rewrite other people's code in their own default style:

| Filetype | Formatter | Formats on save when the project has |
|----------|-----------|--------------------------------------|
| C, C++, CUDA | clang-format | `.clang-format` or `_clang-format` |
| Lua | stylua | `stylua.toml` or `.stylua.toml` |
| Python | ruff | `ruff.toml`, `.ruff.toml` or `pyproject.toml` |
| sh, bash | shfmt | `.editorconfig` |
| Rust | rustfmt | always |

The config file is looked for in the file's directory and every parent. Filetypes without a
formatter fall back to the language server's formatter, if it has one. `:ConformInfo` shows what
applies to the current buffer, and `<leader>uf` turns format on save off for the session.

## Colours

Catppuccin, following the light/dark mode in `~/.local/state/colorscheme/mode`. On the desktop the
`colorscheme` command writes that file at sunrise and sunset, and every running Neovim switches
within a moment. Elsewhere it's dark unless something writes the file. The flavours (Mocha and
Latte) come from `.chezmoidata/colorscheme.toml` at the repo root.

## Updating plugins

```sh
nvim +'Lazy update'                              # or :Lazy and press U
git -C ~/.local/share/chezmoi diff dot_config/nvim/.lazy-lock.json
git -C ~/.local/share/chezmoi commit -m 'nvim: update plugins' dot_config/nvim/.lazy-lock.json
```

The lockfile is in the repo, so the update shows up in `git status` straight away. On the other
machines, after `chezmoi apply`: `:Lazy restore`, then `:TSUpdate`. lazy.nvim also checks for
updates in the background; `:Lazy` shows them, but it never updates on its own.

To undo an update, check out the old lockfile from git and run `:Lazy restore`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Query error ... Invalid node type` when opening a file | The treesitter queries are newer than the parsers: `:TSUpdate` |
| No language server in a buffer | `:checkhealth vim.lsp`; `:Mason` to see whether the server installed |
| A formatter doesn't run on save | `:ConformInfo`; check the project config file from the table above |
| Completion has no fuzzy matching, or warns about the Rust matcher | `:checkhealth blink.cmp`; the prebuilt binary downloads on first start |
| Icons show as boxes | The terminal font isn't a Nerd Font |
| Something else | `:checkhealth`, `:Lazy` (errors are shown per plugin), `:messages` |

`:checkhealth snacks` also reports errors for snacks modules this config doesn't use (image,
lazygit, notifier, and so on). Those are expected.

---

# Implementation

## Layout

```
dot_config/nvim/
├── init.lua                     entry point: loads config/*, then lazy.nvim
├── lua/
│   ├── config/
│   │   ├── options.lua          leader, vim.opt, diagnostics
│   │   ├── keymaps.lua          keymaps that don't belong to a plugin
│   │   ├── autocmds.lua         autocommands that don't belong to a plugin
│   │   └── lazy.lua             lazy.nvim bootstrap and setup
│   ├── plugins/                 one lazy.nvim spec file per area; each returns a list of specs
│   │   ├── colorscheme.lua      catppuccin + live light/dark switching
│   │   ├── completion.lua       blink.cmp
│   │   ├── editor.lua           autopairs, vim-eunuch, mini.ai, mini.surround, which-key
│   │   ├── formatting.lua       conform.nvim
│   │   ├── git.lua              gitsigns
│   │   ├── lsp.lua              mason, mason-lspconfig, nvim-lspconfig, LSP keymaps, lazydev
│   │   ├── markdown.lua         render-markdown
│   │   ├── snacks.lua           picker, explorer, terminal, indent guides, input, bigfile
│   │   ├── treesitter.lua       nvim-treesitter
│   │   └── ui.lua               lualine
│   ├── utils.lua                reads and watches the light/dark mode file
│   └── flavours.lua.tmpl        chezmoi template: Catppuccin flavour per mode
├── stylua.toml                  Lua style for this config
├── symlink_lazy-lock.json.tmpl  chezmoi: ~/.config/nvim/lazy-lock.json → .lazy-lock.json
├── .lazy-lock.json              the real lockfile (not deployed; see "Lockfile")
└── README.md                    this file
```

## Load order

1. `init.lua` requires `config.options` first, so the leader and options are set before any plugin
   creates mappings or reads an option.
2. `config.keymaps` and `config.autocmds` add the few global mappings and autocommands.
3. `config.lazy` clones lazy.nvim if it's missing, then calls `require("lazy").setup` with
   `{ import = "plugins" }`, which loads **every file** in `lua/plugins/`.
4. lazy.nvim runs each spec's `init`, then loads the non-lazy plugins in priority order: catppuccin
   and snacks first (`priority = 1000`), then nvim-treesitter, mason, lspconfig, blink.cmp, lualine,
   gitsigns and eunuch.
5. The rest load on demand:

| Plugin | Loads on |
|--------|----------|
| nvim-autopairs | `InsertEnter` |
| conform.nvim | `BufWritePre`, `:ConformInfo`, `<leader>cf` |
| lazydev.nvim | a Lua buffer |
| render-markdown | a markdown buffer |
| mini.surround | its `s…` keys |
| mini.ai, which-key | `VeryLazy` (just after the UI is drawn) |

lazy.nvim settings (`config/lazy.lua`):
- `checker`: checks for updates in the background without notifying.
- `change_detection.notify = false`: reloads quietly after you edit the config.
- `rocks.enabled = false`: no plugin needs luarocks, and this silences its health warnings.
- `install.colorscheme`: catppuccin is used while a fresh machine installs plugins.

## Options and diagnostics (`config/options.lua`)

Each option has a comment explaining it. A few are there for a plugin:
- `signcolumn = "yes"` reserves the column, so text doesn't jump when gitsigns or diagnostic signs
  appear.
- `updatetime = 250` makes `CursorHold` fire sooner, which gitsigns uses.
- `winborder = "rounded"` gives every floating window a border without per-plugin settings.

Diagnostics show inline (`virtual_text`), sorted by severity, with the source in the float.
`jump.on_jump` opens the float after `[d`/`]d`. That's the behaviour the old
`vim.diagnostic.goto_next` had, which Neovim 0.13 removes.

## Colours (`colorscheme.lua`, `utils.lua`, `flavours.lua.tmpl`)

- `flavours.lua.tmpl` is rendered by chezmoi from `.chezmoidata/colorscheme.toml`, for example
  `return { dark = "mocha", light = "latte" }`. It's passed to catppuccin as its `background`
  table, so catppuccin picks the flavour from `'background'`.
- `utils.mode()` reads `$XDG_STATE_HOME/colorscheme/mode` (default `~/.local/state/...`) and
  returns `"light"` or `"dark"`. A missing file or anything unexpected means `"dark"`.
- `utils.watch_mode(fn)` puts a libuv fs-event watcher on the **directory**, so it still fires when
  `colorscheme` replaces the file rather than writing it in place. On a change it schedules `fn`,
  which sets `'background'` and reapplies the colorscheme. Highlights from the other plugins follow
  because catppuccin includes their integrations.

To test switching without touching the desktop, start Neovim with `XDG_STATE_HOME` pointing at a
temporary directory and write `light` or `dark` into `colorscheme/mode` there.

## snacks.nvim (`snacks.lua`)

One plugin provides the picker, explorer, floating terminal, indent guides, `vim.ui.input` and
large-file handling (`bigfile`). It's loaded at startup with high priority because other specs call
the `Snacks` global.

- **Picker:** with `picker.enabled`, snacks also replaces `vim.ui.select`, so code actions and
  other prompts use it. It does this, and the `vim.ui.input` replacement, on `UIEnter`. That event
  never fires in `nvim --headless`, so headless health checks report both as not set.
- **Explorer:** the explorer is a picker in a sidebar. `Snacks.explorer()` toggles it, because
  opening a picker whose source is already open closes that picker instead.
- **`<C-n>` in the explorer:** pickers bind `<C-n>` to "move down" in their own windows, which
  hides the global toggle once the explorer has focus. `picker.sources.explorer.win` rebinds it
  to `close` in the explorer's list and input only.
- **Terminal:** `terminal.win.position = "float"` makes `Snacks.terminal.toggle()` float. The key
  is mapped in normal and terminal mode, so the same key hides it again.
- **`:q` and the explorer:** without help, `:q` in the last editor window leaves the explorer
  sidebar open and Neovim running. The `QuitPre` autocommand in `init` checks whether every other
  non-floating window in the tab is a snacks window. If so, it closes the explorer pickers first.
  `picker:close()` only removes the windows on the next tick, after `:q` has already decided what
  to do, so the autocommand also calls `picker.layout:close()`, which closes them immediately. It's
  safe to call twice.

## LSP (`lsp.lua`)

- **mason.nvim** installs packages into `stdpath("data")/mason` and puts its `bin/` first on
  `$PATH` inside Neovim. Its `config` also installs the conform formatters (stylua, ruff, shfmt)
  through `mason-registry`, skipping any that are installed or installing.
- **mason-lspconfig** `ensure_installed` installs clangd, lua_ls, basedpyright and rust-analyzer.
  `automatic_enable` calls `vim.lsp.enable()` for every installed server it knows about. That
  includes `ruff`, which runs next to basedpyright for lint diagnostics and fixes. It excludes
  `stylua`, whose Mason package would otherwise also start stylua as a language server.
- **nvim-lspconfig** supplies the server configs that `vim.lsp.enable()` uses. Its `config` sets
  up the `LspAttach` autocommand that adds the buffer-local code keys. `gr` is `nowait`; without it,
  Neovim waits `timeoutlen` to see whether you meant the built-in `grn`/`gra`/`grr`/....
- **blink.cmp** sets `vim.lsp.config("*", { capabilities = ... })` itself, so no server config
  needs completion capabilities passed in.
- **lazydev.nvim** configures lua_ls when it edits Neovim Lua: the runtime, the plugins, luv types
  (when `vim.uv` appears in the file) and snacks types (when `Snacks` appears). It also acts as a
  blink.cmp source.

To configure a server, call `vim.lsp.config("<name>", { settings = ... })`, for example in that
spec's `config`. clangd reads its own `~/.config/clangd/config.yaml`, which is also in this repo.
To add a server, add it to `ensure_installed`, or install it with `:Mason`.

## Completion (`completion.lua`)

blink.cmp follows `version = "1.*"`: release tags come with a prebuilt Rust fuzzy matcher, so
nothing is compiled. The `default` keymap preset is kept, and `<Tab>`, `<S-Tab>` and `<CR>` are
changed. Each key runs a list of commands and stops at the first that applies: with the menu open
it selects, otherwise it jumps through snippet placeholders, otherwise it inserts the key.
`preselect = false` with `auto_insert = true` means nothing is selected until `<Tab>`, and the
selected item is inserted as you move. The sources are lazydev, LSP, file paths,
snippets (friendly-snippets) and buffer words.

## Formatting (`formatting.lua`)

conform.nvim maps filetypes to formatters (`formatters_by_ft`). `default_format_opts.lsp_format =
"fallback"` makes it use the language server's formatter when none is configured for the filetype.

`format_on_save` is a function. It returns nothing (so no formatting happens) when:
- `vim.g.autoformat == false`, which `<leader>uf` sets through a `Snacks.toggle`. That toggle is
  created on `VeryLazy`, because conform's `init` runs before snacks has loaded.
- the filetype is in `project_config` and `vim.fs.root(bufnr, markers)` finds none of its config
  files in the file's directory or any parent.

Otherwise it returns `{ timeout_ms = 500 }`. To add a formatter, add it to `formatters_by_ft`. Also
add it to `project_config` if its default style shouldn't be applied to every project, and to the
Mason list in `lsp.lua` if the system doesn't provide it.

This config is formatted with stylua using `stylua.toml`. `collapse_simple_statement =
"FunctionOnly"` keeps one-line keymap functions on one line.

## Treesitter (`treesitter.lua`)

This uses nvim-treesitter's **main** branch, a rewrite for Neovim 0.12. It installs parsers and
queries into `stdpath("data")/site`, doesn't support lazy-loading, and no longer enables
highlighting itself. So:
- `install({...})` installs the listed parsers. It's asynchronous and skips installed ones, so
  adding a language to the list installs it on the next start. That includes the parsers Neovim
  bundles (`lua`, `vim`, `vimdoc`, `query`, `markdown`), so their queries match the
  nvim-treesitter versions.
- A `FileType` autocommand calls `vim.treesitter.start()` in a `pcall`. Highlighting starts for
  any filetype with a parser, and filetypes without one are skipped quietly.
- `build = ":TSUpdate"` rebuilds parsers when lazy.nvim updates the plugin. When an update runs
  headless and exits early, the queries can end up newer than the parsers ("Invalid node type").
  `:TSUpdate` fixes it.

Indentation and folding still use Vim's defaults: nvim-treesitter's `indentexpr` is marked
experimental.

## Git, editing and UI plugins

- **gitsigns** (`git.lua`): the keys are set in `on_attach`, so they exist only in buffers that are
  in a git repo. `]c`/`[c` fall back to Vim's own `]c`/`[c` in diff mode.
- **mini.ai / mini.surround** (`editor.lua`): defaults. mini.surround is loaded by its `keys`
  entries, which also give which-key their descriptions.
- **which-key** (`editor.lua`): the `spec` only names the leader groups. Every mapping's `desc` is
  what it displays, so give new mappings a `desc`.
- **render-markdown** (`markdown.lua`): defaults with LaTeX disabled, since that needs the latex
  parser plus `utftex` or `latex2text`. It uses the `markdown`, `markdown_inline`, `html` and
  `yaml` parsers.
- **lualine** (`ui.lua`): defaults. It picks up catppuccin's colours by itself.
- **Commenting**: there's no plugin; Neovim 0.10+ has `gc` built in, using `'commentstring'` and
  treesitter injections.

## Lockfile

lazy.nvim writes `lazy-lock.json` into the config directory. Here that would be a deployed target
that changes all the time, so instead:

- The real file is `dot_config/nvim/.lazy-lock.json`. chezmoi ignores source files whose names
  start with a dot, so it isn't deployed as a regular file.
- `symlink_lazy-lock.json.tmpl` makes `~/.config/nvim/lazy-lock.json` a symlink to
  `{{ .chezmoi.sourceDir }}/dot_config/nvim/.lazy-lock.json`. That's the same pattern as eww's
  `colors.scss`.
- lazy.nvim opens the lockfile for writing, which follows the symlink, so updates land directly in
  the repo and `chezmoi diff` stays clean.

## Changing the config

- **Edit in the source repo**, then `chezmoi apply ~/.config/nvim`. A running Neovim reloads plugin
  specs by itself. Options and keymaps need a restart.
- **Add a plugin**: add a spec to the fitting file in `lua/plugins/`, or a new file. lazy.nvim
  imports every file there. Prefer `opts = {}` over a `config` function, and add a loading trigger
  (`event`, `ft`, `keys`, `cmd`) unless the plugin has to be there at startup. Run `:Lazy sync`,
  then commit the lockfile.
- **Remove a plugin spec file**: `chezmoi destroy --force ~/.config/nvim/lua/plugins/<file>.lua`,
  **and** list the path in `.chezmoiremove` at the repo root. chezmoi doesn't delete targets whose
  source is gone, and lazy.nvim would keep loading the stale file on the other machines. Then run
  `:Lazy clean`.
- **Commits** follow the repo convention: `nvim: <imperative summary>`, one change each (see
  `AGENTS.md`).

## Verifying changes

These run without a UI, so they also work over SSH:

```sh
nvim --headless +qa                                    # prints nothing when the config loads cleanly
nvim --headless "+Lazy! sync" +qa                      # install, clean and update plugins
nvim --headless "+checkhealth vim.lsp lazy blink.cmp mason nvim-treesitter snacks" "+w! /tmp/health.txt" +qa
nvim --headless -c 'lua print(vim.inspect(vim.tbl_keys(require("lazy.core.config").plugins)))' +qa
```

Lazy-loaded plugins (conform, which-key, render-markdown) report "No healthcheck found" unless
they're loaded first. For a behaviour check, write a small Lua script that opens a file, waits with
`vim.wait(ms, condition)` and writes what it found with `io.stdout:write`, and run it with
`nvim --headless -c "luafile check.lua" -c "qa!"`. Keys, rendering and borders still need a real
session.
