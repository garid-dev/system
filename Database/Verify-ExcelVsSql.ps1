# 4. ӨГӨГДӨЛ ГАЖУУДАЛГУЙ ОРУУЛСАН ЭСЭХИЙГ ШАЛГАХ
# Excel файлыг уншиж, SQL Server дээрх өгөгдөлтэй мөр мөрөөр харьцуулна.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$xlsx   = Join-Path $folder 'OnlineShop_Data.xlsx'
$sqlcmd = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\180\Tools\Binn\SQLCMD.EXE'

function SqlRows([string]$query) {
    & $sqlcmd -S GARID -E -C -d OnlineShopDB -f 65001 -W -h -1 -s '|' -Q $query 2>&1 |
        Where-Object { $_ -and $_ -notmatch '^\s*[-]+\s*$' -and $_ -notmatch 'rows affected' }
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Open($xlsx, 0, $true)

function SheetRows([string]$name, [int[]]$cols) {
    $ws = $wb.Worksheets.Item($name)
    $last = $ws.UsedRange.Rows.Count
    $result = @()
    for ($r = 2; $r -le $last; $r++) {
        $parts = @()
        foreach ($c in $cols) { $parts += [string]$ws.Cells.Item($r, $c).Value2 }
        if ($parts[0]) { $result += ($parts -join '|') }
    }
    return $result
}

$exUsers      = SheetRows 'Users'      @(1,2,3,4,5)
$exCategories = SheetRows 'Categories' @(1,2)
$exProducts   = SheetRows 'Products'   @(2,3,4,5)   # Code, Name, CategoryId, Price

$sqlUsers      = SqlRows "SELECT Username,Password,FullName,Email,Role FROM dbo.Users ORDER BY Id;"
$sqlCategories = SqlRows "SELECT Id,Name FROM dbo.Categories ORDER BY Id;"
$sqlProducts   = SqlRows "SELECT Code,Name,CategoryId,Price FROM dbo.Products ORDER BY Id;"

# Үнийг "25000000" ба "25000000.00" хэлбэрээс нэг хэлбэрт оруулна.
function Norm([string[]]$rows) {
    $rows | ForEach-Object {
        $parts = $_ -split '\|'
        if ($parts.Count -eq 4) {
            $parts[3] = ([decimal]$parts[3]).ToString('0.00', [Globalization.CultureInfo]::InvariantCulture)
        }
        $parts -join '|'
    }
}
$exProducts   = @(Norm $exProducts)
$sqlProducts  = @(Norm $sqlProducts)

$ok = $true
foreach ($pair in @(
    @{ Name='Users';      Ex=$exUsers;      Db=$sqlUsers },
    @{ Name='Categories'; Ex=$exCategories; Db=$sqlCategories },
    @{ Name='Products';   Ex=$exProducts;   Db=$sqlProducts }
)) {
    $diff = @(Compare-Object $pair.Ex $pair.Db)
    if ($diff.Count -eq 0) {
        Write-Host ("OK   {0}: {1} мөр Excel-тэй яг ижил" -f $pair.Name, $pair.Ex.Count)
    } else {
        $ok = $false
        Write-Host ("ALDA {0}: Excel {1} мөр, SQL {2} мөр" -f $pair.Name, $pair.Ex.Count, $pair.Db.Count)
        $diff | Format-Table -AutoSize | Out-String | Write-Host
    }
}

$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

if (-not $ok) { exit 1 }
Write-Host "ДҮГНЭЛТ: Өгөгдөл гажуудалгүй орсон байна."
