# 🛠️ dotfiles

> Terminal + dev environment config for macOS 🍎.

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

### 1. Install dependencies

[Homebrew](https://brew.sh) is required. Everything else is declared in the [`Brewfile`](./Brewfile):

```bash
brew bundle --file=./Brewfile
```

Install global defaults for Node and pnpm:

```bash
mise use -g node@lts pnpm@latest
```

Per-project versions: drop a `mise.toml` in the repo root pinning whatever the project needs (e.g. `node = "lts"`, `pnpm = "11.1.1"`, `go = "1.26"`). `mise` switches automatically on `cd` — run `mise install` once to materialize the versions, and `mise trust` the first time you enter a new repo.

Install Xcode (kept out of the Brewfile because it's ~10GB+ and prompts for an Apple ID):

```bash
xcodes install --latest --select
```

### 2. Stow each package

```bash
stow --target="$HOME" ghostty git zsh
```

### 🔄 After pulling changes

```bash
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
