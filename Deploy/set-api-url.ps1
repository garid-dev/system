param(
    [Parameter(Mandatory = $true)]
    [string]$Url
)

$ErrorActionPreference = 'Stop'
# cloudflared-ийн гаргасан URL-ийг docs/assets/config.js руу бичнэ.
# Жишээ: .\set-api-url.ps1 -Url https://abcd-1234.trycloudflare.com

$api = $Url.Trim().TrimEnd('/')
if ($api -notmatch '^https?://') { throw "Буруу API хаяг: $api" }

$root   = Split-Path -Parent $PSScriptRoot
$config = Join-Path $root 'docs\assets\config.js'

$text = @"
// GitHub Pages хувилбарын API хаяг (cloudflared quick tunnel).
// Дахин асаасны дараа URL өөрчлөгдвөл энэ файлыг дахин шинэчилнэ үү.
window.SHOP_CONFIG = {
    apiBase: "$api"
};
"@

[System.IO.File]::WriteAllText(
    $config,
    $text,
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Host "API хаяг хадгалагдлаа: $api"
