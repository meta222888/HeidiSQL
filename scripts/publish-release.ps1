#Requires -Version 5.1
<#
.SYNOPSIS
  Build, package, and publish a GitHub release to meta222888/HeidiSQL.
.EXAMPLE
  .\scripts\publish-release.ps1 -Version 12.18.1
#>
param(
    [string]$Version = '13.0.0.1',
    [string]$Tag = 'v13.0.0.1'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$ZipPath = Join-Path $RepoRoot "dist\HeidiSQL_${Version}_64_Portable.zip"
$NotesPath = Join-Path $RepoRoot "dist\RELEASE_${Tag}.md"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error 'GitHub CLI (gh) is required. Install from https://cli.github.com/ and run: gh auth login'
}

& (Join-Path $PSScriptRoot 'build.ps1')
& (Join-Path $PSScriptRoot 'package-portable.ps1') -Version $Version

if (-not (Test-Path $NotesPath)) {
    Write-Error "Release notes not found: $NotesPath"
}

if (-not (git tag -l $Tag)) {
    git tag -a $Tag -m "HeidiSQL $Version (meta222888 fork)"
    git push fork $Tag
}

gh release view $Tag --repo meta222888/HeidiSQL 2>$null
if ($LASTEXITCODE -eq 0) {
    gh release upload $Tag $ZipPath --repo meta222888/HeidiSQL --clobber
    gh release edit $Tag --repo meta222888/HeidiSQL --notes-file $NotesPath
} else {
    gh release create $Tag $ZipPath --repo meta222888/HeidiSQL --title "HeidiSQL $Version" --notes-file $NotesPath
}

Write-Host "Release published: https://github.com/meta222888/HeidiSQL/releases/tag/$Tag" -ForegroundColor Green
