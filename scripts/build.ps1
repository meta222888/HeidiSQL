#Requires -Version 5.1
<#
.SYNOPSIS
  编译 HeidiSQL（需已安装 Delphi 12.3 + madExcept）

.EXAMPLE
  .\scripts\build.ps1
  .\scripts\build.ps1 -Config Release -Platform Win64
#>
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Debug',
    [ValidateSet('Win32', 'Win64')]
    [string]$Platform = 'Win64'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
$RsVars = Join-Path $Pf86 'Embarcadero\Studio\23.0\bin\rsvars.bat'
$GroupProj = Join-Path $RepoRoot 'packages\Delphi12.3\heidisql.groupproj'

if (-not (Test-Path $RsVars)) {
    Write-Error "未找到 Delphi。请先运行 .\scripts\setup-dev.ps1 并按提示安装 RAD Studio 12.3。"
}

& (Join-Path $RepoRoot 'scripts\setup-dev.ps1')
if ($LASTEXITCODE -ne 0 -and -not (Test-Path $RsVars)) { exit 1 }

Write-Host "=== 编译 HeidiSQL ($Config / $Platform) ===" -ForegroundColor Cyan

$buildCmd = @"
call "$RsVars"
cd /d "$RepoRoot\packages\Delphi12.3"
msbuild "$GroupProj" /t:Build /p:Config=$Config /p:Platform=$Platform /verbosity:minimal
"@

$bat = Join-Path $env:TEMP 'heidisql-build.cmd'
Set-Content -Path $bat -Value $buildCmd -Encoding ASCII
cmd /c $bat
$code = $LASTEXITCODE
Remove-Item $bat -Force -ErrorAction SilentlyContinue

if ($code -ne 0) {
    Write-Error "编译失败 (exit $code)。可在 RAD Studio 中打开 packages\Delphi12.3\heidisql.groupproj 查看详细错误。"
}

$exe = Join-Path $RepoRoot 'out\heidisql.exe'
if (Test-Path $exe) {
    Write-Host "编译成功: $exe" -ForegroundColor Green
} else {
    Write-Host '编译完成但未找到 out\heidisql.exe，请检查 MSBuild 输出。' -ForegroundColor Yellow
}
exit $code
