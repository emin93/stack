#!/usr/bin/env bash
# install.sh — provision a fresh Apple Silicon Mac.
# https://stack.emin.ch
#
# Designed to be run interactively. Invoke via:
#   bash -c "$(curl -fsSL https://stack.emin.ch/install.sh)"
# The bash -c form (rather than `curl | bash`) keeps stdin attached to the
# TTY, which is required for the interactive sign-in prompts.
set -euo pipefail

# ---- config -----------------------------------------------------------------

REPO_NAME="stack"
REPO_OWNER="emin93"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
REPO_SSH_URL="git@github.com:${REPO_OWNER}/${REPO_NAME}.git"
REPO_DIR="${HOME}/Documents/Projects/${REPO_NAME}"
STOW_PACKAGES=(git zsh claude codex bin)
PNPM_GLOBAL=(postiz wrangler @paddle/paddle-mcp)
OP_ENV_ITEM="stack env"
OP_ENV_MARKER_BEGIN="# >>> stack: 1password-managed env (do not edit) >>>"
OP_ENV_MARKER_END="# <<< stack: 1password-managed env <<<"
DJAY_APP_ID="450527929"

LOCAL_OVERRIDES=(
  "${HOME}/.gitconfig.local"
  "${HOME}/.zshrc.local"
)

STOW_TARGETS=(
  "${HOME}/.gitconfig"
  "${HOME}/.hushlogin"
  "${HOME}/.zshrc"
  "${HOME}/.claude/settings.json"
  "${HOME}/.codex/config.toml"
  "${HOME}/.local/bin/paddle-sandbox"
  "${HOME}/.local/bin/paddle-prod"
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
  until xcode-select -p >/dev/null 2>&1; do
    local reply
    warn "Xcode Command Line Tools are required before the install can continue."
    printf "    Complete the Apple installer dialog that opened.\n"
    read -rp "    Press Enter once installed, or type 'skip' to stop here: " reply
    if [[ "$reply" == "skip" ]]; then
      die "Xcode Command Line Tools are required for git, Homebrew, and builds."
    fi
    xcode-select --install >/dev/null 2>&1 || true
  done
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
  step "Clone stack repo to $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  if [[ -d "$REPO_DIR/.git" ]]; then
    local existing
    existing=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
    if [[ "$existing" != *"$REPO_NAME"* ]]; then
      die "$REPO_DIR exists but isn't this repo (origin: $existing)."
    fi
    git -C "$REPO_DIR" pull --ff-only
    ok "updated."
  elif [[ -e "$REPO_DIR" && -n "$(ls -A "$REPO_DIR" 2>/dev/null || true)" ]]; then
    die "$REPO_DIR exists and is not empty; move it aside and re-run."
  else
    git clone "$REPO_URL" "$REPO_DIR"
    ok "cloned."
  fi
}

step_brew_bundle() {
  step "Brew bundle"
  if ! HOMEBREW_CASK_OPTS="--adopt" brew bundle --file="$REPO_DIR/Brewfile"; then
    die "brew bundle failed; fix the Homebrew error above and re-run the installer."
  fi
}

step_pnpm_global() {
  step "pnpm global packages"
  if ! command -v pnpm >/dev/null 2>&1; then
    warn "pnpm not on PATH; skipping."
    return
  fi
  if [[ ${#PNPM_GLOBAL[@]} -eq 0 ]]; then
    ok "nothing to install."
    return
  fi
  # Match the PNPM_HOME exported by zsh/.zshrc so pnpm add -g works before
  # the stowed shell config is loaded.
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
  mkdir -p "$PNPM_HOME"
  export PATH="$PNPM_HOME/bin:$PATH"
  local installed
  installed=$(pnpm ls -g --depth=0 --parseable 2>/dev/null || true)
  for pkg in "${PNPM_GLOBAL[@]}"; do
    if grep -Fq "/${pkg}" <<<"$installed"; then
      ok "$pkg already installed."
    else
      if pnpm add -g "$pkg"; then
        ok "installed $pkg."
      else
        warn "couldn't install pnpm global package '$pkg'; re-run when pnpm is ready."
      fi
    fi
  done
}

step_gh_auth() {
  step "GitHub auth"
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh CLI not on PATH; skipping GitHub auth."
    return
  fi
  if gh auth status >/dev/null 2>&1; then
    ok "already authenticated."
  else
    warn "GitHub CLI needs an interactive browser login."
    if ! gh auth login --web --git-protocol https; then
      warn "GitHub auth didn't complete; SSH upload and repo SSH switch may be skipped."
      return
    fi
    if ! gh auth status >/dev/null 2>&1; then
      warn "GitHub auth still isn't ready; re-run when logged in."
      return
    fi
  fi
  if gh auth setup-git; then
    ok "git credential helper configured."
  else
    warn "couldn't configure gh as the git credential helper."
  fi
}

step_1password_ready() {
  step "1Password sign-in and CLI integration"

  if ! command -v op >/dev/null 2>&1; then
    warn "1Password CLI (op) not on PATH; later 1Password steps will be skipped."
    return
  fi

  local agent_socket="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  local reply

  while true; do
    warn "1Password needs a one-time GUI setup before the CLI steps can run."
    printf "    1) Open 1Password and sign in/unlock the app.\n"
    printf "    2) Settings → Developer → enable 'Integrate with 1Password CLI'.\n"
    printf "    3) Settings → Developer → enable 'Use the SSH agent'.\n"
    printf "    4) Make sure you have an SSH Key item in 1Password for this Mac.\n"
    read -rp "    Press Enter once ready, or type 'skip' to continue without 1Password setup: " reply
    if [[ "$reply" == "skip" ]]; then
      warn "continuing without verified 1Password CLI/SSH agent setup."
      return
    fi

    if op whoami >/dev/null 2>&1 && [[ -S "$agent_socket" ]]; then
      ok "1Password is signed in, CLI integration works, and the SSH agent is running."
      return
    fi

    warn "couldn't verify 1Password yet; check the settings above and try again."
  done
}

step_1password_ssh() {
  step "SSH via 1Password agent"

  local agent_socket="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  local ssh_dir="${HOME}/.ssh"
  local ssh_config="${ssh_dir}/config"
  local marker="# 1Password SSH agent (managed by install.sh)"

  if ! command -v op >/dev/null 2>&1; then
    warn "1Password CLI (op) not on PATH; skipping SSH agent wiring."
    return
  fi
  if ! op whoami >/dev/null 2>&1; then
    warn "1Password CLI isn't signed in; skipping SSH agent wiring."
    return
  fi
  if [[ ! -S "$agent_socket" ]]; then
    warn "1Password SSH agent isn't running; skipping SSH agent wiring."
    return
  fi

  mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"
  touch "$ssh_config" && chmod 600 "$ssh_config"

  if ! grep -Fq "$marker" "$ssh_config"; then
    printf '\n%s\nHost *\n  IdentityAgent "%s"\n' "$marker" "$agent_socket" >> "$ssh_config"
    ok "wired ~/.ssh/config to 1Password agent."
  else
    ok "~/.ssh/config already references the 1Password agent."
  fi

  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI isn't authenticated; upload your public key to GitHub by hand or re-run."
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

  local title="$(hostname)"
  if gh api /user/keys --jq '.[].key' 2>/dev/null | grep -Fxq "$pubkey"; then
    ok "1Password key already on GitHub (auth)."
  else
    if printf '%s\n' "$pubkey" | gh ssh-key add - --title "$title" --type authentication; then
      ok "uploaded 1Password key to GitHub (auth)."
    else
      warn "couldn't upload 1Password key to GitHub for auth."
    fi
  fi
  if gh api /user/ssh_signing_keys --jq '.[].key' 2>/dev/null | grep -Fxq "$pubkey"; then
    ok "1Password key already on GitHub (signing)."
  else
    if printf '%s\n' "$pubkey" | gh ssh-key add - --title "$title" --type signing; then
      ok "uploaded 1Password key to GitHub (signing)."
    else
      warn "couldn't upload 1Password key to GitHub for signing."
    fi
  fi
}

step_repo_remote_ssh() {
  step "Switch repo origin to SSH"
  local current
  current=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
  if [[ "$current" == "$REPO_SSH_URL" ]]; then
    ok "already SSH."
    return
  fi
  if ! GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
       git ls-remote "$REPO_SSH_URL" >/dev/null 2>&1; then
    warn "SSH to GitHub not working yet; leaving origin on HTTPS."
    return
  fi
  git -C "$REPO_DIR" remote set-url origin "$REPO_SSH_URL"
  ok "origin -> $REPO_SSH_URL"
}

step_stow() {
  step "Stow configs"
  for target in "${STOW_TARGETS[@]}"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
      local backup="${target}.pre-install.bak"
      if [[ -e "$backup" || -L "$backup" ]]; then
        backup="${target}.pre-install.$(date +%Y%m%d%H%M%S).bak"
      fi
      mv "$target" "$backup"
      warn "backed up $target -> $backup"
    fi
  done
  mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.claude" "${HOME}/.codex"
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
  step "Claude sign-in"
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

step_secrets_from_1password() {
  step "Sync secrets from 1Password to ~/.zshrc.local"
  if ! command -v op >/dev/null 2>&1; then
    warn "1Password CLI (op) not on PATH; skipping."
    return
  fi
  if ! op whoami >/dev/null 2>&1; then
    warn "1Password CLI isn't signed in; skipping."
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not on PATH; skipping 1Password secret sync."
    return
  fi
  if ! op item get "$OP_ENV_ITEM" --format=json >/dev/null 2>&1; then
    warn "1Password item '$OP_ENV_ITEM' not found."
    printf "    Create a Secure Note named '%s' with each secret as a concealed field\n" "$OP_ENV_ITEM"
    printf "    whose label is the env var name (e.g. PADDLE_SANDBOX_API_KEY).\n"
    return
  fi
  local exports
  exports=$(op item get "$OP_ENV_ITEM" --format=json \
    | jq -r '.fields[] | select(.value != null and ((.label // "") | test("^[A-Z_][A-Z0-9_]*$"))) | "export \(.label)=\(.value|@sh)"')
  if [[ -z "$exports" ]]; then
    warn "no env-var-style fields on '$OP_ENV_ITEM' (labels must be UPPER_SNAKE_CASE)."
    return
  fi
  local zshrc_local="${HOME}/.zshrc.local"
  touch "$zshrc_local"
  chmod 600 "$zshrc_local"
  EXPORTS_BLOCK="$exports" \
  MARKER_BEGIN="$OP_ENV_MARKER_BEGIN" \
  MARKER_END="$OP_ENV_MARKER_END" \
  python3 - "$zshrc_local" <<'PY'
import os, re, sys, pathlib
path = pathlib.Path(sys.argv[1])
beg = os.environ["MARKER_BEGIN"]
end = os.environ["MARKER_END"]
body = os.environ["EXPORTS_BLOCK"].rstrip()
block = f"{beg}\n{body}\n{end}\n"
content = path.read_text() if path.exists() else ""
pat = re.compile(re.escape(beg) + r"[\s\S]*?" + re.escape(end) + r"\n?")
if pat.search(content):
    content = pat.sub(block, content)
else:
    if content and not content.endswith("\n"):
        content += "\n"
    content += "\n" + block
path.write_text(content)
PY
  ok "wrote $(grep -c '^export ' <<<"$exports") secret(s) to ~/.zshrc.local"
}

step_claude_mcp_servers() {
  step "Claude MCP servers"
  export PATH="${HOME}/.local/bin:${PNPM_HOME:-$HOME/Library/pnpm}/bin:$PATH"

  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not on PATH; skipping Paddle MCP registration."
    return
  fi
  if ! claude auth status >/dev/null 2>&1; then
    warn "Claude isn't signed in; skipping Paddle MCP registration."
    return
  fi
  if ! command -v paddle >/dev/null 2>&1; then
    warn "Paddle MCP package not on PATH; skipping Claude MCP registration."
    return
  fi

  if claude mcp list 2>/dev/null | grep -q '^paddle:'; then
    ok "paddle already registered with Claude."
  elif claude mcp add --scope user paddle -- paddle-sandbox; then
    ok "registered paddle with Claude."
  else
    warn "couldn't register paddle with Claude."
  fi

  if claude mcp list 2>/dev/null | grep -q '^paddle-prod:'; then
    ok "paddle-prod already registered with Claude."
  elif claude mcp add --scope user paddle-prod -- paddle-prod; then
    ok "registered paddle-prod with Claude."
  else
    warn "couldn't register paddle-prod with Claude."
  fi
}

step_djay_pro() {
  step "djay Pro"
  if ! command -v mas >/dev/null 2>&1; then
    warn "mas not installed (expected from Brewfile); skipping."
    return
  fi
  if mas list 2>/dev/null | awk '{print $1}' | grep -Fxq "$DJAY_APP_ID"; then
    ok "already installed."
    return
  fi
  local reply
  warn "djay Pro installs through the Mac App Store and requires an Apple ID sign-in."
  open -a "App Store" >/dev/null 2>&1 || true
  read -rp "    Sign in to the App Store, then press Enter to install djay Pro (or type 'skip'): " reply
  if [[ "$reply" == "skip" ]]; then
    warn "skipping djay Pro install."
    return
  fi
  if ! mas install "$DJAY_APP_ID"; then
    warn "mas install failed (signed in to the App Store?); re-run when ready."
    return
  fi
  ok "djay Pro installed."
}

step_xcode() {
  step "Xcode (latest)"
  local xcode_app="/Applications/Xcode.app"
  local receipt="$xcode_app/Contents/_MASReceipt/receipt"
  if [[ -d "$xcode_app" && -f "$receipt" ]]; then
    if sudo xcode-select -s "$xcode_app"; then
      ok "already installed and selected."
    else
      warn "Xcode is installed, but xcode-select failed."
    fi
    return
  fi
  if ! command -v mas >/dev/null 2>&1; then
    warn "mas not installed (expected from Brewfile); skipping."
    return
  fi
  local reply
  warn "Xcode installs through the Mac App Store and requires an Apple ID sign-in."
  open -a "App Store" >/dev/null 2>&1 || true
  read -rp "    Sign in to the App Store, then press Enter to install Xcode (or type 'skip'): " reply
  if [[ "$reply" == "skip" ]]; then
    warn "skipping Xcode install."
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
  printf "    Open a new Terminal to pick up the new shell environment.\n\n"
}

# ---- main -------------------------------------------------------------------

STEPS=(
  step_sanity_checks
  step_xcode_clt
  step_homebrew
  step_clone_repo
  step_brew_bundle
  step_pnpm_global
  step_gh_auth
  step_1password_ready
  step_1password_ssh
  step_repo_remote_ssh
  step_local_overrides
  step_stow
  step_secrets_from_1password
  step_claude_signin
  step_codex_signin
  step_claude_mcp_servers
  step_djay_pro
  step_xcode
)
STEP_TOTAL=${#STEPS[@]}

main() {
  for s in "${STEPS[@]}"; do "$s"; done
  step_summary
}

main "$@"
