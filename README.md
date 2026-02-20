# Dotfiles

Declarative system config with [Nix](https://nixos.org/) + [Home Manager](https://github.com/nix-community/home-manager).

## Setup

```bash
bash <(curl -sL https://gist.githubusercontent.com/you/abc123/raw/bootstrap.sh)
```

Installs Nix, authenticates with GitHub, clones this repo, and applies the config. Restart your shell when done.

## Usage

```bash
home-manager switch                # apply changes
nix flake update && home-manager switch  # update packages
git checkout flake.lock && home-manager switch  # rollback
```
