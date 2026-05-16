# CLAUDE.md

**Developer Documentation for Dotfiles Management**

This document provides comprehensive information about this dotfiles repository structure, design decisions, and how to work with it effectively.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Installation Methods](#installation-methods)
- [Key Components](#key-components)
- [Development Guide](#development-guide)
- [Chezmoi Integration](#chezmoi-integration)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

This dotfiles repository provides a complete development environment setup for macOS, focusing on:

- **Minimal dependencies**: Only essential tools (nvm, mole)
- **Modern shell**: zsh + Oh My Zsh + Powerlevel10k
- **Node.js ecosystem**: nvm + pnpm + bun
- **Interactive installation**: Choose what to install
- **Environment detection**: Scan and sync existing configs

### Design Philosophy

1. **Clean and modular**: Each component is separated into logical modules
2. **Non-invasive**: Always backs up existing files before overwriting
3. **Flexible**: Support both manual install and Chezmoi
4. **Interactive**: Prompt for user choices, not automatic installation
5. **Self-documenting**: Clear comments and structure

---

## Architecture

### Installation Flow

```
install.sh (main entry point)
    ↓
├── Check macOS
├── Create ~/Developer directory
├── Install Homebrew + packages (nvm, mole)
│   └── lib/brew.sh
├── Setup shell (Oh My Zsh + Powerlevel10k)
│   └── lib/omz.sh
├── Install Node.js + package managers
│   └── lib/node.sh (nvm, pnpm, bun)
└── Create symlinks
    └── lib/link.sh
```

### Module Responsibilities

| Module | Purpose |
|--------|---------|
| `install.sh` | Main orchestrator with interactive prompts |
| `lib/brew.sh` | Homebrew installation and package management |
| `lib/omz.sh` | Oh My Zsh + Powerlevel10k + plugins setup |
| `lib/node.sh` | Node.js via nvm, pnpm, and bun installation |
| `lib/link.sh` | Create symlinks from dotfiles to $HOME |
| `scripts/detect-env.sh` | Scan current environment |
| `scripts/dump-brew.sh` | Export Brewfile from current system |

---

## File Structure

```
dotfiles/
├── install.sh              # Main installation script
├── README.md               # User-facing documentation
├── CLAUDE.md              # Developer documentation (this file)
├── CHEZMOI.md             # Chezmoi installation guide
├── .gitignore             # Git ignore rules
├── Brewfile               # Homebrew packages (nvm, mole)
├── .node-version          # Default Node.js version
├── npm-globals.txt        # Global npm packages
│
├── zsh/                   # Zsh configuration
│   ├── zshrc              # Main zsh config (Oh My Zsh + p10k + nvm + bun)
│   ├── zshenv             # Environment variables
│   ├── zprofile           # Login shell config
│   └── p10k.zsh           # Powerlevel10k configuration
│
├── git/                   # Git configuration
│   ├── gitconfig          # Git user config
│   └── gitignore_global   # Global gitignore
│
├── config/                # Additional configs
│   └── starship/
│       └── starship.toml  # Starship prompt (alternative to p10k)
│
├── lib/                   # Installation modules
│   ├── brew.sh            # Homebrew logic
│   ├── omz.sh             # Oh My Zsh logic
│   ├── node.sh            # Node.js logic
│   └── link.sh            # Symlink logic
│
└── scripts/               # Utility scripts
    ├── detect-env.sh      # Environment detection
    └── dump-brew.sh       # Brewfile export
```

---

## Installation Methods

### Method 1: Direct Installation (Recommended for first-time setup)

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh
```

**Pros:**
- Simple and straightforward
- Interactive prompts
- Good for learning the setup

**Cons:**
- Manual symlink management
- Harder to sync across multiple machines

### Method 2: Chezmoi (Recommended for ongoing management)

```bash
# Install chezmoi
brew install chezmoi

# Initialize from repository
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git

# Preview changes
chezmoi diff

# Apply dotfiles
chezmoi apply -v
```

See [CHEZMOI.md](CHEZMOI.md) for detailed guide.

**Pros:**
- Automatic symlink management
- Easy to sync across machines
- Supports templating for machine-specific configs
- Can track and merge changes

**Cons:**
- Additional tool to learn
- More complex setup

---

## Key Components

### Shell Configuration (zsh/)

**zshrc** - Main configuration file featuring:
- Powerlevel10k instant prompt
- Oh My Zsh framework
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting
- nvm integration (Homebrew installation)
- bun integration
- Custom aliases
- Support for machine-specific `.zshrc.local`

**p10k.zsh** - Powerlevel10k configuration:
- Copied from user's existing setup
- Customized prompt with lean style
- Git status integration
- Command execution time
- Background jobs indicator

### Node.js Environment (lib/node.sh)

**nvm setup:**
- Supports both Homebrew and manual installation
- Loads from multiple possible locations
- Auto-installs default Node version from `.node-version`
- Bash completion support

**pnpm:**
- Fast, disk-efficient package manager
- Installed globally via npm

**bun:**
- All-in-one JavaScript runtime
- Installed via official installer script
- Adds to PATH automatically

### Homebrew Packages (Brewfile)

Minimal essential packages:
- `nvm` - Node version manager
- `mole` - SSH tunneling tool
- `font-*` - Development fonts (commented, manual install)

### Git Configuration (git/)

**gitconfig:**
- User info (name, email) - to be filled by user
- Aliases for common commands
- Diff and merge tools

**gitignore_global:**
- macOS system files
- Editor files
- Build artifacts
- Environment files

---

## Development Guide

### Adding a New Component

1. **Create module in `lib/`:**
```bash
touch lib/myfeature.sh
chmod +x lib/myfeature.sh
```

2. **Add installation function:**
```bash
#!/usr/bin/env bash
# lib/myfeature.sh — Description

install_myfeature() {
  if command -v myapp &>/dev/null; then
    success "myapp already installed"
    return 0
  fi

  info "Installing myapp..."
  # Installation logic here
  success "myapp installed"
}
```

3. **Integrate in `install.sh`:**
```bash
if [[ "$SKIP_MYFEATURE" == false ]]; then
  header "My Feature"
  source "$DOTFILES_DIR/lib/myfeature.sh"

  read -r -p "  Install myfeature? [Y/n] " response
  [[ ! "$response" =~ ^[Nn]$ ]] && install_myfeature
fi
```

### Adding New Dotfiles

1. **Add file to appropriate directory:**
```bash
# For config files
touch config/myapp/config.conf

# For shell configs
touch zsh/my-aliases.zsh
```

2. **Update `lib/link.sh`:**
```bash
# In create_symlinks() function
link_file "$dotfiles_dir/config/myapp/config.conf" \
          "$HOME/.config/myapp/config.conf"
```

3. **Test the symlink:**
```bash
./install.sh --skip-brew --skip-node --skip-shell
ls -la ~/.config/myapp/config.conf
```

### Updating Brewfile

**From your current system:**
```bash
bash scripts/dump-brew.sh
```

**Manually edit to keep only essentials:**
```ruby
brew "nvm"
brew "mole"
# Add new package
brew "newtool"
```

### Testing Changes

1. **Create test environment:**
```bash
# Use Docker or VM for clean testing
docker run -it --rm -v $(pwd):/dotfiles macOS/ventura bash
```

2. **Test installation:**
```bash
cd /dotfiles
./install.sh --all
```

3. **Verify:**
```bash
bash scripts/detect-env.sh
```

---

## Chezmoi Integration

### Why Chezmoi?

Chezmoi provides:
- **Version control**: Track all dotfiles in git
- **Templating**: Machine-specific configurations
- **Encryption**: For sensitive files
- **Cross-platform**: Works on macOS, Linux, Windows

### Structure Mapping

| Dotfiles Path | Chezmoi Source Path |
|---------------|---------------------|
| `zsh/zshrc` | `.chezmoitemplates/zshrc` or `dot_zshrc` |
| `git/gitconfig` | `dot_gitconfig.tmpl` |
| `zsh/p10k.zsh` | `dot_p10k.zsh` |

### Template Variables

Use in `.chezmoi.toml.tmpl`:
```toml
[data]
    email = "{{ .email }}"
    name = "{{ .name }}"
    editor = "{{ .editor }}"
```

Then in files:
```bash
# gitconfig
[user]
    name = {{ .name }}
    email = {{ .email }}
```

See [CHEZMOI.md](CHEZMOI.md) for full guide.

---

## Troubleshooting

### Common Issues

**1. nvm not loading:**
```bash
# Check nvm installation
echo $NVM_DIR
ls -la $NVM_DIR/nvm.sh

# Reload shell
source ~/.zshrc
```

**2. Oh My Zsh plugins not working:**
```bash
# Check plugin installation
ls -la ~/.oh-my-zsh/custom/plugins/

# Reinstall plugins
bash lib/omz.sh
```

**3. Symlinks broken:**
```bash
# Check symlink status
ls -la ~/.zshrc

# Recreate symlinks
bash lib/link.sh
```

**4. Homebrew packages not found:**
```bash
# Verify Homebrew
brew doctor

# Reinstall packages
brew bundle --file=Brewfile
```

### Debug Mode

Run with verbose output:
```bash
bash -x install.sh --all 2>&1 | tee install.log
```

### Environment Detection

Check current state:
```bash
bash scripts/detect-env.sh
```

---

## Best Practices

### For Users

1. **Always review before applying:**
   ```bash
   chezmoi diff  # or preview install.sh changes
   ```

2. **Use machine-specific configs:**
   ```bash
   # In ~/.zshrc.local (not tracked in git)
   export WORK_API_KEY="secret"
   ```

3. **Keep Brewfile minimal:**
   - Only add essential tools
   - Document why each package is needed

4. **Backup before major changes:**
   ```bash
   cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)
   ```

### For Developers

1. **Comment extensively:**
   - Explain WHY, not just WHAT
   - Use section headers (# ── Section ──)

2. **Test on clean system:**
   - Use VM or Docker
   - Test with different installation orders

3. **Handle errors gracefully:**
   ```bash
   set -euo pipefail  # At start of scripts
   command || { error "Failed"; return 1; }
   ```

4. **Provide feedback:**
   ```bash
   info "Doing something..."
   success "Done!"
   warn "Issue found"
   error "Failed!"
   ```

---

## Maintenance

### Regular Tasks

**Weekly:**
- [ ] Update Brewfile from current system
- [ ] Check for Oh My Zsh updates
- [ ] Test installation on clean system

**Monthly:**
- [ ] Review and update documentation
- [ ] Check for deprecated packages
- [ ] Update Node.js version in `.node-version`

**Quarterly:**
- [ ] Major refactoring if needed
- [ ] Update to new tool versions
- [ ] Review and clean up unused configs

### Version History

Track major changes in git:
```bash
git log --oneline --decorate
```

---

## Resources

### Documentation
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Chezmoi](https://www.chezmoi.io/)
- [nvm](https://github.com/nvm-sh/nvm)

### Similar Projects
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)

---

## Contributing

### Workflow

1. **Create feature branch:**
   ```bash
   git checkout -b feature/my-improvement
   ```

2. **Make changes:**
   - Update code
   - Update documentation
   - Test thoroughly

3. **Commit with conventional commits:**
   ```bash
   git commit -m "feat: add new feature"
   git commit -m "fix: resolve issue"
   git commit -m "docs: update readme"
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/my-improvement
   ```

---

## License

MIT License - Feel free to use and modify for your own needs.

---

**Last Updated:** 2026-05-16
**Maintained By:** @onepercman
**Generated With:** Claude Code Assistant
