$ErrorActionPreference = "Stop"

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Yellow
}

function Run-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command $($Arguments -join ' ')"
    }
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main") {
    throw "Deployment must run from branch 'main'. Current branch: '$branch'."
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEPLOY TO app.carnetdigital.space" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Step "1/6 Checking GitHub Pages deployment mode"
if (-not (Test-Path ".github\workflows\deploy.yml")) {
    throw "Missing .github\workflows\deploy.yml. Cannot confirm GitHub Actions deployment."
}
Write-Host "Deployment mode: GitHub Actions Pages artifact from build/web" -ForegroundColor Green
Write-Host "Trigger branch: main" -ForegroundColor Green

Write-Step "2/6 Installing dependencies"
Run-Command "flutter" @("pub", "get")

Write-Step "3/6 Building Flutter Web release"
Run-Command "flutter" @("build", "web", "--release")

Write-Step "4/6 Preparing Pages files in build/web"
if (Test-Path "web\CNAME") {
    Copy-Item "web\CNAME" -Destination "build\web\CNAME" -Force
} elseif (Test-Path "CNAME") {
    Copy-Item "CNAME" -Destination "build\web\CNAME" -Force
} else {
    throw "CNAME not found in web\CNAME or project root."
}

New-Item -Path "build\web\.nojekyll" -ItemType File -Force | Out-Null
Write-Host "CNAME:" -ForegroundColor Green
Get-Content "build\web\CNAME"

Write-Step "5/6 Staging source changes for GitHub Actions"
Run-Command "git" @("add", "lib/screens/login_screen.dart", "lib/screens/carnet_screen_new.dart", "lib/screens/carnet_selector_screen.dart", "deploy.ps1")

$pendingChanges = git diff --cached --name-only
if ($pendingChanges) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    Run-Command "git" @("commit", "-m", "deploy: publish UAGro redesign - $timestamp")
    Write-Host "Commit created." -ForegroundColor Green
} else {
    Write-Host "No source changes to commit." -ForegroundColor Yellow
}

Write-Step "6/6 Pushing main to GitHub"
Run-Command "git" @("push", "origin", "main")

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT STARTED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Actions will build and publish build/web." -ForegroundColor White
Write-Host "URL: https://app.carnetdigital.space" -ForegroundColor Cyan
Write-Host "Note: GitHub Pages can take 1-5 minutes to update." -ForegroundColor Yellow
