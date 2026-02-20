#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="you/dotfiles"
HM_CONFIG_DIR="$HOME/.config/home-manager"

echo "=== 1. Installing Nix ==="
if ! command -v nix &> /dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  # Source nix in current shell
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "Nix already installed, skipping."
fi

echo "=== 2. Installing gh (temporary, Home Manager will manage it later) ==="
if ! command -v gh &> /dev/null; then
  nix profile install nixpkgs#gh
else
  echo "gh already installed, skipping."
fi

echo "=== 3. GitHub authentication ==="
if ! gh auth status &> /dev/null; then
  gh auth login
else
  echo "Already authenticated with GitHub."
fi

echo "=== 4. Cloning dotfiles ==="
if [ -d "$HM_CONFIG_DIR" ] && [ -d "$HM_CONFIG_DIR/.git" ]; then
  echo "Config already exists at $HM_CONFIG_DIR, pulling latest..."
  git -C "$HM_CONFIG_DIR" pull
else
  # Back up any existing config
  if [ -d "$HM_CONFIG_DIR" ]; then
    echo "Backing up existing config to ${HM_CONFIG_DIR}.bak"
    mv "$HM_CONFIG_DIR" "${HM_CONFIG_DIR}.bak"
  fi
  gh repo clone "$DOTFILES_REPO" "$HM_CONFIG_DIR"
fi

echo "=== 5. Installing Home Manager and applying config ==="
nix run home-manager/master -- switch --flake "$HM_CONFIG_DIR"

echo "=== 6. Cleaning up temporary gh install ==="
# Home Manager now manages gh, so remove the imperative one
nix profile remove '.*gh.*' 2>/dev/null || true

echo "=== Done! Restart your shell or run: source ~/.bashrc ==="
