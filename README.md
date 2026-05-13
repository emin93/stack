# 🛠️ install

> One-command provisioning for a fresh Apple Silicon Mac. Hosted at [install.emin.ch](https://install.emin.ch).

## ✨ Stack

| Tool | What it does |
| --- | --- |
| 👻 [Ghostty](https://ghostty.org) | Terminal emulator |
| 🐚 [zsh](https://www.zsh.org) | Shell |
| 🔍 [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast recursive search |
| 📁 [fd](https://github.com/sharkdp/fd) | Fast file finder |
| 🐙 [gh](https://cli.github.com) | GitHub CLI |
| 🎬 [ffmpeg](https://ffmpeg.org) | Audio/video processing |
| 📦 [mise](https://mise.jdx.dev) | Per-project runtime manager (node, python, etc.) |
| 🔨 [xcodes](https://github.com/XcodesOrg/xcodes) | Install/switch Xcode versions |
| ⚡ [aria2](https://aria2.github.io) | Parallel downloads (used by `xcodes`) |

## 📂 Layout

Each top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package. Its internal structure mirrors `$HOME`, so `stow ghostty` symlinks `ghostty/.config/ghostty/config` to `~/.config/ghostty/config`.

```
ghostty/    ~/.config/ghostty/config
git/        ~/.gitconfig
zsh/        ~/.zshrc
```

## 🚀 Install

On a fresh Mac, paste this into Terminal:

```bash
bash -c "$(curl -fsSL https://install.emin.ch/install.sh)"
```

See [install.emin.ch](https://install.emin.ch) for what it does step-by-step. Safe to re-run on an existing setup — it adds missing pieces and bumps versions.

### Per-project runtimes

Drop a `mise.toml` in any repo pinning what it needs (e.g. `node = "lts"`, `pnpm = "11.1.1"`, `go = "1.26"`). `mise` switches automatically on `cd` — run `mise install` once to materialize, and `mise trust` the first time you enter a new repo.

### After pulling changes

```bash
cd ~/Documents/Projects/install
git pull
stow --target="$HOME" --restow ghostty git zsh   # only if a package was added
brew bundle --file=./Brewfile                    # only if Brewfile changed
```

Symlinked configs apply immediately — no restow needed for edits to existing files. ✅

## 🔐 Per-host overrides

Anything that legitimately differs per machine goes in gitignored local files that the main configs source:

| File | Purpose |
| --- | --- |
| `~/.gitconfig.local` | Extra git config |
| `~/.config/ghostty/config.local` | Extra Ghostty config |
| `~/.zshrc.local` | Secrets and per-host shell config |

## 🔁 Workflow

Edit a config on either machine → `git commit` → `git push` → on the other machine `git pull`. Configs are symlinks, so changes apply immediately — just reload the relevant tool. 🎉
