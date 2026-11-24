$ErrorActionPreference = 'Stop'
# Cloudflare quick tunnel асааж, локаль API-г интернэтэд гаргана.
# Гарах URL нь дахин асаах бүрт өөрчлөгддөг.

$exe = Join-Path $PSScriptRoot 'cloudflared.exe'
if (-not (Test-Path $exe)) {
    throw "cloudflared.exe олдсонгүй. Эхлээд татаж авна уу."
}

& $exe tunnel --url http://localhost:5199
