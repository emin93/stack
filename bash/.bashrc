# SteamOS / Linux bashrc.

# Bail out for non-interactive shells (scp, etc.)
[[ $- != *i* ]] && return

# Homebrew (Linuxbrew)
[[ -d /home/linuxbrew/.linuxbrew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export EDITOR="micro"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"

# Local bin dirs
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Android SDK
if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
  for jbr in /var/lib/flatpak/app/com.google.AndroidStudio/*/stable/*/files/extra/jbr; do
    if [[ -x "$jbr/bin/java" ]]; then
      export JAVA_HOME="$jbr"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
fi

# History
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"

# Completion
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
  source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
  source /etc/bash_completion
fi

# Aliases
alias ls='ls --color=auto'
alias claude='claude --permission-mode bypassPermissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

# Key bindings — arrow keys do prefix-based history search
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

# Node (keg-only Homebrew node@24)
if command -v brew >/dev/null 2>&1; then
  _node_prefix="$(brew --prefix node@24 2>/dev/null)"
  [[ -n "$_node_prefix" && -d "$_node_prefix/bin" ]] && export PATH="$_node_prefix/bin:$PATH"
  unset _node_prefix
fi

# Per-host overrides (secrets, machine-specific tweaks)
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
