# Bootstrap

Declarative system config with Nix + Home Manager.

## Setup

```bash
bash <(curl -sL https://raw.githubusercontent.com/lennardkorte/bootstrap-public/main/bootstrap.sh)
```

Installs Nix, authenticates with GitHub, clones the private config repo, applies the config, and clones all dev repos via ghq. Restart your shell when done.
