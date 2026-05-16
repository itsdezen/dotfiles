#!/usr/bin/env bash
# =============================================================================
# scripts/detect-env.sh
# Detect current environment and suggest updates to dotfiles
# Usage: bash scripts/detect-env.sh
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}[detect]${RESET} $*"; }
success() { echo -e "${GREEN}[detect] ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}[detect] ⚠${RESET} $*"; }
header()  { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}"; }

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

detect_homebrew() {
  header "Homebrew Packages"

  if ! command -v brew &>/dev/null; then
    warn "Homebrew not installed"
    return
  fi

  success "Homebrew installed: $(brew --version | head -1)"

  # Check for packages in Brewfile
  info "Checking packages from Brewfile..."

  local missing_packages=()
  local installed_packages=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^brew[[:space:]]\"([^\"]+)\" ]]; then
      local package="${BASH_REMATCH[1]}"
      if brew list "$package" &>/dev/null; then
        installed_packages+=("$package")
      else
        missing_packages+=("$package")
      fi
    fi
  done < "$DOTFILES_DIR/Brewfile"

  if [[ ${#installed_packages[@]} -gt 0 ]]; then
    info "Installed: ${installed_packages[*]}"
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    warn "Missing: ${missing_packages[*]}"
    info "Run: brew bundle --file=$DOTFILES_DIR/Brewfile"
  else
    success "All Brewfile packages are installed"
  fi
}

detect_node() {
  header "Node.js Environment"

  # Check nvm
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    success "nvm installed"
    source "$NVM_DIR/nvm.sh"
    info "Current Node: $(node --version 2>/dev/null || echo 'none')"
    info "Default Node: $(nvm version default 2>/dev/null || echo 'none')"
  elif [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    success "nvm installed (via Homebrew)"
    source "/opt/homebrew/opt/nvm/nvm.sh"
    info "Current Node: $(node --version 2>/dev/null || echo 'none')"
  else
    warn "nvm not installed"
  fi

  # Check pnpm
  if command -v pnpm &>/dev/null; then
    success "pnpm installed: $(pnpm --version)"
  else
    warn "pnpm not installed"
    info "Install with: npm install -g pnpm"
  fi

  # Check bun
  if command -v bun &>/dev/null; then
    success "bun installed: $(bun --version)"
  else
    warn "bun not installed"
    info "Install with: curl -fsSL https://bun.sh/install | bash"
  fi
}

detect_shell() {
  header "Shell Configuration"

  # Check Oh My Zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success "Oh My Zsh installed"
  else
    warn "Oh My Zsh not installed"
  fi

  # Check Powerlevel10k
  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$P10K_DIR" ]]; then
    success "Powerlevel10k installed"
  else
    warn "Powerlevel10k not installed"
  fi

  # Check zsh plugins
  local PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  if [[ -d "$PLUGIN_DIR/zsh-autosuggestions" ]]; then
    success "zsh-autosuggestions installed"
  else
    warn "zsh-autosuggestions not installed"
  fi

  if [[ -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
    success "zsh-syntax-highlighting installed"
  else
    warn "zsh-syntax-highlighting not installed"
  fi

  # Check starship (optional)
  if command -v starship &>/dev/null; then
    info "starship installed: $(starship --version | head -1)"
  else
    info "starship not installed (optional)"
  fi
}

detect_dotfiles() {
  header "Dotfiles Symlinks"

  local files=(
    ".zshrc:$HOME/.zshrc"
    ".zshenv:$HOME/.zshenv"
    ".zprofile:$HOME/.zprofile"
    ".p10k.zsh:$HOME/.p10k.zsh"
    ".gitconfig:$HOME/.gitconfig"
    ".gitignore_global:$HOME/.gitignore_global"
  )

  for file_pair in "${files[@]}"; do
    local name="${file_pair%%:*}"
    local path="${file_pair##*:}"

    if [[ -L "$path" ]]; then
      local target="$(readlink "$path")"
      if [[ "$target" == *"dotfiles"* ]]; then
        success "$name → symlinked to dotfiles"
      else
        warn "$name → symlinked but not to dotfiles"
      fi
    elif [[ -f "$path" ]]; then
      warn "$name exists but not symlinked"
    else
      info "$name not found"
    fi
  done
}

detect_fonts() {
  header "Fonts"

  local font_dir="$HOME/Library/Fonts"

  if ls "$font_dir"/*Comic*Code* &>/dev/null; then
    success "Comic Code Ligatures fonts found in ~/Library/Fonts"
  else
    warn "Comic Code Ligatures fonts not found"
    info "Install manually to: ~/Library/Fonts/"
  fi
}

# =============================================================================
# MAIN
# =============================================================================

header "Environment Detection"
info "Scanning current system configuration..."
echo ""

detect_homebrew
detect_node
detect_shell
detect_dotfiles
detect_fonts

echo ""
header "Detection Complete"
info "Review the output above to identify missing components"
info "Run './install.sh' to install missing components"
echo ""
