#!/usr/bin/env bash
# lib/fonts.sh — Install Comic Code Ligatures fonts

install_fonts() {
  local FONT_DIR="$HOME/Library/Fonts"
  local DOTFILES_FONT_DIR="$DOTFILES_DIR/fonts"

  # Check if fonts directory exists
  if [[ ! -d "$DOTFILES_FONT_DIR" ]]; then
    warn "Fonts directory not found: $DOTFILES_FONT_DIR"
    return 1
  fi

  # Count fonts
  local total_fonts=0
  local new_fonts=0
  local existing_fonts=0

  # Find all font files
  local font_list
  font_list=$(find "$DOTFILES_FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null)

  while IFS= read -r font_file; do
    [[ -z "$font_file" ]] && continue
    ((total_fonts++))
    local font_name
    font_name=$(basename "$font_file")
    if [[ -f "$FONT_DIR/$font_name" ]]; then
      ((existing_fonts++))
    fi
  done <<< "$font_list"

  # All fonts already installed
  if [[ $existing_fonts -eq $total_fonts ]]; then
    success "All fonts already installed ($total_fonts fonts)"
    return 0
  fi

  # Install missing fonts
  info "Installing Comic Code Ligatures fonts..."
  info "Found: $total_fonts fonts, Already installed: $existing_fonts"

  while IFS= read -r font_file; do
    [[ -z "$font_file" ]] && continue
    local font_name
    font_name=$(basename "$font_file")

    # Skip if already installed
    if [[ -f "$FONT_DIR/$font_name" ]]; then
      continue
    fi

    # Copy font
    if cp "$font_file" "$FONT_DIR/" 2>/dev/null; then
      info "  + $font_name"
      ((new_fonts++))
    fi
  done <<< "$font_list"

  if [[ $new_fonts -gt 0 ]]; then
    success "$new_fonts new fonts installed"

    # Try to clear font cache (optional, no sudo prompt if fails)
    if sudo -n atsutil databases -remove 2>/dev/null; then
      info "Font cache cleared"
    else
      info "Font cache will update automatically (restart or re-login if needed)"
    fi

    return 0
  else
    warn "No fonts were installed"
    return 1
  fi
}

detect_fonts() {
  local FONT_DIR="$HOME/Library/Fonts"

  echo "Installed Comic Code fonts:"
  if ls "$FONT_DIR"/*Comic*Code* &>/dev/null; then
    ls -1 "$FONT_DIR"/*Comic*Code* | while read -r font; do
      echo "  ✓ $(basename "$font")"
    done
  else
    echo "  ⚠ No Comic Code fonts found"
  fi
}

copy_fonts_to_dotfiles() {
  local FONT_DIR="$HOME/Library/Fonts"
  local DOTFILES_FONT_DIR="$DOTFILES_DIR/fonts"

  if ! ls "$FONT_DIR"/*Comic*Code* &>/dev/null; then
    error "No Comic Code fonts found in $FONT_DIR"
    return 1
  fi

  info "Copying Comic Code fonts to dotfiles..."
  mkdir -p "$DOTFILES_FONT_DIR"
  cp "$FONT_DIR"/*Comic*Code*.{ttf,otf} "$DOTFILES_FONT_DIR/" 2>/dev/null || true

  if ls "$DOTFILES_FONT_DIR"/*Comic*Code* &>/dev/null; then
    success "Fonts copied to: $DOTFILES_FONT_DIR"
    echo ""
    echo "Add to .gitignore if fonts are large:"
    echo "  echo 'fonts/' >> .gitignore"
    return 0
  else
    error "Failed to copy fonts"
    return 1
  fi
}
