$ErrorActionPreference = 'Stop'
# Энэ скрипт API-г http://localhost:5199 дээр асаана.
# SQL Server GARID асаалттай байх ёстой.

$root = Split-Path -Parent $PSScriptRoot
$web  = Join-Path $root 'Web'

# Хуучин сервер асаалттай байвал зогсооно (порт давхардахгүйн тулд).
$listeners = Get-NetTCPConnection -LocalPort 5199 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $listeners) {
    Write-Host "5199 порт дээрх хуучин процесс зогсож байна: $($c.OwningProcess)"
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
}

Push-Location $web
try {
    dotnet build
    if ($LASTEXITCODE -ne 0) { throw "dotnet build амжилтгүй боллоо" }
    dotnet run --no-build
}
finally {
    Pop-Location
}
