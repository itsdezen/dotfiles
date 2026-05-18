# dotfiles 🏠

Personal macOS development environment — setup a new machine with **one command**.

## Quick Install (New Machine)

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh
```

The installer features an **interactive checklist UI** that:
- 🔍 Auto-detects what's already installed
- ✓ Pre-selects missing components
- ⌨️ Arrow keys to navigate, SPACE to toggle, ENTER to confirm
- 🎨 Beautiful ASCII art interface by **onepercman**

## Structure

```
dotfiles/
├── install.sh              ← Entry point, run this
├── Brewfile                ← Homebrew packages (mise, mole, fonts)
├── npm-globals.txt         ← Global npm packages
├── .node-version           ← Default Node version (lts)
│
├── zsh/
│   ├── zshrc               → ~/.zshrc
│   ├── zshenv              → ~/.zshenv
│   └── zprofile            → ~/.zprofile
│
├── git/
│   ├── gitconfig           → ~/.gitconfig
│   └── gitignore_global    → ~/.gitignore_global
│
├── config/
│   └── starship/
│       └── starship.toml   → ~/.config/starship.toml
│
├── scripts/
│   ├── dump-brew.sh        ← Export current Brewfile
│   └── detect-env.sh       ← Detect current environment configs
│
└── lib/
    ├── brew.sh             ← Homebrew installation logic
    ├── node.sh             ← Node.js via mise + pnpm + bun
    ├── link.sh             ← Create symlinks
    └── zinit.sh            ← zinit plugin manager setup
```

## Interactive Installation

### 🎮 Interactive Mode (Recommended)

Run the installer to see the interactive checklist:

```bash
./install.sh
```

**How it works:**
1. **Auto-detection** - Scans your system for installed tools
2. **Smart defaults** - Pre-selects missing components
3. **Interactive selection**:
   - Use `↑` `↓` arrow keys to navigate
   - Press `SPACE` to toggle checkboxes
   - Press `ENTER` to start installation
4. **Installation** - Installs only selected components
5. **Completion screen** - Shows next steps

**Available components:**
- ☑ Homebrew & Essential Tools (mise, mole, starship)
- ☑ JetBrains Mono Nerd Font
- ☑ zinit (Plugin Manager) + Plugins
- ☑ Starship Prompt
- ☑ Node.js (via mise)
- ☑ pnpm Package Manager
- ☑ bun Runtime
- ☑ Terminal.app Profile (Clear Dark with JetBrains Mono)
- ☑ Create Symlinks (.zshrc, .gitconfig, etc.)

### ⚡ Non-Interactive Mode

For automated installations or CI/CD:

```bash
./install.sh --all              # Install everything without prompts
./install.sh --skip-brew        # Skip Homebrew
./install.sh --skip-node        # Skip Node.js
./install.sh --skip-shell       # Skip shell setup
```

## Environment Detection

Scan your current environment to update dotfiles:

```bash
bash scripts/detect-env.sh
```

This will check and suggest updates for:
- Installed Homebrew packages
- Current zsh configuration
- Node.js version
- Installed package managers (pnpm, bun)

## After Setup

1. **Update git config** with your personal info in [git/gitconfig](git/gitconfig):
   ```
   name  = Your Name
   email = your.email@example.com
   ```

2. **Update Brewfile** from current machine:
   ```bash
   bash ~/Developer/dotfiles/scripts/dump-brew.sh
   git add Brewfile && git commit -m "chore: update Brewfile"
   ```

3. **Add machine-specific config** (not committed to git):
   ```bash
   # ~/.zshrc.local — machine-specific aliases/env
   echo 'export WORK_TOKEN="xxx"' >> ~/.zshrc.local
   ```

## Update Dotfiles

```bash
dots          # cd to ~/Developer/dotfiles (alias)
# Edit files...
git add -A && git commit -m "feat: ..."
git push
```

## Shell Features

- **zinit** — Modern, fast, and flexible zsh plugin manager with turbo mode
- **Starship** — Fast, minimal, and highly customizable cross-shell prompt
- **mise** — Polyglot version manager (Node, Python, Ruby, etc.)
- **pnpm** — Fast, disk space efficient package manager
- **bun** — All-in-one JavaScript runtime & toolkit

### Plugins (managed by zinit)

- **git** — Git aliases and completion from OMZ library
- **zsh-autosuggestions** — Fish-like command suggestions
- **zsh-syntax-highlighting** — Real-time syntax highlighting

## Aliases

| Command | Description |
|---------|-------------|
| `reload` | Reload ~/.zshrc |
| `dots` | cd to dotfiles directory |
| `zrc` | Open ~/.zshrc in editor |
| `dev` | cd to ~/Developer |

## Fonts

JetBrains Mono Nerd Font is installed automatically via Homebrew for the best terminal experience with icon support.

### Install Font

The font is included in the Brewfile and will be installed automatically:
```bash
brew bundle  # Installs font-jetbrains-mono-nerd-font
```

Or manually:
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

After installation, set the font in your terminal:
- **Terminal.app**: Preferences → Profiles → Font
- **iTerm2**: Preferences → Profiles → Text → Font
- **VS Code**: Settings → Terminal › Integrated: Font Family

## Tips

- Customize Starship prompt by editing `~/.config/starship/starship.toml`
- Run `starship config` to see all available options
- Local overrides go in `~/.zshrc.local` (not tracked in git)
