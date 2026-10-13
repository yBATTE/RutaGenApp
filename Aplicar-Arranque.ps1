$ErrorActionPreference = 'Stop'
$proyecto = (Get-Location).Path
if (-not (Test-Path (Join-Path $proyecto 'pubspec.yaml')) -or
    -not (Test-Path (Join-Path $proyecto 'ios/Runner/Info.plist'))) {
    throw 'Ejecuta este script desde la carpeta raiz de ruta_gen_app.'
}
$archivos = @(
    'lib/main.dart',
    'lib/app.dart',
    'pubspec.yaml',
    'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json',
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png',
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png'
)
foreach ($archivo in $archivos) {
    if (-not (Test-Path (Join-Path $PSScriptRoot $archivo))) {
        throw "Falta un archivo del parche: $archivo"
    }
}
$respaldo = Join-Path (Split-Path $proyecto -Parent) ('backup-arranque-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
foreach ($archivo in $archivos) {
    $actual = Join-Path $proyecto $archivo
    if (Test-Path $actual) {
        $copia = Join-Path $respaldo $archivo
        New-Item -ItemType Directory -Path (Split-Path $copia) -Force | Out-Null
        Copy-Item -LiteralPath $actual -Destination $copia
    }
}
foreach ($archivo in $archivos) {
    $destino = Join-Path $proyecto $archivo
    New-Item -ItemType Directory -Path (Split-Path $destino) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $archivo) -Destination $destino -Force
}
Write-Host "Parche aplicado. Respaldo: $respaldo" -ForegroundColor Green
Write-Host 'Ahora ejecuta: flutter clean; flutter pub get'
