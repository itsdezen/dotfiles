#!/usr/bin/env bash
# lib/zinit.sh — Install and setup zinit (modern, fast plugin manager)

install_zinit() {
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  if [[ -d "$ZINIT_HOME" ]]; then
    success "zinit already installed"
    return 0
  fi

  info "Installing zinit..."

  # Create zinit directory
  mkdir -p "$(dirname "$ZINIT_HOME")"

  # Clone zinit
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

  if [[ -d "$ZINIT_HOME" ]]; then
    success "zinit installed"
  else
    error "Failed to install zinit"
    return 1
  fi
}

cleanup_oh_my_zsh() {
  local OMZ_DIR="$HOME/.oh-my-zsh"

  if [[ ! -d "$OMZ_DIR" ]]; then
    info "No Oh My Zsh installation found, skipping cleanup"
    return 0
  fi

  warn "Found existing Oh My Zsh installation at $OMZ_DIR"
  read -r -p "  Remove Oh My Zsh? [y/N] " response

  if [[ "$response" =~ ^[Yy]$ ]]; then
    info "Backing up Oh My Zsh to $OMZ_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$OMZ_DIR" "$OMZ_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    success "Oh My Zsh backed up and removed"
  else
    info "Keeping Oh My Zsh (you can remove it manually later)"
  fi
}

setup_shell() {
  cleanup_oh_my_zsh
  install_zinit
}
