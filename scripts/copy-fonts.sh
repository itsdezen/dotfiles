#!/usr/bin/env bash
# =============================================================================
# scripts/copy-fonts.sh
# Copy Comic Code Ligatures fonts from system to dotfiles
# Usage: bash scripts/copy-fonts.sh
# =============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_DIR="$HOME/Library/Fonts"
DOTFILES_FONT_DIR="$DOTFILES/fonts"

echo "Looking for Comic Code Ligatures fonts..."

if ! ls "$FONT_DIR"/*Comic*Code* &>/dev/null; then
  echo "✗ No Comic Code fonts found in $FONT_DIR"
  echo ""
  echo "Install fonts first, then run this script again."
  exit 1
fi

echo "Found fonts:"
ls -1 "$FONT_DIR"/*Comic*Code* | while read -r font; do
  echo "  $(basename "$font")"
done

echo ""
read -r -p "Copy these fonts to dotfiles? [Y/n] " response

if [[ "$response" =~ ^[Nn]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# Create fonts directory
mkdir -p "$DOTFILES_FONT_DIR"

# Copy fonts
echo "Copying fonts..."
cp "$FONT_DIR"/*Comic*Code*.{ttf,otf} "$DOTFILES_FONT_DIR/" 2>/dev/null || true

if ls "$DOTFILES_FONT_DIR"/*Comic*Code* &>/dev/null; then
  echo "✓ Fonts copied to: $DOTFILES_FONT_DIR"
  echo ""
  echo "Copied files:"
  ls -1 "$DOTFILES_FONT_DIR" | sed 's/^/  /'
  echo ""
  echo "Note: Font files can be large. Consider adding to .gitignore:"
  echo "  echo 'fonts/*.ttf' >> .gitignore"
  echo "  echo 'fonts/*.otf' >> .gitignore"
else
  echo "✗ Failed to copy fonts"
  exit 1
fi
