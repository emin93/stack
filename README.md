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
| 🟢 [node@24](https://nodejs.org) | JavaScript runtime (pnpm via Corepack) |

## 📂 Layout

Each top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package. Its internal structure mirrors `$HOME`, so `stow ghostty` symlinks `ghostty/.config/ghostty/config` to `~/.config/ghostty/config`.

```
ghostty/    ~/.config/ghostty/config
git/        ~/.gitconfig
zsh/        ~/.zshrc
```

## 🚀 Install

### 1. Install dependencies

[Homebrew](https://brew.sh) is required.

```bash
brew install stow ripgrep fd gh ffmpeg node@24
brew install --cask font-jetbrains-mono
```

`node@24` is keg-only; the shell rc puts it on `PATH` automatically. Enable Corepack-managed pnpm once:

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

### 2. Stow each package

```bash
stow --target="$HOME" ghostty git zsh
```

### 🔄 After pulling changes

```bash
git pull
stow --target="$HOME" --restow ghostty git zsh   # only if a package was added
brew install <new-tool>                          # only if README lists a new dep
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
