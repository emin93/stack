#!/usr/bin/env bash
# install.sh — provision a fresh Apple Silicon Mac.
# https://install.emin.ch
#
# Designed to be run interactively. Invoke via:
#   bash -c "$(curl -fsSL https://install.emin.ch/install.sh)"
# The bash -c form (rather than `curl | bash`) keeps stdin attached to the
# TTY, which is required for the interactive sign-in prompts.
set -euo pipefail

# ---- config -----------------------------------------------------------------

REPO_NAME="install"
REPO_URL="https://github.com/emin93/${REPO_NAME}.git"
REPO_DIR="${HOME}/Documents/Projects/${REPO_NAME}"
STOW_PACKAGES=(ghostty git zsh)

LOCAL_OVERRIDES=(
  "${HOME}/.gitconfig.local"
  "${HOME}/.zshrc.local"
  "${HOME}/.config/ghostty/config.local"
)

STOW_TARGETS=(
  "${HOME}/.gitconfig"
  "${HOME}/.zshrc"
  "${HOME}/.config/ghostty/config"
)

# ---- helpers ----------------------------------------------------------------

C_BLUE=$(printf '\033[34m')
C_GREEN=$(printf '\033[32m')
C_YELLOW=$(printf '\033[33m')
C_RED=$(printf '\033[31m')
C_RESET=$(printf '\033[0m')

header() { printf "\n%s==>%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
ok()     { printf "    %s✓%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()   { printf "    %s!%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
die()    { printf "%s✗%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# ---- steps ------------------------------------------------------------------

step_sanity_checks() {
  header "Sanity checks"
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS only."
  [[ "$(uname -m)" == "arm64" ]] || die "Apple Silicon only."
  [[ "$EUID" -ne 0 ]] || die "Do not run as root."
  ok "macOS on Apple Silicon, not root."
}

step_xcode_clt() {
  header "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed."
    return
  fi
  xcode-select --install || true
  printf "    Waiting for CLT install to finish (a GUI dialog will appear)"
  until xcode-select -p >/dev/null 2>&1; do
    printf "."
    sleep 5
  done
  printf "\n"
  ok "installed."
}

step_homebrew() {
  header "Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  local brew_shellenv='eval "$(/opt/homebrew/bin/brew shellenv)"'
  if ! grep -Fxq "$brew_shellenv" "${HOME}/.zprofile" 2>/dev/null; then
    printf '%s\n' "$brew_shellenv" >> "${HOME}/.zprofile"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "$(brew --version | head -n1)"
}

step_clone_repo() {
  header "Clone install repo to $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  if [[ -d "$REPO_DIR/.git" ]]; then
    local existing
    existing=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
    if [[ "$existing" != *"$REPO_NAME"* ]]; then
      die "$REPO_DIR exists but isn't this repo (origin: $existing)."
    fi
    git -C "$REPO_DIR" pull --ff-only
    ok "updated."
  else
    git clone "$REPO_URL" "$REPO_DIR"
    ok "cloned."
  fi
}

step_brew_bundle() {
  header "Brew bundle"
  brew bundle --file="$REPO_DIR/Brewfile"
}

step_gh_auth() {
  header "GitHub auth"
  if gh auth status >/dev/null 2>&1; then
    ok "already authenticated."
  else
    gh auth login --web --git-protocol https
  fi
  gh auth setup-git
  ok "git credential helper configured."
}

step_ssh_key() {
  header "SSH key for GitHub"
  local key="${HOME}/.ssh/id_ed25519"
  if [[ -f "$key" ]]; then
    ok "key already exists at $key."
    return
  fi
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  local email
  email=$(gh api user --jq .email 2>/dev/null || true)
  [[ -z "$email" || "$email" == "null" ]] && email="$(whoami)@$(hostname)"
  ssh-keygen -t ed25519 -C "$email" -f "$key" -N ""
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add --apple-use-keychain "$key" 2>/dev/null || ssh-add "$key"
  gh ssh-key add "${key}.pub" --title "$(hostname)" --type authentication
  ok "key generated and uploaded to GitHub."
}

step_stow() {
  header "Stow configs"
  for target in "${STOW_TARGETS[@]}"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
      mv "$target" "${target}.pre-install.bak"
      warn "backed up $target -> ${target}.pre-install.bak"
    fi
  done
  mkdir -p "${HOME}/.config"
  stow --target="$HOME" --dir="$REPO_DIR" --restow "${STOW_PACKAGES[@]}"
  ok "stowed: ${STOW_PACKAGES[*]}"
}

step_local_overrides() {
  header "Local override files"
  for f in "${LOCAL_OVERRIDES[@]}"; do
    mkdir -p "$(dirname "$f")"
    if [[ ! -e "$f" ]]; then
      touch "$f"
      ok "created $f"
    else
      ok "$f already exists."
    fi
  done
}

step_claude_signin() {
  header "Claude Code sign-in"
  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not on PATH yet. Open a new shell after this finishes and run 'claude'."
    return
  fi
  printf "    Launching 'claude'. Complete sign-in, then exit with /quit to continue.\n"
  read -rp "    Press Enter when ready... " _
  claude || true
}

step_codex_signin() {
  header "Codex sign-in"
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex CLI not on PATH yet. Open a new shell after this finishes and run 'codex'."
    return
  fi
  printf "    Launching 'codex'. Complete sign-in, then exit to continue.\n"
  read -rp "    Press Enter when ready... " _
  codex || true
}

step_xcode() {
  header "Xcode (latest)"
  command -v xcodes >/dev/null 2>&1 || die "xcodes not installed (expected from Brewfile)."
  xcodes install --latest --select
  ok "Xcode installed and selected."
}

step_summary() {
  header "Done"
  printf "    Open a new Ghostty window to pick up the new shell environment.\n\n"
}

# ---- main -------------------------------------------------------------------

main() {
  step_sanity_checks
  step_xcode_clt
  step_homebrew
  step_clone_repo
  step_brew_bundle
  step_gh_auth
  step_ssh_key
  step_stow
  step_local_overrides
  step_claude_signin
  step_codex_signin
  step_xcode
  step_summary
}

main "$@"
