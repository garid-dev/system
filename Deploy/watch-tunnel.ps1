$ErrorActionPreference = 'Stop'

# Auto-recovery watcher: GitHub Pages -> tunnel -> local API -> SQL Server.
# Every 60 seconds it checks the public URL from docs/assets/config.js.
# If the URL is down, it starts a fresh localhost.run tunnel, writes the new
# URL into the static site, bumps the asset cache version, and pushes to GitHub.
# Keep this script running while the computer is in use.

# Only one watcher may run at a time.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\OnlineShopWatchTunnel', [ref]$createdNew)
if (-not $createdNew) {
    Write-Host 'Watcher is already running.'
    exit 0
}

$root = Split-Path -Parent $PSScriptRoot
$config = Join-Path $root 'docs\assets\config.js'
$index = Join-Path $root 'docs\index.html'
$readmes = @((Join-Path $root 'README.md'), (Join-Path $root 'Deploy\README.md'))
$logDir = Join-Path $env:LOCALAPPDATA 'OnlineShopTunnel'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$tunnelOut = Join-Path $logDir 'tunnel-stdout.log'
$tunnelErr = Join-Path $logDir 'tunnel-stderr.log'
$watchLog = Join-Path $logDir 'watcher.log'
$key = Join-Path $env:USERPROFILE '.ssh\id_ed25519_shop'

function Write-Log {
    param([string]$Message)
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $watchLog -Value $line -Encoding UTF8
    Write-Host $line
}

function Get-CurrentUrl {
    $text = [System.IO.File]::ReadAllText($config, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($text, 'apiBase\s*:\s*"([^"]+)"')
    if ($m.Success) { return $m.Groups[1].Value.TrimEnd('/') }
    return $null
}

function Test-ApiHealth {
    param([string]$Url)
    if (-not $Url) { return $false }
    try {
        $r = Invoke-RestMethod -Uri ($Url + '/api/health') -TimeoutSec 12 -UseBasicParsing
        return ($r.ok -eq $true)
    } catch { return $false }
}

function Test-LocalApi {
    return (Test-ApiHealth 'http://localhost:5199')
}

function Start-LocalApi {
    $web = Join-Path $root 'Web'
    Start-Process -FilePath 'dotnet' -ArgumentList @('run') -WorkingDirectory $web -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $logDir 'api-stdout.log') `
        -RedirectStandardError (Join-Path $logDir 'api-stderr.log') | Out-Null
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        if (Test-LocalApi) { return $true }
    }
    return $false
}

function Stop-StaleTunnels {
    Get-CimInstance Win32_Process -Filter "name='ssh.exe'" | Where-Object {
        $_.CommandLine -match 'localhost\.run|serveo\.net'
    } | ForEach-Object {
        Write-Log "Stopping stale tunnel PID $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

function Start-NewTunnel {
    Stop-StaleTunnels
    Remove-Item $tunnelOut, $tunnelErr -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $key)) { throw "SSH key missing: $key" }

    $argLine = '-T -i "{0}" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -R 80:127.0.0.1:5199 localhost.run' -f $key
    Start-Process -FilePath 'ssh.exe' -ArgumentList $argLine -WindowStyle Hidden `
        -RedirectStandardOutput $tunnelOut -RedirectStandardError $tunnelErr | Out-Null

    $newUrl = $null
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Seconds 2
        if (Test-Path $tunnelErr) {
            $text = [System.IO.File]::ReadAllText($tunnelErr)
            $found = [regex]::Matches($text, 'tunneled with tls termination, https://([a-z0-9]+\.app\.lhr\.life)')
            if ($found.Count -gt 0) {
                $newUrl = 'https://' + $found[$found.Count - 1].Groups[1].Value
                break
            }
        }
    }
    if (-not $newUrl) { throw 'No tunnel URL found in ssh log' }

    for ($i = 0; $i -lt 15; $i++) {
        if (Test-ApiHealth $newUrl) { return $newUrl }
        Start-Sleep -Seconds 3
    }
    throw "Tunnel $newUrl is not healthy"
}

function Update-SiteFiles {
    param([string]$Url, [string]$OldUrl)

    $utf8 = New-Object System.Text.UTF8Encoding($false)

    $configText = [System.IO.File]::ReadAllText($config, [System.Text.Encoding]::UTF8)
    $configText = [regex]::Replace($configText, 'apiBase\s*:\s*"[^"]+"', ('apiBase: "{0}"' -f $Url))
    [System.IO.File]::WriteAllText($config, $configText, $utf8)

    foreach ($p in $readmes) {
        if (-not (Test-Path $p)) { continue }
        $t = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
        if ($OldUrl) { $t = $t.Replace($OldUrl, $Url) }
        $t = [regex]::Replace($t, 'https://[a-z0-9]+\.app\.lhr\.life', $Url)
        [System.IO.File]::WriteAllText($p, $t, $utf8)
    }

    # Bump ?v=N so browsers reload config.js after the URL changes.
    $idx = [System.IO.File]::ReadAllText($index, [System.Text.Encoding]::UTF8)
    $versions = @([regex]::Matches($idx, '\?v=(\d+)') | ForEach-Object { [int]$_.Groups[1].Value })
    $next = 1
    if ($versions.Count -gt 0) { $next = ($versions | Measure-Object -Maximum).Maximum + 1 }
    $idx = [regex]::Replace($idx, '\?v=\d+', ('?v={0}' -f $next))
    [System.IO.File]::WriteAllText($index, $idx, $utf8)
    return $next
}

function Publish-Change {
    param([string]$Message)
    Push-Location $root
    try {
        git add docs/assets/config.js docs/index.html README.md Deploy/README.md 2>&1 | Out-Null
        $st = git status --porcelain
        if (-not $st) { Write-Log 'No file changes to commit'; return $true }

        $out = git commit -m $Message 2>&1
        Write-Log ('git commit: ' + ($out -join ' | '))
        if ($LASTEXITCODE -ne 0) { return $false }

        $out = git push origin main 2>&1
        Write-Log ('git push: ' + ($out -join ' | '))
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

function Recover {
    Write-Log 'Recovery started'
    if (-not (Test-LocalApi)) {
        Write-Log 'Local API is down; starting it'
        if (-not (Start-LocalApi)) { throw 'Local API could not be started' }
    }
    $old = Get-CurrentUrl
    $new = Start-NewTunnel
    Write-Log "New tunnel URL: $new"
    $v = Update-SiteFiles -Url $new -OldUrl $old
    Write-Log "Asset cache version bumped to v=$v"
    if (-not (Publish-Change "Auto-update tunnel URL to $new")) {
        Write-Log 'Git push failed; will retry next cycle'
    } else {
        Write-Log 'GitHub Pages updated'
    }
}

Write-Log "Watcher started (PID $PID)"
while ($true) {
    try {
        $url = Get-CurrentUrl
        if (Test-ApiHealth $url) {
            Write-Log "OK $url"
        } else {
            Write-Log "DOWN $url"
            Recover
        }
    } catch {
        Write-Log ('ERROR ' + $_.Exception.Message)
    }
    Start-Sleep -Seconds 60
}
