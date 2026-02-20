# Dotfiles

Declarative system config with Nix + Home Manager.

## Setup

```bash
bash <(curl -sL https://raw.githubusercontent.com/lennardkorte/bootstrap-public/main/bootstrap.sh)
```

Installs Nix, authenticates with GitHub, clones the private config repo, and applies the config. Restart your shell when done.

## Usage

```bash
home-manager switch                # apply changes
nix flake update && home-manager switch  # update packages
git checkout flake.lock && home-manager switch  # rollback
```
