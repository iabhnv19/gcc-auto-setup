# GCC Auto Setup bootstrapper
$ErrorActionPreference = "Stop"
$repoRaw    = "https://raw.githubusercontent.com/iabhnv19/gcc-auto-setup/main"
$installDir = Join-Path $env:LOCALAPPDATA "GccAutoSetup"
$mainScript = Join-Path $installDir "gccup.ps1"

Write-Host ""
Write-Host "  GCC Auto Setup - Bootstrapper" -ForegroundColor Yellow
Write-Host "  Installing the 'gccup' command..." -ForegroundColor Cyan

# older Windows PowerShell needs TLS 1.2 for GitHub
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# execution policy (so scripts never get blocked)
try {
    $current = Get-ExecutionPolicy -Scope CurrentUser
    if ($current -in @("Restricted", "AllSigned", "Undefined")) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "  Execution policy set to RemoteSigned (current user)." -ForegroundColor DarkGray
    }
} catch {
    # can fail if Group Policy controls it; the shim below bypasses policy anyway
    Write-Host "  Note: couldn't change execution policy (managed by system). Continuing." -ForegroundColor DarkGray
}

# remove leftovers from the old profile-based installer
$oldProfiles = @(
    $PROFILE,
    $PROFILE.CurrentUserAllHosts,
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1")
) | Where-Object { $_ } | Select-Object -Unique

foreach ($pf in $oldProfiles) {
    try {
        if (Test-Path $pf) {
            $txt = Get-Content -Path $pf -Raw -ErrorAction Stop
            if ($txt -and $txt.Contains("# >>> GCC Auto Setup >>>")) {
                $clean = [regex]::Replace($txt, "(?s)\r?\n?# >>> GCC Auto Setup >>>.*?# <<< GCC Auto Setup <<<\r?\n?", "")
                Set-Content -Path $pf -Value $clean -Encoding utf8
            }
        }
    } catch { } 
}
$oldDir = Join-Path $HOME ".gcc-auto-setup"
if (Test-Path $oldDir) { Remove-Item $oldDir -Recurse -Force -ErrorAction SilentlyContinue }

# download main script 
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Invoke-WebRequest -Uri "$repoRaw/gccup.ps1" -OutFile $mainScript -UseBasicParsing

# shim so "gccup" works in any terminal, ignoring policy
$shim = '@powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gccup.ps1" %*'
Set-Content -Path (Join-Path $installDir "gccup.cmd") -Value $shim -Encoding Ascii

# add to User PATH 
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$entries  = @(($userPath -split ";") | Where-Object { $_.Trim() -ne "" })
if ($entries -notcontains $installDir) {
    [Environment]::SetEnvironmentVariable("Path", (($entries + $installDir) -join ";"), "User")
}
if (($env:Path -split ";") -notcontains $installDir) { $env:Path += ";$installDir" }

Write-Host ""
Write-Host "Installed successfully." -ForegroundColor Green
Write-Host "In a NEW terminal (as Administrator) type: gccup" -ForegroundColor Cyan
Write-Host "Running it now..." -ForegroundColor DarkGray
& powershell -NoProfile -ExecutionPolicy Bypass -File $mainScript
