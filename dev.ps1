# dev.ps1 — Arranca Flutter con las variables de .env
# Uso: .\dev.ps1 [dispositivo]
# Ejemplo: .\dev.ps1 windows
#          .\dev.ps1 chrome

param(
    [string]$Device = "chrome"
)

$EnvFile = ".\.env"
if (-not (Test-Path $EnvFile)) {
    Write-Error "No se encontro .env. Copia .env.example en .env y rellena los valores."
    exit 1
}

flutter run -d $Device --dart-define-from-file=.env @args
