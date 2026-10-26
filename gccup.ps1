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
        @{ Label = "LEGACY MINGW"; Value = $(if ($legacyMinGW -and $legacyMinGW.Found) { "Detected (will purge)" } else { "Clean" }) },
        @{ Label = "MSYS2"; Value = $(if ($haveMsys) { "Installed" } else { "Not installed" }) },
        @{ Label = "GCC & G++"; Value = $(if ($haveGcc -and $haveGpp) { "Installed" } else { "Not installed" }) },
        @{ Label = "VS CODE"; Value = $(if ($haveCode) { "Installed" } else { "Not installed" }) },
        @{ Label = "COMPILER"; Value = "C / C++" },
        @{ Label = "----------------"; Value = "----------------" },
        @{ Label = "[1]"; Value = "Purge legacy MinGW (v6 etc.)" },
        @{ Label = "[2]"; Value = "MSYS2 package manager" },
        @{ Label = "[3]"; Value = "GCC & G++ compiler (UCRT64)" },
        @{ Label = "[4]"; Value = "Configure system PATH" },
        @{ Label = "[5]"; Value = "VS Code & Extensions" },
        @{ Label = "[6]"; Value = "Check for updates" }
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
$isLegacyMinGWPath = {
    param([string]$p)
    if (-not $p) { return $false }
    $norm = $p.Trim().TrimEnd('\')
    if ($norm -match '(?i)msys' -or $norm -match '(?i)git') { return $false }
    return ($norm -match '(?i)\\mingw' -or $norm -match '(?i)^[a-z]:\\mingw' -or $norm -match '(?i)\\tdm-gcc')
}
function Find-LegacyMinGW {
    $dirs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $pathRemovalsMachine = [System.Collections.Generic.List[string]]::new()
    $pathRemovalsUser = [System.Collections.Generic.List[string]]::new()
    $envVarsToClean = [System.Collections.Generic.List[string]]::new()
    $details = [System.Collections.Generic.List[string]]::new()

    # 1. Common root and Program Files directories across all local drives
    $drives = @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Root)
    foreach ($drv in $drives) {
        foreach ($name in @("MinGW", "MinGW32", "TDM-GCC-64", "TDM-GCC-32")) {
            $cand = Join-Path $drv $name
            if (Test-Path $cand) {
                [void]$dirs.Add($cand)
                [void]$details.Add("Legacy directory found: $cand")
            }
        }
    }

    $pfCandidates = @(
        "${env:ProgramFiles}\MinGW",
        "${env:ProgramFiles(x86)}\MinGW"
    )
    foreach ($pfc in $pfCandidates) {
        if ($pfc -and (Test-Path $pfc)) {
            [void]$dirs.Add($pfc)
            [void]$details.Add("Legacy directory found: $pfc")
        }
    }

    # 2. Check Machine PATH
    $mPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($mPath) {
        foreach ($entry in ($mPath -split ";")) {
            if (& $isLegacyMinGWPath $entry) {
                $trimmed = $entry.Trim().TrimEnd('\')
                $pathRemovalsMachine.Add($entry)
                [void]$details.Add("Machine PATH entry: $entry")
                if (Test-Path $trimmed) {
                    $parent = Split-Path $trimmed -Parent
                    if ($trimmed -match '(?i)bin$' -and (Test-Path $parent)) {
                        [void]$dirs.Add($parent)
                    } else {
                        [void]$dirs.Add($trimmed)
                    }
                }
            }
        }
    }

    # 3. Check User PATH
    $uPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($uPath) {
        foreach ($entry in ($uPath -split ";")) {
            if (& $isLegacyMinGWPath $entry) {
                $trimmed = $entry.Trim().TrimEnd('\')
                $pathRemovalsUser.Add($entry)
                [void]$details.Add("User PATH entry: $entry")
                if (Test-Path $trimmed) {
                    $parent = Split-Path $trimmed -Parent
                    if ($trimmed -match '(?i)bin$' -and (Test-Path $parent)) {
                        [void]$dirs.Add($parent)
                    } else {
                        [void]$dirs.Add($trimmed)
                    }
                }
            }
        }
    }

    # 4. Check Environment Variables (MINGW_HOME, C_INCLUDE_PATH, etc.)
    foreach ($scope in @("Machine", "User")) {
        $envDict = [Environment]::GetEnvironmentVariables($scope)
        foreach ($key in $envDict.Keys) {
            $val = $envDict[$key]
            if ($val -and ($key -match '(?i)^mingw' -or $key -in @("C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH", "LIBRARY_PATH", "CPATH"))) {
                if (($val -match '(?i)mingw' -or $val -match '(?i)tdm') -and ($val -notmatch '(?i)msys') -and ($val -notmatch '(?i)git')) {
                    $envVarsToClean.Add("$($scope):$key")
                    [void]$details.Add("$scope Variable: $key = $val")
                }
            }
        }
    }

    # 5. Check if any legacy gcc command outside MSYS2 is discovered
    $allGcc = @(Get-Command gcc -All -ErrorAction SilentlyContinue | Where-Object {
        $_.Source -notmatch '(?i)msys' -and $_.Source -notmatch '(?i)git'
    })
    foreach ($cmd in $allGcc) {
        $ver = (& $cmd.Source --version 2>&1 | Select-Object -First 1)
        [void]$details.Add("Legacy GCC binary: $($cmd.Source) ($ver)")
        $binDir = Split-Path $cmd.Source -Parent
        if ($binDir -match '(?i)bin$') {
            $rootDir = Split-Path $binDir -Parent
            if ($rootDir -and (Test-Path $rootDir) -and ($rootDir -match '(?i)mingw' -or $rootDir -match '(?i)tdm')) {
                [void]$dirs.Add($rootDir)
            }
        }
    }

    $found = ($dirs.Count -gt 0 -or $pathRemovalsMachine.Count -gt 0 -or $pathRemovalsUser.Count -gt 0 -or $envVarsToClean.Count -gt 0)

    return [PSCustomObject]@{
        Found               = $found
        Directories         = @($dirs)
        PathRemovalsMachine = @($pathRemovalsMachine)
        PathRemovalsUser    = @($pathRemovalsUser)
        EnvVarsToClean      = @($envVarsToClean)
        Details             = @($details)
    }
}

function Remove-LegacyMinGW {
    param([PSCustomObject]$Detection)

    if (-not $Detection -or -not $Detection.Found) {
        Write-Host "  No legacy MinGW installations detected." -ForegroundColor DarkGray
        return
    }

    Write-Host ""
    Write-Host "  Purging Legacy MinGW & Cleaning Environment Variables" -ForegroundColor Yellow

    # 1. Stop any running MinGW processes that might lock files
    foreach ($dir in $Detection.Directories) {
        if (Test-Path $dir) {
            $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                try { $_.Path -and $_.Path.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase) } catch { $false }
            }
            foreach ($p in $procs) {
                Write-Host "  Stopping running process: $($p.Name) (PID: $($p.Id))..." -ForegroundColor Yellow
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # 2. Delete legacy MinGW directories completely
    foreach ($dir in $Detection.Directories) {
        if (Test-Path $dir) {
            Write-Host "  Deleting legacy MinGW directory: $dir..." -ForegroundColor Cyan
            try {
                # Clear read-only attributes on files (common in MinGW headers)
                Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try { $_.Attributes = 'Normal' } catch {}
                }
                Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                Write-Host "  [OK] Successfully deleted: $dir" -ForegroundColor Green
            } catch {
                Write-Host "  [WARNING] Could not fully delete $dir ($($_.Exception.Message))" -ForegroundColor Yellow
            }
        }
    }

    # 3. Clean Machine PATH
    if ($Detection.PathRemovalsMachine.Count -gt 0) {
        Write-Host "  Cleaning legacy entries from Machine PATH..." -ForegroundColor Cyan
        $mPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($mPath) {
            $mArray = @(($mPath -split ";") | Where-Object {
                $trimmed = $_.Trim()
                if (-not $trimmed) { return $false }
                return -not (& $isLegacyMinGWPath $trimmed)
            })
            $newM = $mArray -join ";"
            [Environment]::SetEnvironmentVariable("Path", $newM, "Machine")
            Write-Host "  [OK] Cleaned Machine PATH." -ForegroundColor Green
        }
    }

    # 4. Clean User PATH
    if ($Detection.PathRemovalsUser.Count -gt 0) {
        Write-Host "  Cleaning legacy entries from User PATH..." -ForegroundColor Cyan
        $uPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($uPath) {
            $uArray = @(($uPath -split ";") | Where-Object {
                $trimmed = $_.Trim()
                if (-not $trimmed) { return $false }
                return -not (& $isLegacyMinGWPath $trimmed)
            })
            $newU = $uArray -join ";"
            [Environment]::SetEnvironmentVariable("Path", $newU, "User")
            Write-Host "  [OK] Cleaned User PATH." -ForegroundColor Green
        }
    }

    # 5. Clean current Process $env:Path
    if ($env:Path) {
        $pArray = @(($env:Path -split ";") | Where-Object {
            $trimmed = $_.Trim()
            if (-not $trimmed) { return $false }
            return -not (& $isLegacyMinGWPath $trimmed)
        })
        $env:Path = $pArray -join ";"
    }

    # 6. Remove environment variables (e.g. MINGW_HOME, C_INCLUDE_PATH)
    foreach ($item in $Detection.EnvVarsToClean) {
        $parts = $item -split ":"
        $scope = $parts[0]
        $vName = $parts[1]
        Write-Host "  Removing $scope environment variable: $vName..." -ForegroundColor Cyan
        [Environment]::SetEnvironmentVariable($vName, $null, $scope)
        if (Test-Path "env:$vName") {
            Remove-Item "env:$vName" -ErrorAction SilentlyContinue
        }
        Write-Host "  [OK] Removed $vName ($scope)" -ForegroundColor Green
    }

    # 7. Clean Windows Registry Uninstall entries if any
    $uninstallKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($regPath in $uninstallKeys) {
        if (Test-Path (Split-Path $regPath -Parent)) {
            Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -and ($_.DisplayName -match "(?i)mingw" -or $_.DisplayName -match "(?i)tdm-gcc") -and
                $_.DisplayName -notmatch "(?i)git" -and $_.DisplayName -notmatch "(?i)msys"
            } | ForEach-Object {
                Write-Host "  Cleaning registry uninstall entry: $($_.DisplayName)..." -ForegroundColor Cyan
                try {
                    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] Removed registry entry for $($_.DisplayName)" -ForegroundColor Green
                } catch {}
            }
        }
    }

    Write-Host "  [OK] Legacy MinGW cleanup completed successfully." -ForegroundColor Green
    Write-Host ""
}

$haveMsys = Test-Path $sh
$haveGcc  = Test-Path "$bin\gcc.exe"
$haveGpp  = Test-Path "$bin\g++.exe"
$haveCode = $null -ne (Get-CodeCmd)
$legacyMinGW = Find-LegacyMinGW

# info screen
Show-Logo
Write-Host "  This script will set up the modern C/C++ development environment on your PC:" 
Write-Host ""
Write-Host "    1. Legacy MinGW  Detect & remove old MinGW (v6 etc.) and clean PATH  " -NoNewline
if ($legacyMinGW.Found) {
    Write-Host "[detected - will remove]" -ForegroundColor Red
    foreach ($d in $legacyMinGW.Details) {
        Write-Host "       -> $d" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[clean]" -ForegroundColor Green
}
Write-Host "    2. MSYS2        package manager + shell                              " -NoNewline
if ($haveMsys) { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    3. GCC & G++    C/C++ compiler (UCRT64)                              " -NoNewline
if ($haveGcc -and $haveGpp) { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    4. PATH         so modern 'gcc' and 'g++' work in any terminal"
Write-Host "    5. VS Code      editor + C/C++ & Code Runner extensions              " -NoNewline
if ($haveCode) { Write-Host "[found]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    6. Update check at the end, with an option to update GCC"
Write-Host ""
$go = Read-Host "  Press Y to start (anything else cancels)"
if ($go -notmatch "^[Yy]") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    return
}
Write-Host ""

# 1. Legacy MinGW Purge 
if ($legacyMinGW.Found) {
    Remove-LegacyMinGW -Detection $legacyMinGW
} else {
    Write-Host "No conflicting legacy MinGW detected, skipping purge." -ForegroundColor DarkGray
}

# 2. MSYS2 
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

# 3. GCC
if (-not $haveGcc) {
    Write-Host "Updating MSYS2 packages..." -ForegroundColor Cyan
    & $sh -lc "pacman -Syu --noconfirm"
    & $sh -lc "pacman -Syu --noconfirm"  
    Write-Host "Installing GCC..." -ForegroundColor Cyan
    & $sh -lc "pacman -S --needed --noconfirm $pkg"
} else {
    Write-Host "GCC already installed, skipping install." -ForegroundColor DarkGray
}

#  4. PATH 
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
    $env:Path = "$bin;$env:Path"
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

# 5. VS Code & Extensions 
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

# 6. Update check
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
