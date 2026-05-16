#!/usr/bin/env bash
# =============================================================================
# scripts/dump-brew.sh
# Export current Homebrew packages to Brewfile
# Usage: bash scripts/dump-brew.sh
# =============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew is not installed!"
  exit 1
fi

echo "Exporting Brewfile from current system..."
brew bundle dump --file="$DOTFILES/Brewfile" --force

echo "✓ Done! Review: $DOTFILES/Brewfile"
echo ""
echo "Note: You may want to manually edit the Brewfile to keep only"
echo "      the essential packages (nvm, mole) for your dotfiles setup."
