# GCC Auto Setup

A PowerShell-based helper that installs and maintains the GCC/G++ toolchain through MSYS2 UCRT64 on Windows.

It keeps the installation in a user-friendly command, `gccup`, and includes a golden ASCII glasses banner.

## Features

- Installs MSYS2 with `winget` when missing.
- Installs GCC and G++ through the MSYS2 UCRT64 package.
- Adds `C:\msys64\ucrt64\bin` to the current user's PATH without duplicate entries.
- Provides status, update, and PATH repair commands.
- Shows the original ASCII banner and switches to a stacked layout in narrow terminals.

## Publish this repository first

1. Create a public GitHub repository named `gcc-auto-setup`.
2. Upload `install.ps1`, `gccup.ps1`, `README.md`, `LICENSE`, and `.gitignore`.
3. In `install.ps1`, replace `YOUR-USERNAME` with your GitHub username.
4. Commit and push the change.

## One-time installation

Open PowerShell and run the following command after replacing `YOUR-USERNAME`:

```powershell
irm https://raw.githubusercontent.com/YOUR-USERNAME/gcc-auto-setup/main/install.ps1 | iex
```

The bootstrapper downloads the main script into `%USERPROFILE%\.gcc-auto-setup`, adds a `gccup` function to your PowerShell profile, and starts the tool.

Open a new PowerShell window after installation to use `gccup` from any directory.

## Commands

```powershell
gccup
gccup install
gccup status
gccup update
gccup repair
gccup path
```

- `gccup`: opens the interactive menu.
- `gccup install`: install or repair MSYS2/GCC and configure PATH.
- `gccup status`: show installation status.
- `gccup update`: update MSYS2 packages and GCC.
- `gccup repair`: rerun installation checks and repair the PATH.
- `gccup path`: add GCC to the user PATH if missing.

## Requirements and notes

- Windows 10/11 with PowerShell.
- `winget` is required to install MSYS2 automatically.
- Network access is required for downloads and package updates.
- The default MSYS2 path is `C:\msys64`. If MSYS2 is installed elsewhere, update `$Root` in `gccup.ps1`.
- The first installation may prompt for permissions depending on the machine's policy and MSYS2 installer.
- After PATH changes, open a new terminal for the persistent user PATH to be reflected in all applications.
- The bootstrap command downloads and executes code from this repository. Review the scripts before running them, and use a repository you control.

## Security

Do not run a remote script from a source you do not trust. Inspect `install.ps1` and `gccup.ps1` before using the one-line bootstrap command.
