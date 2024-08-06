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
