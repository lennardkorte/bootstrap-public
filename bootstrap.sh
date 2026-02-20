#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="lennardkorte/bootstrap"
HM_CONFIG_DIR="$HOME/.config/home-manager"
HM_FLAKE="$HM_CONFIG_DIR#default"

# --- 1. Nix ---
echo "=== 1. Installing Nix ==="
if ! command -v nix &> /dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "Nix already installed, skipping."
fi

# --- 2. Temporary gh ---
echo "=== 2. Installing gh (temporary) ==="
if ! command -v gh &> /dev/null; then
  nix profile install nixpkgs#gh
else
  echo "gh already installed, skipping."
fi

# --- 3. GitHub auth ---
echo "=== 3. GitHub authentication ==="
if ! gh auth status &> /dev/null; then
  gh auth login
else
  echo "Already authenticated with GitHub."
fi

# --- 4. Clone config ---
echo "=== 4. Cloning dotfiles ==="
if [ -d "$HM_CONFIG_DIR/.git" ]; then
  echo "Config exists, pulling latest..."
  git -C "$HM_CONFIG_DIR" pull
else
  [ -d "$HM_CONFIG_DIR" ] && mv "$HM_CONFIG_DIR" "${HM_CONFIG_DIR}.bak"
  gh repo clone "$DOTFILES_REPO" "$HM_CONFIG_DIR"
fi

# --- 5. User config ---
echo "=== 5. Setting up user config ==="
USER_NIX="$HM_CONFIG_DIR/user.nix"
if [ ! -f "$USER_NIX" ]; then
  read -rp "Full name (for git): " full_name
  read -rp "Email (for git): " email
  cat > "$USER_NIX" <<EOF
{
  name = "$full_name";
  email = "$email";
}
EOF
  echo "Created $USER_NIX"
else
  echo "user.nix already exists, skipping."
fi

# --- 6. Capture auth token before cleanup ---
echo "=== 6. Capturing GitHub auth token ==="
GH_TOKEN="$(gh auth token)"

# --- 7. Home Manager ---
echo "=== 7. Applying Home Manager config ==="
nix run home-manager/master -- switch --flake "$HM_FLAKE" --impure

# --- 8. Swap gh ---
echo "=== 8. Replacing temporary gh with managed one ==="
nix profile remove '.*gh.*' 2>/dev/null || true

HM_BIN="$HOME/.nix-profile/bin"
echo "$GH_TOKEN" | "$HM_BIN/gh" auth login --with-token
unset GH_TOKEN
echo "GitHub auth transferred."

# --- 9. Clone dev repos ---
echo "=== 9. Cloning dev repos ==="
"$HM_BIN/setup-repos"

echo "=== Done! Restart your shell or run: exec \$SHELL ==="
