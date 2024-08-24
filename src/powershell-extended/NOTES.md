## Enhanced Shell Experience

The `installOhMyPoshConfig` setting installs a pre-configured set of [PowerShell profile files](./dotfiles/.config/powershell/)
that provide a fully-featured and ready-to-go terminal console experience.

> Follow the [Enhancement Guide](ENHANCEMENTS.md) to unlock the full potential of the PowerShell terminal in your Dev Container.

Here are some highlights:

### 1. Terminal Prompt Theme

This feature includes a custom [Oh My Posh](https://ohmyposh.dev/) theme to customize the terminal prompt.
[![Oh My Posh theme: devcontainers.minimal](images/devcontainers.minimal.omp.png)](./dotfiles/.config/oh-my-posh/themes/devcontainers.minimal.omp.json)
You can [change the theme](ENHANCEMENTS.md#3-change-your-oh-my-posh-powershell-prompt) to one that you prefer.

> **Note**: Most other themes require installing a [Nerd Font](https://ohmyposh.dev/docs/installation/fonts) on your
> **host system** (not the Dev Container) and adjusting your font settings in VSCode. The Windows Terminal default font
> [_Cascadia Mono_](https://github.com/microsoft/cascadia-code/releases/tag/v2404.23) now has a native Nerd Font variant,
> which can [easily be installed](ENHANCEMENTS.md#1-install-nerd-font) and looks great in VSCode as well.

### 2. Command Line Completion / IntelliSense

Command completion is crucial for productivity when using the command line. The profile includes multiple popular completions
enabled out-of-the-box:

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) (also see [devcontainers/features/azure-cli](https://github.com/devcontainers/features/tree/main/src/azure-cli))
- [GitHub CLI](https://cli.github.com/) (also see [devcontainers/features/github-cli](https://github.com/devcontainers/features/tree/main/src/github-cli))
- [`Posh-Git`](https://github.com/dahlbyk/posh-git): Tab completion support for common git commands, branch names, paths
  and more.
- [`Microsoft.PowerShell.UnixTabCompletion`](https://github.com/PowerShell/UnixCompleters)
- `PSReadLine` [Predictive IntelliSense](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors)
  plugins:
  - [`CompletionPredictor`](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors?view=powershell-7.4#using-other-predictor-plug-ins):
    Command-line IntelliSense based on PowerShell auto-completion.

Optional completions that can be enabled:

- [`Az.Tools.Predictor`](https://learn.microsoft.com/en-us/powershell/azure/predictor-overview): Module providing
  recommendations for cmdlets in the `Az` module.
- [Oh My Posh CLI](https://ohmyposh.dev/blog/whats-new-2#cli-interface-also-2)
- [`PSFzf`](https://github.com/kelleyma49/PSFzf): A PowerShell module that wraps `fzf`, a fuzzy file finder for the
  command line.

Other tools:

- [`z`](https://github.com/badmotorfinger/z): Lets you quickly navigate the file system in PowerShell based on your `cd`
  command history.
- Custom `dir` command alias to sort folders first and show hidden files.

### 3. Other Highlights

- **Fully Customizable Profile Configuration**:

  Profile presets can be adjusted using `PSPROFILE_*` environment variables directly in your `devcontainer.json`. Settings
  can be controlled separately for both regular PowerShell terminals and the VSCode PowerShell Extension host.

  Custom profile settings can be placed in profile directories to avoid modifying the built-in profile files. This includes
  separate directories for special terminal multiplexers like `tmux`.

- **Fast Profile Load Time**:

  The profile uses delayed and parallel module imports to enhance load times. This approach provides a feature-rich terminal
  experience while maintaining quick responsiveness when opening a new terminal window.

- **Daily Update of Help Files**:

  A background job automatically updates help files once a day when a new shell is started.

## Advanced Resource Installation Options

This is a re-write of the original [ghcr.io/devcontainers/features/powershell](https://ghcr.io/devcontainers/features/powershell)
package. It uses [Microsoft.PowerShell.PSResourceGet](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/)
instead of [PowerShellGet](https://learn.microsoft.com/en-us/powershell/gallery/overview) to install resources, which is
included with PowerShell since version 7.4.0.

The new configuration options support an advanced syntax for 3rd party installation repositories as well as enhanced version
definition, including version ranges and pre-releases.

### Setting a version for `resources`

To use advanced options for resource installation, you may do so using the extended
resource name syntax:

`[<Repository-URI>]Resource-Name[@<Version>]`

#### Version Examples

| Notation                                     | Description                                                                                                                            |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `Az`                                         | Installs the latest version.                                                                                                           |
| `Az@12.1.0`                                  | Install exactly version 12.1.0.                                                                                                        |
| `Az@[12.1.0,]`                               | Installs any version equal or greater than 12.1.0.                                                                                     |
| `Az@[12.1,12.2)`                             | Installs the latest bugfix release within the 12.1.x range.                                                                            |
| `https://example.com/api/v2/MyPrivateModule` | Installs a module from a 3rd-party repository. The URI base is interpreted as resource name, while the rest is used as repository URI. |

For a detailled description about version formats, see [`Install-PSResource -Version`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/install-psresource?#-version)
reference.

Resource repositories are automatically created using their domain, unless they are pre-defined with their name
(see below). Note that these repositories will be available also after the container was created, but they will
**not be trusted** automatically after the initial installation of resources.

> **IMPORTANT:** Please note that multiple items must be separated using a semicolon (`;`).
> The comma is reserved to be used within version ranges as explained above.
> For example: `Az@12.1.0; Microsoft.Graph@2.20.0`

### Setting resource `repositories`

To register a resource repository (or change PSGallery default repository), you make use this syntax:

`[<Repository-Name>=]Repository-URI[^<Priority>]`

#### Resource Repository Examples

| Notation                                    | Description                                                  | Resulting Repository Name |
| ------------------------------------------- | ------------------------------------------------------------ | ------------------------- |
| `https://example.com/api/v2`                | Minimum example.                                             | `example.com`             |
| `MyRepo=https://example.com/api/v2`         | Setting an explicit repository name.                         | `MyRepo`                  |
| `https://www.poshtestgallery.com/api/v2^70` | Add PowerShell Test Gallery with a decreased priority of 70. | `www.poshtestgallery.com` |
| `PSGallery^60`                              | Decrease priority of PSGallery to 60.                        | `PSGallery`               |
| `PSGallery`                                 | Set PSGallery as trusted.                                    | `PSGallery`               |

Note that every repository you explicitly set in the configuration will automatically be configured as a **trusted resource**.

> **IMPORTANT:** Please note that multiple items must be separated using a semicolon (`;`).
> It follows the principle used to separate items in the `resources` option.
> For example: `PSGallery; PoshTestGallery=https://www.poshtestgallery.com/api/v2^70`
