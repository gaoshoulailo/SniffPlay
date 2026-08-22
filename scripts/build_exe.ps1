param(
    [switch]$SkipInstall,
    [switch]$KeepBuildFiles
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pythonPath = Join-Path $projectRoot ".venv\Scripts\python.exe"
$specPath = Join-Path $projectRoot "sniffplay.spec"
$distPath = Join-Path $projectRoot "dist"
$buildPath = Join-Path $projectRoot "build"
$exePath = Join-Path $distPath "SniffPlay.exe"

function Assert-ProjectChildPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $rootPrefix = $projectRoot.TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside the project: $fullPath"
    }
}

Assert-ProjectChildPath $distPath
Assert-ProjectChildPath $buildPath

if (-not (Test-Path -LiteralPath $pythonPath)) {
    throw "Python virtual environment not found: $pythonPath`nCreate it first with: python -m venv .venv"
}

$dllPath = Join-Path $projectRoot "vendor\mpv\libmpv-2.dll"
if (-not (Test-Path -LiteralPath $dllPath)) {
    throw "Missing libmpv DLL: $dllPath"
}

if (-not $SkipInstall) {
    & $pythonPath -m pip install --upgrade "pyinstaller>=6.10,<7"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not install PyInstaller"
    }
}

if (Test-Path -LiteralPath $distPath) {
    Remove-Item -LiteralPath $distPath -Recurse -Force
}
if (Test-Path -LiteralPath $buildPath) {
    Remove-Item -LiteralPath $buildPath -Recurse -Force
}

Push-Location $projectRoot
try {
    & $pythonPath -m PyInstaller --clean --noconfirm $specPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exePath)) {
        throw "PyInstaller did not produce $exePath"
    }
}
finally {
    Pop-Location
}

$hash = Get-FileHash -LiteralPath $exePath -Algorithm SHA256
$sizeMb = [math]::Round((Get-Item -LiteralPath $exePath).Length / 1MB, 1)
Write-Host "Built: $exePath"
Write-Host "Size:  $sizeMb MB"
Write-Host "SHA256: $($hash.Hash)"

if (-not $KeepBuildFiles -and (Test-Path -LiteralPath $buildPath)) {
    Remove-Item -LiteralPath $buildPath -Recurse -Force
}
