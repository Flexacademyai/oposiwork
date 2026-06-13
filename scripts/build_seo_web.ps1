param(
  [switch]$PagosHabilitados
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$deploy = Join-Path $root "build\seo"
$flutterBuild = Join-Path $root "build\web"
$landing = Join-Path $root "web\landing"

Set-Location $root

if (Test-Path $flutterBuild) {
  $resolvedFlutterBuild = (Resolve-Path -LiteralPath $flutterBuild).Path
  $expectedFlutterBuild = (Join-Path $root "build\web")
  if ($resolvedFlutterBuild -ne $expectedFlutterBuild) {
    throw "Ruta build web inesperada: $resolvedFlutterBuild"
  }
  Remove-Item -LiteralPath $resolvedFlutterBuild -Recurse -Force
}

$flutterArgs = @(
  "build",
  "web",
  "--release",
  "--base-href",
  "/app/",
  "--dart-define-from-file=.env"
)

if ($PagosHabilitados) {
  $flutterArgs += "--dart-define=PAGOS_HABILITADOS=true"
}

flutter @flutterArgs

$flutterExtras = @(
  ".vercel",
  ".gitignore",
  "api",
  "landing",
  "robots.txt",
  "sitemap.xml",
  "vercel.json"
)

foreach ($extra in $flutterExtras) {
  $extraPath = Join-Path $flutterBuild $extra
  if (Test-Path $extraPath) {
    $resolvedExtra = (Resolve-Path -LiteralPath $extraPath).Path
    if (-not $resolvedExtra.StartsWith($flutterBuild)) {
      throw "Ruta extra inesperada: $resolvedExtra"
    }
    Remove-Item -LiteralPath $resolvedExtra -Recurse -Force
  }
}

if (Test-Path $deploy) {
  $resolvedDeploy = (Resolve-Path -LiteralPath $deploy).Path
  $expectedDeploy = (Join-Path $root "build\seo")
  if ($resolvedDeploy -ne $expectedDeploy) {
    throw "Ruta deploy inesperada: $resolvedDeploy"
  }
  Remove-Item -LiteralPath $resolvedDeploy -Recurse -Force
}

New-Item -ItemType Directory -Path $deploy | Out-Null
New-Item -ItemType Directory -Path (Join-Path $deploy "app") | Out-Null

$vercelProject = Join-Path $root ".vercel"
if (Test-Path $vercelProject) {
  Copy-Item -Path $vercelProject -Destination (Join-Path $deploy ".vercel") -Recurse -Force
}

Copy-Item -Path (Join-Path $flutterBuild "*") -Destination (Join-Path $deploy "app") -Recurse -Force
Copy-Item -Path (Join-Path $landing "*") -Destination $deploy -Recurse -Force

$iconSource = Join-Path $flutterBuild "icons"
$faviconSource = Join-Path $flutterBuild "favicon.png"
$manifestSource = Join-Path $flutterBuild "manifest.json"
$apiSource = Join-Path $root "api"

if (Test-Path $iconSource) {
  Copy-Item -Path $iconSource -Destination (Join-Path $deploy "icons") -Recurse -Force
}

if (Test-Path $faviconSource) {
  Copy-Item -Path $faviconSource -Destination (Join-Path $deploy "favicon.png") -Force
}

if (Test-Path $manifestSource) {
  Copy-Item -Path $manifestSource -Destination (Join-Path $deploy "manifest.json") -Force
}

if (Test-Path $apiSource) {
  Copy-Item -Path $apiSource -Destination (Join-Path $deploy "api") -Recurse -Force
}

Copy-Item -Path (Join-Path $root "vercel.json") -Destination (Join-Path $deploy "vercel.json") -Force

Write-Host "Build SEO listo en $deploy"
