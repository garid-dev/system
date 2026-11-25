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
    [pscustomobject]@{ Id=4; Name='Ном' },
    [pscustomobject]@{ Id=5; Name='Гэр ахуй' },
    [pscustomobject]@{ Id=6; Name='Спорт' },
    [pscustomobject]@{ Id=7; Name='Гоо сайхан' },
    [pscustomobject]@{ Id=8; Name='Хүүхэд' },
    [pscustomobject]@{ Id=9; Name='Хоол унд' },
    [pscustomobject]@{ Id=10; Name='Автомашин' }
)

$products = @(
    [pscustomobject]@{ Id=1; Code='P001'; Name='iPhone 15'; CategoryId=1; Price=25000000; Stock=20; Description='Apple утас' },
    [pscustomobject]@{ Id=2; Code='P002'; Name='Samsung Galaxy S24'; CategoryId=1; Price=22000000; Stock=8; Description='Android утас' },
    [pscustomobject]@{ Id=3; Code='P003'; Name='Xiaomi 14'; CategoryId=1; Price=12000000; Stock=10; Description='Android утас' },
    [pscustomobject]@{ Id=4; Code='P004'; Name='Dell XPS 13'; CategoryId=2; Price=32000000; Stock=3; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=5; Code='P005'; Name='Lenovo ThinkPad'; CategoryId=2; Price=26000000; Stock=4; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=6; Code='P006'; Name='HP Pavilion'; CategoryId=2; Price=18000000; Stock=6; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=7; Code='P007'; Name='Монгол хувцас'; CategoryId=3; Price=150000; Stock=20; Description='Үндэсний хувцас' },
    [pscustomobject]@{ Id=8; Code='P008'; Name='Хүрэм'; CategoryId=3; Price=320000; Stock=15; Description='Өвлийн хүрэм' },
    [pscustomobject]@{ Id=9; Code='P009'; Name='Парка'; CategoryId=3; Price=450000; Stock=12; Description='Өвлийн парка' },
    [pscustomobject]@{ Id=10; Code='P010'; Name='Programming 101'; CategoryId=4; Price=45000; Stock=30; Description='Програмчлалын ном' },
    [pscustomobject]@{ Id=11; Code='P011'; Name='Өгөгдлийн сангийн систем'; CategoryId=4; Price=55000; Stock=25; Description='SQL ном' },
    [pscustomobject]@{ Id=12; Code='P012'; Name='Математикийн ном'; CategoryId=4; Price=38000; Stock=40; Description='Математик' },
    [pscustomobject]@{ Id=13; Code='P013'; Name='Google Pixel 8'; CategoryId=1; Price=19900000; Stock=6; Description='Android утас' },
    [pscustomobject]@{ Id=14; Code='P014'; Name='OnePlus 12'; CategoryId=1; Price=17500000; Stock=5; Description='Android утас' },
    [pscustomobject]@{ Id=15; Code='P015'; Name='iPhone 13'; CategoryId=1; Price=15000000; Stock=9; Description='Apple утас' },
    [pscustomobject]@{ Id=16; Code='P016'; Name='Samsung Galaxy A55'; CategoryId=1; Price=7500000; Stock=14; Description='Android утас' },
    [pscustomobject]@{ Id=17; Code='P017'; Name='Nokia G42'; CategoryId=1; Price=4500000; Stock=12; Description='Android утас' },
    [pscustomobject]@{ Id=18; Code='P018'; Name='Xiaomi Redmi Note 13'; CategoryId=1; Price=5200000; Stock=16; Description='Android утас' },
    [pscustomobject]@{ Id=19; Code='P019'; Name='MacBook Air M3'; CategoryId=2; Price=34000000; Stock=4; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=20; Code='P020'; Name='Asus Zenbook 14'; CategoryId=2; Price=28000000; Stock=5; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=21; Code='P021'; Name='Acer Aspire 5'; CategoryId=2; Price=19000000; Stock=7; Description='Зөөврийн компьютер' },
    [pscustomobject]@{ Id=22; Code='P022'; Name='MSI Katana 15'; CategoryId=2; Price=26000000; Stock=3; Description='Тоглоомын компьютер' },
    [pscustomobject]@{ Id=23; Code='P023'; Name='iMac 24'; CategoryId=2; Price=42000000; Stock=2; Description='Ширээний компьютер' },
    [pscustomobject]@{ Id=24; Code='P024'; Name='Dell OptiPlex 7010'; CategoryId=2; Price=22000000; Stock=6; Description='Ширээний компьютер' },
    [pscustomobject]@{ Id=25; Code='P025'; Name='LG UltraGear монитор'; CategoryId=2; Price=8500000; Stock=9; Description='Монитор' },
    [pscustomobject]@{ Id=26; Code='P026'; Name='Logitech MX Master 3'; CategoryId=2; Price=450000; Stock=20; Description='Хулгана' },
    [pscustomobject]@{ Id=27; Code='P027'; Name='Жинсэн өмд'; CategoryId=3; Price=120000; Stock=25; Description='Өмд' },
    [pscustomobject]@{ Id=28; Code='P028'; Name='Цамц'; CategoryId=3; Price=85000; Stock=30; Description='Цамц' },
    [pscustomobject]@{ Id=29; Code='P029'; Name='Сүлжмэл цамц'; CategoryId=3; Price=180000; Stock=18; Description='Цамц' },
    [pscustomobject]@{ Id=30; Code='P030'; Name='Спортын хувцас'; CategoryId=3; Price=220000; Stock=15; Description='Спортын хувцас' },
    [pscustomobject]@{ Id=31; Code='P031'; Name='Малгай'; CategoryId=3; Price=45000; Stock=40; Description='Малгай' },
    [pscustomobject]@{ Id=32; Code='P032'; Name='Оймс'; CategoryId=3; Price=15000; Stock=60; Description='Оймс' },
    [pscustomobject]@{ Id=33; Code='P033'; Name='SQL Server сургалт'; CategoryId=4; Price=65000; Stock=22; Description='Өгөгдлийн сангийн ном' },
    [pscustomobject]@{ Id=34; Code='P034'; Name='C# програмчлал'; CategoryId=4; Price=72000; Stock=18; Description='Програмчлалын ном' },
    [pscustomobject]@{ Id=35; Code='P035'; Name='Веб хөгжүүлэлт'; CategoryId=4; Price=68000; Stock=20; Description='Веб ном' },
    [pscustomobject]@{ Id=36; Code='P036'; Name='Монгол түүх'; CategoryId=4; Price=52000; Stock=26; Description='Түүх' },
    [pscustomobject]@{ Id=37; Code='P037'; Name='Бизнесийн удирдлага'; CategoryId=4; Price=78000; Stock=14; Description='Бизнес' },
    [pscustomobject]@{ Id=38; Code='P038'; Name='Кофе машин'; CategoryId=5; Price=1200000; Stock=8; Description='Гэр ахуй' },
    [pscustomobject]@{ Id=39; Code='P039'; Name='Тоос сорогч'; CategoryId=5; Price=950000; Stock=10; Description='Гэр ахуй' },
    [pscustomobject]@{ Id=40; Code='P040'; Name='Шалны сүү'; CategoryId=5; Price=450000; Stock=15; Description='Гэр ахуй' },
    [pscustomobject]@{ Id=41; Code='P041'; Name='Гал тогооны хутга'; CategoryId=5; Price=180000; Stock=20; Description='Гал тогоо' },
    [pscustomobject]@{ Id=42; Code='P042'; Name='Гантель'; CategoryId=6; Price=350000; Stock=12; Description='Фитнес' },
    [pscustomobject]@{ Id=43; Code='P043'; Name='Йогын дэвсгэр'; CategoryId=6; Price=120000; Stock=25; Description='Фитнес' },
    [pscustomobject]@{ Id=44; Code='P044'; Name='Хөл бөмбөг'; CategoryId=6; Price=180000; Stock=18; Description='Спорт' },
    [pscustomobject]@{ Id=45; Code='P045'; Name='Унадаг дугуй'; CategoryId=6; Price=1800000; Stock=6; Description='Спорт' },
    [pscustomobject]@{ Id=46; Code='P046'; Name='Шампунь'; CategoryId=7; Price=45000; Stock=40; Description='Гоо сайхан' },
    [pscustomobject]@{ Id=47; Code='P047'; Name='Нүүрний тос'; CategoryId=7; Price=120000; Stock=22; Description='Гоо сайхан' },
    [pscustomobject]@{ Id=48; Code='P048'; Name='Хүүхдийн тоглоом'; CategoryId=8; Price=85000; Stock=30; Description='Тоглоом' },
    [pscustomobject]@{ Id=49; Code='P049'; Name='Хүүхдийн ном'; CategoryId=8; Price=35000; Stock=35; Description='Хүүхдийн ном' },
    [pscustomobject]@{ Id=50; Code='P050'; Name='Кофены шош'; CategoryId=9; Price=65000; Stock=50; Description='Ундаа' },
    [pscustomobject]@{ Id=51; Code='P051'; Name='Машины дугуй'; CategoryId=10; Price=350000; Stock=14; Description='Автомашин' },
    [pscustomobject]@{ Id=52; Code='P052'; Name='Машины тос'; CategoryId=10; Price=85000; Stock=30; Description='Автомашин' }
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
