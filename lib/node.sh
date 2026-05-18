#!/usr/bin/env bash
# lib/node.sh — Install Node.js via mise + pnpm + bun

install_node() {
  # mise should already be installed via Brewfile
  if ! command -v mise &>/dev/null; then
    error "mise not found. Please install: brew install mise"
    return 1
  fi

  # Get default Node version from .node-version or use LTS
  local node_version
  if [[ -f "$DOTFILES_DIR/.node-version" ]]; then
    node_version="$(cat "$DOTFILES_DIR/.node-version" | tr -d '[:space:]')"
  else
    node_version="lts"
  fi

  # Install Node.js via mise
  info "Installing Node.js $node_version via mise..."
  mise install "node@$node_version"
  mise use -g "node@$node_version"

  # Activate mise for current session
  eval "$(mise activate bash)"

  if command -v node &>/dev/null; then
    success "Node.js $(node --version) is ready"
  else
    error "Node.js installation failed. Please check mise configuration."
    return 1
  fi

  # Install global npm packages
  if [[ -f "$DOTFILES_DIR/npm-globals.txt" ]]; then
    info "Installing global npm packages..."
    while IFS= read -r package || [[ -n "$package" ]]; do
      [[ "$package" =~ ^#.*$ || -z "$package" ]] && continue
      npm install -g "$package" --silent
      info "  + $package"
    done < "$DOTFILES_DIR/npm-globals.txt"
    success "npm globals installed"
  fi
}

install_pnpm() {
  if command -v pnpm &>/dev/null; then
    success "pnpm already installed ($(pnpm --version))"
    return 0
  fi

  info "Installing pnpm..."
  if command -v npm &>/dev/null; then
    npm install -g pnpm --silent
    success "pnpm $(pnpm --version) installed"
  else
    warn "npm not available, skipping pnpm installation"
    return 1
  fi
}

install_bun() {
  if command -v bun &>/dev/null; then
    success "bun already installed ($(bun --version))"
    return 0
  fi

  info "Installing bun..."
  curl -fsSL https://bun.sh/install | bash

  # Add bun to PATH for current session
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  if command -v bun &>/dev/null; then
    success "bun $(bun --version) installed"
  else
    warn "bun installation may require a new shell session"
  fi
}
