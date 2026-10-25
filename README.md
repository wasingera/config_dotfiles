# config_dotfiles

Dotfiles for Linux (Hyprland desktop), macOS and WSL, managed with [chezmoi](https://www.chezmoi.io).

Every machine gets the shared baseline (zsh, nvim, tmux, clangd). The Hyprland desktop
configs (hypr, eww, rofi, dunst, kitty, yazi, zathura, GTK/satty theming, Chromium flags)
are only applied on native Linux.

## Install on a new machine

```sh
# Arch: sudo pacman -S chezmoi    macOS: brew install chezmoi
chezmoi init --apply git@github.com:wasingera/config_dotfiles.git
```

This also sets `ZDOTDIR` (via `~/.zshenv`), creates the zsh history folder and
downloads the zsh plugins.

## Dependencies

chezmoi only places config files; the programs they configure come from the package
manager. The zsh and tmux plugins (`.chezmoiexternal.toml`) and nvim's plugins, language
servers and formatters (lazy.nvim and Mason) download themselves, but need the tools below.

### Every machine

| What | Arch | Homebrew | Why |
|------|------|----------|-----|
| chezmoi, git, curl | `chezmoi git curl` | `chezmoi git` | applying the repo, downloading plugins |
| zsh | `zsh` | built in | the shell; the pure prompt needs git |
| tmux 3.3+ | `tmux` | `tmux` | `allow-passthrough` and popups |
| fzf, zoxide | `fzf zoxide` | `fzf zoxide` | the tmux session picker and extrakto (`prefix f`, `prefix Tab`), `z`/`zi` |
| python3 | `python` | `python@3.13` (or the Xcode tools' python3) | extrakto; Mason's Python packages (basedpyright) |
| Neovim 0.12+ | `neovim` | `neovim` | |
| C compiler, make | `gcc make` | Xcode Command Line Tools | building treesitter parsers |
| tree-sitter CLI | `tree-sitter-cli` | `tree-sitter-cli` | building treesitter parsers |
| ripgrep, fd | `ripgrep fd` | `ripgrep fd` | nvim's grep and file pickers |
| unzip, tar, gzip | `unzip` (tar, gzip are in base) | built in | Mason's downloads |
| Node.js and npm | `nodejs npm` | `node` | Mason's npm packages (jsonls) |
| A Nerd Font in the terminal | `ttf-iosevka-nerd` | `--cask font-iosevka-nerd-font` | icons in nvim, tmux and the prompt |

Optional, all machines:

| What | Arch | Homebrew | Why |
|------|------|----------|-----|
| lazygit | `lazygit` | `lazygit` | `<leader>gg` in nvim |
| clang-format, rustfmt | `clang` / `rustup` | `clang-format` / `rustup` | C/C++ and Rust formatting |
| yazi | `yazi` | `yazi` | the `y` file browser |
| A terminal with the kitty graphics protocol (kitty, Ghostty, WezTerm) | `kitty` | `--cask kitty` | images and rendered LaTeX math in nvim |
| ImageMagick and a TeX distribution | `imagemagick texlive-basic texlive-latex texlive-latexrecommended` | `imagemagick`, `--cask basictex` | rendered math in nvim |
| latexmk and a PDF viewer | `texlive-binextra` and the desktop's zathura | `--cask skim`, then `sudo tlmgr install latexmk mathtools` for BasicTeX | LaTeX documents with vimtex |

### macOS

Run `xcode-select --install` first. It provides git, clang, make and `swift`, which runs
`colorscheme-macos`, the LaunchAgent that switches nvim between light and dark with the
system appearance. Everything else is in the Homebrew column above.

### WSL

Only the "every machine" list applies; the desktop configs are skipped. Distro packages
work, with two catches on Ubuntu/Debian (the WSL default):

- Their `neovim` is older than 0.12. Install the release build from
  [GitHub](https://github.com/neovim/neovim/releases) instead.
- `fd` is packaged as `fd-find`, whose command is `fdfind`. Link it as `fd`:
  `ln -s "$(command -v fdfind)" ~/.local/bin/fd`.

`npm install -g tree-sitter-cli` works where the distro has no tree-sitter CLI.

### Desktop (Arch + Hyprland)

On top of the "every machine" list:

| Area | Packages | Used by |
|------|----------|---------|
| Session | `hyprland hyprpaper hyprlock xdg-desktop-portal-hyprland xdg-desktop-portal-gtk` | the compositor (started from `.zprofile` on tty1), wallpaper, lock screen, screen sharing and file dialogs |
| Bar | eww, built from source (below), `jq socat curl` | the bar and its listener scripts; `socat` reads Hyprland's event socket, `curl` fetches the weather |
| Bar menus | `rofi python-gobject at-spi2-core` | the dropdown menus; `bar_anchor.py` finds the clicked button through AT-SPI |
| Notifications | `dunst libnotify` | notifications and the bell's history (`gdbus` comes with `glib2`) |
| Network | `networkmanager` | the Wi-Fi and VPN widgets (`nmcli`) |
| Bluetooth | `bluez bluez-utils` | the Bluetooth widget and pairing (`bluetoothctl`; `busctl` comes with systemd) |
| Audio | `pipewire pipewire-pulse wireplumber libpulse` | volume keys (`wpctl`), the volume widget and mixer (`pactl subscribe`) |
| Media | `playerctl` | the media widget and media keys (`playerctld` is started by Hyprland) |
| Screenshots | `grim slurp wl-clipboard satty` | Print, Shift+Print, Ctrl+Print |
| Apps | `kitty yazi imv zathura zathura-pdf-mupdf chromium` | terminal, file manager (Win+E) and its image viewer, the PDF viewer vimtex opens, the browser (`chromium-flags.conf`, the Apple Music app) |
| Colours | `python-pillow papirus-icon-theme`, AUR `catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte` | `colorscheme-accents`, the wallpaper picker and the lock screen's card; icons; GTK3 apps and file dialogs |
| Fonts | `ttc-iosevka ttf-iosevka-nerd` | "Iosevka Term" (kitty), "Iosevka Term Extended" (bar, menus), "Iosevka Nerd Font" (icons) |
| Hardware-specific | `nvidia-utils` (NVIDIA only), `brightnessctl` (laptops) | the GPU widget (`nvidia-smi`); the brightness keys |

eww comes from its source checkout in `~/eww` rather than a package. It needs
[rustup](https://rustup.rs) and `gtk3 gtk-layer-shell pango gdk-pixbuf2 libdbusmenu-gtk3 cairo glib2`:

```sh
git clone https://github.com/elkowar/eww ~/eww
cd ~/eww && cargo build --release
install -Dm755 target/release/eww ~/.local/bin/eww
```

After `chezmoi apply` on a new desktop, start the sunrise/sunset switch once with
`systemctl --user enable --now colorscheme-solar.timer` (see "Colours").

## Migrating a machine from the old layout

Before this, `~/.config` itself was the git repo. On a machine still set up that way:

```sh
mv ~/.config/.git ~/config-git-backup   # stop ~/.config being a repo
chezmoi init git@github.com:wasingera/config_dotfiles.git
chezmoi diff                            # review what will change
chezmoi apply
```

`chezmoi apply` deletes the old repo's leftover `~/.config/.gitignore` and
`~/.config/.gitmodules`, and replaces the plugin submodule checkouts with plain copies.
Once everything works, delete `~/config-git-backup`.

## Machine flags

`.chezmoi.toml.tmpl` detects these when you run `chezmoi init`:

| flag      | true when                                   |
|-----------|---------------------------------------------|
| `wsl`     | Linux whose kernel release mentions Microsoft |
| `desktop` | Linux and not WSL (the Hyprland machine)    |

- `.chezmoiignore` skips the desktop configs unless `desktop` is true.
- `.chezmoiremove` lists files to delete on apply. On the desktop that's the old
  bspwm/X11 setup.
- Small OS differences inside `.zshrc` are runtime checks (`$OSTYPE`, `$+commands[...]`).

## Machine-specific settings

Anything that should only exist on one machine goes in `~/.config/zsh/local.zsh`.
`.zshrc` sources it if it exists, and it isn't tracked by chezmoi.

## Everyday use

```sh
chezmoi edit ~/.config/zsh/.zshrc   # edit the source copy (add --apply to apply on save)
chezmoi add ~/.config/foo/bar.conf  # start tracking a file
chezmoi diff && chezmoi apply       # apply source changes to this machine
chezmoi update                      # git pull + apply
chezmoi cd                          # shell in the source repo, to commit and push
```

zsh plugins are pinned in `.chezmoiexternal.toml`. To update one, change the commit
hash in its URL.

## Colours

Everything uses [Catppuccin](https://catppuccin.com). The palette is in
`.chezmoidata/catppuccin.toml`, and `.chezmoidata/colorscheme.toml` picks the
flavour for each mode (dark = Mocha, light = Latte) along with each mode's
default wallpaper. Tool configs refer to colours by name, so to change a flavour
edit that file and run `chezmoi apply`. The accents (window borders, workspaces,
launcher, GTK, lock screen) are the Catppuccin colours closest to the wallpaper's,
picked by `colorscheme-accents`.

On the desktop the whole session (terminal, nvim, bar, menus, notifications, GTK
apps, borders, wallpaper, lock screen) switches between light and dark at sunrise
and sunset:

```sh
colorscheme light        # or dark / toggle; no argument re-applies the current mode
wallpaper                # pick one from ~/Pictures/wallpapers (also Win+Shift+W)
wallpaper FILE           # or set it directly; --mode dark|light FILE for one mode only
systemctl --user enable --now colorscheme-solar.timer   # once, on a new desktop
```

The desktop needs the AUR packages `catppuccin-gtk-theme-mocha` and
`catppuccin-gtk-theme-latte` (GTK3 apps and file dialogs), plus `papirus-icon-theme`.
nvim follows `~/.local/state/colorscheme/mode` on every machine, and defaults to
dark when nothing writes it. On macOS a LaunchAgent writes it from the system's light/dark
appearance.

## Neovim

[`dot_config/nvim/GUIDE.md`](dot_config/nvim/GUIDE.md) is a quick guide to common commands;
[`dot_config/nvim/README.md`](dot_config/nvim/README.md) covers the keys, setup, plugin updates
and how the config works.
