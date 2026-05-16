# Fonts

This directory contains Comic Code Ligatures fonts for development environment.

## Installation

### Option 1: Copy from system

If you already have the fonts installed:

```bash
bash scripts/copy-fonts.sh
```

### Option 2: Manual installation

1. Place font files (`.ttf` or `.otf`) in this directory
2. Run `./install.sh` and select font installation

### Option 3: Install to system directly

Copy font files to:
```bash
~/Library/Fonts/
```

## Recommended Fonts

- **Comic Code Ligatures** - Main coding font
- **Comic Code Ligatures Nerd** - With icon support for terminal

Download from:
- https://github.com/ryanoasis/nerd-fonts

## Git Tracking

Font files are typically large. Consider adding to `.gitignore`:

```bash
echo 'fonts/*.ttf' >> .gitignore
echo 'fonts/*.otf' >> .gitignore
```

Or keep them in git for easy sync across machines (not recommended for public repos).
