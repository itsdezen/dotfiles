#!/usr/bin/env bash
# =============================================================================
# dotfiles/install.sh
# Bootstrap script — setup a new Mac with one command
# Usage: ./install.sh [--all] [--skip-brew] [--skip-node] [--skip-shell]
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[dotfiles]"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}${LOG_PREFIX}${RESET} $*"; }
success() { echo -e "${GREEN}${LOG_PREFIX} ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}${LOG_PREFIX} ⚠${RESET} $*"; }
error()   { echo -e "${RED}${LOG_PREFIX} ✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}"; }

# ── Flags ────────────────────────────────────────────────────────────────────
INSTALL_ALL=false
SKIP_BREW=false
SKIP_NODE=false
SKIP_SHELL=false

for arg in "$@"; do
  case $arg in
    --all)        INSTALL_ALL=true ;;
    --skip-brew)  SKIP_BREW=true   ;;
    --skip-node)  SKIP_NODE=true   ;;
    --skip-shell) SKIP_SHELL=true  ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --all           Install everything without prompts"
      echo "  --skip-brew     Skip Homebrew installation"
      echo "  --skip-node     Skip Node.js installation"
      echo "  --skip-shell    Skip shell setup (Oh My Zsh, Powerlevel10k)"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
  esac
done

# ── Check macOS ──────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script only runs on macOS!"
  exit 1
fi

header "Starting dotfiles setup"
info "DOTFILES_DIR = $DOTFILES_DIR"

# ── Ensure ~/Developer directory exists ──────────────────────────────────────
if [[ ! -d "$HOME/Developer" ]]; then
  info "Creating ~/Developer directory..."
  mkdir -p "$HOME/Developer"
  success "~/Developer directory created"
else
  success "~/Developer directory exists"
fi

# ── 1. Homebrew & packages ───────────────────────────────────────────────────
if [[ "$SKIP_BREW" == false ]]; then
  header "Homebrew"
  source "$DOTFILES_DIR/lib/brew.sh"

  if [[ "$INSTALL_ALL" == true ]]; then
    install_homebrew
    install_packages "$DOTFILES_DIR/Brewfile"
  else
    read -r -p "  Install Homebrew packages (nvm, mole)? [Y/n] " response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
      install_homebrew
      install_packages "$DOTFILES_DIR/Brewfile"
    else
      info "Skipping Homebrew installation"
    fi
  fi
fi

# ── 2. Oh My Zsh + Powerlevel10k ─────────────────────────────────────────────
if [[ "$SKIP_SHELL" == false ]]; then
  header "Shell Setup"
  source "$DOTFILES_DIR/lib/omz.sh"

  if [[ "$INSTALL_ALL" == true ]]; then
    setup_shell
  else
    read -r -p "  Install Oh My Zsh + Powerlevel10k + plugins? [Y/n] " response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
      setup_shell
    else
      info "Skipping shell setup"
    fi
  fi
fi

# ── 3. Node.js via nvm ───────────────────────────────────────────────────────
if [[ "$SKIP_NODE" == false ]]; then
  header "Node.js"
  source "$DOTFILES_DIR/lib/node.sh"

  if [[ "$INSTALL_ALL" == true ]]; then
    install_node

    read -r -p "  Install pnpm? [Y/n] " response
    [[ ! "$response" =~ ^[Nn]$ ]] && install_pnpm

    read -r -p "  Install bun? [Y/n] " response
    [[ ! "$response" =~ ^[Nn]$ ]] && install_bun
  else
    read -r -p "  Install Node.js via nvm? [Y/n] " response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
      install_node

      read -r -p "  Install pnpm? [Y/n] " response
      [[ ! "$response" =~ ^[Nn]$ ]] && install_pnpm

      read -r -p "  Install bun? [Y/n] " response
      [[ ! "$response" =~ ^[Nn]$ ]] && install_bun
    else
      info "Skipping Node.js installation"
    fi
  fi
fi

# ── 4. Symlinks ──────────────────────────────────────────────────────────────
header "Dotfiles symlinks"
source "$DOTFILES_DIR/lib/link.sh"

if [[ "$INSTALL_ALL" == true ]]; then
  create_symlinks "$DOTFILES_DIR"
else
  read -r -p "  Create dotfiles symlinks (.zshrc, .gitconfig, etc.)? [Y/n] " response
  if [[ ! "$response" =~ ^[Nn]$ ]]; then
    create_symlinks "$DOTFILES_DIR"
  else
    info "Skipping symlinks"
  fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
header "Setup complete! 🎉"
echo ""
echo -e "  ${GREEN}Next steps:${RESET}"
echo "  1. Open a new terminal (or run: source ~/.zshrc)"
echo "  2. Check git config: git config --list"
echo "  3. Run 'p10k configure' to customize your prompt"
echo "  4. Update git/gitconfig with your name and email"
echo ""
