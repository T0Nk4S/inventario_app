param(
  [string]$projectId = 'bdagenda-8392a',
  [string]$rulesFile = 'firestore.rules'
)

# Verificar firebase CLI
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Host 'Firebase CLI no está instalado. Instálalo con: npm i -g firebase-tools' -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Path $rulesFile)) {
  Write-Host "No se encontró el archivo de reglas: $rulesFile" -ForegroundColor Red
  exit 1
}

Write-Host "Desplegando $rulesFile al proyecto $projectId ..." -ForegroundColor Cyan
firebase deploy --only firestore:rules --project $projectId

if ($LASTEXITCODE -ne 0) {
  Write-Error "El despliegue falló (exit code $LASTEXITCODE). Revisa la salida anterior."
  exit $LASTEXITCODE
} else {
  Write-Host "Reglas desplegadas correctamente en el proyecto $projectId." -ForegroundColor Green
}
