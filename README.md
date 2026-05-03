# 🛠️ dotfiles

> Cross-platform terminal + dev environment config. One source of truth for Linux 🐧 and macOS 🍎.

## ✨ Stack

| Tool | What it does |
| --- | --- |
| 👻 [Ghostty](https://ghostty.org) | Terminal emulator |
| 🐚 [zsh](https://www.zsh.org) | Shell |
| 🦎 [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| 🎨 [delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs |
| 🔍 [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast recursive search |
| 📁 [fd](https://github.com/sharkdp/fd) | Fast file finder |
| 🐙 [gh](https://cli.github.com) | GitHub CLI |
| 🎬 [ffmpeg](https://ffmpeg.org) | Audio/video processing |
| ✏️ [micro](https://micro-editor.github.io) | Modeless terminal editor |
| 🟢 [node@24](https://nodejs.org) | JavaScript runtime (pnpm via Corepack) |

## 📂 Layout

Each top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package. Its internal structure mirrors `$HOME`, so `stow ghostty` symlinks `ghostty/.config/ghostty/config` to `~/.config/ghostty/config`.

```
ghostty/    ~/.config/ghostty/config
lazygit/    ~/.config/lazygit/config.yml
git/        ~/.gitconfig
zsh/        ~/.zshrc
```

## 🚀 Install

### 1. Install dependencies

[Homebrew](https://brew.sh) is required.

```bash
brew install stow lazygit git-delta micro ripgrep fd gh ffmpeg node@24
```

🍎 macOS only — also install the font:

```bash
brew install --cask font-jetbrains-mono
```

`node@24` is keg-only; the zshrc puts it on `PATH` automatically. Enable Corepack-managed pnpm once:

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

### 2. Stow each package

```bash
stow --target="$HOME" ghostty lazygit git zsh
```

### 🔄 After pulling changes

```bash
git pull
stow --target="$HOME" --restow ghostty lazygit git zsh   # only if a package was added
brew install <new-tool>                                  # only if README lists a new dep
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
