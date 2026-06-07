# Editor
export EDITOR="vim"
export VISUAL="$EDITOR"

# 1Password SSH agent
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Local tools
export PATH="$HOME/.local/bin:$PATH"

# Java (Android Studio bundled JBR)
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"

# Android NDK (brew cask android-ndk; symlink tracks the current version)
export ANDROID_NDK_HOME="/opt/homebrew/share/android-ndk"

# pnpm globals
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Machine-local overrides
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/emin/.lmstudio/bin"
# End of LM Studio CLI section

