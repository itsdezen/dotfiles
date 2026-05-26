#!/usr/bin/env bash
# stow-install.sh — Install dotfiles using GNU Stow

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if stow is installed
check_stow() {
  if ! command -v stow &>/dev/null; then
    error "GNU Stow is not installed"
    info "Install with: brew install stow"
    exit 1
  fi
}

# Stow a package
stow_package() {
  local package="$1"

  if [[ ! -d "$SCRIPT_DIR/$package" ]]; then
    warn "Package not found: $package"
    return 1
  fi

  info "Stowing $package..."
  cd "$SCRIPT_DIR"

  if stow -v "$package" 2>&1; then
    success "$package installed"
  else
    warn "$package may have conflicts (use --adopt to merge or -D to remove first)"
  fi
}

# Restow a package (useful for updates)
restow_package() {
  local package="$1"

  info "Restowing $package..."
  cd "$SCRIPT_DIR"

  if stow -R -v "$package" 2>&1; then
    success "$package reinstalled"
  else
    warn "$package restow failed"
  fi
}

# Remove a package
remove_package() {
  local package="$1"

  info "Removing $package..."
  cd "$SCRIPT_DIR"

  if stow -D -v "$package" 2>&1; then
    success "$package removed"
  else
    warn "$package removal failed"
  fi
}

# List available packages
list_packages() {
  echo ""
  echo "Available packages:"
  for dir in "$SCRIPT_DIR"/*/; do
    if [[ -d "$dir" && ! "$dir" =~ (\..*)|(scripts)|(lib)|(zsh-old)|(config)$ ]]; then
      basename "$dir"
    fi
  done
  echo ""
}

# Main
main() {
  check_stow

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  GNU Stow Dotfiles Installer"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  case "${1:-}" in
    install|"")
      list_packages
      info "Stowing all packages..."
      stow_package "zsh"
      stow_package "git"
      stow_package "nvim"
      stow_package "aerospace"
      stow_package "starship"
      ;;

    restow|update)
      info "Restowing all packages..."
      restow_package "zsh"
      restow_package "git"
      restow_package "nvim"
      restow_package "aerospace"
      restow_package "starship"
      ;;

    remove|uninstall)
      info "Removing all packages..."
      remove_package "zsh"
      remove_package "git"
      remove_package "nvim"
      remove_package "aerospace"
      remove_package "starship"
      ;;

    list)
      list_packages
      ;;

    *)
      echo "Usage: $0 [install|restow|remove|list]"
      echo ""
      echo "Commands:"
      echo "  install   - Install all dotfiles (default)"
      echo "  restow    - Reinstall all dotfiles (update symlinks)"
      echo "  remove    - Remove all dotfiles"
      echo "  list      - List available packages"
      echo ""
      echo "Examples:"
      echo "  $0              # Install all"
      echo "  $0 restow       # Update symlinks"
      echo "  stow zsh        # Install only zsh"
      echo "  stow -D nvim    # Remove only nvim"
      exit 1
      ;;
  esac

  echo ""
  success "Done!"
}

main "$@"
