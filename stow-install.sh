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
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

# Backup existing file/directory
backup_existing() {
  local file="$1"

  # Skip if it's already a symlink (Stow will handle it)
  if [[ -L "$file" ]]; then
    return 0
  fi

  # Backup if it's a real file or directory
  if [[ -e "$file" ]]; then
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$(basename "$file")"
    info "Backing up existing file: $file → $backup_path"
    mv "$file" "$backup_path"
  fi
}

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
    error "Package not found: $package"
    return 1
  fi

  info "Stowing $package..."
  cd "$SCRIPT_DIR"

  # Check if already stowed (idempotency)
  local test_file
  test_file=$(find "$package" -type f -not -path '*/\.*' | head -1)
  if [[ -n "$test_file" ]]; then
    local target_file="${HOME}/${test_file#$package/}"
    if [[ -L "$target_file" ]]; then
      info "$package already stowed, restowing..."
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would restow: $package"
        return 0
      fi
      if ! stow -t "$HOME" -R -v "$package" 2>&1; then
        error "$package restow failed"
        return 1
      fi
      success "$package reinstalled"
      return 0
    fi
  fi

  # Backup conflicting files before fresh install
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local target="${HOME}/${file#$package/}"
    if [[ "$DRY_RUN" == "true" ]]; then
      if [[ -e "$target" && ! -L "$target" ]]; then
        echo "[DRY-RUN] Would backup: $target"
      fi
    else
      backup_existing "$target"
    fi
  done < <(find "$package" -type f -not -path '*/\.*')

  # Fresh install
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would stow: $package"
    stow -n -t "$HOME" -v "$package" 2>&1
    return 0
  fi

  if ! stow -t "$HOME" -v "$package" 2>&1; then
    error "$package installation failed"
    if [[ -d "$BACKUP_DIR" ]]; then
      warn "Backups are available in: $BACKUP_DIR"
    fi
    return 1
  fi
  success "$package installed"

  # Show backup info if backups were created
  if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    info "Backed up files to: $BACKUP_DIR"
  fi
}

# Restow a package (useful for updates)
restow_package() {
  local package="$1"

  if [[ ! -d "$SCRIPT_DIR/$package" ]]; then
    error "Package not found: $package"
    return 1
  fi

  info "Restowing $package..."
  cd "$SCRIPT_DIR"

  if ! stow -t "$HOME" -R -v "$package" 2>&1; then
    error "$package restow failed"
    return 1
  fi
  success "$package reinstalled"
}

# Remove a package
remove_package() {
  local package="$1"

  if [[ ! -d "$SCRIPT_DIR/$package" ]]; then
    warn "Package not found: $package (skipping)"
    return 0
  fi

  info "Removing $package..."
  cd "$SCRIPT_DIR"

  if ! stow -t "$HOME" -D -v "$package" 2>&1; then
    warn "$package removal failed (may not be stowed)"
    return 0  # Not critical if removal fails
  fi
  success "$package removed"
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
  # Parse flags
  local command=""
  for arg in "$@"; do
    case "$arg" in
      --dry-run|-n)
        DRY_RUN=true
        info "Dry-run mode enabled (no changes will be made)"
        ;;
      *)
        command="$arg"
        ;;
    esac
  done

  check_stow

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  GNU Stow Dotfiles Installer"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  case "${command:-}" in
    install|"")
      list_packages
      info "Stowing all packages..."
      stow_package "zsh" || exit 1
      stow_package "nvim" || exit 1
      stow_package "aerospace" || exit 1
      stow_package "starship" || exit 1
      stow_package "zed" || exit 1
      ;;

    restow|update)
      info "Restowing all packages..."
      restow_package "zsh" || exit 1
      restow_package "nvim" || exit 1
      restow_package "aerospace" || exit 1
      restow_package "starship" || exit 1
      restow_package "zed" || exit 1
      ;;

    remove|uninstall)
      info "Removing all packages..."
      remove_package "zsh"  # Don't exit on removal failure
      remove_package "nvim"
      remove_package "aerospace"
      remove_package "starship"
      remove_package "zed"
      ;;

    list)
      list_packages
      ;;

    *)
      echo "Usage: $0 [install|restow|remove|list] [--dry-run]"
      echo ""
      echo "Commands:"
      echo "  install   - Install all dotfiles (default)"
      echo "  restow    - Reinstall all dotfiles (update symlinks)"
      echo "  remove    - Remove all dotfiles"
      echo "  list      - List available packages"
      echo ""
      echo "Flags:"
      echo "  --dry-run, -n  - Preview changes without applying them"
      echo ""
      echo "Examples:"
      echo "  $0              # Install all"
      echo "  $0 --dry-run    # Preview installation"
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
