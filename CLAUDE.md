# CLAUDE.md

AI assistant instructions for this dotfiles repository. For general documentation, stack overview, scripts, and troubleshooting — see **[README.md](./README.md)**.

---

## Design Philosophy

1. **One script**: `sync.sh` is the single entry point — install, update, repair. No per-tool install scripts.
2. **Modular**: each Stow package is self-contained. Files symlink to `$HOME` via `stow -t "$HOME"`.
3. **Dotfiles win**: conflicts resolved by removing the target file, never creating backups.
4. **Minimal**: no abstractions beyond what the tools need.

---

## Directory Structure

```
dotfiles/
├── sync.sh
├── Brewfile
├── zsh/        → ~/.zshrc, ~/.zshenv, ~/.zprofile
├── nvim/       → ~/.config/nvim/
├── aerospace/  → ~/.config/aerospace/
├── hammerspoon/→ ~/.hammerspoon/
├── starship/   → ~/.config/starship.toml
├── zed/        → ~/.config/zed/
├── ghostty/    → ~/.config/ghostty/
├── cmux/       → ~/.config/cmux/
├── tmux/       → ~/.tmux.conf
├── mise/       → ~/.config/mise/config.toml
├── superfile/  → ~/.config/superfile/
└── claude/     → ~/.claude/settings.json
```

---

## AI Assistant Rules

### 1. Always use Stow

- Never create custom symlink scripts or backup files
- Use `stow -t "$HOME" -R <package>` for all symlink operations
- Detect conflicts with `stow -n`, remove conflicting files, then stow

### 2. One script philosophy

- `sync.sh` is the single entry point: `./sync.sh` to install, `./sync.sh uninstall` to remove
- When adding a package: add to `PACKAGES` in `sync.sh` only

### 3. Conventions

- Stow package dirs: lowercase
- Scripts: `set -euo pipefail`, helpers: `ok/run/warn/abort`
- No banners, no prompts (except destructive ops in `uninstall.sh`)
- Commit style: emoji prefix (`🚀 🐞 🔧 ♻️ 📝 🗑️ ⬆️`)

### 4. When adding features

1. Create/update Stow package directory
2. Add package to `PACKAGES` in `sync.sh`
3. Add to `Brewfile` if installable via Homebrew
4. **Update docs** (see rule 5)

### 5. Keep docs in sync

Whenever a dotfiles change affects something documented in `README.md` or `CLAUDE.md`, update the relevant doc in the same commit. This includes:

- Stack or tool changes → `README.md` Stack section
- New/removed Stow packages → `README.md` Stow Packages table + Directory Structure above
- New standout/user-facing capability → `README.md` Highlights section
- New scripts or changed script behavior → `README.md` Scripts table
- New AI rules or conventions → `CLAUDE.md` AI Assistant Rules

**Do not** document ephemeral state (current branch, in-progress work, which PR fixed what). **Do not** document per-package config values (theme names, font sizes, keybind specifics, etc.) — those live in the config file itself and go stale; `README.md` stays at the Stack/Highlights altitude.

Before claiming a doc update is done, verify each fact against the actual config file (`grep`/`Read` it) rather than assuming — stale or invented details are worse than no docs.

---

**Maintained by:** @itsdezen — https://github.com/itsdezen/dotfiles
