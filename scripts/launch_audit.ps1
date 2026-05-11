$ErrorActionPreference = "Stop"

Write-Host "1/4 Verificando UTF-8..."
python scripts\verify_text_encoding.py

Write-Host "2/4 Analizando Flutter..."
flutter analyze

Write-Host "3/4 Ejecutando tests..."
flutter test

Write-Host "4/4 Build web debug..."
flutter build web --debug --dart-define-from-file=.env --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/

Write-Host "Auditoría local completada."
