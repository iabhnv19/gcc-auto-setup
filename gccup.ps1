# ---------- helpers ----------
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
        @{ Label = "GCC AUTO-SETUP"; Value = "v1.1.9" },
        @{ Label = "----------------"; Value = "----------------" },
        @{ Label = "OS"; Value = (Get-CimInstance Win32_OperatingSystem).Caption },
        @{ Label = "SHELL"; Value = "PowerShell" },
        @{ Label = "ENVIRONMENT"; Value = "MSYS2 UCRT64" },
        @{ Label = "MSYS2"; Value = $(if ($haveMsys) { "Installed" } else { "Not installed" }) },
        @{ Label = "GCC"; Value = $(if ($haveGcc) { "Installed" } else { "Not installed" }) },
        @{ Label = "COMPILER"; Value = "C / C++" },
        @{ Label = "----------------"; Value = "----------------" },
        @{ Label = "[1]"; Value = "MSYS2 package manager" },
        @{ Label = "[2]"; Value = "GCC compiler (UCRT64)" },
        @{ Label = "[3]"; Value = "Configure system PATH" },
        @{ Label = "[4]"; Value = "Check for updates" }
    )

    Write-Host ""

    $artLines = $art -split "`r?`n"
    $logoWidth = ($artLines | Measure-Object -Property Length -Maximum).Maximum
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $gap = 3
    $infoWidth = 38

    # Side-by-side only when the complete layout fits.
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
        # Narrow console: print the original logo without modifying it.
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

# ---------- admin check ----------
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    return
}

$root = "C:\msys64"
$sh   = "$root\usr\bin\bash.exe"
$bin  = "$root\ucrt64\bin"
$pkg  = "mingw-w64-ucrt-x86_64-gcc"

$haveMsys = Test-Path $sh
$haveGcc  = Test-Path "$bin\gcc.exe"

# ---------- info screen ----------
Show-Logo
Write-Host "  This script will set up the C/C++ compiler on your PC:" 
Write-Host ""
Write-Host "    1. MSYS2        package manager + shell      " -NoNewline
if ($haveMsys) { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    2. GCC          C/C++ compiler (UCRT64)      " -NoNewline
if ($haveGcc)  { Write-Host "[already installed]" -ForegroundColor Green } else { Write-Host "[will install]" -ForegroundColor Yellow }
Write-Host "    3. PATH         so 'gcc' works in any terminal"
Write-Host "    4. Update check at the end, with an option to update GCC"
Write-Host ""
$go = Read-Host "  Press Y to start (anything else cancels)"
if ($go -notmatch "^[Yy]") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    return
}
Write-Host ""

# ---------- 1. MSYS2 ----------
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

# ---------- 2. GCC ----------
if (-not $haveGcc) {
    Write-Host "Updating MSYS2 packages..." -ForegroundColor Cyan
    & $sh -lc "pacman -Syu --noconfirm"
    & $sh -lc "pacman -Syu --noconfirm"   # second pass: first can end early after a core update
    Write-Host "Installing GCC..." -ForegroundColor Cyan
    & $sh -lc "pacman -S --needed --noconfirm $pkg"
} else {
    Write-Host "GCC already installed, skipping install." -ForegroundColor DarkGray
}

# ---------- 3. PATH ----------
$p = [Environment]::GetEnvironmentVariable("Path", "User")
if ($p -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$p;$bin", "User")
    Write-Host "Added $bin to PATH." -ForegroundColor Cyan
}
if ($env:Path -notlike "*$bin*") { $env:Path += ";$bin" }

if (-not (Test-Path "$bin\gcc.exe")) {
    Write-Host "GCC didn't install. Run this script again." -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "GCC ready:" -ForegroundColor Green
& "$bin\gcc.exe" --version | Select-Object -First 1

# ---------- 4. Update check ----------
Write-Host ""
Write-Host "Checking for a newer GCC..." -ForegroundColor Cyan
$upd = & $sh -lc "pacman -Sy --noconfirm >/dev/null 2>&1; pacman -Qu $pkg" 2>$null
$upd = ($upd | Out-String).Trim()

if ($upd) {
    Write-Host "Update available: $upd" -ForegroundColor Yellow
    $u = Read-Host "Update GCC now? (Y/n)"
    if ($u -eq "" -or $u -match "^[Yy]") {
        Write-Host "Updating..." -ForegroundColor Cyan
        & $sh -lc "pacman -Syu --noconfirm"
        & $sh -lc "pacman -Syu --noconfirm"
        Write-Host "Updated:" -ForegroundColor Green
        & "$bin\gcc.exe" --version | Select-Object -First 1
    } else {
        Write-Host "Skipped. Run this script again any time to update." -ForegroundColor DarkGray
    }
} else {
    Write-Host "You're on the latest GCC." -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Open a NEW terminal so PATH applies everywhere." -ForegroundColor Cyan