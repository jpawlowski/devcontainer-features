
# GitHub Codespace dotfiles (codespace-dotfiles)

Install your dotfiles repository into GitHub Codespaces from your `devcontainer.json`. This feature will not do anything outside of GitHub Codespaces and will leave the dotfile setup to the [VS Code builtin personalization option](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories).

## Example Usage

```json
"features": {
    "ghcr.io/jpawlowski/devcontainer-features/codespace-dotfiles:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| repository | URL of a dotfiles Git repository (e.g., https://github.com/owner/repository.git) or owner/repository of a GitHub repository. | string | - |
| targetPath | The path to clone the dotfiles repository to. Defaults to `~/dotfiles`. | string | - |
| installCommand | The command to run after cloning the dotfiles repository. Defaults to run the first file of `install.sh`, `install`, `bootstrap.sh`, `bootstrap`, `setup.sh` and `setup` found in the dotfiles repository's root folder. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jpawlowski/devcontainer-features/blob/main/src/codespace-dotfiles/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
