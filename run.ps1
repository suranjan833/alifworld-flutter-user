
# -----------------------------
# Locate Flutter project root
# -----------------------------

$TargetDir = Get-Location
$ProjectRoot = $null

while ($TargetDir) {
    if (Test-Path (Join-Path $TargetDir.Path "pubspec.yaml")) {
        $ProjectRoot = $TargetDir.Path
        break
    }

    $Parent = Split-Path $TargetDir.Path -Parent

    if (!$Parent -or $Parent -eq $TargetDir.Path) {
        break
    }

    $TargetDir = Get-Item $Parent
}

# Fallback: script directory
if (!$ProjectRoot) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

    if (Test-Path (Join-Path $ScriptDir "pubspec.yaml")) {
        $ProjectRoot = $ScriptDir
    }
}

if (!$ProjectRoot) {
    Write-Host "Error: No pubspec.yaml found!" -ForegroundColor Red
    exit 1
}

Set-Location $ProjectRoot

$Project = Split-Path $ProjectRoot -Leaf

# -----------------------------
# Environment selection
# -----------------------------

Write-Host ""
Write-Host "Flutter Run Options" -ForegroundColor Cyan
Write-Host "-------------------"

Write-Host ""
Write-Host "Select Environment:"
Write-Host "  1) Production (.env.production)"
Write-Host "  2) Development (.env.local)"

$EnvChoice = Read-Host "Choose environment [1/2] (default: 1)"

if ([string]::IsNullOrWhiteSpace($EnvChoice)) {
    $EnvChoice = "1"
}

switch -Regex ($EnvChoice) {
    '^(2|dev|development|local)' {
        $EnvName = "local"
        $EnvFile = ".env.local"
        $EnvLabel = "Development"
        break
    }

    default {
        $EnvName = "production"
        $EnvFile = ".env.production"
        $EnvLabel = "Production"
    }
}

if (!(Test-Path $EnvFile)) {
    Write-Host "Warning: $EnvFile not found!" -ForegroundColor Yellow
}

# -----------------------------
# Run mode selection
# -----------------------------

Write-Host ""
Write-Host "Select Run Mode:"
Write-Host "  1) Debug"
Write-Host "  2) Release"

$ModeChoice = Read-Host "Choose mode [1/2] (default: 1)"

if ([string]::IsNullOrWhiteSpace($ModeChoice)) {
    $ModeChoice = "1"
}

if ($ModeChoice -match '^(2|release)') {
    $RunMode = "release"
}
else {
    $RunMode = "debug"
}

# -----------------------------
# Device selection
# -----------------------------

Write-Host ""
$Device = Read-Host "Device ID (leave empty for default device)"

# -----------------------------
# Build information
# -----------------------------

$BuildVersion = git describe --tags --always 2>$null

if (!$BuildVersion) {
    $BuildVersion = "no-git"
}

$BuildTime = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"

# -----------------------------
# Display configuration
# -----------------------------

Write-Host ""
Write-Host "-----------------------------" -ForegroundColor DarkGray
Write-Host "Project     : $Project"
Write-Host "Environment : $EnvLabel"
Write-Host "Env File    : $EnvFile"
Write-Host "Run Mode    : $RunMode"
Write-Host "Version     : $BuildVersion"
Write-Host "Build Time  : $BuildTime"
Write-Host "-----------------------------" -ForegroundColor DarkGray

# -----------------------------
# Dart defines
# -----------------------------

$FlutterArgs = @(
    "run"
    "--$RunMode"
    "--dart-define=BUILD_VERSION=$BuildVersion"
    "--dart-define=BUILD_TIME=$BuildTime"
    "--dart-define=ENV=$EnvName"
    "--dart-define=ENV_FILE=$EnvFile"
)

if (![string]::IsNullOrWhiteSpace($Device)) {
    $FlutterArgs += @("-d", $Device)
}

# -----------------------------
# Run Flutter
# -----------------------------

Write-Host ""
Write-Host "Starting $Project ($EnvLabel - $RunMode)..." -ForegroundColor Green
Write-Host ""

& flutter @FlutterArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Flutter run failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Flutter session finished." -ForegroundColor Green
