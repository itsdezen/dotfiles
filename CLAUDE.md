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
├── zsh/          → ~/.zshrc, ~/.zshenv, ~/.zprofile
├── nvim/         → ~/.config/nvim/
├── tili/         → ~/.config/tili/
├── starship/     → ~/.config/starship.toml
├── ghostty/      → ~/.config/ghostty/
├── mise/         → ~/.config/mise/config.toml
├── fastfetch/    → ~/.config/fastfetch/
├── git/          → ~/.gitconfig
├── ollama/       → ~/.config/ollama/env
├── superfile/    → ~/.config/superfile/
├── btop/         → ~/.config/btop/
├── lazygit/      → ~/.config/lazygit/
├── claude/       → ~/.claude/settings.json
└── herdr/        → ~/.config/herdr/config.toml
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
- Scripts: `set -euo pipefail`, helpers: `ok/run/warn/abort/section/section_end/spin/spin_ok/spin_warn`
- No banners, no prompts (except destructive ops in `sync.sh uninstall`)
- Commit style: emoji prefix (`🚀 🐞 🔧 ♻️ 📝 🗑️ ⬆️`)

### 4. When adding features

1. Create/update Stow package directory
2. Add package to `PACKAGES` in `sync.sh`
3. Add to `Brewfile` if installable via Homebrew
4. **Update docs** (see rule 5)

### 5. Keep docs in sync

**Mandatory check before every commit**: if the change touches a config file, a package dir, or `sync.sh` — scan `README.md` and `CLAUDE.md` for any mention of what changed and update it in the same commit. No exceptions.

Trigger → what to update:

| Change | Doc to update |
|--------|--------------|
| Add/remove a tool or package | `README.md` Stack + Stow Packages table; `CLAUDE.md` Directory Structure |
| Add/remove a Stow package dir | Same as above |
| Change `sync.sh` behavior or helpers | `README.md` Scripts table; `CLAUDE.md` Conventions helpers list |
| New user-facing capability | `README.md` Highlights |
| New AI rule or convention | `CLAUDE.md` AI Assistant Rules |

**Verification step** — before marking a doc edit done:
1. `grep` or `Read` the actual config file to confirm each stated fact
2. Cross-check `PACKAGES` in `sync.sh` against the Stow Packages table in `README.md` — they must match exactly
3. Cross-check `CLAUDE.md` Directory Structure against the actual package dirs on disk

**Do not** document: ephemeral state, current branch, per-package config values (theme names, font sizes, keybinds) — those live in the config file and go stale. `README.md` stays at Stack/Highlights altitude.

---

**Maintained by:** @itsdezen — https://github.com/itsdezen/dotfiles
