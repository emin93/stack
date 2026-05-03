# Portable zshrc — sourced on both Linux and macOS.

# Homebrew (macOS or Linuxbrew)
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export EDITOR="micro"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"

# Local bin dirs
export PATH="$HOME/.local/bin:$PATH"

# pnpm (macOS uses ~/Library/pnpm, Linux uses ~/.local/share/pnpm)
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# nvm (Linux: ~/.nvm; macOS via brew: $(brew --prefix)/opt/nvm)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
elif command -v brew >/dev/null 2>&1 && [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]]; then
  . "$(brew --prefix)/opt/nvm/nvm.sh"
fi

# Android SDK (Linux only — macOS uses different path, set in ~/.zshrc.local if needed)
if [[ "$OSTYPE" == "linux"* && -d "$HOME/Android/Sdk" ]]; then
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
alias cc='claude'

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Node (keg-only Homebrew node@24 on macOS; system node elsewhere)
if command -v brew >/dev/null 2>&1; then
  _node_prefix="$(brew --prefix node@24 2>/dev/null)"
  [[ -n "$_node_prefix" && -d "$_node_prefix/bin" ]] && export PATH="$_node_prefix/bin:$PATH"
  unset _node_prefix
fi

# Per-host overrides (secrets, machine-specific tweaks)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
