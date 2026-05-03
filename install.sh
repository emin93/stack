#!/usr/bin/env bash
# Bootstrap dotfiles on Linux or macOS.
# Homebrew is required on both platforms — installs it if missing.
# Idempotent — safe to re-run after `git pull`.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(ghostty lazygit git)
BREW_FORMULAE=(stow lazygit git-delta neovim)
BREW_CASKS_MACOS=(ghostty font-jetbrains-mono)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

detect_os() {
  case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*)  echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then return; fi
  log "Homebrew not found — installing"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    warn "Homebrew install did not produce a known brew path — aborting"
    exit 1
  fi
}

install_packages() {
  log "Installing packages via brew"
  brew install "${BREW_FORMULAE[@]}"
  if [[ "$(detect_os)" == "macos" ]]; then
    for cask in "${BREW_CASKS_MACOS[@]}"; do
      brew install --cask "$cask" || true
    done
  fi
}

stow_packages() {
  log "Stowing packages into \$HOME"
  cd "$DOTFILES_DIR"
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
  if [[ "$os" == "unknown" ]]; then
    warn "Unsupported OS: $OSTYPE"
    exit 1
  fi
  ensure_brew
  install_packages
  stow_packages
  log "Done."
}

main "$@"
