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
| `run_onchange_after_colorscheme.sh.tmpl` | Re-runs `colorscheme` when the palette, a colour template or the accent picker changes. Desktop only (renders empty elsewhere). |
| `README.md`, `AGENTS.md`, `CLAUDE.md` | Docs, ignored by chezmoi (not deployed). |

## Machine types

`.chezmoi.toml.tmpl` writes `~/.config/chezmoi/chezmoi.toml` on `chezmoi init`:

- `wsl`: Linux whose kernel release contains "microsoft"
- `desktop`: Linux and not WSL

What each machine gets:

- **Every machine:** zsh (`ZDOTDIR=~/.config/zsh` via `dot_zshenv`), nvim, clangd.
- **Desktop only:** `hypr`, `eww`, `rofi` (+ `~/.local/share/rofi`), `dunst`, `kitty`,
  `gtk-3.0`, `gtk-4.0`, `satty`, `chromium-flags.conf`, `zsh/.zprofile` (starts Hyprland on tty1),
  and the light/dark switching: `~/.config/colorscheme/`, `~/.local/bin/colorscheme`,
  `~/.local/bin/colorscheme-accents`, `~/.local/bin/colorscheme-solar`, `~/.local/bin/wallpaper`
  and `~/.config/systemd/`.

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
| hyprlock | never the real config (see the trap below): `hyprlock -c test.conf --grace 60 &`, screenshot, then `pkill -USR1 -x hyprlock`; `faillock --user $USER` lists no new failures |
| visual result | `grim -g "x,y wxh" out.png` (screen scale is 1.5, so the image is in physical px) |
| bar widget geometry | `~/.config/eww/scripts/bar_anchor.py` prints where a menu would hang from the button under the pointer |

Some things can't be checked from a non-interactive shell: rofi menus, keybinds, mouse behaviour.
For those, ask the user to try them, or open a test instance with dummy data in the background
and ask them to interact with it.

Shell traps:

- `eww logs` follows the log forever; wrap it in `timeout`.
- `pkill -f pattern` also matches your own shell, whose command line contains the pattern.
  Anchor it (`pkill -f '^kitty --class test'`) or use `pkill -x name`.
- Importing a Python script (e.g. `bar_anchor.py` in a test) writes `__pycache__/` next to it. In
  the source directory chezmoi would deploy that, so set `PYTHONDONTWRITEBYTECODE=1`, and don't
  combine it with `python3 -I`, which ignores it.
- Ending a real `hyprlock` with `SIGUSR1` or the grace period aborts its PAM password prompt, which
  pam_faillock can count as a failed login. Three of those lock the account, `sudo` included,
  for 10 minutes. So test with a `test.conf` (anywhere outside this directory) that turns PAM off:
  `source = ~/.config/hypr/hyprlock.conf`, `auth:pam:enabled = false` and
  `auth:fingerprint:enabled = true` (hyprlock needs one method; without fprintd it authenticates
  nothing). Any input during the grace period unlocks too, so screenshot after about a second.

## Component notes and gotchas

### Hyprland (`dot_config/hypr/hyprland.lua`)

- This is Hyprland **0.56 with the Lua config**. `hyprctl dispatch` takes Lua (`hl.dsp...`). The old
  string dispatchers (`movewindowpixel exact ...`) fail, which also breaks third-party tools that
  use them, such as ueberzugpp positioning.
- `mainMod` is SUPER. Check for conflicts before binding a key: Win+Shift+S already moves a
  window to the special workspace, Win+V toggles floating, and Win+Shift+W opens the wallpaper
  picker. Binds are `hl.bind(...)`; a bare `bind` is nil and stops the config at that line.
- Window and layer rules use `hl.window_rule({...})`. Some field names differ from the old config:
  use `border_size = 0`, not `no_border`.
- Wallpapers in `hypr/images/` are intentionally untracked (large files).

### Lock screen (`dot_config/hypr/hyprlock.conf`)

- Positions and sizes are in physical pixels. With `valign = center` a widget's y is its centre's
  distance above the screen's centre.
- The layout is computed from `$` variables at the top with hyprlang arithmetic: `{{a + b}}`,
  one operation per pair of braces, on numbers or variable names without the `$`.
- The text sits on a frosted card. hyprlock can only blur its whole background, so
  `hypr/scripts/hyprlock_card.py` renders the wallpaper behind the card, blurred and tinted with
  `$base`, to `~/.local/state/colorscheme/current/hyprlock-card.png`. hyprlock draws that as an
  image inside the card's rim. `colorscheme` re-renders it on every switch, and
  `run_onchange_after_colorscheme.sh` re-runs when `hyprlock.conf` or the script changes. The
  script reads the `$card_*` variables itself, so keep them as plain numbers or `{{a op b}}`.
- The tint's opacity adapts to the wallpaper: at least `$card_opacity`, and as much more as
  `$dim_text` (the date's colour) needs to reach `$card_contrast` : 1 everywhere on the card. A
  light card over a dark wallpaper needs far more than a dark one.
- hyprlock draws images after shapes unless `zindex` says otherwise. An image's `size` is its
  shorter side.

### eww bar (`dot_config/eww/`)

- The `eww` binary is `~/.local/bin/eww`, built from the source checkout in `~/eww`. That checkout
  isn't part of this repo.
- Scripts live in `scripts/`. Shared helpers are in `scripts/lib.sh`; load them with
  `source "${BASH_SOURCE%/*}/lib.sh"`:

  | Helper | What it does |
  |--------|--------------|
  | `rofi_menu THEME` | Shows a rofi dropdown under the clicked bar button and prints the chosen option. |
  | `rofi_menu_streamed THEME LINES` | The same, but rows arriving on stdin later are added while it's shown (room for LINES; rofi can't resize an open menu). |
  | `nm_connections TYPE [--active]` | Prints NetworkManager connection names of that type. |
  | `bluez_objects` | Prints BlueZ's objects (adapters, devices) as JSON, `{path: {interface: {property: value}}}`. |
  | `popup_anchor` | Prints `RIGHT TOP` for an eww popup window hanging from the clicked button. |
  | `hypr_events` | Streams Hyprland's event socket. |
  | `drain_burst` | Waits out a burst of events (until 50ms of quiet). |
  | `emit` | Prints a widget's state only when it changed. |

- Widgets are **event-driven** (`deflisten`), not polled. Listeners print an initial state, then
  re-render on events:
  - `workspaces.sh` and `keyboard.sh` use Hyprland's socket.
  - `network.sh` uses `nmcli monitor`.
  - `bluetooth.sh` uses `gdbus monitor --system --dest org.bluez` (`dbus-monitor --system` needs
    root), filtered to power, connection, scan (`Discovering`) and add/remove signals.
  - `volume.sh` and `mixer.sh` (the mixer popup) use `pactl subscribe`.
  - The clock is `formattime(EWW_TIME, ...)`.
  - `gpu.sh` streams `nvidia-smi --loop=2` (one long-lived process).
  - `weather.sh` is the one that has to poll: it fetches Open-Meteo (no API key) every 15 minutes
    in its own loop, at the location `colorscheme-solar` caches, and early when `nmcli monitor`
    reports the network coming online (e.g. after a suspend). The details are its tooltip.
  - `notifications.sh` uses `gdbus monitor --session --dest org.freedesktop.Notifications`
    (dunst's `displayedLength` changes as a notification moves into the history), plus a FIFO in
    `$XDG_RUNTIME_DIR` that `notification_history.sh` writes to after marking them seen, and
    `notification_added.sh` (a dunst rule's script) for notifications that skip the screen.
  - CPU, memory and temperatures use eww's built-in `EWW_CPU`, `EWW_RAM` and `EWW_TEMPS`,
    which eww samples itself.

  Follow this pattern for new widgets; avoid `defpoll` with external commands.
- `pactl subscribe` must be filtered to `sink`/`server` events. `pamixer` and `pactl` calls create
  `client` events, so reacting to those loops forever.
- Never run `nmcli dev wifi` without `--rescan no`: it triggers an ~8s scan.
- The notification history is an eww window (`notifications.yuck`), not a rofi menu. It covers
  the screen on the overlay layer, with transparent buttons around the card that close it, and is
  placed from `bar_anchor.py` like the menus. Layer-shell keeps it out of the bar's exclusive zone,
  so its `top` is shifted up by Hyprland's reserved space. The count is of notifications newer than
  the ID in `~/.local/state/eww/notifications-seen`, stored with dunst's D-Bus name so a restarted
  dunst (whose IDs start again at 1) counts from zero. dunst sends `NotificationClosed` only to the
  app that sent the notification, so a listener never sees it.
- The volume mixer (right-click on the volume icon) is the same kind of popup, `volume_mixer` in
  `volume.yuck`: outputs, then a slider and mute button per app. Its `mixer.sh` listener runs only
  while the popup is open (eww starts a `deflisten` when a window uses it). App icons are passed
  as file paths (Papirus first), because eww's GTK icon theme is Adwaita.
- In a box, eww puts a `for`'s widgets after their siblings, not where the `for` is written. Give
  each `for` a box of its own.
- A `for` rebuilds all its widgets on **any** change to its variable, even to fields it doesn't
  show; a slider being dragged is destroyed and the drag stops. Keep fast-changing values (the
  mixer's volumes, `mixer_levels`) in a separate variable that the rows look up by key.
- eww starts the listeners for the variables a window uses when it opens. A variable used only
  inside a `for`'s rows, which don't exist yet, never starts, so use it in a static widget too.
- BlueZ: read its state and act through `busctl` (`bluez_objects` in lib.sh). Pairing needs an
  agent, which `bluetoothctl` registers only in interactive mode (`--agent` does nothing with a
  command), so `scripts/bt_pair.py` registers its own and calls Pair. Use `bluetoothctl` only to
  scan, as a scan lasts as long as the client that started it. Non-interactively it can hang on
  errors (e.g. an unknown address), so run it under `timeout`. BlueZ drops every device's RSSI as
  soon as discovery stops, which is why the menu keeps a scan running while it's open.
- **Nerd Font glyphs**: icons in `.yuck` and `.sh` files are private-use Unicode characters that
  may not render in your editor or tool output. Don't retype or rewrite lines containing them.
  Edit only the surrounding ASCII (e.g. a Python `str.replace` on exact substrings), and check
  with `od -c` or `cat -A`.
- The workspace dots are centred using measured font metrics; the reasoning is in comments in
  `eww.scss` (`.workspaces`, `.ws-icon`). Re-check with a screenshot if you change the font size
  or padding.

### rofi (`dot_config/rofi/`)

- `config.rasi` is the app launcher; it uses the theme `~/.local/share/rofi/themes/catppuccin.rasi`.
- The bar menus (wifi, VPN, Bluetooth, media, power) share the layout in
  `dropdown.rasi`. Each menu's `theme.rasi` only sets `menu-color` and `menu-width`.
- **Menus are placed from the real widget geometry, never hand-measured offsets.**
  `eww/scripts/bar_anchor.py` finds the bar button under the pointer in eww's accessibility tree
  (AT-SPI, through python-gobject), and `rofi_menu` pads the menu to the button's bottom and right
  edges. A button's "pill" is the innermost widget spanning the bar's full height, so keep pills'
  contents inside their padding and their margins on the left. Without AT-SPI the pointer stands in
  for the right edge. The anchor is found once per script (`MENU_ANCHOR`), so a follow-up menu (the
  Wi-Fi password prompt, a rescan) opens in the same place.
- rofi 2.0's `click-to-exit` is **not implemented on Wayland**. So the dropdown window covers the
  screen transparently, and `rofi_menu` binds `MousePrimary` to `kb-cancel`. Clicks on an entry are
  handled by the entry first; clicks on empty space cancel. The launcher does the same: its window
  is full-screen with the box centred by filler widgets, `kb-cancel` is set in `config.rasi`, and
  its height comes from `listview { lines }`.
- Rasi limits found the hard way:
  - A variable can't go inside a multi-value property (`padding: 5px @x 0 0` fails to parse).
  - Boxes accept `width` but not `height`, so the row count is set with `-theme-str`.

### Notifications (`dot_config/dunst/dunstrc`)

- Only critical notifications pop up. The `quiet_low` and `quiet_normal` rules send the rest straight
  into the history (`skip_display`), where the bell on the bar shows them; their `script` wakes the
  bar's listener. So a `notify-send` test of the look needs `-u critical`.
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
   picks `dark` and `light`, and each mode's default wallpaper (desktop and lock screen, relative
   to `$HOME`; the images aren't tracked). Change a flavour there, nowhere else.
2. **Templates:** `.chezmoitemplates/colors/<file>` renders one tool's colours. Its `.` is one
   flavour's map (`.base`, `.blue`, ..., plus `.name`, e.g. `"latte"`).
3. **Per-mode files:** one-line stubs in `dot_config/colorscheme/{dark,light}/` render each
   template into `~/.config/colorscheme/<mode>/`, e.g.
   `{{ template "colors/eww.scss" (index .catppuccin .colorscheme.dark) }}`.
4. **Active scheme:** `colorscheme dark|light|toggle` (`dot_local/bin/executable_colorscheme`)
   copies a mode's files into `~/.local/state/colorscheme/current/` (untracked state), via a
   staging directory where `colorscheme-accents` picks the accents (below). Then it writes
   `~/.local/state/colorscheme/mode` and reloads running tools. `colorscheme-solar` calls it from
   a systemd timer. Switching therefore never touches a managed file.
5. **Tools read `current/`** through their own include mechanism, so their main configs stay
   plain files:

   | Tool | How |
   |------|-----|
   | kitty | `include` of `current/kitty.conf`; `colorscheme` sends it SIGUSR1 to reload |
   | eww | `@import "colors"`; `colors.scss` is a chezmoi symlink to `current/eww.scss` |
   | rofi | `@import "~/.local/state/colorscheme/current/rofi.rasi"` |
   | dunst | `dunstrc.d/colors.conf`, a symlink to `current/dunst.conf` |
   | Hyprland | `pcall(dofile, ...current/hypr.lua)` returns hex without `#`, with a fallback |
   | hyprlock | `source = ~/.local/state/colorscheme/current/hyprlock.conf` (`$blue` = `rgb(...)`, the card's translucent `$panel_rim` and `$panel_fill`, plus `$wallpaper`, and `$accent` and `$date_colour` for the greeting and the date) |
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

**Accents follow the wallpaper.** The scheme's main colours are an accent pair: `accent` for
highlights (the workspaces pill, the launcher, GTK's accent, kitty's active tab, the lock screen's
greeting) and `accent2` beside it (the second colour of the window border's gradient, the lock
screen's date). The templates set them to blue and mauve. `dot_local/bin/executable_colorscheme-accents`
then replaces them in the staged files with the Catppuccin accents nearest the wallpaper's main
hues, and points the files at the wallpaper:

- Formats with variables get palette names appended (`$accent: $peach;`, `accent: @peach;`,
  `$accent = $peach`). kitty and GTK4 get hex appended, which wins over the earlier lines.
  `hypr.lua`, `gtk3.ini` and `hyprpaper.conf` have a line rewritten.
- The rules are in its docstring: never red (it means an error), at least 3:1 on `base` (which
  leaves Latte only mauve, maroon, blue, green and teal), and blue/mauve for a grey wallpaper.
- `colorscheme-accents --print ~/Pictures/wallpapers/*` shows what it would pick for each mode.
- If it fails, `colorscheme` keeps the defaults. Use `$accent`/`@accent`/`c.accent` for anything
  that should match the wallpaper; a tool without variables needs a line in `colorscheme-accents`.

**Changing the wallpaper** doesn't touch the repo. `wallpaper FILE` (`dot_local/bin/executable_wallpaper`)
writes the path to `~/.local/state/colorscheme/wallpaper/dark` and `.../light` (`--mode MODE` for
one of them) and re-runs `colorscheme`, which passes the current mode's to `colorscheme-accents`. A
mode without one gets the default from `colorscheme.toml`. Win+Shift+W, or `wallpaper` with no
arguments, opens a rofi grid of `~/Pictures/wallpapers` (`rofi/wallpaper/theme.rasi`, laid out like
the launcher): Enter sets both modes, Shift+Enter the current one. Its thumbnails are square,
because rofi fits an icon into a square, and cached in `~/.cache/wallpaper/`.

`chezmoi apply` runs `run_onchange_after_colorscheme.sh` when templates or palette change; it
re-applies the current mode.

Details:

- nvim on every machine reads `~/.local/state/colorscheme/mode` (dark if missing) and flips
  live when it changes. On the Mac or WSL something else may write it, or nothing.
- GTK3 needs the AUR themes `catppuccin-gtk-theme-mocha` and `catppuccin-gtk-theme-latte`
  (`catppuccin-<flavour>-<accent>-standard+default`, every accent). They're also used by the
  xdg-desktop-portal-gtk file dialog, which follows gsettings live.
- GTK4: some apps' own CSS uses libadwaita's old named colours (satty's toolbar uses
  `@headerbar_bg_color`), so `gtk4.css` sets every colour both as a CSS variable and with
  `@define-color`. A plain selector like `.toolbar {}` in `gtk.css` loses to app CSS.
- Don't force GTK4's built-in file chooser (`GDK_DEBUG=no-portals`): it fails here with "folder
  contents could not be displayed".

The bar font is "Iosevka Term Extended"; icons come from "Iosevka Nerd Font".

### Shell (`dot_config/zsh/`)

- `rm` is aliased to `rm -v`; inside functions use `command rm` to stay quiet.
- yazi shows image previews through kitty's graphics protocol. Don't route it through ueberzugpp:
  that puts the image mid-screen on this Hyprland.
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
- **Spelling:** `~/.config/nvim/spell/en.utf-8.add` is a symlink to
  `dot_config/nvim/spell/.en.utf-8.add` the same way, so `zg` writes into the repo. Commit it as
  `nvim: add words to the spell list`. `options.lua` recompiles it at startup when it's newer than
  its untracked `.spl`.
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
- `~/.local/state/colorscheme/`: the active scheme and mode, written by `colorscheme`, and each
  mode's wallpaper, written by `wallpaper`.
- `~/.config/systemd/user/colorscheme-solar-transition.timer`: rewritten by `colorscheme-solar`
  for each sunrise and sunset.
- `~/.claude/`: Claude Code settings and hooks, including the desktop notification hook.
- `~/eww`: eww source checkout.
- `hypr/images/`: wallpapers.
- Old repo backup: `~/.local/share/config-git-backup`. This is the pre-chezmoi `~/.config/.git`;
  it can be deleted once the user is happy.
