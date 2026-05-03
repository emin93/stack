# ghostty-config

My [Ghostty](https://ghostty.org) terminal config.

## Install

Clone and symlink:

```bash
git clone git@github.com:emin93/ghostty-config.git ~/Documents/Projects/ghostty-config
mkdir -p ~/.config/ghostty
ln -s ~/Documents/Projects/ghostty-config/config ~/.config/ghostty/config
```

Reload inside Ghostty with `Ctrl+Shift+,`.

## What's in it

- Theme: Catppuccin Mocha (bundled with Ghostty)
- 12px window padding, balanced
- 95% background opacity
- Copy on select, hide cursor while typing
- No close-surface confirmation
- 100k line scrollback
- Shell integration with cursor, sudo, and title features
