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

    & $pythonPath -m PyInstaller --noconfirm --clean $specPath
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller build failed."
    }

    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        throw "Build output was not created: $outputDirectory"
    }

    $dataDirectory = Join-Path $outputDirectory "data"
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
        $databasePath = Join-Path $dataDirectory "sniffplay.db"
        New-Item -ItemType Directory -Force -Path $smokeRoot | Out-Null
        $previousDataDirectory = $env:SNIFFPLAY_DATA_DIR
        $process = $null
        try {
            Remove-Item Env:SNIFFPLAY_DATA_DIR -ErrorAction SilentlyContinue
            $process = Start-Process -FilePath (Join-Path $outputDirectory "SniffPlay.exe") -WorkingDirectory $smokeRoot -WindowStyle Hidden -PassThru
            $deadline = [DateTime]::UtcNow.AddSeconds(30)
            while ([DateTime]::UtcNow -lt $deadline) {
                if ($process.HasExited) {
                    throw "Packaged application exited during smoke testing with code $($process.ExitCode)."
                }
                if (Test-Path -LiteralPath $databasePath -PathType Leaf) {
                    break
                }
                Start-Sleep -Milliseconds 500
            }
            if (-not (Test-Path -LiteralPath $databasePath -PathType Leaf)) {
                throw "Packaged application did not initialize its data directory."
            }
        }
        finally {
            if ($null -ne $process -and -not $process.HasExited) {
                Stop-Process -Id $process.Id
                $process.WaitForExit()
            }
            $env:SNIFFPLAY_DATA_DIR = $previousDataDirectory
            Get-ChildItem -LiteralPath $dataDirectory -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
            if (Test-Path -LiteralPath $smokeRoot) {
                Remove-Item -LiteralPath $smokeRoot -Recurse -Force
            }
        }
    }

    Write-Output "Windows build created: $outputDirectory"
}
finally {
    Pop-Location
}
