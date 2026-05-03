# Portable zshrc — sourced on both Linux and macOS.

# Homebrew (macOS or Linuxbrew)
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"

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
alias ls='ls --color=auto' 2>/dev/null || alias ls='ls -G'
alias ll='ls -lah'
alias lg='lazygit'
alias g='git'
alias zj='zellij'
alias cc='claude'

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Per-host overrides (gitignored)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
