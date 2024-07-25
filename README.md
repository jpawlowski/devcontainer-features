# Julian's Development Container Features

<table style="width: 100%; border-style: none;"><tr>
    <td style="width: 140px; text-align: center;"><a href="https://github.com/devcontainers"><img width="128px" src="https://raw.githubusercontent.com/microsoft/fluentui-system-icons/78c9587b995299d5bfc007a0077773556ecb0994/assets/Cube/SVG/ic_fluent_cube_32_filled.svg" alt="devcontainers organization logo"/></a></td>
    <td>
        <strong>Julian's Development Container 'Features'</strong><br />
        <i>A fine selection of new or enhanced Features.</i>
    </td>
</tr></table>

Welcome to yet another DevContainer Features repository! This repository extends the official [`ghcr.io/devcontainers/features`](https://github.com/orgs/devcontainers/packages?repo_name=features) main repository
and contains a collection of features to enhance your development environment within a [DevContainer](https://containers.dev/).

You may learn about Features at [containers.dev](https://containers.dev/implementors/features/), which is the website for the dev container specification.

## Features

Below are the features currently available in this repository:

| Feature Name        | Description                                                                                                                                                                         |               Documentation                |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------: |
| CLI Microsoft 365   | CLI for Microsoft 365 is a cross-platform CLI that allows users on any platform to manage various configuration settings of Microsoft 365.                                          | [📚 Link](./src/cli-microsoft365/) |
| PnP.PowerShell      | PnP PowerShell is a cross-platform PowerShell module that allows users on any platform to manage various configuration settings of Microsoft 365.                                   | [📚 Link](./src/cli-microsoft365/) |
| PowerShell Extended | Installs PowerShell on AMD64 and ARM64 machines, and optional additional resources from the PowerShell Gallery using PSResourceGet. It also supports advanced installation options. | [📚 Link](./src/cli-microsoft365/) |

'Features' are self-contained units of installation code and development container configuration. Features are designed
to install atop a wide-range of base container images.

## Usage

To reference a Feature from this repository, add the desired Features to a `devcontainer.json`. Each Feature has a `README.md` that shows how to reference the Feature and which options are available for that Feature.

The example below installs the`powershell-extended` feature declared in the [`./src`](./src) directory of this
repository.

See the relevant Feature's README for supported options.

```jsonc
"name": "my-project-devcontainer",
"image": "mcr.microsoft.com/devcontainers/base:ubuntu",  // Any generic, debian-based image.
"features": {
    "ghcr.io/jpawlowski/devcontainer-features/powershell-extended:2": {
        "version": "7.4"
    }
}
```

The `:latest` version annotation is added implicitly if omitted. To pin to a specific package version
([example](https://github.com/jpawlowski/devcontainer-features/pkgs/container/features/powershell-extended/versions)), append
it to the end of the Feature. Features follow semantic versioning conventions, so you can pin to a major version `:2`, minor
version `:2.0`, or patch version `:2.0.0` by specifying the appropriate label.

```jsonc
"features": {
    "ghcr.io/jpawlowski/devcontainer-features/powershell-extended:2.0.0": {
        "version": "7.4"
    }
}
```

## Contributing to this repository

This repository will accept improvement and bug fix contributions related to the
[current set of maintained Features](./src).

Learn more about [how to create a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
at the GitHub documentation page.
