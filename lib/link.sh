#!/usr/bin/env bash
# lib/link.sh — Create symlinks from dotfiles to $HOME

link_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  # Backup existing file if it's not a symlink
  if [[ -f "$dst" && ! -L "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d_%H%M%S)"
    warn "Backup: $dst → $backup"
    mv "$dst" "$backup"
  fi

  [[ -L "$dst" ]] && rm "$dst"
  ln -s "$src" "$dst"
  success "Linked: $(basename "$dst")"
}

create_symlinks() {
  local dotfiles_dir="$1"

  # zsh
  link_file "$dotfiles_dir/zsh/zshrc"    "$HOME/.zshrc"
  link_file "$dotfiles_dir/zsh/zshenv"   "$HOME/.zshenv"
  link_file "$dotfiles_dir/zsh/zprofile" "$HOME/.zprofile"

  # p10k
  if [[ -f "$dotfiles_dir/zsh/p10k.zsh" ]]; then
    link_file "$dotfiles_dir/zsh/p10k.zsh" "$HOME/.p10k.zsh"
  fi

  # git
  link_file "$dotfiles_dir/git/gitconfig"        "$HOME/.gitconfig"
  link_file "$dotfiles_dir/git/gitignore_global" "$HOME/.gitignore_global"

  # starship (optional)
  if [[ -f "$dotfiles_dir/config/starship/starship.toml" ]]; then
    link_file "$dotfiles_dir/config/starship/starship.toml" \
              "$HOME/.config/starship.toml"
  fi
}
