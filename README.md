# config_dotfiles

Dotfiles for Linux (Hyprland desktop), macOS and WSL, managed with [chezmoi](https://www.chezmoi.io).

Every machine gets the shared baseline (zsh, nvim, clangd). The Hyprland desktop
configs (hypr, eww, rofi, dunst, alacritty, GTK/satty theming, Chromium flags) are
only applied on native Linux.

## Install on a new machine

```sh
# Arch: sudo pacman -S chezmoi    macOS: brew install chezmoi
chezmoi init --apply git@github.com:wasingera/config_dotfiles.git
```

This also sets `ZDOTDIR` (via `~/.zshenv`), creates the zsh history folder and
downloads the zsh plugins.

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

## Machine types

`.chezmoi.toml.tmpl` detects these when you run `chezmoi init`:

| data      | true when                                   |
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
flavour for each mode (dark = Mocha, light = Latte). Tool configs refer to colours
by name, so to change a flavour edit that one line and run `chezmoi apply`.

On the desktop the whole session (terminal, nvim, bar, menus, notifications, GTK
apps, borders, lock screen) switches between light and dark at sunrise and sunset:

```sh
colorscheme light        # or dark / toggle; no argument re-applies the current mode
systemctl --user enable --now colorscheme-solar.timer   # once, on a new desktop
```

The desktop needs the AUR packages `catppuccin-gtk-theme-mocha` and
`catppuccin-gtk-theme-latte` (GTK3 apps and file dialogs), plus `papirus-icon-theme`.
nvim follows `~/.local/state/colorscheme/mode` on every machine, and defaults to
dark when nothing writes it.
