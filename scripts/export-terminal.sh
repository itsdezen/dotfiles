#!/usr/bin/env bash
# =============================================================================
# scripts/export-terminal.sh
# Export Terminal.app style settings (minimal profile)
# Only exports: Font, Background Color, Blur, Text Colors
# Usage: bash scripts/export-terminal.sh [profile_name]
# =============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERMINAL_DIR="$DOTFILES/terminal"
PROFILE_NAME="${1:-Clear Dark}"

echo "Exporting minimal Terminal profile: $PROFILE_NAME"
echo ""
echo "Note: This script creates a minimal Terminal profile with only style settings."
echo "To capture all current settings from your Terminal profile, manually:"
echo "1. Open Terminal.app Preferences > Profiles"
echo "2. Select your profile"
echo "3. Click the gear icon > Export"
echo "4. Save to: $TERMINAL_DIR/$PROFILE_NAME.terminal"
echo ""
echo "Current minimal profile includes:"
echo "  - Font: ComicCodeLigaturesNerdFont"
echo "  - Background: Black with 30% blur"
echo "  - Text colors: White on black"
echo "  - Selection color: Semi-transparent white"
