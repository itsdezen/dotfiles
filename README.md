# dotfiles 🏠

Personal macOS development environment — setup a new machine with **one command**.

## Quick Install (New Machine)

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh
```

The installer will prompt you to choose which components to install.

## Structure

```
dotfiles/
├── install.sh              ← Entry point, run this
├── Brewfile                ← Homebrew packages (nvm, mole)
├── npm-globals.txt         ← Global npm packages
├── .node-version           ← Default Node version (lts)
│
├── zsh/
│   ├── zshrc               → ~/.zshrc
│   ├── zshenv              → ~/.zshenv
│   ├── zprofile            → ~/.zprofile
│   └── p10k.zsh            → ~/.p10k.zsh
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
    ├── node.sh             ← Node.js via nvm + pnpm + bun
    ├── link.sh             ← Create symlinks
    └── omz.sh              ← Oh My Zsh + Powerlevel10k setup
```

## Interactive Installation

The installer will ask you what to install:

```bash
./install.sh
```

You can choose:
- Homebrew packages (nvm, mole)
- Node.js setup (nvm + default version)
- Package managers (pnpm, bun)
- Oh My Zsh + Powerlevel10k
- Dotfiles symlinks
- Comic Code Ligatures fonts
- Starship prompt (optional)

Or use flags to skip prompts:

```bash
./install.sh --all              # Install everything
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

- **Oh My Zsh** — Framework for managing zsh configuration
- **Powerlevel10k** — Fast and customizable prompt
- **Starship** — Alternative cross-shell prompt (optional)
- **nvm** — Node version manager
- **pnpm** — Fast, disk space efficient package manager
- **bun** — All-in-one JavaScript runtime & toolkit

## Aliases

| Command | Description |
|---------|-------------|
| `reload` | Reload ~/.zshrc |
| `dots` | cd to dotfiles directory |
| `zrc` | Open ~/.zshrc in editor |
| `dev` | cd to ~/Developer |

## Fonts

Comic Code Ligatures with Nerd Font icons is recommended for the best terminal experience.

### Install Fonts

**Option 1: During installation**
```bash
./install.sh
# Select Y when prompted for font installation
```

**Option 2: Copy from system**
```bash
bash scripts/copy-fonts.sh
```

**Option 3: Manual installation**
1. Place font files in `fonts/` directory
2. Run `./install.sh` and select font installation

Or copy directly to system:
```bash
cp fonts/*.{ttf,otf} ~/Library/Fonts/
```

### Font Files

- Place `.ttf` or `.otf` files in the `fonts/` directory
- See `fonts/README.md` for details
- Download Nerd Fonts: https://github.com/ryanoasis/nerd-fonts

## Tips

- Use `p10k configure` to customize your prompt
- Starship can be used instead of/alongside p10k
- Local overrides go in `~/.zshrc.local` (not tracked in git)
