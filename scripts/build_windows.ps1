[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$SkipSmokeTest
)

$ErrorActionPreference = "Stop"
$projectDirectory = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pythonPath = Join-Path $projectDirectory ".venv\Scripts\python.exe"
$specPath = Join-Path $projectDirectory "sniffplay.spec"
$mpvPath = Join-Path $projectDirectory "vendor\mpv\libmpv-2.dll"
$iconPath = Join-Path $projectDirectory "assets\sniffplay.ico"
$outputDirectory = Join-Path $projectDirectory "dist\SniffPlay"
$existingDataDirectory = Join-Path $outputDirectory "data"
$dataBackupDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("sniffplay-build-data-" + [guid]::NewGuid().ToString("N"))

foreach ($requiredPath in @($pythonPath, $specPath, $mpvPath, $iconPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required build file not found: $requiredPath"
    }
}

Push-Location $projectDirectory
try {
    if (-not $SkipTests) {
        & $pythonPath -m pytest -q
        if ($LASTEXITCODE -ne 0) {
            throw "Tests failed."
        }
    }

    # PyInstaller recreates dist\SniffPlay. Preserve the portable database
    # so rebuilding does not remove playlists, favorites, or settings.
    $hasExistingData = Test-Path -LiteralPath $existingDataDirectory -PathType Container
    if ($hasExistingData) {
        New-Item -ItemType Directory -Force -Path $dataBackupDirectory | Out-Null
        Copy-Item -Path (Join-Path $existingDataDirectory "*") -Destination $dataBackupDirectory -Recurse -Force
    }

    & $pythonPath -m PyInstaller --noconfirm --clean $specPath
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller build failed."
    }

    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        throw "Build output was not created: $outputDirectory"
    }

    $dataDirectory = Join-Path $outputDirectory "data"
    if ($hasExistingData -and (Test-Path -LiteralPath $dataBackupDirectory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $dataDirectory | Out-Null
        Copy-Item -Path (Join-Path $dataBackupDirectory "*") -Destination $dataDirectory -Recurse -Force
    }
    $licenseDirectory = Join-Path $outputDirectory "licenses"
    New-Item -ItemType Directory -Force -Path $dataDirectory | Out-Null
    New-Item -ItemType Directory -Force -Path $licenseDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectDirectory "README.md") -Destination $outputDirectory -Force
    Copy-Item -LiteralPath (Join-Path $projectDirectory "LICENSE") -Destination (Join-Path $licenseDirectory "GPL-3.0.txt") -Force
    Copy-Item -LiteralPath (Join-Path $projectDirectory "vendor\mpv\README.md") -Destination (Join-Path $licenseDirectory "libmpv-README.md") -Force
    Copy-Item -LiteralPath (Join-Path $projectDirectory "vendor\mpv\LGPL-2.1.txt") -Destination $licenseDirectory -Force
    Copy-Item -LiteralPath (Join-Path $projectDirectory "vendor\mpv\LGPL-3.0.txt") -Destination $licenseDirectory -Force

    if (-not $SkipSmokeTest) {
        $smokeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sniffplay-build-smoke-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Force -Path $smokeRoot | Out-Null
        $previousDataDirectory = $env:SNIFFPLAY_DATA_DIR
        $process = $null
        try {
            $smokeDataDirectory = Join-Path $smokeRoot "data"
            $env:SNIFFPLAY_DATA_DIR = $smokeDataDirectory
            $process = Start-Process -FilePath (Join-Path $outputDirectory "SniffPlay.exe") -WorkingDirectory $smokeRoot -WindowStyle Hidden -PassThru
            $deadline = [DateTime]::UtcNow.AddSeconds(30)
            while ([DateTime]::UtcNow -lt $deadline) {
                if ($process.HasExited) {
                    throw "Packaged application exited during smoke testing with code $($process.ExitCode)."
                }
                $smokeDatabasePath = Join-Path $smokeDataDirectory "sniffplay.db"
                if (Test-Path -LiteralPath $smokeDatabasePath -PathType Leaf) {
                    break
                }
                Start-Sleep -Milliseconds 500
            }
            if (-not (Test-Path -LiteralPath $smokeDatabasePath -PathType Leaf)) {
                throw "Packaged application did not initialize its data directory."
            }
        }
        finally {
            if ($null -ne $process -and -not $process.HasExited) {
                Stop-Process -Id $process.Id
                $process.WaitForExit()
            }
            $env:SNIFFPLAY_DATA_DIR = $previousDataDirectory
            if (Test-Path -LiteralPath $smokeRoot) {
                Remove-Item -LiteralPath $smokeRoot -Recurse -Force
            }
        }
    }

    Write-Output "Windows build created: $outputDirectory"
}
finally {
    if (Test-Path -LiteralPath $dataBackupDirectory) {
        Remove-Item -LiteralPath $dataBackupDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
    Pop-Location
}
