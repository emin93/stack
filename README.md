# dotfiles

Cross-platform terminal + dev environment config. One source of truth for Linux and macOS.

Stack: [Ghostty](https://ghostty.org) · [lazygit](https://github.com/jesseduffield/lazygit) · [delta](https://github.com/dandavison/delta) · git.

## Layout

Each top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package. Its internal structure mirrors `$HOME`, so `stow ghostty` symlinks `ghostty/.config/ghostty/config` to `~/.config/ghostty/config`.

```
ghostty/    ~/.config/ghostty/config
lazygit/    ~/.config/lazygit/config.yml
git/        ~/.gitconfig
```

## Install

```bash
git clone git@github.com:emin93/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Homebrew is required on both platforms (the script installs it if missing). The script then `brew install`s every dependency and stows each package into `$HOME`. Pre-existing real files are moved to `*.bak` so stow can replace them with symlinks.

Re-run `./install.sh` (or `stow -R *`) after pulling changes — it's idempotent.

## Per-host overrides

Anything that legitimately differs per machine goes in gitignored local files that the main configs source:

- `~/.gitconfig.local` — extra git config
- `~/.config/ghostty/config.local` — extra Ghostty config

## Workflow

Edit a config on either machine → commit → push → on the other machine `git pull` (configs are symlinks, so changes apply immediately; reload the relevant tool).
