#!/usr/bin/env pwsh
# ============================================================
#  MTP Project Generator v2 - Windows Launcher
#  Runs the advanced generator (setup-project.sh) via Git Bash
#  Requirement: Git for Windows (https://git-scm.com)
#  Usage: .\setup-project.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)
$bash = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $bash) {
    $cmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($cmd) { $bash = $cmd.Source }
}

if (-not $bash) {
    Write-Host "`n[ERROR] Git Bash not found." -ForegroundColor Red
    Write-Host "Install it from: https://git-scm.com/download/win (Git for Windows)`n" -ForegroundColor Yellow
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$shScript = Join-Path $scriptDir "setup-project.sh"

Write-Host "`nMTP Project Generator v2 (via Git Bash)`n" -ForegroundColor Cyan
& $bash $shScript
exit $LASTEXITCODE