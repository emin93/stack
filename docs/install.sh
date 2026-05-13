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
STOW_PACKAGES=(git zsh zed)

LOCAL_OVERRIDES=(
  "${HOME}/.gitconfig.local"
  "${HOME}/.zshrc.local"
)

STOW_TARGETS=(
  "${HOME}/.gitconfig"
  "${HOME}/.zshrc"
  "${HOME}/.config/zed/settings.json"
)

# ---- helpers ----------------------------------------------------------------

C_BLUE=$(printf '\033[34m')
C_GREEN=$(printf '\033[32m')
C_YELLOW=$(printf '\033[33m')
C_RED=$(printf '\033[31m')
C_DIM=$(printf '\033[2m')
C_RESET=$(printf '\033[0m')

STEP_NUM=0

header() { printf "\n%s==>%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
step()   { STEP_NUM=$((STEP_NUM + 1)); printf "\n%s==>%s %s[%d/%d]%s %s\n" "$C_BLUE" "$C_RESET" "$C_DIM" "$STEP_NUM" "$STEP_TOTAL" "$C_RESET" "$*"; }
ok()     { printf "    %s✓%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()   { printf "    %s!%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
die()    { printf "%s✗%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# ---- steps ------------------------------------------------------------------

step_sanity_checks() {
  step "Sanity checks"
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS only."
  [[ "$(uname -m)" == "arm64" ]] || die "Apple Silicon only."
  [[ "$EUID" -ne 0 ]] || die "Do not run as root."
  ok "macOS on Apple Silicon, not root."
}

step_xcode_clt() {
  step "Xcode Command Line Tools"
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
  step "Homebrew"
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
  step "Clone install repo to $REPO_DIR"
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
  step "Brew bundle"
  HOMEBREW_CASK_OPTS="--adopt" brew bundle --file="$REPO_DIR/Brewfile"
}

step_zed_cli() {
  step "Zed CLI"
  local zed_cli="/Applications/Zed.app/Contents/MacOS/cli"
  local target="/opt/homebrew/bin/zed"
  if [[ ! -x "$zed_cli" ]]; then
    warn "Zed.app not found at /Applications; skipping."
    return
  fi
  if [[ -L "$target" && "$(readlink "$target")" == "$zed_cli" ]]; then
    ok "already linked at $target."
    return
  fi
  ln -sf "$zed_cli" "$target"
  ok "linked $target -> $zed_cli"
}

step_gh_auth() {
  step "GitHub auth"
  if gh auth status >/dev/null 2>&1; then
    ok "already authenticated."
  else
    gh auth login --web --git-protocol https
  fi
  gh auth setup-git
  ok "git credential helper configured."
}

step_1password_ssh() {
  step "SSH via 1Password agent"

  local agent_socket="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  local ssh_dir="${HOME}/.ssh"
  local ssh_config="${ssh_dir}/config"
  local marker="# 1Password SSH agent (managed by install.sh)"

  mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"
  touch "$ssh_config" && chmod 600 "$ssh_config"

  if ! grep -Fq "$marker" "$ssh_config"; then
    printf '\n%s\nHost *\n  IdentityAgent "%s"\n' "$marker" "$agent_socket" >> "$ssh_config"
    ok "wired ~/.ssh/config to 1Password agent."
  else
    ok "~/.ssh/config already references the 1Password agent."
  fi

  if [[ ! -S "$agent_socket" ]]; then
    warn "1Password SSH agent isn't running yet."
    printf "    1) Open 1Password, sign in.\n"
    printf "    2) Settings → Developer → enable 'Use the SSH agent'.\n"
    printf "    3) Same panel → enable 'Integrate with 1Password CLI'.\n"
    read -rp "    Press Enter once those are on... " _
  fi

  if ! command -v op >/dev/null 2>&1; then
    warn "1Password CLI (op) not on PATH; upload your public key to GitHub by hand."
    return
  fi

  local key_id
  key_id=$(op item list --categories "SSH Key" 2>/dev/null | awk 'NR==2 {print $1}' || true)
  if [[ -z "$key_id" ]]; then
    warn "no SSH key found in 1Password — create one in the GUI (New Item → SSH Key) and re-run."
    return
  fi

  local pubkey
  pubkey=$(op item get "$key_id" --field 'public key' 2>/dev/null || true)
  if [[ -z "$pubkey" ]]; then
    warn "couldn't read public key from 1Password (is the GUI integration enabled?)."
    return
  fi

  if gh ssh-key list 2>/dev/null | grep -Fq "$pubkey"; then
    ok "1Password public key already on GitHub."
  else
    printf '%s\n' "$pubkey" | gh ssh-key add - --title "$(hostname)" --type authentication
    ok "uploaded 1Password public key to GitHub."
  fi
}

step_stow() {
  step "Stow configs"
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
  step "Local override files"
  for f in "${LOCAL_OVERRIDES[@]}"; do
    mkdir -p "$(dirname "$f")"
    touch "$f"
  done
  ok "ensured ${#LOCAL_OVERRIDES[@]} override file(s)."
}

step_claude_signin() {
  step "Claude Code sign-in"
  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not on PATH yet. Open a new shell after this finishes and run 'claude auth login'."
    return
  fi
  if claude auth status >/dev/null 2>&1; then
    ok "already signed in."
    return
  fi
  claude auth login || warn "claude auth login didn't complete; re-run when ready."
}

step_claude_settings() {
  step "Claude Code default mode"
  local settings_file="${HOME}/.claude/settings.json"
  mkdir -p "$(dirname "$settings_file")"
  [[ -f "$settings_file" ]] || echo '{}' > "$settings_file"
  python3 - "$settings_file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    settings = json.load(f)
settings.setdefault("permissions", {})["defaultMode"] = "bypassPermissions"
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY
  ok "permissions.defaultMode = bypassPermissions"
}

step_codex_signin() {
  step "Codex sign-in"
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex CLI not on PATH yet. Open a new shell after this finishes and run 'codex login'."
    return
  fi
  if codex login status >/dev/null 2>&1; then
    ok "already signed in."
    return
  fi
  codex login || warn "codex login didn't complete; re-run when ready."
}

step_codex_settings() {
  step "Codex default mode"
  local config_file="${HOME}/.codex/config.toml"
  mkdir -p "$(dirname "$config_file")"
  touch "$config_file"
  python3 - "$config_file" <<'PY'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
content = path.read_text()

def set_top_key(text, key, value):
    line = f"{key} = {value}\n"
    section = re.search(r"^\[", text, flags=re.MULTILINE)
    head, tail = (text[:section.start()], text[section.start():]) if section else (text, "")
    pat = re.compile(rf"^{re.escape(key)}\s*=.*\n?", flags=re.MULTILINE)
    if pat.search(head):
        head = pat.sub(line, head)
    else:
        if head and not head.endswith("\n"):
            head += "\n"
        head += line
    return head + tail

content = set_top_key(content, "approval_policy", '"never"')
content = set_top_key(content, "sandbox_mode", '"danger-full-access"')
path.write_text(content)
PY
  ok "approval_policy=never, sandbox_mode=danger-full-access"
}

step_xcode() {
  step "Xcode (latest)"
  local xcode_app="/Applications/Xcode.app"
  local receipt="$xcode_app/Contents/_MASReceipt/receipt"
  if [[ -d "$xcode_app" && -f "$receipt" ]]; then
    sudo xcode-select -s "$xcode_app"
    ok "already installed and selected."
    return
  fi
  if ! command -v mas >/dev/null 2>&1; then
    warn "mas not installed (expected from Brewfile); skipping."
    return
  fi
  # mas needs root to drop the App Store receipt into the root-owned bundle.
  # Prime sudo so mas's internal non-interactive escalation succeeds.
  printf "    sudo is needed so mas can write the App Store receipt.\n"
  if ! sudo -v; then
    warn "sudo unavailable; skipping Xcode install."
    return
  fi
  if [[ -d "$xcode_app" && ! -f "$receipt" ]]; then
    warn "removing partial Xcode.app (no App Store receipt) so mas can reinstall."
    sudo rm -rf "$xcode_app"
  fi
  if ! mas install 497799835; then
    warn "mas install failed (signed in to the App Store?); re-run when ready."
    return
  fi
  sudo xcode-select -s "$xcode_app"
  ok "Xcode installed and selected."
}

step_summary() {
  header "Done"
  ok "${STEP_NUM}/${STEP_TOTAL} steps completed."
  printf "    Open a new Terminal or Zed terminal to pick up the new shell environment.\n\n"
}

# ---- main -------------------------------------------------------------------

STEPS=(
  step_sanity_checks
  step_xcode_clt
  step_homebrew
  step_clone_repo
  step_brew_bundle
  step_zed_cli
  step_gh_auth
  step_1password_ssh
  step_local_overrides
  step_stow
  step_claude_signin
  step_claude_settings
  step_codex_signin
  step_codex_settings
  step_xcode
)
STEP_TOTAL=${#STEPS[@]}

main() {
  for s in "${STEPS[@]}"; do "$s"; done
  step_summary
}

main "$@"
