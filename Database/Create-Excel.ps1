# 1. ӨГӨГДӨЛ ҮҮСГЭСЭН БАЙДАЛ (Excel)
# Энэ скрипт OnlineShop_Data.xlsx файлыг 3 хуудстайгаар үүсгэнэ.
# Доторх өгөгдөл OnlineShopDB.sql руу яг ижил орсон болно.

$ErrorActionPreference = 'Stop'
$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$xlsx   = Join-Path $folder 'OnlineShop_Data.xlsx'

$users = @(
    [pscustomobject]@{ Username='admin'; Password='admin123'; FullName='Админ'; Email='admin@shop.mn'; Role='Admin' },
    [pscustomobject]@{ Username='bold';  Password='bold123';  FullName='Болд';  Email='bold@shop.mn';  Role='Customer' },
    [pscustomobject]@{ Username='saran'; Password='saran123'; FullName='Сараа'; Email='saran@shop.mn'; Role='Customer' }
)

$categories = @(
    [pscustomobject]@{ Id=1; Name='Утас' },
    [pscustomobject]@{ Id=2; Name='Компьютер' },
    [pscustomobject]@{ Id=3; Name='Хувцас' },
    [pscustomobject]@{ Id=4; Name='Ном' }
)

$products = @(
    [pscustomobject]@{ Id=1;  Code='P001'; Name='iPhone 15';                CategoryId=1; Price=25000000; Stock=5;  Description='Apple утас' },
    [pscustomobject]@{ Id=2;  Code='P002'; Name='Samsung Galaxy S24';       CategoryId=1; Price=22000000; Stock=8;  Description='Android утас' },
    [pscustomobject]@{ Id=3;  Code='P003'; Name='Xiaomi 14';                CategoryId=1; Price=12000000; Stock=10; Description='Android утас' },
    [pscustomobject]@{ Id=4;  Code='P004'; Name='Dell XPS 13';              CategoryId=2; Price=32000000; Stock=3;  Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=5;  Code='P005'; Name='Lenovo ThinkPad';          CategoryId=2; Price=26000000; Stock=4;  Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=6;  Code='P006'; Name='HP Pavilion';              CategoryId=2; Price=18000000; Stock=6;  Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=7;  Code='P007'; Name='Монгол хувцас';            CategoryId=3; Price=150000;   Stock=20; Description='Үндэсний хувцас' },
    [pscustomobject]@{ Id=8;  Code='P008'; Name='Хүрэм';                    CategoryId=3; Price=320000;   Stock=15; Description='Өвлийн хүрэм' },
    [pscustomobject]@{ Id=9;  Code='P009'; Name='Парка';                    CategoryId=3; Price=450000;   Stock=12; Description='Өвлийн парка' },
    [pscustomobject]@{ Id=10; Code='P010'; Name='Programming 101';          CategoryId=4; Price=45000;    Stock=30; Description='Програмчлалын ном' },
    [pscustomobject]@{ Id=11; Code='P011'; Name='Өгөгдлийн сангийн систем'; CategoryId=4; Price=55000;    Stock=25; Description='SQL ном' },
    [pscustomobject]@{ Id=12; Code='P012'; Name='Математикийн ном';         CategoryId=4; Price=38000;    Stock=40; Description='Математик' }
)

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$firstSheet = $wb.Worksheets.Item(1)

function Fill-Sheet([string]$name, [string[]]$headers, [string[]]$props, $rows) {
    if ($name -eq 'Users') {
        $ws = $firstSheet
    } else {
        $ws = $wb.Worksheets.Add()
    }
    $ws.Name = $name
    for ($c = 0; $c -lt $headers.Count; $c++) {
        $ws.Cells.Item(1, $c + 1).Value2 = $headers[$c]
        $ws.Cells.Item(1, $c + 1).Font.Bold = $true
        $ws.Cells.Item(1, $c + 1).Interior.Color = 15790320
    }
    for ($r = 0; $r -lt $rows.Count; $r++) {
        for ($c = 0; $c -lt $props.Count; $c++) {
            $value = $rows[$r].($props[$c])
            $cell = $ws.Cells.Item($r + 2, $c + 1)
            $cell.Value2 = [string]$value
        }
    }
    $ws.Columns.AutoFit() | Out-Null
    return $ws
}

Fill-Sheet 'Users'      @('Username','Password','FullName','Email','Role') @('Username','Password','FullName','Email','Role') $users | Out-Null
Fill-Sheet 'Categories' @('Id','Name') @('Id','Name') $categories | Out-Null
Fill-Sheet 'Products'   @('Id','Code','Name','CategoryId','Price','Stock','Description') @('Id','Code','Name','CategoryId','Price','Stock','Description') $products | Out-Null

$wb.SaveAs($xlsx, 51)
$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Host "Excel бэлэн: $xlsx"
Write-Host "Хуудас: Users ($($users.Count)), Categories ($($categories.Count)), Products ($($products.Count))"
