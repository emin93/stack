# macOS zshrc.

# Homebrew
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

export EDITOR="micro"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"

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
alias claude='claude --permission-mode bypassPermissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Node (keg-only Homebrew node@24)
if command -v brew >/dev/null 2>&1; then
  _node_prefix="$(brew --prefix node@24 2>/dev/null)"
  [[ -n "$_node_prefix" && -d "$_node_prefix/bin" ]] && export PATH="$_node_prefix/bin:$PATH"
  unset _node_prefix
fi

# Per-host overrides (secrets, machine-specific tweaks)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
