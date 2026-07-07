# ~/.zprofile — loaded once on login shell startup
# Use for one-time environment setup that only login shells need

# Homebrew — must be here for login shells (before .zshrc runs)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
