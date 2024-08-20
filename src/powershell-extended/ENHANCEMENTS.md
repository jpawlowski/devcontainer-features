# How to Enhance Your PowerShell Terminal Experience in Dev Containers

Your Dev Container (or Codespace) uses the [`powershell-extended`](https://github.com/jpawlowski/devcontainer-features/tree/main/src/powershell-extended)
feature which provides a great out-of-box experience for your PowerShell.

Some advanced visual features depend on the availability of a Nerd Font, which are fonts that are extended with special characters
to display glyphs/icons and other graphics right in your terminal window.

By installing such font and tweaking some settings of your Dev Container and Visual Studio Code settings, you unlock the
best experience for your PowerShell terminal.

## Install Nerd Font

Since the VSCode default font (on Windows) is _Cascadia Mono_, we recommend to install an updated version of that very
same font directly from [Github/Microsoft/Cascadia-Code](https://github.com/microsoft/cascadia-code/releases).
Since its [May 2024 release](https://github.com/microsoft/cascadia-code/releases/tag/v2404.23) it provides a native
Nerd Font variant with all the nice details we care about. Since it is not bundles with any of the
Microsoft applications (yet), you will need to install it separately.

However, you may also select any other font from [nerdfonts.com](https://www.nerdfonts.com/).

To make the setup easier for you, you may copy the following lines into your **local** PowerShell
terminal (that is, a local Windows Terminal window, or a local VSCode window that is not running your Dev Container):

```powershell
& ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont')))
```

This will provide an interactive menu for you to select the desired font.
The install script is designed to be multi-platform and will install fonts on Windows, macOS, and Linux devices.
