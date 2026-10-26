# helpers 
$esc = [char]27
$useAnsi = $false
try { $useAnsi = [bool]$Host.UI.SupportsVirtualTerminal } catch {}

function Write-Gold($text) {
    if ($useAnsi) { Write-Host "$esc[38;5;220m$text$esc[0m" }
    else          { Write-Host $text -ForegroundColor Yellow }
}


function Show-Logo {
    $art = @'
                              *$:::::::::::::::::::::::::::::::::::::$$$$$$:::***$$:
             :***%%%%###################%$$$$$$  ::::::::: :::   ::$$$$%####@@@@@@@@#@@@@@@@#####%%**
         :*%#@@@@####%%%%%%%%%%%%%%%%%%####@@@#%                 %#@@@@###%%%%%%%%%%%%%%%%%%%%%###@@@@%**:
      *%*%@@#$*:                            *%@@#              :#@@%*:                             *$@@#***:
    :%% *@@*  $                               *@@#:$$*$$$$$$$$*#@@*                                $ :@@% :$*:
   *%$* #@#     $                              *@@$$$::    $$$%@@*                                $   %@@**$$$:
   $$$$$#@%      $                             *@@$           $@@*                               $    *@#$$$$$:
    $$$$%@%       $$                           %@#            *@@#                              $     *@@$
       *@@%         $                         :@@% $*         *%@@*                           $$$     *@@*
       :@@#         $                         %@@$$$          :$#@#                           $$      *@@*
        #@@:       ::                        *@@$$$             $@@%                                  #@#
        *@@%                                *@@$$                $@@%                                *@@%
         %@@:                              :#@#                   %@@*                               %@@:
         :@@#                             *#@#:                    %@@*                             *@@%
          *@@%                           *@@%:                      %@@%:                          *@@%
           *@@#*                       *#@@$                         *@@@%:                     :*#@@#
            *%@@#%%****::  :::::***%%%#@@%*                           :%@@@#%%****:::::::****%%##@@#*
              :*%##@@@@@@@@@@@@@@@@@##%*:                                *%##@@@@@@@@@@@@@@@@@##%%*:::
              ::::**********************::                           :::::::***************:::::
'@

    $info = @(
        @{ Label = "GCC AUTO-SETUP"; Value = "v1.0" },
        @{ Label = "----------------"; Value = "----------------" },
        @{ Label = "OS"; Value = (Get-CimInstance Win32_OperatingSystem).Caption },
        @{ Label = "SHELL"; Value = "PowerShell" },
        @{ Label = "ENVIRONMENT"; Value = "MSYS2 UCRT64" },
        @{ Label = "MSYS2"; Value = $(if ($haveMsys) { "Installed" } else { "Not installed" }) },
        @{ Label = "GCC & G++"; Value = $(if ($haveGcc -and $haveGpp) { "Installed" } else { "Not installed" }) },
        @{ Label = "VS CODE"; Value = $(if ($haveCode) { "Installed" } else { "Not installed" }) },
        @{ Label = "COMPILER"; Value = "C / C++" },
        @{ Label = "----------------"; Value = "----------------" },
        @{ Label = "[1]"; Value = "MSYS2 package manager" },
        @{ Label = "[2]"; Value = "GCC & G++ compiler (UCRT64)" },
        @{ Label = "[3]"; Value = "Configure system PATH" },
        @{ Label = "[4]"; Value = "VS Code & Extensions" },
        @{ Label = "[5]"; Value = "Check for updates" }
    )

    Write-Host ""

    $artLines = $art -split "`r?`n"
    $logoWidth = ($artLines | Measure-Object -Property Length -Maximum).Maximum
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $gap = 3
    $infoWidth = 38
    $sideBySide = $consoleWidth -ge ($logoWidth + $gap + $infoWidth)

    if ($sideBySide) {
        $height = [Math]::Max($artLines.Count, $info.Count)

        for ($i = 0; $i -lt $height; $i++) {
            if ($i -lt $artLines.Count) {
                Write-Host ($artLines[$i] + (" " * ($logoWidth - $artLines[$i].Length + $gap))) `
                    -ForegroundColor Yellow -NoNewline
            } else {
                Write-Host (" " * ($logoWidth + $gap)) -NoNewline
            }

            if ($i -lt $info.Count) {
                Write-Host (" " + $info[$i].Label.PadRight(13)) `
                    -ForegroundColor Cyan -NoNewline
                Write-Host $info[$i].Value -ForegroundColor White
            } else {
                Write-Host ""
            }
        }
    }
    else {
        foreach ($line in $artLines) {
            Write-Host $line -ForegroundColor Yellow
        }

        Write-Host ""
        foreach ($item in $info) {
            Write-Host ("  " + $item.Label.PadRight(15)) `
                -ForegroundColor Cyan -NoNewline
            Write-Host $item.Value -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host (" " * 20 + "G C C   A U T O - S E T U P") -ForegroundColor Yellow
    Write-Host ""
    Write-Host (" " * 20 + "Made with <3 by Abhinav") -ForegroundColor Red
    Write-Host ""
}

# admin check 
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    return
}

$root = "C:\msys64"
$sh   = "$root\usr\bin\bash.exe"
$bin  = "$root\ucrt64\bin"
$pkg  = "mingw-w64-ucrt-x86_64-gcc"

function Get-CodeCmd {
    $cmd = Get-Command code.cmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) { return $cand }
    }
    return $null
}

$haveMsys = Test-Path $sh
$haveGcc  = Test-Path "$bin\gcc.exe"
$haveGpp  = Test-Path "$bin\g++.exe"
$haveCode = $null -ne (Get-CodeCmd)

# info screen
Show-Logo
Write-Host "  This script will set up the C/C++ development environment on your PC:" 
Write-Host ""
Write-Host "    1. MSYS2        package manager + shell      " -NoNewline
if ($haveMsys) { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    2. GCC & G++    C/C++ compiler (UCRT64)      " -NoNewline
if ($haveGcc -and $haveGpp) { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    3. PATH         so 'gcc' and 'g++' work in any terminal"
Write-Host "    4. VS Code      editor + C/C++ & Code Runner extensions " -NoNewline
if ($haveCode) { Write-Host "[found]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    5. Update check at the end, with an option to update GCC"
Write-Host ""
$go = Read-Host "  Press Y to start (anything else cancels)"
if ($go -notmatch "^[Yy]") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    return
}
Write-Host ""

# 1. MSYS2
if (-not $haveMsys) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget not found. Update 'App Installer' from the Microsoft Store and try again." -ForegroundColor Red
        return
    }
    Write-Host "Installing MSYS2..." -ForegroundColor Cyan
    winget install -e --id MSYS2.MSYS2 --silent --accept-package-agreements --accept-source-agreements
}
if (-not (Test-Path $sh)) {
    Write-Host "MSYS2 install failed. Check your internet and try again." -ForegroundColor Red
    return
}

# 2. GCC 
if (-not $haveGcc) {
    Write-Host "Updating MSYS2 packages..." -ForegroundColor Cyan
    & $sh -lc "pacman -Syu --noconfirm"
    & $sh -lc "pacman -Syu --noconfirm"  
    Write-Host "Installing GCC..." -ForegroundColor Cyan
    & $sh -lc "pacman -S --needed --noconfirm $pkg"
} else {
    Write-Host "GCC already installed, skipping install." -ForegroundColor DarkGray
}

# 3. PATH 
$p = [Environment]::GetEnvironmentVariable("Path", "User")
$pArray = @(($p -split ";") | Where-Object { $_.Trim() -ne "" })
if ($pArray -notcontains $bin) {
    $newP = ($pArray + $bin) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newP, "User")
    Write-Host "Added $bin to User PATH." -ForegroundColor Cyan
} else {
    Write-Host "User PATH already contains $bin." -ForegroundColor DarkGray
}
if (($env:Path -split ";") -notcontains $bin) {
    $env:Path = "$env:Path;$bin"
}

if (-not (Test-Path "$bin\gcc.exe")) {
    Write-Host "GCC didn't install. Run this script again." -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "Compilers ready:" -ForegroundColor Green
Write-Host "  gcc: " -ForegroundColor Cyan -NoNewline
& "$bin\gcc.exe" --version | Select-Object -First 1
if (Test-Path "$bin\g++.exe") {
    Write-Host "  g++: " -ForegroundColor Cyan -NoNewline
    & "$bin\g++.exe" --version | Select-Object -First 1
}

# 4. VS Code & Extensions 
Write-Host ""
Write-Host "Setting up VS Code & Extensions..." -ForegroundColor Cyan

$codeCmd = Get-CodeCmd
if (-not $codeCmd) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget not found. Please install VS Code manually from https://code.visualstudio.com" -ForegroundColor Red
    } else {
        Write-Host "Installing Visual Studio Code via winget..." -ForegroundColor Cyan
        winget install -e --id Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements
        $codeCmd = Get-CodeCmd
        if ($codeCmd) {
            $codeDir = Split-Path $codeCmd
            if (($env:Path -split ";") -notcontains $codeDir) { $env:Path = "$env:Path;$codeDir" }
        }
    }
}

if ($codeCmd) {
    Write-Host "VS Code located: $codeCmd" -ForegroundColor Green

    $extensions = @(
        @{ Id = "ms-vscode.cpptools"; Name = "C/C++" },
        @{ Id = "ms-vscode.cpp-devtools"; Name = "C/C++ DevTools" },
        @{ Id = "ms-vscode.cpptools-extension-pack"; Name = "C/C++ Extension Pack" },
        @{ Id = "formulahendry.code-runner"; Name = "Code Runner" }
    )

    $installedExts = @(& $codeCmd --list-extensions 2>$null)

    foreach ($ext in $extensions) {
        if ($installedExts -contains $ext.Id) {
            Write-Host "  [OK] $($ext.Name) ($($ext.Id)) is already installed." -ForegroundColor DarkGray
        } else {
            Write-Host "  Installing $($ext.Name) ($($ext.Id))..." -ForegroundColor Cyan
            & $codeCmd --install-extension $ext.Id --force
        }
    }

    # Configure VS Code settings for Code Runner
    Write-Host "Configuring Code Runner settings in VS Code..." -ForegroundColor Cyan
    $settingsPath = "$env:APPDATA\Code\User\settings.json"
    $settingsDir  = Split-Path $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    $settingsObj = [PSCustomObject]@{}
    if (Test-Path $settingsPath) {
        try {
            $rawSettings = Get-Content $settingsPath -Raw
            if ($rawSettings -and $rawSettings.Trim()) {
                $parsed = $rawSettings | ConvertFrom-Json -ErrorAction Stop
                if ($parsed) { $settingsObj = $parsed }
            }
        } catch {
            Write-Host "  Note: Could not parse existing settings.json; initializing clean settings." -ForegroundColor Yellow
        }
    }

    $settingsObj | Add-Member -MemberType NoteProperty -Name "code-runner.runInTerminal" -Value $true -Force
    $settingsObj | Add-Member -MemberType NoteProperty -Name "code-runner.saveFileBeforeRun" -Value $true -Force
    $settingsObj | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "  [OK] Enabled: Code-runner: Run In Terminal (code-runner.runInTerminal = true)" -ForegroundColor Green
    Write-Host "  [OK] Enabled: Code-runner: Save File Before Run (code-runner.saveFileBeforeRun = true)" -ForegroundColor Green
} else {
    Write-Host "VS Code CLI not found; skipped extension and settings installation." -ForegroundColor Yellow
}

# 5. Update check 
Write-Host ""
Write-Host "Checking for a newer GCC / G++..." -ForegroundColor Cyan
$upd = & $sh -lc "pacman -Sy --noconfirm >/dev/null 2>&1; pacman -Qu $pkg" 2>$null
$upd = ($upd | Out-String).Trim()

if ($upd) {
    Write-Host "Update available: $upd" -ForegroundColor Yellow
    $u = Read-Host "Update GCC & G++ now? (Y/n)"
    if ($u -eq "" -or $u -match "^[Yy]") {
        Write-Host "Updating..." -ForegroundColor Cyan
        & $sh -lc "pacman -Syu --noconfirm"
        & $sh -lc "pacman -Syu --noconfirm"
        Write-Host "Updated:" -ForegroundColor Green
        & "$bin\gcc.exe" --version | Select-Object -First 1
        if (Test-Path "$bin\g++.exe") {
            & "$bin\g++.exe" --version | Select-Object -First 1
        }
    } else {
        Write-Host "Skipped. Run this script again any time to update." -ForegroundColor DarkGray
    }
} else {
    Write-Host "You're on the latest GCC & G++." -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Open a NEW terminal so PATH applies everywhere." -ForegroundColor Green
