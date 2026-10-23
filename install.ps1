# GCC Auto Setup bootstrapper
# After publishing this repository, replace YOUR-USERNAME below with your GitHub username.

$ErrorActionPreference = "Stop"
$repoRaw = "https://raw.githubusercontent.com/YOUR-USERNAME/gcc-auto-setup/main"
$installDir = Join-Path $HOME ".gcc-auto-setup"
$mainScript = Join-Path $installDir "gccup.ps1"
$profilePath = $PROFILE

Write-Host ""
Write-Host "  GCC Auto Setup - Bootstrapper" -ForegroundColor Yellow
Write-Host "  Installing the personal command..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Invoke-WebRequest -Uri "$repoRaw/gccup.ps1" -OutFile $mainScript

$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$markerStart = "# >>> GCC Auto Setup >>>"
$markerEnd = "# <<< GCC Auto Setup <<<"
$profileText = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $profileText) { $profileText = "" }

$block = @"
$markerStart
function gccup {
    & "`$HOME\.gcc-auto-setup\gccup.ps1" @args
}
$markerEnd
"@

if ($profileText.Contains($markerStart) -and $profileText.Contains($markerEnd)) {
    $pattern = "(?s)# >>> GCC Auto Setup >>>.*?# <<< GCC Auto Setup <<<"
    $profileText = [regex]::Replace($profileText, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block.TrimEnd() })
} else {
    if ($profileText.Length -gt 0 -and -not $profileText.EndsWith("`n")) { $profileText += "`r`n" }
    $profileText += "`r`n$block`r`n"
}
Set-Content -Path $profilePath -Value $profileText -Encoding utf8

Write-Host ""
Write-Host "Installed successfully." -ForegroundColor Green
Write-Host "Open a new PowerShell window and type: gccup" -ForegroundColor Cyan
Write-Host "You can also run it now:" -ForegroundColor DarkGray
& ([scriptblock]::Create((Get-Content -Path $mainScript -Raw))) @args
