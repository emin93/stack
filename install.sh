#!/usr/bin/env bash
# Bootstrap dotfiles on Linux or macOS.
# Idempotent — safe to re-run after `git pull`.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(ghostty zellij lazygit git zsh)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

detect_os() {
  case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*)  echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  log "Installing packages via brew"
  brew install stow zellij lazygit git-delta neovim
  brew install --cask ghostty || true
  brew install --cask font-jetbrains-mono || true
}

install_linux() {
  if command -v pacman >/dev/null 2>&1; then
    log "Installing packages via pacman"
    sudo pacman -S --needed --noconfirm stow zellij lazygit git-delta neovim ttf-jetbrains-mono
  elif command -v apt-get >/dev/null 2>&1; then
    log "Installing packages via apt"
    sudo apt-get update
    sudo apt-get install -y stow neovim fonts-jetbrains-mono
    warn "zellij, lazygit, and delta may need manual install on apt-based systems"
  elif command -v dnf >/dev/null 2>&1; then
    log "Installing packages via dnf"
    sudo dnf install -y stow zellij lazygit git-delta neovim jetbrains-mono-fonts
  else
    warn "Unknown Linux distro — install stow, zellij, lazygit, delta, neovim manually"
  fi
}

stow_packages() {
  log "Stowing packages into \$HOME"
  cd "$DOTFILES_DIR"
  # Back up any conflicting plain files so stow can take over
  for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r -d '' src; do
      rel="${src#"$DOTFILES_DIR/$pkg/"}"
      dest="$HOME/$rel"
      if [[ -e "$dest" && ! -L "$dest" ]]; then
        warn "Backing up $dest -> $dest.bak"
        mv "$dest" "$dest.bak"
      fi
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
  done
  stow --target="$HOME" --restow "${PACKAGES[@]}"
}

main() {
  local os
  os="$(detect_os)"
  log "Detected OS: $os"
  case "$os" in
    macos) install_macos ;;
    linux) install_linux ;;
    *) warn "Unsupported OS: $OSTYPE — skipping package install" ;;
  esac
  stow_packages
  log "Done. Open a new shell to pick up changes."
}

main "$@"
