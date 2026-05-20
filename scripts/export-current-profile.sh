#!/usr/bin/env bash
# =============================================================================
# scripts/export-current-profile.sh
# Export current Terminal.app profile to terminal/ directory
# Usage: bash scripts/export-current-profile.sh
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERMINAL_DIR="$DOTFILES_DIR/terminal"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${BLUE}Exporting Terminal.app profile...${RESET}"
echo ""

# Get current profile name
PROFILE_NAME=$(osascript -e 'tell application "Terminal" to get name of current settings of selected tab of front window' 2>/dev/null)

if [[ -z "$PROFILE_NAME" ]]; then
    echo -e "${YELLOW}Could not detect current profile. Using 'Clear Dark'${RESET}"
    PROFILE_NAME="Clear Dark"
fi

echo -e "Profile: ${GREEN}$PROFILE_NAME${RESET}"
echo ""

# Create terminal directory if not exists
mkdir -p "$TERMINAL_DIR"

# Output file
OUTPUT_FILE="$TERMINAL_DIR/$PROFILE_NAME.terminal"

# Backup existing file
if [[ -f "$OUTPUT_FILE" ]]; then
    BACKUP_FILE="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$OUTPUT_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✓${RESET} Backed up old profile to: ${BACKUP_FILE##*/}"
fi

# Export profile using defaults and plutil
TEMP_PLIST="/tmp/terminal_export_$$.plist"

# Read current Terminal preferences
if [[ -f ~/Library/Preferences/com.apple.Terminal.plist ]]; then
    # Extract the specific profile
    /usr/libexec/PlistBuddy -x -c "Print :'Window Settings':'$PROFILE_NAME'" \
        ~/Library/Preferences/com.apple.Terminal.plist > "$TEMP_PLIST" 2>/dev/null || {
        echo -e "${YELLOW}⚠${RESET} Could not extract profile from preferences"
        echo ""
        echo "Please export manually:"
        echo "1. Open Terminal.app Preferences (Cmd+,)"
        echo "2. Go to Profiles tab"
        echo "3. Select '$PROFILE_NAME'"
        echo "4. Click gear icon (⚙️) → Export"
        echo "5. Save to: $OUTPUT_FILE"
        rm -f "$TEMP_PLIST"
        exit 1
    }

    # Convert to binary plist format (Terminal profile format)
    plutil -convert binary1 "$TEMP_PLIST" -o "$OUTPUT_FILE"
    rm -f "$TEMP_PLIST"

    echo -e "${GREEN}✓${RESET} Profile exported successfully"
    echo ""
    echo "Output: $OUTPUT_FILE"
    echo ""

    # Show font info if possible
    if command -v plutil &>/dev/null; then
        echo "Profile details:"
        plutil -p "$OUTPUT_FILE" | grep -E "Font|name|ProfileCurrentVersion" | head -5 || true
    fi

else
    echo -e "${YELLOW}⚠${RESET} Terminal preferences not found"
    echo ""
    echo "Please export manually as described above."
    exit 1
fi

echo ""
echo -e "${GREEN}Done!${RESET} 🎉"
echo ""
echo "Next steps:"
echo "1. Commit the new profile:"
echo "   git add terminal/"
echo "   git commit -m 'feat: update Terminal profile with Monofur font'"
echo ""
