# Editor
export EDITOR="open -W -a OpenCode"
export VISUAL="$EDITOR"

# 1Password SSH agent
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Local tools
export PATH="$HOME/.local/bin:$PATH"

# Unsloth Studio
alias ustudio='unsloth studio -H 0.0.0.0 -p 8888'

# Java (Android Studio bundled JBR)
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# pnpm globals
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Machine-local overrides
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
