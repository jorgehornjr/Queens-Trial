param([string]$ZigPath = "zig")
$ErrorActionPreference = "Stop"
$capeRoot = $PSScriptRoot
$capeOutput = Join-Path $capeRoot "bin/priest_cape.windows.x86_64.dll"
New-Item -ItemType Directory -Force (Join-Path $capeRoot "bin") | Out-Null
& $ZigPath cc -O3 -g0 -shared -target x86_64-windows-gnu (Join-Path $capeRoot "priest_cape.c") -I (Join-Path $capeRoot "vendor") -o $capeOutput
if ($LASTEXITCODE -ne 0) { throw "Cape solver compilation failed ($LASTEXITCODE)." }
Write-Output "Built $capeOutput"
