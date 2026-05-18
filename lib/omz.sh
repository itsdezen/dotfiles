#!/usr/bin/env bash
# lib/omz.sh — Install and setup Oh My Zsh (with Starship prompt)

install_oh_my_zsh() {
  local ZSH_DIR="$HOME/.oh-my-zsh"

  if [[ -d "$ZSH_DIR" ]]; then
    success "Oh My Zsh already installed"
    return 0
  fi

  info "Installing Oh My Zsh..."

  # Install Oh My Zsh without running zsh at the end
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  if [[ -d "$ZSH_DIR" ]]; then
    success "Oh My Zsh installed"
  else
    error "Failed to install Oh My Zsh"
    return 1
  fi
}


install_zsh_plugins() {
  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # zsh-autosuggestions
  local AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  if [[ ! -d "$AUTOSUGGESTIONS_DIR" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR"
    success "zsh-autosuggestions installed"
  else
    success "zsh-autosuggestions already installed"
  fi

  # zsh-syntax-highlighting
  local HIGHLIGHTING_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  if [[ ! -d "$HIGHLIGHTING_DIR" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HIGHLIGHTING_DIR"
    success "zsh-syntax-highlighting installed"
  else
    success "zsh-syntax-highlighting already installed"
  fi
}

setup_shell() {
  install_oh_my_zsh
  install_zsh_plugins
}
