# AGENTS.md

Guidance for AI agents (and people) working on this dotfiles repo.

## What this is

Dotfiles for three kinds of machine, managed with [chezmoi](https://www.chezmoi.io):

- **desktop**: native Arch Linux running Hyprland (Wayland), the main machine
- **macOS**
- **WSL**

This directory, `~/.local/share/chezmoi`, is chezmoi's *source state*. It's also the git repo,
pushed to `git@github.com:wasingera/config_dotfiles.git` on `master`. chezmoi renders it into the
home directory, the *target*. `~/.config` is **not** a git repo.

## Layout and naming

chezmoi maps source names to target paths:

| Source | Target |
|--------|--------|
| `dot_config/zsh/dot_zshrc` | `~/.config/zsh/.zshrc` |
| `dot_config/eww/scripts/executable_volume.sh` | `~/.config/eww/scripts/volume.sh` (mode 755) |
| `dot_config/private_gtk-3.0/` | `~/.config/gtk-3.0/` (mode 700) |
| `dot_config/satty/config.toml.tmpl` | `~/.config/satty/config.toml` (Go template) |
| `dot_config/eww/symlink_colors.scss.tmpl` | `~/.config/eww/colors.scss`, a symlink to the path in the file |

- `chezmoi source-path <target>` and `chezmoi target-path <source>` convert between the two.
- A plain file like `lib.sh` (no `executable_`) is deployed non-executable. That's intended for
  sourced files.
- Files starting with `.` are ignored by chezmoi, except its special files.

Special files at the root:

| File | Purpose |
|------|---------|
| `.chezmoi.toml.tmpl` | Detects the machine type into `.wsl` and `.desktop` (see below). |
| `.chezmoiignore` | Template. Desktop-only paths are listed inside `{{ if not .desktop }}`. |
| `.chezmoiremove` | Template. Target paths to **delete** on apply (the old X11 setup, leftovers). |
| `.chezmoiexternal.toml` | zsh plugins, as GitHub archives pinned to a commit hash. |
| `.chezmoidata/` | Template data on every machine: the Catppuccin palette and the flavour per mode. See "Colours". |
| `.chezmoitemplates/colors/` | One colour template per tool, rendered from the palette. See "Colours". |
| `run_onchange_after_colorscheme.sh.tmpl` | Re-runs `colorscheme` when the palette or a colour template changes. Desktop only (renders empty elsewhere). |
| `README.md`, `AGENTS.md`, `CLAUDE.md` | Docs, ignored by chezmoi (not deployed). |

## Machine types

`.chezmoi.toml.tmpl` writes `~/.config/chezmoi/chezmoi.toml` on `chezmoi init`:

- `wsl`: Linux whose kernel release contains "microsoft"
- `desktop`: Linux and not WSL

What each machine gets:

- **Every machine:** zsh (`ZDOTDIR=~/.config/zsh` via `dot_zshenv`), nvim, clangd.
- **Desktop only:** `hypr`, `eww`, `rofi` (+ `~/.local/share/rofi`), `dunst`, `alacritty`,
  `gtk-3.0`, `gtk-4.0`, `satty`, `chromium-flags.conf`, `zsh/.zprofile` (starts Hyprland on tty1),
  and the light/dark switching: `~/.config/colorscheme/`, `~/.local/bin/colorscheme`,
  `~/.local/bin/colorscheme-solar` and `~/.config/systemd/`.

When adding a new desktop-only config, also add its path to the `{{ if not .desktop }}` block in
`.chezmoiignore`. Then check it doesn't leak to other machines:

```sh
chezmoi managed --override-data '{"desktop":false,"wsl":true}'
```

`.zshrc` must work on all three. Handle differences with **runtime checks**
(`[[ $OSTYPE == darwin* ]]`, `(( $+commands[tool] ))`), not templates, so it stays a plain file.
Settings for one machine only belong in the untracked `~/.config/zsh/local.zsh`, which `.zshrc`
sources if it exists.

## Workflow

1. **Edit the source**: edit files in this directory, or run `chezmoi edit <target>`. If a target
   file was edited directly, pull the change back with `chezmoi re-add <target>`. Don't re-add
   `.tmpl` files: re-adding writes the rendered output back over the template. Edit their source
   instead.
2. **Preview and apply**: run `chezmoi diff`, then `chezmoi apply`.
3. **Verify in the running system**; see "Verifying changes" below.
4. **Check for drift**: `chezmoi diff` should be empty afterwards.
5. **Commit** with `chezmoi git -- ...` or plain git in this directory. **Push only when the user
   asks.**

Other common operations:

- **Add a file:** `chezmoi add <target>` picks the right prefixes (`executable_`, `private_`).
- **Rename:** `git mv` the source, then `rm` the old target. chezmoi doesn't delete targets whose
  source disappeared.
- **Delete a file that's tracked here:** `chezmoi destroy --force <target>` removes the source, the
  target and chezmoi's state.
- **Delete a file that should vanish on every machine** (e.g. an old config the repo never tracked):
  list it in `.chezmoiremove`.

### Commits

- Keep commits small and logical: one fix or feature each. The user asked for this explicitly.
- Subjects use the form `<area>: <imperative summary>`, e.g. `eww: fix VPN menu with names
  containing spaces`. Areas are `zsh`, `nvim`, `hypr`, `eww`, `rofi`, `dunst`, `theme`, etc.
- The body explains *why*, plus anything non-obvious.
- Check `git log` for examples.

## Verifying changes

The desktop is live while you work. Check each change in the real session:

| Component | Reload / check |
|-----------|----------------|
| Hyprland | `hyprctl reload && hyprctl configerrors` (empty output = OK) |
| eww bar | `eww reload`, then `eww get <variable>` |
| eww listener script | `timeout 3 ./scripts/x.sh` from `~/.config/eww`: prints once, then stays quiet while idle |
| dunst | `dunstctl reload`, then `notify-send -u low/normal/critical ...` |
| rofi theme | `rofi -theme <file> -dump-theme 2>&1 \| grep 'Failed to parse'` (no output = OK) |
| zsh | `zsh -n <file>`, then `zsh -ic exit` |
| any shell script | `bash -n <file>` |
| nvim | `nvim --headless +qa` prints nothing; `nvim --headless "+checkhealth <plugin>" "+w! out.txt" +qa` |
| colours | `colorscheme light`, check, `colorscheme dark`; `chezmoi diff` must be empty in both modes |
| hyprlock | `hyprlock --grace 60 &` (any input unlocks), screenshot, then `pkill -USR1 -x hyprlock` to unlock |
| visual result | `grim -g "x,y wxh" out.png` (screen scale is 1.5, so the image is in physical px) |
| bar widget geometry | `~/.config/eww/scripts/bar_anchor.py` prints where a menu would hang from the button under the pointer |

Some things can't be checked from a non-interactive shell: rofi menus, keybinds, mouse behaviour.
For those, ask the user to try them, or open a test instance with dummy data in the background
and ask them to interact with it.

Shell traps:

- `eww logs` follows the log forever; wrap it in `timeout`.
- `pkill -f pattern` also matches your own shell, whose command line contains the pattern.
  Anchor it (`pkill -f '^alacritty --class test'`) or use `pkill -x name`.
- Importing a Python script (e.g. `bar_anchor.py` in a test) writes `__pycache__/` next to it. In
  the source directory chezmoi would deploy that, so set `PYTHONDONTWRITEBYTECODE=1`.

## Component notes and gotchas

### Hyprland (`dot_config/hypr/hyprland.lua`)

- This is Hyprland **0.56 with the Lua config**. `hyprctl dispatch` takes Lua (`hl.dsp...`). The old
  string dispatchers (`movewindowpixel exact ...`) fail, which also breaks third-party tools that
  use them, such as ueberzugpp positioning.
- `mainMod` is SUPER. Check for conflicts before binding a key: Win+Shift+S already moves a
  window to the special workspace, and Win+V toggles floating.
- Window and layer rules use `hl.window_rule({...})`. Some field names differ from the old config:
  use `border_size = 0`, not `no_border`.
- Wallpapers in `hypr/images/` are intentionally untracked (large files).

### eww bar (`dot_config/eww/`)

- The `eww` binary is `~/.local/bin/eww`, built from the source checkout in `~/eww`. That checkout
  isn't part of this repo.
- Scripts live in `scripts/`. Shared helpers are in `scripts/lib.sh`; load them with
  `source "${BASH_SOURCE%/*}/lib.sh"`:

  | Helper | What it does |
  |--------|--------------|
  | `rofi_menu THEME` | Shows a rofi dropdown under the clicked bar button and prints the chosen option. |
  | `nm_connections TYPE [--active]` | Prints NetworkManager connection names of that type. |
  | `bluez_objects` | Prints BlueZ's objects (adapters, devices) as JSON, `{path: {interface: {property: value}}}`. |
  | `hypr_events` | Streams Hyprland's event socket. |
  | `drain_burst` | Waits out a burst of events (until 50ms of quiet). |
  | `emit` | Prints a widget's state only when it changed. |

- Widgets are **event-driven** (`deflisten`), not polled. Listeners print an initial state, then
  re-render on events:
  - `workspaces.sh` and `keyboard.sh` use Hyprland's socket.
  - `network.sh` uses `nmcli monitor`.
  - `bluetooth.sh` uses `gdbus monitor --system --dest org.bluez` (`dbus-monitor --system` needs
    root), filtered to power, connection and add/remove signals.
  - `volume.sh` uses `pactl subscribe`.
  - The clock is `formattime(EWW_TIME, ...)`.
  - `gpu.sh` streams `nvidia-smi --loop=2` (one long-lived process).
  - CPU, memory and temperatures use eww's built-in `EWW_CPU`, `EWW_RAM` and `EWW_TEMPS`,
    which eww samples itself.

  Follow this pattern for new widgets; avoid `defpoll` with external commands.
- `pactl subscribe` must be filtered to `sink`/`server` events. `pamixer` and `pactl` calls create
  `client` events, so reacting to those loops forever.
- Never run `nmcli dev wifi` without `--rescan no`: it triggers an ~8s scan.
- **Nerd Font glyphs**: icons in `.yuck` and `.sh` files are private-use Unicode characters that
  may not render in your editor or tool output. Don't retype or rewrite lines containing them.
  Edit only the surrounding ASCII (e.g. a Python `str.replace` on exact substrings), and check
  with `od -c` or `cat -A`.
- The workspace dots are centred using measured font metrics; the reasoning is in comments in
  `eww.scss` (`.workspaces`, `.ws-icon`). Re-check with a screenshot if you change the font size
  or padding.

### rofi (`dot_config/rofi/`)

- `config.rasi` is the app launcher; it uses the theme `~/.local/share/rofi/themes/catppuccin.rasi`.
- The bar menus (wifi, VPN, audio output, power) share the layout in `dropdown.rasi`. Each menu's `theme.rasi`
  only sets `menu-color` and `menu-width`.
- **Menus are placed from the real widget geometry, never hand-measured offsets.**
  `eww/scripts/bar_anchor.py` finds the bar button under the pointer in eww's accessibility tree
  (AT-SPI, through python-gobject), and `rofi_menu` pads the menu to the button's bottom and right
  edges. A button's "pill" is the innermost widget spanning the bar's full height, so keep pills'
  contents inside their padding and their margins on the left. Without AT-SPI the pointer stands in
  for the right edge. The anchor is found once per script (`MENU_ANCHOR`), so a follow-up menu (the
  Wi-Fi password prompt, a rescan) opens in the same place.
- rofi 2.0's `click-to-exit` is **not implemented on Wayland**. So the dropdown window covers the
  screen transparently, and `rofi_menu` binds `MousePrimary` to `kb-cancel`. Clicks on an entry are
  handled by the entry first; clicks on empty space cancel.
- Rasi limits found the hard way:
  - A variable can't go inside a multi-value property (`padding: 5px @x 0 0` fails to parse).
  - Boxes accept `width` but not `height`, so the row count is set with `-theme-str`.

### Notifications (`dot_config/dunst/dunstrc`)

- dunst places notifications below the eww bar's reserved space, so `offset = 5x5` means "5px under
  the bar".
- Colours and the icon theme are in the drop-in `dunstrc.d/colors.conf`, which links to the active
  scheme (see "Colours"); `dunstrc` holds only layout and timeouts.
- The frosted-glass look is translucent backgrounds (`#RRGGBBAA` in the colour template) plus a
  Hyprland `layer_rule` that blurs the `notifications` layer.
- Icons are capped at 24px so Papirus serves its flat monochrome glyphs; at 32px and up it switches
  to the colourful set. App icons (Firefox etc.) still show in full colour.

### Colours

Everything uses **Catppuccin**: Mocha in dark mode and Latte in light mode. On the desktop the
whole session switches at sunrise and sunset. **Never write hex colours into a tool's config**;
use palette names from the active scheme.

How it fits together:

1. **Palette:** `.chezmoidata/catppuccin.toml` holds all four flavours. `.chezmoidata/colorscheme.toml`
   picks `dark` and `light`, and each mode's wallpapers (desktop and lock screen, relative to
   `$HOME`; the images aren't tracked). Change a flavour or wallpaper there, nowhere else.
2. **Templates:** `.chezmoitemplates/colors/<file>` renders one tool's colours. Its `.` is one
   flavour's map (`.base`, `.blue`, ..., plus `.name`, e.g. `"latte"`).
3. **Per-mode files:** one-line stubs in `dot_config/colorscheme/{dark,light}/` render each
   template into `~/.config/colorscheme/<mode>/`, e.g.
   `{{ template "colors/eww.scss" (index .catppuccin .colorscheme.dark) }}`.
4. **Active scheme:** `colorscheme dark|light|toggle` (`dot_local/bin/executable_colorscheme`)
   copies a mode's files into `~/.local/state/colorscheme/current/` (untracked state), writes
   `~/.local/state/colorscheme/mode`, and reloads running tools. `colorscheme-solar` calls it from
   a systemd timer. Switching therefore never touches a managed file.
5. **Tools read `current/`** through their own include mechanism, so their main configs stay
   plain files:

   | Tool | How |
   |------|-----|
   | alacritty | `import` of `current/alacritty.toml`; live-reloads by itself |
   | eww | `@import "colors"`; `colors.scss` is a chezmoi symlink to `current/eww.scss` |
   | rofi | `@import "~/.local/state/colorscheme/current/rofi.rasi"` |
   | dunst | `dunstrc.d/colors.conf`, a symlink to `current/dunst.conf` |
   | Hyprland | `pcall(dofile, ...current/hypr.lua)` returns hex without `#`, with a fallback |
   | hyprlock | `source = ~/.local/state/colorscheme/current/hyprlock.conf` (`$blue` = `rgb(...)`, plus `$wallpaper`) |
   | hyprpaper | `hypr/hyprpaper.conf` is a symlink to `current/hyprpaper.conf`; `colorscheme` sets the wallpaper over IPC |
   | GTK4 | `gtk-4.0/gtk.css` is a symlink to `current/gtk4.css` |
   | GTK3 | `gtk-3.0/settings.ini` is a symlink to `current/gtk3.ini`; the theme name also goes to gsettings |
   | nvim | `lua/flavours.lua.tmpl` (flavour names) and a watcher on the mode file |
   | satty | `config.toml.tmpl`: annotation colours from the dark flavour, not switched |

**To add a tool:**

1. Write `.chezmoitemplates/colors/<file>`.
2. Add a stub to both `dot_config/colorscheme/dark/` and `.../light/`.
3. Point the tool at `~/.local/state/colorscheme/current/<file>`, with a `symlink_` entry if the
   tool can only include relative paths.
4. If the tool doesn't re-read the file by itself, add its reload command to `colorscheme`.

A template that needs a per-mode value besides colours gets it merged into the palette by its
stub, e.g. hyprlock's `(merge (dict "wallpaper" ...) (index .catppuccin .colorscheme.dark))`. A
template whose `.` is only a path (hyprpaper) is passed that directly.

`chezmoi apply` runs `run_onchange_after_colorscheme.sh` when templates or palette change; it
re-applies the current mode.

Details:

- nvim on every machine reads `~/.local/state/colorscheme/mode` (dark if missing) and flips
  live when it changes. On the Mac or WSL something else may write it, or nothing.
- GTK3 needs the AUR themes `catppuccin-gtk-theme-mocha` and `catppuccin-gtk-theme-latte`
  (`catppuccin-<flavour>-blue-standard+default`). They're also used by the
  xdg-desktop-portal-gtk file dialog, which follows gsettings live.
- GTK4: some apps' own CSS uses libadwaita's old named colours (satty's toolbar uses
  `@headerbar_bg_color`), so `gtk4.css` sets every colour both as a CSS variable and with
  `@define-color`. A plain selector like `.toolbar {}` in `gtk.css` loses to app CSS.
- Don't force GTK4's built-in file chooser (`GDK_DEBUG=no-portals`): it fails here with "folder
  contents could not be displayed".
- An alacritty window watches only the import paths it saw at startup; windows opened before an
  import path changes won't live-switch until reopened.

The bar font is "Iosevka Term Extended"; icons come from "Iosevka Nerd Font".

### Shell (`dot_config/zsh/`)

- `rm` is aliased to `rm -v`; inside functions use `command rm` to stay quiet.
- `yazi` is wrapped by a function that hides `HYPRLAND_INSTANCE_SIGNATURE`, so yazi uses its
  built-in chafa image previews. Its ueberzugpp mode puts the image mid-screen on this Hyprland.
  The Win+E bind does the same with `env -u`.
- `y` runs yazi and `cd`s to the last directory you browsed. zoxide (`z`, `zi`) is initialised
  last, only if it's installed.

### Neovim (`dot_config/nvim/`)

Full usage and implementation docs: `dot_config/nvim/README.md` (also deployed to
`~/.config/nvim/README.md`). Keep it in step with the config.

- lazy.nvim, with one spec file per area in `lua/plugins/`. Options, keymaps and autocmds live in
  `lua/config/` and load before the plugins.
- **Lockfile:** `~/.config/nvim/lazy-lock.json` is a symlink (`symlink_lazy-lock.json.tmpl`) to
  `dot_config/nvim/.lazy-lock.json` in this repo; the leading dot stops chezmoi deploying it as a
  file. `:Lazy update` writes straight into the repo, so commit the lock afterwards
  (`nvim: update plugins`). On the other machines, `chezmoi apply`, then `:Lazy restore` to check
  out the same commits. If highlighting then fails with "Invalid node type", the queries are
  newer than the parsers: run `:TSUpdate`.
- **Removing a plugin spec file:** also list it in `.chezmoiremove`. lazy.nvim loads every file in
  `lua/plugins/`, and chezmoi leaves deleted files behind on the other machines.
- **Formatting:** conform formats on save only when the project has that formatter's config (the
  `project_config` table in `lua/plugins/formatting.lua`); this config has `stylua.toml`.
  `<leader>cf` formats on demand, `<leader>uf` toggles format on save.
- Mason installs the language servers (`ensure_installed` in `lsp.lua`) and stylua, ruff and
  shfmt. clang-format and rustfmt come from the system, and the treesitter parsers need the
  `tree-sitter` CLI.

## Not tracked here (on purpose)

- `~/.config/zsh/local.zsh`: per-machine settings.
- `~/.local/state/colorscheme/`: the active scheme and mode, written by `colorscheme`.
- `~/.config/systemd/user/colorscheme-solar-transition.timer`: rewritten by `colorscheme-solar`
  for each sunrise and sunset.
- `~/.claude/`: Claude Code settings and hooks, including the desktop notification hook.
- `~/eww`: eww source checkout.
- `hypr/images/`: wallpapers.
- Old repo backup: `~/.local/share/config-git-backup`. This is the pre-chezmoi `~/.config/.git`;
  it can be deleted once the user is happy.
