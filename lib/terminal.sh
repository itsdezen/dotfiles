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

  # Backup current preferences
  if [[ -f ~/Library/Preferences/com.apple.Terminal.plist ]]; then
    local backup_file="$HOME/Library/Preferences/com.apple.Terminal.plist.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/Library/Preferences/com.apple.Terminal.plist "$backup_file" 2>/dev/null
    info "Backed up to: ${backup_file##*/}"
  fi

  # Convert profile to XML for processing
  local TEMP_PROFILE="/tmp/terminal_profile_$$.plist"
  plutil -convert xml1 "$PROFILE_FILE" -o "$TEMP_PROFILE" 2>/dev/null || {
    warn "Could not convert profile file"
    return 1
  }

  # Remove existing profile if present
  /usr/libexec/PlistBuddy -c "Delete :'Window Settings':'$PROFILE_NAME'" \
    ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null || true

  # Add new profile
  /usr/libexec/PlistBuddy -c "Add :'Window Settings':'$PROFILE_NAME' dict" \
    ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null || true

  # Merge profile data
  /usr/libexec/PlistBuddy -c "Merge '$TEMP_PROFILE' :'Window Settings':'$PROFILE_NAME'" \
    ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null || {
    warn "Could not merge profile, trying direct import..."
    # Fallback: use open command
    open "$PROFILE_FILE"
    sleep 2
  }

  # Clean up temp file
  rm -f "$TEMP_PROFILE"

  # Force set as default profile (regardless of current profile)
  defaults write com.apple.Terminal "Default Window Settings" -string "$PROFILE_NAME"
  defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE_NAME"

  # Reload Terminal preferences
  killall cfprefsd 2>/dev/null || true

  success "Terminal profile applied successfully!"
  info "Profile: $PROFILE_NAME"
  info "Font: Fantasque Sans Mono Nerd Font (14pt)"
  info "Restart Terminal.app to see changes"

  return 0
}

update_terminal_font() {
  local PROFILE_NAME="${1:-Clear Dark}"
  local FONT_NAME="Fantasque Sans Mono Nerd Font"
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
