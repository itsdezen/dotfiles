# Chezmoi Installation Guide

Complete guide for managing dotfiles with Chezmoi.

---

## What is Chezmoi?

[Chezmoi](https://www.chezmoi.io/) is a dotfile manager that:
- Tracks dotfiles in a git repository
- Manages symlinks automatically
- Supports templating for machine-specific configs
- Handles encryption for sensitive data
- Works across multiple machines

---

## Quick Start

### 1. Install Chezmoi

```bash
# Via Homebrew (recommended)
brew install chezmoi

# Or via install script
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### 2. Initialize from Repository

```bash
# Initialize chezmoi with this repository
chezmoi init https://github.com/onepercman/dotfiles.git

# Or if you've already cloned it
chezmoi init --apply ~/Developer/dotfiles
```

### 3. Review Changes

```bash
# See what would change
chezmoi diff

# Show detailed plan
chezmoi plan
```

### 4. Apply Dotfiles

```bash
# Apply all changes
chezmoi apply -v

# Apply specific file
chezmoi apply ~/.zshrc
```

---

## Repository Structure

### Before Chezmoi (Current)

```
dotfiles/
├── zsh/zshrc         → ~/.zshrc
├── git/gitconfig     → ~/.gitconfig
└── config/starship/starship.toml → ~/.config/starship/starship.toml
```

### After Chezmoi Migration

```
~/.local/share/chezmoi/
├── dot_zshrc
├── dot_gitconfig.tmpl
├── dot_config/
│   └── starship/
│       └── starship.toml
├── .chezmoi.toml.tmpl
└── run_once_install.sh
```

---

## Migration Guide

### Step 1: Prepare Repository Structure

Create chezmoi-compatible structure:

```bash
cd ~/Developer/dotfiles

# Create chezmoi structure
mkdir -p .chezmoi

# Copy files with chezmoi naming convention
# dot_* = dotfile (.)
# run_once_* = script to run once
# .tmpl = template file
```

### Step 2: Convert Files

| Original | Chezmoi Name | Description |
|----------|--------------|-------------|
| `zsh/zshrc` | `dot_zshrc` | Main zsh config |
| `zsh/zshenv` | `dot_zshenv` | Zsh environment |
| `zsh/zprofile` | `dot_zprofile` | Zsh profile |
| `config/starship/starship.toml` | `dot_config/starship/starship.toml` | Starship prompt config |
| `git/gitconfig` | `dot_gitconfig.tmpl` | Git config (template) |
| `git/gitignore_global` | `dot_gitignore_global` | Global gitignore |
| `install.sh` | `run_once_install.sh` | Installation script |

### Step 3: Create Configuration

**`.chezmoi.toml.tmpl`:**
```toml
{{- $email := promptStringOnce . "email" "Email address" -}}
{{- $name := promptStringOnce . "name" "Full name" -}}
{{- $editor := promptStringOnce . "editor" "Preferred editor" -}}

[data]
    email = {{ $email | quote }}
    name = {{ $name | quote }}
    editor = {{ $editor | quote }}
```

**`dot_gitconfig.tmpl`:**
```ini
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
    editor = {{ .editor }}
    excludesfile = ~/.gitignore_global

[alias]
    st = status -sb
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate
```

### Step 4: Create Installation Script

**`run_once_install.sh`:**
```bash
#!/usr/bin/env bash
# This script runs once when chezmoi apply is executed

set -euo pipefail

echo "Running one-time setup..."

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages
brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile"

# Setup Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Setup Powerlevel10k
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

echo "Setup complete!"
```

---

## Daily Workflow

### Adding New Dotfiles

```bash
# Add a file to chezmoi
chezmoi add ~/.vimrc

# Add with template support
chezmoi add --template ~/.gitconfig

# Add and open in editor
chezmoi add --edit ~/.zshrc
```

### Editing Dotfiles

```bash
# Edit with chezmoi (recommended)
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply
```

### Syncing Changes

```bash
# Pull latest changes from git
chezmoi update

# Or manually
cd ~/.local/share/chezmoi
git pull
chezmoi apply
```

### Pushing Changes

```bash
# Go to chezmoi source directory
chezmoi cd

# Commit and push
git add .
git commit -m "feat: update zshrc"
git push

# Return to previous directory
exit
```

---

## Advanced Usage

### Templates

Use variables in dotfiles:

**`dot_gitconfig.tmpl`:**
```ini
[user]
    name = {{ .name }}
    email = {{ .email }}

{{- if eq .chezmoi.hostname "work-laptop" }}
[user]
    signingkey = {{ .work_signing_key }}
{{- end }}
```

### Machine-Specific Configs

**`.chezmoi.toml.tmpl`:**
```toml
{{- $hostname := .chezmoi.hostname -}}
{{- $is_work := promptBoolOnce . "is_work" "Is this a work machine" -}}

[data]
    hostname = {{ $hostname | quote }}
    is_work = {{ $is_work }}
```

**In dotfiles:**
```bash
# dot_zshrc.tmpl
{{- if .is_work }}
export WORK_ENV=production
{{- end }}
```

### Encryption

For sensitive files:

```bash
# Use age encryption
chezmoi add --encrypt ~/.ssh/id_rsa

# Requires age key setup
age-keygen -o ~/.config/chezmoi/key.txt
```

**`.chezmoi.toml.tmpl`:**
```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."
```

### Scripts

**Run once:**
```bash
# run_once_install-packages.sh
# Runs once, creates .run_once_install-packages.sh.state
```

**Run on every apply:**
```bash
# run_update-packages.sh
# Runs every time chezmoi apply is executed
```

**Run before apply:**
```bash
# .chezmoiscripts/run_before_backup.sh
```

**Run after apply:**
```bash
# .chezmoiscripts/run_after_reload.sh
```

---

## Multi-Machine Setup

### Machine 1 (Initial Setup)

```bash
# Install chezmoi
brew install chezmoi

# Initialize with existing dotfiles
chezmoi init --apply ~/Developer/dotfiles

# Push to git
chezmoi cd
git add .
git commit -m "init: setup chezmoi"
git push
```

### Machine 2 (New Machine)

```bash
# Install chezmoi
brew install chezmoi

# Initialize from remote
chezmoi init --apply https://github.com/onepercman/dotfiles.git

# Chezmoi will prompt for variables
# Email: onepercman@gmail.com
# Name: onepercman
# Editor: code
```

### Keeping Machines in Sync

```bash
# On Machine 1 - Make changes
chezmoi edit ~/.zshrc
chezmoi apply
chezmoi cd && git add . && git commit -m "update zshrc" && git push

# On Machine 2 - Sync changes
chezmoi update -v
```

---

## Comparison: Manual vs Chezmoi

| Feature | Manual (install.sh) | Chezmoi |
|---------|---------------------|---------|
| Initial setup | Simple, one script | More setup required |
| Symlink management | Manual via link.sh | Automatic |
| Multi-machine sync | Manual git pull | `chezmoi update` |
| Machine-specific configs | `.local` files | Templates |
| Sensitive data | Not supported | Encryption support |
| Version control | Full repo | Source directory only |
| Learning curve | Low | Medium |

---

## Troubleshooting

### Issue: Chezmoi conflicts with existing files

```bash
# Remove existing symlinks first
rm ~/.zshrc ~/.gitconfig

# Then apply
chezmoi apply -v
```

### Issue: Template variables not prompting

```bash
# Remove state
rm ~/.config/chezmoi/chezmoistate.boltdb

# Re-initialize
chezmoi init
```

### Issue: Changes not syncing

```bash
# Check git status
chezmoi cd
git status
git log

# Force update
chezmoi update --force
```

### Issue: Script not running

```bash
# Check script permissions
ls -la ~/.local/share/chezmoi/run_*

# Make executable
chmod +x ~/.local/share/chezmoi/run_once_install.sh

# Force re-run
rm ~/.config/chezmoi/chezmoistate.boltdb
chezmoi apply
```

---

## Best Practices

### Do's

✅ Use templates for machine-specific configs
✅ Encrypt sensitive files with age
✅ Use `run_once_` for expensive operations
✅ Test changes with `chezmoi diff` first
✅ Commit often with descriptive messages
✅ Keep Brewfile minimal

### Don'ts

❌ Don't commit sensitive data unencrypted
❌ Don't skip `chezmoi diff` before apply
❌ Don't manually edit files in `~/.local/share/chezmoi`
❌ Don't forget to push changes
❌ Don't use `--force` unless necessary

---

## Migration Checklist

Planning to migrate from manual to Chezmoi? Use this checklist:

- [ ] Install chezmoi
- [ ] Backup current dotfiles
- [ ] Create `.chezmoi.toml.tmpl`
- [ ] Convert files to chezmoi naming
- [ ] Create `run_once_install.sh`
- [ ] Test on clean machine/VM
- [ ] Commit and push to git
- [ ] Update README with chezmoi instructions
- [ ] Test sync between two machines
- [ ] Remove old manual symlinks
- [ ] Update installation instructions

---

## Resources

- **Official Docs**: https://www.chezmoi.io/
- **User Guide**: https://www.chezmoi.io/user-guide/setup/
- **Reference**: https://www.chezmoi.io/reference/
- **Comparison**: https://www.chezmoi.io/comparison-table/

---

## Example Repositories

- [twpayne/dotfiles](https://github.com/twpayne/dotfiles) - Chezmoi creator's dotfiles
- [renemarc/dotfiles](https://github.com/renemarc/dotfiles) - Comprehensive example
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles) - Cross-platform setup

---

**Note:** This repository currently uses manual installation via `install.sh`. Chezmoi support is optional and can be added alongside the existing setup.

---

**Last Updated:** 2026-05-16
**Maintained By:** @onepercman
