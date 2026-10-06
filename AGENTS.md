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
| `dot_config/hypr/hyprpaper.conf.tmpl` | `~/.config/hypr/hyprpaper.conf` (Go template) |

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
| `README.md`, `AGENTS.md`, `CLAUDE.md` | Docs, ignored by chezmoi (not deployed). |

## Machine types

`.chezmoi.toml.tmpl` writes `~/.config/chezmoi/chezmoi.toml` on `chezmoi init`:

- `wsl`: Linux whose kernel release contains "microsoft"
- `desktop`: Linux and not WSL

What each machine gets:

- **Every machine:** zsh (`ZDOTDIR=~/.config/zsh` via `dot_zshenv`), nvim, clangd.
- **Desktop only:** `hypr`, `eww`, `rofi` (+ `~/.local/share/rofi`), `dunst`, `alacritty`,
  `gtk-3.0`, `gtk-4.0`, `satty`, `chromium-flags.conf`, `zsh/.zprofile` (starts Hyprland on tty1).

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
| visual result | `grim -g "x,y wxh" out.png` (screen scale is 1.5, so the image is in physical px) |

Some things can't be checked from a non-interactive shell: rofi menus, keybinds, mouse behaviour.
For those, ask the user to try them, or open a test instance with dummy data in the background
and ask them to interact with it.

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
  | `rofi_menu THEME` | Shows a rofi dropdown and prints the chosen option. |
  | `nm_connections TYPE [--active]` | Prints NetworkManager connection names of that type. |
  | `hypr_events` | Streams Hyprland's event socket. |
  | `drain_burst` | Waits out a burst of events (until 50ms of quiet). |
  | `emit` | Prints a widget's state only when it changed. |

- Widgets are **event-driven** (`deflisten`), not polled. Listeners print an initial state, then
  re-render on events:
  - `workspaces.sh` and `keyboard.sh` use Hyprland's socket.
  - `network.sh` uses `nmcli monitor`.
  - `volume.sh` uses `pactl subscribe`.
  - The clock is `formattime(EWW_TIME, ...)`.

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

- `config.rasi` is the app launcher; it uses the theme `~/.local/share/rofi/themes/catppuccin-frappe.rasi`.
- The bar menus (wifi, VPN, power) share the layout in `dropdown.rasi`. Each menu's `theme.rasi`
  only sets `menu-color`, `menu-width` and `menu-right`.
- rofi 2.0's `click-to-exit` is **not implemented on Wayland**. So the dropdown window covers the
  screen transparently, and `rofi_menu` binds `MousePrimary` to `kb-cancel`. Clicks on an entry are
  handled by the entry first; clicks on empty space cancel.
- Rasi limits found the hard way:
  - A variable can't go inside a multi-value property (`padding: 5px @x 0 0` fails to parse).
  - Boxes accept `width` but not `height`, so the row count is set with `-theme-str`.

### Notifications (`dot_config/dunst/dunstrc`)

- dunst places notifications below the eww bar's reserved space, so `offset = 5x5` means "5px under
  the bar".
- Colours follow the palette below. The border uses the bar's blue, red for critical.

### Theming

The whole desktop uses **Catppuccin Frappé**:

| Name | Colour |
|------|--------|
| base | `#303446` |
| mantle | `#292c3c` |
| crust | `#232634` |
| surface0 | `#414559` |
| overlay0 | `#737994` |
| text | `#c6d0f5` |
| subtext0 | `#a5adce` |
| blue | `#8caaee` |
| red | `#e78284` |
| yellow | `#e5c890` |
| green | `#a6d189` |
| mauve | `#ca9ee6` |

The bar font is "Iosevka Term Extended"; icons come from "Iosevka Nerd Font".

- **GTK4 / libadwaita** (e.g. satty): colour variables in `private_gtk-4.0/gtk.css`.
- **GTK3** and the file dialog from xdg-desktop-portal-gtk: the `catppuccin-frappe-blue-standard+default`
  theme (AUR package), set in `private_gtk-3.0/settings.ini` and gsettings.
- Don't force GTK4's built-in file chooser (`GDK_DEBUG=no-portals`): it fails here with "folder
  contents could not be displayed".

### Shell (`dot_config/zsh/`)

- `rm` is aliased to `rm -v`; inside functions use `command rm` to stay quiet.
- `yazi` is wrapped by a function that hides `HYPRLAND_INSTANCE_SIGNATURE`, so yazi uses its
  built-in chafa image previews. Its ueberzugpp mode puts the image mid-screen on this Hyprland.
  The Win+E bind does the same with `env -u`.
- `y` runs yazi and `cd`s to the last directory you browsed. zoxide (`z`, `zi`) is initialised
  last, only if it's installed.

## Not tracked here (on purpose)

- `~/.config/zsh/local.zsh`: per-machine settings.
- `~/.claude/`: Claude Code settings and hooks, including the desktop notification hook.
- `~/eww`: eww source checkout.
- `hypr/images/`: wallpapers.
- `nvim/lazy-lock.json`.
- Old repo backup: `~/.local/share/config-git-backup`. This is the pre-chezmoi `~/.config/.git`;
  it can be deleted once the user is happy.
