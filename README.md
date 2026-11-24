# Онлайн дэлгүүр — Өгөгдлийн сангийн систем (бие даалт)

VS Code дээр ажилладаг, **SSMS / SQL Server-тэй шууд холбогддог** жижиг онлайн дэлгүүр.
Хэрэглэгч нэвтрэх, бүртгүүлэх, бараа сагсанд хийх, захиалах бүх үйлдэл `ActivityLog` хүснэгтэд шууд бичигдэж, сайт дээр **Live лог** хэлбэрээр 4 секунд тутамд шинэчлэгдэж харагдана.

- Сервер: `GARID` (таны SSMS-ийн холбогдсон сервер)
- Сан: `OnlineShopDB`
- Локаль сайт: `http://localhost:5199`
- Static демо (локаль): `http://localhost:5199/demo/`
- GitHub Pages: `https://garid-dev.github.io/system/`

---

## Хэрхэн ажиллуулах (эхлээд үүнийг хийнэ үү)

1. VS Code нээгээд `File → Open Folder...` → **`C:\Users\dell\Documents\Default Project\OnlineShop\Web`** хавтсыг сонгоно.
2. Доод талын Terminal дээр бичнэ:

   ```
   dotnet run
   ```

3. Browser дээр **`http://localhost:5199`** нээнэ. (Энэ бичлэгийн үед сайт ажиллаж байна.)
4. Туршилтын нэвтрэх: **bold / bold123** эсвэл **admin / admin123**.
5. Барааны "`＋ Сагс`" дараад "`✅ Бараа захиалах`" дарна. Доорх **Live лог** хэсэгт `bold | ORDER | P002 | огноо/цаг` гарч ирнэ.
6. SSMS дээр **F5** дараад `OnlineShopDB → Tables → dbo.ActivityLog` → `SELECT TOP 20 * FROM dbo.ActivityLog` хийвэл мөн л харагдана.

---

## GitHub Pages дээр нийтлэх (SSMS руу үнэхээр бичдэг хувилбар)

GitHub Pages зөвхөн HTML/CSS/JS өгдөг тул C# код, SQL холболт тэнд ажиллахгүй. Тиймээс дараах бүтэцтэй:

```text
GitHub Pages (docs/)  →  Cloudflare tunnel  →  Локаль API (localhost:5199)  →  SQL Server GARID / OnlineShopDB
```

### Хийх алхам

1. **Терминал 1** — API асаана:
   ```
   cd "C:\Users\dell\Documents\Default Project\OnlineShop"
   powershell -ExecutionPolicy Bypass -File Deploy\start-api.ps1
   ```
2. **Терминал 2** — Cloudflare tunnel асаана:
   ```
   powershell -ExecutionPolicy Bypass -File Deploy\start-tunnel.ps1
   ```
3. Гарч ирсэн `https://xxxx.trycloudflare.com` хаягийг авч **Терминал 3** дээр бичнэ:
   ```
   powershell -ExecutionPolicy Bypass -File Deploy\set-api-url.ps1 -Url https://xxxx.trycloudflare.com
   ```
4. `https://garid-dev.github.io/system/` хуудсыг `Ctrl + F5` хийж шинэчилнэ.
   Эсвэл шууд ийм хаягаар нээж болно:
   ```
   https://garid-dev.github.io/system/?api=https://xxxx.trycloudflare.com
   ```
5. Захиалга хийгээд SSMS дээр шалгана:
   ```sql
   SELECT TOP 5 UserName, ActionCode, ProductCode, Details, AtTime
   FROM dbo.ActivityLog ORDER BY Id DESC;
   ```

Одоогийн ажиллаж байгаа tunnel: `https://sep-tions-blond-commitments.trycloudflare.com`  
(Quick tunnel тул дахин асаах бүрт хаяг өөрчлөгдөнө — өөрчлөгдсөн бол 3-р алхамыг дахин хийнэ үү.)

Дэлгэрэнгүй: [`Deploy\README.md`](Deploy/README.md).

> Анхааруулга: энэ нь хичээлийн demo. API бүх origin-оос хүсэлт авдаг (`AllowAnyOrigin`), мөн таны компьютер асаалттай байхад л ажиллана. Бодит системд named tunnel + жинхэнэ аюулгүй байдал шаардлагатай.

---

## Файлууд юу хийдэг вэ

| Хавтас / файл | Тайлбар |
|---|---|
| `Database\OnlineShop_Data.xlsx` | **1-р шалгуур** — Excel дээр үүсгэсэн өгөгдөл (3 хуудас: Users, Categories, Products) |
| `Database\Create-Excel.ps1` | Excel файлыг дахин үүсгэгч жижиг скрипт |
| `Database\OnlineShopDB.sql` | **2, 3, 4, 7-р шалгуур** — сан, хэрэглэгч/роль, хүснэгт, өгөгдөл, procedure/function/trigger |
| `Database\05_DataManipulation.sql` | **5-р шалгуур** — INSERT / UPDATE / DELETE жишээ |
| `Database\06_GroupingQueries.sql` | **6-р шалгуур** — GROUP BY, SUM, COUNT, дүгнэлт |
| `Database\06_QueryResults.txt` | 6-р запросуудын бодит үр дүн |
| `Database\08_BackupRestore.sql` | **8-р шалгуур** — BACKUP / RESTORE |
| `Database\Backups\OnlineShopDB.bak` | бэлэн нөөцлөлт (.bak файл) |
| `Database\Verify-ExcelVsSql.ps1` | Excel болон SQL-ийн өгөгдөл ижил эсэхийг шалгана |
| `Web\Program.cs` | Сайтыг `localhost:5199` дээр асаана |
| `Web\Db.cs` | **SQL Server руу шууд холболт** (2 арга: `Get()` унших, `Run()` бичих) |
| `Web\Pages\Index.cshtml(.cs)` | Нэвтрэх, бүртгүүлэх, бараа, сагс, захиалга |
| `Web\Pages\Log.cshtml(.cs)` | **Live лог** — хэн / ямар код / ямар бараа / хэзээ |
| `docs\index.html`, `docs\assets\*` | **GitHub Pages** хувилбар (статик frontend) |
| `Deploy\*.ps1`, `Deploy\README.md` | API + Cloudflare tunnel асаах, URL тохируулах заавар |

---

## 8 шалгуурын дагуу хийсэн зүйлс

### 1. Өгөгдөл үүсгэсэн байдал (Excel)
`OnlineShop_Data.xlsx` дотор 3 хуудас байна:

| Хуудас | Мөр | Агуулга |
|---|---|---|
| Users | 3 | admin, bold, saran |
| Categories | 4 | Утас, Компьютер, Хувцас, Ном |
| Products | 12 | P001…P012, нэр, үнэ, үлдэгдэл |

Хэрэв дахин үүсгэхийг хүсвэл PowerShell дээр:
```
powershell -ExecutionPolicy Bypass -File "C:\Users\dell\Documents\Default Project\OnlineShop\Database\Create-Excel.ps1"
```

### 2. Users and roles ( Connecting to SQL server)
`OnlineShopDB.sql` дотор:

```sql
CREATE ROLE [ShopReadWrite];
CREATE LOGIN [online_shop_login] WITH PASSWORD = N'Shop@12345', CHECK_POLICY = OFF;
CREATE USER [online_shop_user] FOR LOGIN [online_shop_login];
ALTER ROLE [ShopReadWrite] ADD MEMBER [online_shop_user];
ALTER ROLE [db_datareader]   ADD MEMBER [online_shop_user];
ALTER ROLE [db_datawriter]   ADD MEMBER [online_shop_user];
```

Сайт өөрөө Windows Authentication (`Server=GARID; ... Integrated Security=True`) ашиглаж шууд холбогдоно — `Web\Db.cs`-д байна.

SSMS-д шалгах:
```sql
SELECT name FROM sys.database_principals WHERE type = 'R';
SELECT name FROM sys.database_principals WHERE type = 'S';
```

### 3. Өгөгдлийн сангийн бүтэц
6 хүснэгт: `Users`, `Categories`, `Products`, `Orders`, `OrderItems`, `ActivityLog`.

- PRIMARY KEY: бүх хүснэгтэд `Id`
- FOREIGN KEY: 5 ширхэг (Products→Categories, Orders→Users, OrderItems→Orders/Products, Attempts гэх мэт биш)
- UNIQUE: `Users.Username`, `Categories.Name`, `Products.Code`
- CHECK: үнэ ≥ 0, үлдэгдэл ≥ 0, тоо > 0, роль Admin/Customer

### 4. Өгөгдлийг гажуудалгүй оруулсан байдал
Excel болон SQL-ийг мөр мөрөөр харьцуулсан:

```
OK   Users: 3 мөр Excel-тэй яг ижил
OK   Categories: 4 мөр Excel-тэй яг ижил
OK   Products: 12 мөр Excel-тэй яг ижил
ДҮГНЭЛТ: Өгөгдөл гажуудалгүй орсон байна.
```

Дахин шалгах:
```
powershell -ExecutionPolicy Bypass -File "C:\Users\dell\Documents\Default Project\OnlineShop\Database\Verify-ExcelVsSql.ps1"
```

### 5. Өгөгдөлтэй ажиллах (Data manipulation)
`05_DataManipulation.sql` дотор `INSERT`, `UPDATE`, `DELETE` жишээ бүгд бичигдсэн бөгөөд ажиллуулсан. Үр дүн `05_Result.txt`-д байна.

### 6. Query бичих (Grouping and summarizing)
`06_GroupingQueries.sql` дотор 5 запрос:

1. Ангилал тус бүрийн борлуулалт
2. Хэрэглэгч тус бүрийн захиалга (функц ашигласан)
3. Өдрөөр дүгнэх
4. Хамгийн их зарагдсан 5 бараа
5. Үйлдлийн кодоор лог дүгнэх

Үр дүн: `06_QueryResults.txt`.

### 7. Stored procedures, Functions and Triggers

| Төрөл | Нэр | Юу хийдэг |
|---|---|---|
| Procedure | `sp_RegisterUser` | Бүртгүүлэх + REGISTER лог |
| Procedure | `sp_LoginUser` | Нэвтрэх + LOGIN лог |
| Procedure | `sp_PlaceOrder` | Захиалга өгөх, үлдэгдэл хасах (transaction-тай) |
| Function | `fn_OrderTotal` | Захиалгын нийт дүн |
| Function | `fn_UserName` | Хэрэглэгчийн нэр |
| Trigger | `trg_OrderItem_Log` | Захиалга болмогц **ORDER** лог бичнэ |
| Trigger | `trg_Product_PriceLog` | Үнэ өөрчлөгдөхөд **PRICE** лог бичнэ |

### 8. Өгөгдлийн санг нөөцлөх, сэргээх
`08_BackupRestore.sql` ажиллуулсан:

- `BACKUP DATABASE ... TO DISK = '...\Database\Backups\OnlineShopDB.bak'`
- `RESTORE DATABASE OnlineShopDB_Restore ...` → 12 бараа, 6 лог мөр сэргэснийг шалгасан
- Туршилтын `OnlineShopDB_Restore` санг дараа нь устгасан, зөвхөн `.bak` үлдсэн.

---

## Live лог хэрхэн ажилладаг вэ

1. Сайт дээр нэвтрэх → `sp_LoginUser` → `ActivityLog` руу `LOGIN`.
2. Бараа захиалах → `sp_PlaceOrder` → `OrderItems` руу INSERT → **`trg_OrderItem_Log` trigger** ажиллаж `ORDER`, хэрэглэгч, барааны код, цаг бичнэ.
3. `Pages\Log.cshtml` 4 секунд тутамд `SELECT ... FROM ActivityLog ORDER BY Id DESC` хийж хүснэгтийг шинэчилнэ.

Ингэснээр **"ямар хэрэглэгч, ямар код, ямар бараа, хэзээ"** гэдэг мэдээлэл сайт дээр шууд харагдана.

---

## Анхаарах зүйлс

- Энэ бол сургалтын жишээ тул нууц үг хүснэгтэд энгийн хадгалагдсан (жинхэнэ системд hash хийх ёстой).
- Databases тал дээр өөрчлөлт харагдахгүй байвал SSMS дээр **F5** дарна уу.
- Санг дахин үүсгэхийг хүсвэл:
  ```
  sqlcmd -S GARID -E -C -f 65001 -i "C:\Users\dell\Documents\Default Project\OnlineShop\Database\OnlineShopDB.sql"
  ```
  (Дахин ажиллуулбал бүх өгөгдөл шинээр үүсэж, өмнөх захиалгууд устгагдана.)
