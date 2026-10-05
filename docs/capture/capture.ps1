param(
    [Parameter(Mandatory = $true)][string]$QtBin,
    [Parameter(Mandatory = $true)][string]$MinGWBin,
    [switch]$PetDemo,
    [string]$PythonBin = 'python'
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$captureBuild = Join-Path $repositoryRoot 'build/docs-capture'
$originalPath = $env:PATH
$originalPlatform = $env:QT_QPA_PLATFORM
$originalBackend = $env:QSG_RHI_BACKEND
Push-Location $repositoryRoot
try {
    $env:PATH = "$QtBin;$MinGWBin;$originalPath"
    $env:QT_QPA_PLATFORM = 'offscreen'
    $env:QSG_RHI_BACKEND = 'software'
    New-Item -ItemType Directory -Path $captureBuild -Force | Out-Null
    & (Join-Path $QtBin 'rcc.exe') --binary resources.qrc -o (Join-Path $captureBuild 'readme.rcc')
    if ($LASTEXITCODE -ne 0) { throw 'Resource compilation failed.' }
    Push-Location $captureBuild
    try {
        & (Join-Path $QtBin 'qmake.exe') ../../docs/capture/capture.pro CONFIG+=release
        if ($LASTEXITCODE -ne 0) { throw 'qmake failed.' }
        & (Join-Path $MinGWBin 'mingw32-make.exe') -j4
        if ($LASTEXITCODE -ne 0) { throw 'Capture build failed.' }
    } finally { Pop-Location }
    $inputQml = 'docs/capture/tst_readme.qml'
    $logName = 'results.txt'
    if ($PetDemo) {
        $inputQml = 'docs/capture/tst_pet_demo.qml'
        $logName = 'pet-results.txt'
        New-Item -ItemType Directory -Path (Join-Path $captureBuild 'pet-frames') -Force | Out-Null
    }
    $captureLog = (Join-Path $captureBuild $logName) + ',txt'
    & (Join-Path $captureBuild 'release/ReadmeCapture.exe') -input $inputQml -o $captureLog
    if ($LASTEXITCODE -ne 0) { throw 'Screenshot capture failed.' }
    Get-Content (Join-Path $captureBuild $logName)
    $images = @('widget-overview.png', 'settings-refresh.png', 'settings-windows.png')
    if ($PetDemo) {
        & $PythonBin docs/capture/encode_pet_demo.py
        if ($LASTEXITCODE -ne 0) { throw 'GIF encoding failed.' }
        $images = @('pet-in-action.gif')
    }
    foreach ($image in $images) {
        $targetImage = Join-Path $repositoryRoot "docs/images/$image"
        if (-not (Test-Path -LiteralPath $targetImage) -or (Get-Item -LiteralPath $targetImage).Length -eq 0) {
            throw "Missing screenshot: $image"
        }
    }
} finally {
    $env:PATH = $originalPath
    $env:QT_QPA_PLATFORM = $originalPlatform
    $env:QSG_RHI_BACKEND = $originalBackend
    Pop-Location
}
