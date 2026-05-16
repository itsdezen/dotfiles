#!/usr/bin/env bash
# =============================================================================
# scripts/export-terminal.sh
# Export current Terminal.app profile settings
# Usage: bash scripts/export-terminal.sh [profile_name]
# =============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERMINAL_DIR="$DOTFILES/terminal"
PROFILE_NAME="${1:-Clear Dark}"

echo "Exporting Terminal profile: $PROFILE_NAME"

# Create terminal directory
mkdir -p "$TERMINAL_DIR"

# Export the profile
plutil -convert xml1 -o - ~/Library/Preferences/com.apple.Terminal.plist | \
  xmllint --xpath "//key[text()='Window Settings']/following-sibling::dict[1]/key[text()='$PROFILE_NAME']/following-sibling::dict[1]" - \
  > "$TERMINAL_DIR/$PROFILE_NAME.xml" 2>/dev/null || {
    echo "✗ Failed to export profile: $PROFILE_NAME"
    echo ""
    echo "Available profiles:"
    plutil -convert xml1 -o - ~/Library/Preferences/com.apple.Terminal.plist | \
      xmllint --xpath "//key[text()='Window Settings']/following-sibling::dict[1]/key/text()" - 2>/dev/null || echo "  (none found)"
    exit 1
  }

# Add XML header
cat > "$TERMINAL_DIR/$PROFILE_NAME.terminal" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOF

# Add the profile content
cat "$TERMINAL_DIR/$PROFILE_NAME.xml" >> "$TERMINAL_DIR/$PROFILE_NAME.terminal"

# Close the plist
echo "</dict>" >> "$TERMINAL_DIR/$PROFILE_NAME.terminal"
echo "</plist>" >> "$TERMINAL_DIR/$PROFILE_NAME.terminal"

# Clean up temp file
rm "$TERMINAL_DIR/$PROFILE_NAME.xml"

echo "✓ Exported to: $TERMINAL_DIR/$PROFILE_NAME.terminal"
echo ""
echo "Settings included:"
echo "  - Font and size"
echo "  - Background color and blur"
echo "  - ANSI colors"
echo "  - Window size"
echo "  - Cursor style"
