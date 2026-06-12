#Requires -Version 5.1
<#
.SYNOPSIS
  Download official HeidiSQL .mo translation files into locale/ for the app and out/.
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$LocaleRoot = Join-Path $RepoRoot 'locale'
$OutLocale = Join-Path $RepoRoot 'out\locale'
$Tag = if ($env:HEIDISQL_LOCALE_TAG) { $env:HEIDISQL_LOCALE_TAG } else { 'v12.18' }
$ApiUrl = "https://api.github.com/repos/HeidiSQL/HeidiSQL/contents/extra/locale?ref=$Tag"

Write-Host "Fetching translation list from HeidiSQL $Tag ..." -ForegroundColor Cyan
$entries = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing
$moFiles = $entries | Where-Object { $_.name -like 'heidisql.*.mo' }

if (-not $moFiles) {
    Write-Error "No heidisql.*.mo files found at $ApiUrl"
}

foreach ($entry in $moFiles) {
    $lang = $entry.name -replace '^heidisql\.', '' -replace '\.mo$', ''
    $destDir = Join-Path $LocaleRoot "$lang\LC_MESSAGES"
    $destFile = Join-Path $destDir 'default.mo'
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "  $lang"
    Invoke-WebRequest -Uri $entry.download_url -OutFile $destFile -UseBasicParsing
}

foreach ($root in @($OutLocale)) {
    if (-not (Test-Path (Split-Path $root -Parent))) { continue }
    Write-Host "Copying to $root ..." -ForegroundColor Yellow
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
    Copy-Item -Path $LocaleRoot -Destination $root -Recurse -Force
}

Write-Host "Locale sync done ($($moFiles.Count) languages)." -ForegroundColor Green
