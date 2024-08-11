
# GitHub Codespace dotfiles (codespaces-dotfiles)

Install your dotfiles repository into GitHub Codespaces from your `devcontainer.json`. This feature will not do anything outside of GitHub Codespaces and will leave the dotfile setup to the [VS Code builtin personalization option](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories).

## Example Usage

```json
"features": {
    "ghcr.io/jpawlowski/devcontainer-features/codespaces-dotfiles:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| repository | URL of a dotfiles Git repository (e.g., https://github.com/owner/repository.git) or owner/repository of a GitHub repository. | string | - |
| targetPath | The path to clone the dotfiles repository to. Defaults to `~/dotfiles`. | string | - |
| installCommand | The command to run after cloning the dotfiles repository. Defaults to run the first file of `install.sh`, `install`, `bootstrap.sh`, `bootstrap`, `setup.sh` and `setup` found in the dotfiles repository's root folder. If none of these files are found, then the `installFallbackMethod` will be used. | string | - |
| installFallbackMethod | The method to use if no install command is found. Defaults to `symlink`. This will symlink or copy any files or folders in your dotfiles repository starting with . to the codespace's ~ or $HOME directory. | string | symlink |

## How does it work?

This feature installs a `postStartCommand` element that will install your dotfiles during the first start of your Codespace.
It will only install in case no dotfiles were installed already as configured in the GitHub users' Codespaces profile settings.

Note that when using Codespaces prebuilds, this feature will only prepare the `postStartCommand`, but the actual dotfile
cloning and installation will happen during the first start of the users' Codespace.

## Installing in Codespaces and Dev Containers

When this feature is installed on Dev Containers instead of GitHub Codespaces, no dotfiles will be installed. That means
it will be harmless to such containers and will leave the dotfile setup to the
[native `dotfiles.repository` configuration setting](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories).

This allows to use the same `devcontainer.json` file for GitHub Codespaces and Dev Containers with both definitions in parallel.
For Dev Containers, the native dotfile setup will be used, for GitHub Codespaces, this feature will install dotfiles unless
the user has defined them in the GitHub profile settings.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jpawlowski/devcontainer-features/blob/main/src/codespaces-dotfiles/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
