# GCC Auto Setup 

**A one-command GCC/G++ setup tool for Windows, powered by PowerShell and MSYS2.**

GCC Auto Setup automates the installation and configuration of the GCC compiler toolchain on Windows 10/11. It installs MSYS2 when needed, configures your PATH, checks for GCC updates, and displays a custom golden ASCII glasses banner.

##  Features

- **One-command bootstrap:** Install the setup tool directly from GitHub.
- **Automatic MSYS2 installation:** Uses `winget` when MSYS2 is not installed.
- **GCC/G++ setup:** Installs the UCRT64 GCC toolchain through MSYS2's package manager.
- **Automatic PATH configuration:** Adds the GCC binary directory to your user PATH.
- **Installation detection:** Skips GCC installation when the compiler is already present.
- **Update checking:** Checks for available GCC package updates and lets you update.
- **Custom terminal interface:** Golden ASCII glasses artwork with system information and colored output.
- **PowerShell integration:** Adds a personal `gccup` command to your PowerShell profile.

##  Installation

### Prerequisites

- Windows 10 or Windows 11
- PowerShell
- An internet connection
- `winget` for automatic MSYS2 installation when it is missing
- Administrator privileges for the setup process

### One-command installation

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/iabhnv19/gcc-auto-setup/main/install.ps1 | iex
```

The bootstrapper downloads the main script into:

```text
%USERPROFILE%\.gcc-auto-setup
```

It then adds the `gccup` function to your PowerShell profile and starts the setup process.

After installation, open a new PowerShell window to use the personalized command.

## Usage

Run the following command in PowerShell:

```powershell
gccup
```

The setup process will:

1. Display the custom terminal interface.
2. Ask for confirmation before starting.
3. Install MSYS2 if it is missing.
4. Update MSYS2 package databases and packages.
5. Install GCC if it is missing.
6. Configure the GCC directory in your user PATH.
7. Verify the GCC installation.
8. Check for available GCC updates and offer to install them.

You can rerun `gccup` whenever you want to check or update your setup. Existing GCC installations are detected, so the initial installation step can be skipped when appropriate.

## Installed Toolchain

The default installation uses the following configuration:

| Component | Configuration |
|---|---|
| Package manager | MSYS2 |
| Environment | UCRT64 |
| C compiler | GCC |
| C++ compiler | G++ |
| Installation directory | `C:\msys64` |
| Compiler binaries | `C:\msys64\ucrt64\bin` |
| Package | `mingw-w64-ucrt-x86_64-gcc` |

## Verify the Installation

Open a new terminal and run:

```powershell
gcc --version
g++ --version
```

You can also verify that the compiler can build a C++ program:

```powershell
g++ --version
```

If both commands display their compiler versions, the executables are accessible through your PATH.

## Repository Structure

```text
gcc-auto-setup/
├── install.ps1    # One-time bootstrapper
├── gccup.ps1      # Main GCC setup script
├── README.md      # Project documentation
├── LICENSE        # Project license
└── .gitignore     # Git ignore rules
```

## Troubleshooting

### PowerShell says script execution is disabled

PowerShell execution policies can prevent `.ps1` files from running directly.

For a temporary setting limited to the current PowerShell process, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then retry the command if needed. This setting disappears when that PowerShell process closes. Organizational policies may impose additional restrictions.

### `winget` is not found

Install or update **App Installer** through the Microsoft Store, then retry the setup.

### GCC is not recognized

Check whether this directory exists:

```text
C:\msys64\ucrt64\bin
```

If it does, ensure that directory is included in your user PATH, then open a new terminal.

### MSYS2 installation fails

Check your internet connection and ensure that `winget` is available. If MSYS2 is installed in a non-default directory, update the paths in `gccup.ps1`.

## Security

This project downloads and executes PowerShell code from GitHub. Review the scripts before running them and use a repository you trust.

The setup modifies your user PATH and PowerShell profile. Administrator privileges may be required for installation, depending on your system configuration.

## License

This project is distributed under the MIT License. See the [`LICENSE`](LICENSE) file for details.

## Author

**Abhinav**

Made with ❤️ and PowerShell.

---

*Simplifying C/C++ compiler setup on Windows, one command at a time.*
