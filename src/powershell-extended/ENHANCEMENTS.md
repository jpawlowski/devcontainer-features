# How to Enhance Your PowerShell Terminal Experience in Dev Containers

Your Dev Container (or Codespace) uses the [`powershell-extended`](https://github.com/jpawlowski/devcontainer-features/tree/main/src/powershell-extended)
feature which provides a great out-of-box experience for your PowerShell.

Some advanced visual features depend on the availability of a Nerd Font, which are fonts that are extended with special characters
to display glyphs/icons and other graphics right in your terminal window.

By installing such font and tweaking some settings of your Dev Container and Visual Studio Code settings, you unlock the
best experience for your PowerShell terminal.

## 1. Install Nerd Font

Since the VSCode default font (on Windows) is _Cascadia Mono_, we recommend to install an updated version of that very
same font directly from [Github/Microsoft/Cascadia-Code](https://github.com/microsoft/cascadia-code/releases).
Since its [May 2024 release](https://github.com/microsoft/cascadia-code/releases/tag/v2404.23) it provides a native
Nerd Font variant with all the nice details we care about. Since it is not bundles with any of the
Microsoft applications (yet), you will need to install it separately.

However, you may also select any other font from [nerdfonts.com](https://www.nerdfonts.com/).

### Install _Cascadia_ Code & _Cascadia Mono_ as your Nerd Font _(recommended)_

1. **Open new VSCode window**:
   - In Visual Studio Code (VSCode), open a new window: `File > New Window`.

2. **Start a new PowerShell session**:
   - You can do this by opening the command palette
   (`Cmd + Shift + P` on Mac or `Ctrl + Shift + P` on Windows/Linux) and selecting `Terminal: Create New Terminal (With Profile)`.
   - Select `pwsh` from the menu.

3. **Run the Nerd Font installer script**:
   - Copy & paste the following code into the terminal window:

     ```powershell
     & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont'))) -FontName Cascadia
     ```
   - Press `Enter` to run the code.

4. **Confirm installation**:
   - You will see the following output to confirm the installation:

     ```console
     Nerd Fonts Installation
     Do you confirm to install the font 'Cascadia' from GitHub.com/Microsoft ?
     [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): 
     ```

   - Press `Enter` to continue with the installation.

After this, you may continue with [step 2](#2-change-your-font-settings-in-vscode), or install additional fonts as
described below.

### Get an interactive menu to select a Nerd Font to install _(optional)_

1. **Open new VSCode window**:
   - In Visual Studio Code (VSCode), open a new window: `File > New Window`.

2. **Start a new PowerShell session**:
   - You can do this by opening the command palette
   (`Cmd + Shift + P` on Mac or `Ctrl + Shift + P` on Windows/Linux) and selecting `Terminal: Create New Terminal (With Profile)`.
   - Select `pwsh` from the menu.

3. **Run the Nerd Font installer script**:
   - Copy & paste the following code into the terminal window:

     ```powershell
     & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont')))
     ```
   - Press `Enter` to run the code.

4. **Select Nerd Font**:
   - You will see a selection menu like this:

     ```console
                                     🤓 Nerd Fonts Installation
     =========================================================================================

      1: 0xProto              28: Go-Mono              55: Monaspice            
      2: 3270                 29: Gohu                 56: Monofur              
      3: Agave                30: Hack                 57: Monoid               
      4: AnonymicePro         31: Hasklig              58: Mononoki             
      5: AnonymousPro         32: Hasklug              59: MPlus                
      6: Arimo                33: HeavyData            60: NerdFontsSymbolsOnly 
      7: AurulentSansMono     34: Hermit               61: Noto                 
      8: BigBlueTerminal      35: Hurmit               62: OpenDyslexic         
      9: BitstreamVeraSansMono36: iA-Writer            63: Overpass             
     10: Cascadia             37: IBMPlexMono          64: ProFont              
     11: CascadiaCode         38: iMWriting            65: ProggyClean          
     12: CascadiaMono         39: Inconsolata          66: Recursive            
     13: CaskaydiaCove        40: InconsolataGo        67: RobotoMono           
     14: CaskaydiaMono        41: InconsolataLGC       68: SauceCodePro         
     15: CodeNewRoman         42: IntelOneMono         69: ShareTechMono        
     16: ComicShannsMono      43: IntoneMono           70: SourceCodePro        
     17: CommitMono           44: Iosevka              71: SpaceMono            
     18: Cousine              45: IosevkaTerm          72: SureTechMono         
     19: D2Coding             46: IosevkaTermSlab      73: Terminess            
     20: DaddyTimeMono        47: JetBrainsMono        74: Terminus             
     21: DejaVuSansMono       48: Lekton               75: Tinos                
     22: DroidSansMono        49: LiberationMono       76: Ubuntu               
     23: EnvyCodeR            50: Lilex                77: UbuntuMono           
     24: FantasqueSansMono    51: LiterationMono       78: UbuntuSans           
     25: FiraCode             52: MartianMono          79: VictorMono           
     26: FiraMono             53: Meslo                80: ZedMono              
     27: GeistMono            54: Monaspace            

     Enter 'q' to quit.

     Select a number: 53
     ```

   - Enter a number corresponding to the list of Nerd Font names. To choose your favorite,
you may want to visit [nerdfonts.com](https://www.nerdfonts.com/) for a preview.

     Note that some Nerd Font names may be slightly modified on the website due to legal compliance. The script lists both
     the alias names and their original font names to make your selection easier.

   - Press `Enter` to confirm your selection.

4. **Confirm installation**:
   - You will see the following output to confirm the installation:

     ```console
     Your selected font: Meslo

     Nerd Fonts Installation
     Do you confirm to install the font 'Meslo' from GitHub.com/ryanoasis ?
     [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):
     ```

   - Press `Enter` to continue with the installation, or repeat the steps to install more fonts.

After this, continue with [step 2](#2-change-your-font-settings-in-vscode).

## 2. Change your font settings in VSCode

To change the font settings in Visual Studio Code (VSCode) for both the code editor and the terminal, follow these steps:

### Changing the Font for the Code Editor

1. **Open Settings**:
   - Press `Cmd + ,` or go to `File > Preferences > Settings`.

2. **Search for Font Settings**:
   - In the search bar at the top, type `font`.

3. **Edit Font Family**:
   - Look for the setting named `Editor: Font Family`.
   - Click on `Edit in settings.json` or directly edit the text box to add your desired font before the existing ones.
   For example:

     ```json
     "editor.fontFamily": "'Cascadia Code NF', Consolas, 'Courier New', monospace"
     ```

     Note that font names with multiple words should be put into single quotes (`'`).

     If your font supports [ligatures](https://www.hanselman.com/blog/monospaced-programming-fonts-with-ligatures), you
     may optionally enable these to give you some (potentially) nice typographic enhancements in the editor :

     ```json
     "editor.fontLigatures": true,
     ```

    Ultimately, the choice is yours. Some people appreciate it, while others do not. It's best to form your own opinion.
    If you have an interest in typography, you might enjoy it. However, if you prefer sticking to standards, you might not.
    It's a balance between the artist and the nerd within you.

4. **Save Settings**:
   - Save the changes if you edited the `settings.json` file.

### Changing the Font for the Integrated Terminal

1. **Open Settings**:
   - Press `Cmd + ,` or go to `File > Preferences > Settings`.

2. **Search for Terminal Font Settings**:
   - In the search bar at the top, type `terminal font`.

3. **Edit Terminal Font Family**:
   - Look for the setting named `Terminal > Integrated: Font Family`.
   - Click on `Edit in settings.json` or directly edit the text box to add your desired font. For example:
     ```json
     "terminal.integrated.fontFamily": "'Cascadia Mono NF', 'Courier New', monospace"
     ```

4. **Save Settings**:
   - Save the changes if you edited the `settings.json` file.

By following these steps, you can customize the fonts used in both the code editor and the integrated terminal in VSCode
to your preferred Nerd Font or any other font.

## 3. Change your _Oh My Posh_ PowerShell prompt

Now that you have installed a super nerdy font, you are ready to change your prompt to something more pleasing.

There is a selected preview of options on the [Oh My Posh site](https://ohmyposh.dev/docs/themes), and many more out there
in the depths of the internet like the [community discussions](https://github.com/JanDeDobbeleer/oh-my-posh/discussions/categories/themes).

To change the prompt to something of your taste, follow these steps:

### Changing the _Oh My Posh_ theme in your `devcontainer.json`

1. **Open `devcontainer.json`**:
   - In the file explorer of VSCode, open the `.devcontainer` folder and click on the `.devcontainer.json` file to open it.

2. **Search for `containerEnv` section**:
   - Find the `containerEnv` section in the bottom part of the file.
   - If it does not exist, you may create an empty section like this:
     ```json
     ...
     "containerEnv": {

     }
     ...
     ```

3. **Change environment variables**:
   - Now you want to change (or add) the environment variables shown below:

     ```json
     ...
     "containerEnv": {
        // Set theme for regular PowerShell session
        "PSPROFILE_POSH_THEME": "devcontainers.minimal.omp.json",

        // Set theme for PowerShell Extension session
        "PSPROFILE_VSCODE_POSH_THEME": "devcontainers.minimal.omp.json"
     },
     ...
     ```

     Note that you will need to pay attention to keep a valid JSON format which might require adding some commas `,` at
     the end of a section or existing environment variables.

     You may either enter the name of one of the pre-delivered themes or set a direct URL to download the theme automatically.

4. **Save `devcontainer.json`**:
   - Save the changes.

5. **Rebuild your dev container**:
   - To apply the changes, you need to rebuild your dev container. You can do this by opening the command palette
   (`Cmd + Shift + P` on Mac or `Ctrl + Shift + P` on Windows/Linux) and selecting `Remote-Containers: Rebuild Container`.

   - **Note**: This procedure is the same for GitHub Codespaces. Open the command palette and select
   `Codespaces: Rebuild Container`.

By following these steps, you can customize your _Oh My Posh_ PowerShell prompt to your liking.
