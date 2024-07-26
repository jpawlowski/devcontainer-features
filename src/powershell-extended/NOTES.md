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
