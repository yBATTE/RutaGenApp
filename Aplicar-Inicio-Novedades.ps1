param(
    [string]$AppPath = 'C:\Users\lucki\Desktop\Ruta Gen\mobile\ruta_gen_app'
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path (Join-Path $AppPath 'pubspec.yaml'))) {
    throw "No se encontró la app Flutter en: $AppPath"
}

$archivos = @(
    'lib\features\home\home_page.dart',
    'lib\features\news\news_carousel.dart',
    'lib\features\news\news_list_page.dart'
)

# Validar los tres archivos antes de modificar el proyecto.
foreach ($archivo in $archivos) {
    if (-not (Test-Path (Join-Path $PSScriptRoot $archivo))) {
        throw "Falta $archivo. Extraé primero el ZIP completo."
    }
}

$origen = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$destino = [System.IO.Path]::GetFullPath($AppPath).TrimEnd('\')
if ($origen -eq $destino) {
    throw 'Extraé el ZIP en otra carpeta para poder respaldar la app actual antes de aplicar los cambios.'
}

$backup = Join-Path (Split-Path $AppPath -Parent) ('backup-inicio-novedades-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null

# Respaldar todos los archivos existentes antes de copiar cambios.
foreach ($archivo in $archivos) {
    $actual = Join-Path $AppPath $archivo
    if (Test-Path $actual) {
        $respaldo = Join-Path $backup $archivo
        New-Item -ItemType Directory -Path (Split-Path $respaldo -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $actual -Destination $respaldo -Force
    }
}

foreach ($archivo in $archivos) {
    $actual = Join-Path $AppPath $archivo
    New-Item -ItemType Directory -Path (Split-Path $actual -Parent) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $archivo) -Destination $actual -Force
}

Write-Host "Inicio actualizado. Respaldo: $backup" -ForegroundColor Green
Write-Host 'Desde la carpeta de tu app ejecutá: flutter analyze y después flutter run.'
