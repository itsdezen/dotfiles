# ~/.zshenv — loaded first, in every shell context (interactive, non-interactive, scripts)
# Only set variables that must be available in ALL contexts

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Homebrew: always update to the latest stable tag, never the beta `main` branch
# (overrides the "developer mode" that dev commands like `brew trust` turn on)
export HOMEBREW_UPDATE_TO_TAG=1
