$ErrorActionPreference = "Stop"

$deployRepo = "https://github.com/CD-uagro/app.carnetdigital.space.git"
$deployBranch = "main"
$deployDir = Join-Path $env:TEMP "app-carnetdigital-space-pages"

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
        [string[]]$Arguments,
        [string]$WorkingDirectory = $PWD.Path
    )

    Push-Location $WorkingDirectory
    try {
        & $Command @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: $Command $($Arguments -join ' ')"
        }
    } finally {
        Pop-Location
    }
}

function Clear-DeployDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = Resolve-Path $Path
    $tempRoot = [System.IO.Path]::GetFullPath($env:TEMP)
    $target = [System.IO.Path]::GetFullPath($resolved.Path)

    if (-not $target.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean directory outside TEMP: $target"
    }

    Get-ChildItem -LiteralPath $target -Force |
        Where-Object { $_.Name -ne ".git" } |
        Remove-Item -Recurse -Force
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEPLOY TO app.carnetdigital.space" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target repo: $deployRepo" -ForegroundColor White

Write-Step "1/7 Checking local source branch"
$sourceBranch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Source branch: $sourceBranch" -ForegroundColor Green

Write-Step "2/7 Installing dependencies"
Run-Command "flutter" @("pub", "get")

Write-Step "3/7 Building Flutter Web release"
Run-Command "flutter" @("build", "web", "--release")

Write-Step "4/7 Preparing build/web for GitHub Pages"
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

Write-Step "5/7 Cloning or updating static Pages repository"
if (Test-Path $deployDir) {
    Run-Command "git" @("fetch", "origin", $deployBranch) $deployDir
    Run-Command "git" @("checkout", $deployBranch) $deployDir
    Run-Command "git" @("reset", "--hard", "origin/$deployBranch") $deployDir
} else {
    Run-Command "git" @("clone", "--branch", $deployBranch, $deployRepo, $deployDir)
}

Write-Step "6/7 Copying build/web into static repository"
Clear-DeployDirectory $deployDir
Get-ChildItem -LiteralPath "build\web" -Force |
    Copy-Item -Destination $deployDir -Recurse -Force

$workflowDir = Join-Path $deployDir ".github\workflows"
New-Item -Path $workflowDir -ItemType Directory -Force | Out-Null
@'
name: Deploy static Flutter Web to GitHub Pages

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: "."
      - id: deployment
        uses: actions/deploy-pages@v4
'@ | Set-Content -Path (Join-Path $workflowDir "deploy-pages.yml") -Encoding utf8

Write-Step "7/7 Committing and pushing static site"
Run-Command "git" @("add", "--all") $deployDir
$changes = git -C $deployDir status --porcelain
if ($changes) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    Run-Command "git" @("commit", "-m", "deploy: publish UAGro redesign - $timestamp") $deployDir
    Run-Command "git" @("push", "origin", $deployBranch) $deployDir
    Write-Host "Static site pushed to $deployRepo ($deployBranch)." -ForegroundColor Green
} else {
    Write-Host "No static changes to publish." -ForegroundColor Yellow
}

Run-Command "git" @("checkout", "-B", "gh-pages") $deployDir
Run-Command "git" @("push", "origin", "gh-pages") $deployDir
Run-Command "git" @("checkout", $deployBranch) $deployDir
Write-Host "Static site also pushed to gh-pages for classic GitHub Pages." -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT COMPLETED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "URL: https://app.carnetdigital.space" -ForegroundColor Cyan
Write-Host "Fallback URL: https://cd-uagro.github.io/app.carnetdigital.space/" -ForegroundColor Cyan
Write-Host "Note: GitHub Pages can take 1-5 minutes to update." -ForegroundColor Yellow
