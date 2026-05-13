# macOS zshrc.

# Homebrew
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

export EDITOR="zed --wait"
export VISUAL="$EDITOR"
export LESS="-R"

# Route all SSH agent traffic through 1Password.
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Local bin dirs
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Aliases
alias ls='ls -G'

# Key bindings — prefix-search on up/down
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Per-host overrides (secrets, machine-specific tweaks)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
