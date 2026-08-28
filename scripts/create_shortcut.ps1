[CmdletBinding()]
param(
    [ValidateSet("01", "02", "03", "04", "05", "06")]
    [string]$IconVariant = "01",

    [switch]$ProjectOnly,

    [switch]$DesktopOnly
)

$ErrorActionPreference = "Stop"

if ($ProjectOnly -and $DesktopOnly) {
    throw "ProjectOnly and DesktopOnly cannot be used together."
}

$projectDirectory = Split-Path -Parent $PSScriptRoot
$launcherPath = Join-Path $PSScriptRoot "start_sniffplay.vbs"
$pythonWindow = Join-Path $projectDirectory ".venv\Scripts\pythonw.exe"
$iconNames = @{
    "01" = "01-dark-brand.ico"
    "02" = "02-mint-tile.ico"
    "03" = "03-light-contrast.ico"
    "04" = "04-round-badge.ico"
    "05" = "05-player-window.ico"
    "06" = "06-launch-signal.ico"
}
$iconPath = Join-Path $projectDirectory (
    "assets\shortcut-icon-variants\" + $iconNames[$IconVariant]
)

foreach ($requiredPath in @($launcherPath, $pythonWindow, $iconPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file was not found: $requiredPath"
    }
}

$destinations = [System.Collections.Generic.List[string]]::new()
if (-not $DesktopOnly) {
    $destinations.Add((Join-Path $projectDirectory "SniffPlay.lnk"))
}
if (-not $ProjectOnly) {
    $desktopDirectory = [Environment]::GetFolderPath("Desktop")
    if ([string]::IsNullOrWhiteSpace($desktopDirectory)) {
        throw "Windows desktop directory could not be resolved."
    }
    $destinations.Add((Join-Path $desktopDirectory "SniffPlay.lnk"))
}

$wscriptPath = Join-Path $env:SystemRoot "System32\wscript.exe"
$shell = New-Object -ComObject WScript.Shell

foreach ($destination in $destinations) {
    $shortcut = $shell.CreateShortcut($destination)
    $shortcut.TargetPath = $wscriptPath
    $shortcut.Arguments = "//nologo `"$launcherPath`""
    $shortcut.WorkingDirectory = $projectDirectory
    $shortcut.IconLocation = "$iconPath,0"
    $shortcut.Description = "Launch SniffPlay"
    $shortcut.Save()
    Write-Output "Created shortcut: $destination"
}
