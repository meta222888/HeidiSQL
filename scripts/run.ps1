#Requires -Version 5.1
<#
.SYNOPSIS
  启动 HeidiSQL：优先使用 out\heidisql.exe（自编译），否则使用已安装版本。

.EXAMPLE
  .\scripts\run.ps1
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Candidates = @(
    (Join-Path $RepoRoot 'out\heidisql.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\HeidiSQL\heidisql.exe'),
    'C:\Program Files\HeidiSQL\heidisql.exe'
)

foreach ($exe in $Candidates) {
    if (Test-Path $exe) {
        $dir = Split-Path $exe -Parent
        Write-Host "启动: $exe" -ForegroundColor Cyan
        if ($dir -ieq (Join-Path $RepoRoot 'out')) {
            Write-Host '（自编译版本，包含 fork 修复）' -ForegroundColor Green
        } else {
            Write-Host '（官方安装版，不含 fork 源码修复；编译后 out\heidisql.exe 优先）' -ForegroundColor Yellow
        }
        Start-Process -FilePath $exe -WorkingDirectory $dir
        exit 0
    }
}

Write-Error "未找到 heidisql.exe。请运行 .\scripts\setup-dev.ps1 或 winget install HeidiSQL.HeidiSQL"
