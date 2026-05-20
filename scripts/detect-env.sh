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

  # Check mise
  if command -v mise &>/dev/null; then
    success "mise installed: $(mise --version)"
    if mise which node &>/dev/null; then
      info "Current Node: $(node --version 2>/dev/null || echo 'none')"
      info "mise global: $(mise current node 2>/dev/null || echo 'none')"
    else
      warn "Node.js not installed via mise"
      info "Install with: mise install node@lts && mise use -g node@lts"
    fi
  else
    warn "mise not installed"
    info "Install with: brew install mise"
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

  # Check zinit
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  if [[ -d "$ZINIT_HOME" ]]; then
    success "zinit installed"

    # Check if plugins are managed by zinit
    local ZINIT_PLUGINS="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/plugins"
    if [[ -d "$ZINIT_PLUGINS" ]]; then
      local plugin_count=$(find "$ZINIT_PLUGINS" -maxdepth 1 -type d | wc -l)
      info "zinit plugins: $((plugin_count - 1))"
    fi
  else
    warn "zinit not installed"
    info "Install with: ./install.sh (select zinit option)"
  fi

  # Check Starship
  if command -v starship &>/dev/null; then
    success "Starship installed: $(starship --version | head -1)"
  else
    warn "Starship not installed"
    info "Install with: brew install starship"
  fi
}

detect_dotfiles() {
  header "Dotfiles Symlinks"

  local files=(
    ".zshrc:$HOME/.zshrc"
    ".zshenv:$HOME/.zshenv"
    ".zprofile:$HOME/.zprofile"
    ".gitconfig:$HOME/.gitconfig"
    ".gitignore_global:$HOME/.gitignore_global"
    "starship.toml:$HOME/.config/starship/starship.toml"
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

  local font_file="$HOME/Library/Fonts/MapleMonoNF-Regular.ttf"

  if [[ -f "$font_file" ]]; then
    success "Maple Mono NF installed"
  else
    warn "Maple Mono NF not found"
    info "Install with: brew install --cask font-maple-mono-nf"
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
