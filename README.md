# Bootstrap

Declarative system config with Nix + Home Manager.

## Setup

```bash
bash <(curl -sL https://raw.githubusercontent.com/lennardkorte/bootstrap-public/main/bootstrap.sh)
```

Installs Nix, authenticates with GitHub, clones the private config repo, applies the config, and clones all dev repos via ghq. Restart your shell when done.

## Usage

```bash
home-manager switch --flake ~/.config/home-manager#default --impure  # apply changes
setup-repos                                                          # re-clone any missing repos
nix flake update --flake ~/.config/home-manager && home-manager switch --flake ~/.config/home-manager#default --impure  # update packages
```
