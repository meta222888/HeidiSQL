# Shared Delphi / madExcept path resolution for HeidiSQL build scripts.
function Get-HeidiDelphiBin {
    param([string]$RepoRoot)
    $candidates = @(
        $env:HEIDISQL_DELPHI_BIN,
        'D:\tools\Delphi 12.3\bin',
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Embarcadero\Studio\23.0\bin')
    ) | Where-Object { $_ -and ($_ -ne '') }
    foreach ($bin in $candidates) {
        if (Test-Path (Join-Path $bin 'dcc64.exe')) {
            return $bin
        }
    }
    return $null
}

function Get-HeidiDelphiRoot {
    param([string]$DelphiBin)
    Split-Path $DelphiBin -Parent
}

function Get-HeidiRsVars {
    param([string]$RepoRoot)
    $local = Join-Path $RepoRoot 'scripts\rsvars-local.bat'
    if (Test-Path $local) { return $local }
    $bin = Get-HeidiDelphiBin -RepoRoot $RepoRoot
    if ($bin) { return (Join-Path $bin 'rsvars.bat') }
    return $null
}

function Get-HeidiMadDir {
    $candidates = @(
        $env:HEIDISQL_MAD_DIR,
        'D:\tools\madCollection',
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'madCollection')
    ) | Where-Object { $_ -and ($_ -ne '') }
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir 'madExcept\Tools\madExceptPatch.exe')) {
            return $dir
        }
    }
    return $null
}

function Test-HeidiMadExceptPackages {
    param([string]$MadDir, [string]$Platform = 'Win64')
    if (-not $MadDir) { return $false }
    $bit = if ($Platform -eq 'Win64') { '64' } else { '32' }
    $pas = Join-Path $MadDir 'madExcept\madExcept.pas'
    $dcu = Join-Path $MadDir "madExcept\BDS23\win$bit\madExcept.dcu"
    return (Test-Path $pas) -or (Test-Path $dcu)
}

function Ensure-HeidiDelphiRsVars {
    param(
        [string]$RepoRoot,
        [string]$DelphiRoot
    )
    $bat = Join-Path $RepoRoot 'scripts\rsvars-local.bat'
    $commonDir = Join-Path $env:ProgramData 'Embarcadero\Studio\23.0'
    if (-not (Test-Path $commonDir)) {
        New-Item -ItemType Directory -Path (Join-Path $commonDir 'Bpl\Win64') -Force | Out-Null
    }
    $content = @"
@ECHO OFF
SET "BDS=$DelphiRoot"
SET "BDSINCLUDE=$DelphiRoot\include"
SET "BDSCOMMONDIR=$commonDir"
SET "FrameworkDir=C:\Windows\Microsoft.NET\Framework\v4.0.30319"
SET "FrameworkVersion=v4.5"
SET "FrameworkSDKDir="
SET "PATH=%FrameworkDir%;%FrameworkSDKDir%;$DelphiRoot\bin;$DelphiRoot\bin64;$DelphiRoot\cmake;%PATH%"
SET "LANGDIR=EN"
SET "PLATFORM="
SET "PlatformSDK="
"@
    Set-Content -Path $bat -Value $content -Encoding ASCII
    return $bat
}
