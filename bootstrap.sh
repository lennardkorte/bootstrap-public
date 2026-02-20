#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="git@github.com:lennardkorte/bootstrap.git"
HM_CONFIG_DIR="$HOME/.config/home-manager"
HM_FLAKE="$HM_CONFIG_DIR#default"

# --- 1. Nix ---
echo "v2"
echo "=== 1. Installing Nix ==="
if ! command -v nix &> /dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "Nix already installed, skipping."
fi

# --- 2. Enable flakes ---
echo "=== 2. Enabling Nix experimental features ==="
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF="$NIX_CONF_DIR/nix.conf"
if ! grep -q 'experimental-features' "$NIX_CONF" 2>/dev/null; then
  mkdir -p "$NIX_CONF_DIR"
  echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
  echo "Enabled nix-command and flakes."
else
  echo "Experimental features already enabled, skipping."
fi

# --- 3. SSH key ---
echo "=== 3. Setting up SSH key ==="
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
  echo "Generated new SSH key."
else
  echo "SSH key already exists, skipping."
fi

# --- 4. GitHub SSH access ---
echo "=== 4. Setting up GitHub SSH access ==="
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "SSH access already working, skipping."
else
  echo "Create a token at: https://github.com/settings/tokens/new"
  echo "Required scope: admin:public_key"
  read -rsp "Paste GitHub token (hidden): " gh_token
  echo ""

  KEY_TITLE="bootstrap-$(hostname)-$(date +%Y%m%d)"
  PUB_KEY="$(cat "${SSH_KEY}.pub")"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://api.github.com/user/keys" \
    -H "Authorization: token $gh_token" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$KEY_TITLE\",\"key\":\"$PUB_KEY\"}")

  unset gh_token

  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "422" ]; then
    # 201 = created, 422 = key already exists on GitHub
    echo "SSH key registered with GitHub."
  else
    echo "Error: Failed to upload SSH key (HTTP $HTTP_CODE)."
    exit 1
  fi

  # Wait for GitHub to propagate
  sleep 2
  if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "Error: SSH auth still failing."
    exit 1
  fi
fi

# --- 4. Clone config ---
echo "=== 4. Cloning dotfiles ==="
if [ -d "$HM_CONFIG_DIR/.git" ]; then
  echo "Config exists, pulling latest..."
  git -C "$HM_CONFIG_DIR" pull
else
  [ -d "$HM_CONFIG_DIR" ] && mv "$HM_CONFIG_DIR" "${HM_CONFIG_DIR}.bak"
  git clone "$DOTFILES_REPO" "$HM_CONFIG_DIR"
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

# --- 6. Home Manager ---
echo "=== 6. Applying Home Manager config ==="
nix run home-manager/master -- switch --flake "$HM_FLAKE" --impure

# --- 7. Clone dev repos ---
echo "=== 7. Cloning dev repos ==="
"$HOME/.nix-profile/bin/setup-repos"

echo "=== Done! Restart your shell or run: exec \$SHELL ==="
