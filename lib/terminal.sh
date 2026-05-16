#!/usr/bin/env bash
# lib/terminal.sh — Configure Terminal.app with custom profile

setup_terminal_profile() {
  local TERMINAL_DIR="$DOTFILES_DIR/terminal"
  local PROFILE_NAME="Clear Dark"
  local PROFILE_FILE="$TERMINAL_DIR/$PROFILE_NAME.terminal"

  info "Configuring Terminal.app profile..."

  # Check if profile file exists
  if [[ ! -f "$PROFILE_FILE" ]]; then
    warn "Terminal profile not found: $PROFILE_FILE"
    info "Run: bash scripts/export-terminal.sh"
    return 1
  fi

  # Import the profile
  info "Importing profile: $PROFILE_NAME"
  open "$PROFILE_FILE"

  # Wait a moment for Terminal to process
  sleep 2

  # Set as default profile
  defaults write com.apple.Terminal "Default Window Settings" -string "$PROFILE_NAME"
  defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE_NAME"

  success "Terminal profile configured"
  info "Profile: $PROFILE_NAME"
  info "Restart Terminal.app to see changes"

  return 0
}

update_terminal_font() {
  local PROFILE_NAME="${1:-Clear Dark}"
  local FONT_NAME="ComicCodeLigatures Nerd Font"
  local FONT_SIZE="14"

  info "Updating Terminal font to: $FONT_NAME $FONT_SIZE"

  # Create font data (NSFont archived object)
  # This is complex, so we'll use a simpler approach: modify plist directly

  # Note: This requires Terminal.app to be closed
  if pgrep -x "Terminal" > /dev/null; then
    warn "Terminal.app is running. Close it first to update font."
    return 1
  fi

  # Backup current settings
  cp ~/Library/Preferences/com.apple.Terminal.plist \
     ~/Library/Preferences/com.apple.Terminal.plist.backup 2>/dev/null || true

  # Use PlistBuddy to update font
  /usr/libexec/PlistBuddy -c "Set :'Window Settings':'$PROFILE_NAME':Font:name '$FONT_NAME'" \
    ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null || {
    warn "Could not update font automatically"
    info "Please set font manually in Terminal preferences"
    return 1
  }

  success "Font updated. Restart Terminal.app"
  return 0
}

export_current_terminal() {
  local PROFILE_NAME="${1:-Clear Dark}"

  info "Exporting Terminal profile: $PROFILE_NAME"
  bash "$DOTFILES_DIR/scripts/export-terminal.sh" "$PROFILE_NAME"
}
