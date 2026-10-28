param([switch]$Desktop)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'
$dataRoot = Join-Path $projectRoot '.local-data'
$bunRoot = Join-Path $toolsRoot 'bun\bun-windows-x64'
$nodeRoot = Join-Path $toolsRoot 'node'
$uvRoot = Join-Path $toolsRoot 'uv'

# Keep application data, model downloads, build caches, and scratch files on E:.
foreach ($path in @(
  (Join-Path $dataRoot 'app'),
  (Join-Path $dataRoot 'models'),
  (Join-Path $dataRoot 'hf'),
  (Join-Path $dataRoot 'torch'),
  (Join-Path $dataRoot 'temp'),
  (Join-Path $dataRoot 'appdata\roaming'),
  (Join-Path $dataRoot 'appdata\local'),
  (Join-Path $dataRoot 'cache\bun'),
  (Join-Path $dataRoot 'cache\electron'),
  (Join-Path $toolsRoot 'downloads')
)) {
  New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$env:PATH = "$bunRoot;$nodeRoot;$uvRoot;$env:PATH"
$env:OMNIVOICE_DATA_DIR = Join-Path $dataRoot 'app'
$env:OMNIVOICE_CACHE_DIR = Join-Path $dataRoot 'models'
$env:OMNIVOICE_ENV_FILE = Join-Path $dataRoot 'app\user.env'
$env:APPDATA = Join-Path $dataRoot 'appdata\roaming'
$env:LOCALAPPDATA = Join-Path $dataRoot 'appdata\local'
$env:XDG_CACHE_HOME = Join-Path $dataRoot 'cache'
$env:HF_HOME = Join-Path $dataRoot 'hf'
$env:HF_HUB_CACHE = Join-Path $dataRoot 'hf\hub'
$env:TORCH_HOME = Join-Path $dataRoot 'torch'
$env:UV_CACHE_DIR = Join-Path $dataRoot 'cache\uv'
$env:UV_PYTHON_INSTALL_DIR = Join-Path $toolsRoot 'python'
$env:BUN_INSTALL_CACHE_DIR = Join-Path $dataRoot 'cache\bun'
$env:ELECTRON_CACHE = Join-Path $dataRoot 'cache\electron'
$env:TEMP = Join-Path $dataRoot 'temp'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  throw "Bun is missing. Put bun.exe in $bunRoot, then run this script again."
}
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  throw "uv is missing. Put uv.exe in $uvRoot, then run this script again."
}

Set-Location $projectRoot
if (-not $Desktop) {
  Write-Host 'VoiceStudio browser UI: http://localhost:3901/'
  Write-Host 'API health: http://127.0.0.1:3900/health'
  & bun install
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  & bun scripts/clear-dev-ports.mjs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  & bun node_modules/concurrently/dist/bin/index.js -n api,fe -c green,cyan --kill-others-on-fail 'bun run dev:api' 'bun run dev:frontend'
} else {
  & bun run dev
}
exit $LASTEXITCODE
