# Ejecutar desde la carpeta de Flutter que contiene pubspec.yaml.
$ErrorActionPreference = 'Stop'
if (-not (Test-Path '.\pubspec.yaml')) { throw 'Ejecutá este script desde la carpeta raíz de la app Flutter.' }
$cambiosPremios = @{}
$reglasPremios = @'
[
  {
    "Archivo": "lib/data/models.dart",
    "Antes": "    required this.stock,\n    required this.icon,",
    "Despues": "    required this.stock,\n    this.stockTrackingEnabled = true,\n    required this.icon,",
    "ReemplazarTodos": false
  },
  {
    "Archivo": "lib/data/models.dart",
    "Antes": "  final int stock;\n  final IconData icon;",
    "Despues": "  final int stock;\n  final bool stockTrackingEnabled;\n  final IconData icon;",
    "ReemplazarTodos": false
  },
  {
    "Archivo": "lib/data/models.dart",
    "Antes": "  bool get hasStock => stock > 0;",
    "Despues": "  bool get hasStock => !stockTrackingEnabled || stock > 0;",
    "ReemplazarTodos": false
  },
  {
    "Archivo": "lib/data/api_ruta_gen_repository.dart",
    "Antes": "      stock: _intValue(data['totalStock'] ?? data['stock']),",
    "Despues": "      stock: _intValue(data['totalStock'] ?? data['stock']),\n      stockTrackingEnabled: data['stockTrackingEnabled'] != false,",
    "ReemplazarTodos": false
  },
  {
    "Archivo": "lib/features/rewards/rewards_page.dart",
    "Antes": "reward.stock > 0",
    "Despues": "reward.hasStock",
    "ReemplazarTodos": true
  },
  {
    "Archivo": "lib/features/rewards/rewards_page.dart",
    "Antes": "                                          Text(\n                                            reward.hasStock\n                                                ? 'Stock disponible'",
    "Despues": "                                          if (reward.stockTrackingEnabled) Text(\n                                            reward.hasStock\n                                                ? 'Stock disponible'",
    "ReemplazarTodos": false
  },
  {
    "Archivo": "lib/features/rewards/reward_detail_page.dart",
    "Antes": "reward.stock > 0",
    "Despues": "reward.hasStock",
    "ReemplazarTodos": true
  },
  {
    "Archivo": "lib/features/rewards/reward_detail_page.dart",
    "Antes": "          Center(\n            child: Text(\n              reward.hasStock ? '✓ Stock disponible'",
    "Despues": "          if (reward.stockTrackingEnabled) Center(\n            child: Text(\n              reward.hasStock ? '✓ Stock disponible'",
    "ReemplazarTodos": false
  }
]
'@ | ConvertFrom-Json
foreach ($reglaPremios in $reglasPremios) {
    $rutaPremios = $reglaPremios.Archivo
    if (-not $cambiosPremios.ContainsKey($rutaPremios)) {
        if (-not (Test-Path $rutaPremios)) { throw "No existe $rutaPremios. No se cambió ningún archivo." }
        $cambiosPremios[$rutaPremios] = [System.IO.File]::ReadAllText((Resolve-Path $rutaPremios).Path).Replace("`r`n", "`n")
    }
$textoPremios = $cambiosPremios[$rutaPremios]
    $antesPremios = $reglaPremios.Antes.Replace("`r`n", "`n")
    $despuesPremios = $reglaPremios.Despues.Replace("`r`n", "`n")
    if (-not $reglaPremios.ReemplazarTodos -and $textoPremios.Contains($despuesPremios)) { continue }
    if ($reglaPremios.ReemplazarTodos -and -not $textoPremios.Contains($antesPremios) -and $textoPremios.Contains($despuesPremios)) { continue }
    if (-not $textoPremios.Contains($antesPremios)) { throw "El contenido de $rutaPremios cambió. No se escribió ningún archivo. Pasame el ZIP actual de la app para adaptarlo." }
    $cambiosPremios[$rutaPremios] = $textoPremios.Replace($antesPremios, $despuesPremios)
}
$respaldoPremios = Join-Path (Get-Location) ('backup-premios-' + (Get-Date -Format yyyyMMdd-HHmmss))
$utf8Premios = New-Object System.Text.UTF8Encoding($false)
foreach ($rutaPremios in $cambiosPremios.Keys) {
    $destinoPremios = Join-Path $respaldoPremios $rutaPremios
    New-Item -ItemType Directory -Path (Split-Path $destinoPremios) -Force | Out-Null
    Copy-Item $rutaPremios $destinoPremios
    [System.IO.File]::WriteAllText((Resolve-Path $rutaPremios).Path, $cambiosPremios[$rutaPremios], $utf8Premios)
}
Write-Host 'Listo: la app oculta el texto de stock en los premios que no lo controlan.'
Write-Host "Respaldo: $respaldoPremios"
Write-Host 'Ahora ejecutá flutter analyze y compilá una nueva versión de la app.'
