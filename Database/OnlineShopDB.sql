/* =========================================================================
   OnlineShopDB  —  "Өгөгдлийн сангийн систем" бие даалт
   Сервер: GARID  (таны SSMS-ийн холбогдсон сервер)
   Энэ нэг файлд 2..7-р шалгуур бүгд байна.
   ========================================================================= */

/* ---------- 0. Сан шинээр үүсгэх ---------- */
IF DB_ID(N'OnlineShopDB') IS NOT NULL
    ALTER DATABASE [OnlineShopDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
IF DB_ID(N'OnlineShopDB') IS NOT NULL
    DROP DATABASE [OnlineShopDB];
GO
CREATE DATABASE [OnlineShopDB];
GO
USE [OnlineShopDB];
GO
PRINT N'0. OnlineShopDB сан бэлэн боллоо.';
GO

/* =========================================================================
   2. USERS AND ROLES  (Connecting to SQL server)
   ========================================================================= */
CREATE ROLE [ShopReadWrite];
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [ShopReadWrite];
GRANT EXECUTE ON SCHEMA::dbo TO [ShopReadWrite];
GO

-- SQL Server түвшинд login үүсгээд, сангийн дотор user болгож рольд нэмнэ.
IF SUSER_ID(N'online_shop_login') IS NULL
    EXEC(N'CREATE LOGIN [online_shop_login] WITH PASSWORD = N''Shop@12345'', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF');
GO
IF USER_ID(N'online_shop_user') IS NULL
    EXEC(N'CREATE USER [online_shop_user] FOR LOGIN [online_shop_login]');
GO
ALTER ROLE [ShopReadWrite] ADD MEMBER [online_shop_user];
ALTER ROLE [db_datareader]   ADD MEMBER [online_shop_user];
ALTER ROLE [db_datawriter]   ADD MEMBER [online_shop_user];
GO
PRINT N'2. Login / User / Role бэлэн: online_shop_login -> online_shop_user -> ShopReadWrite';
GO

/* =========================================================================
   3. ӨГӨГДЛИЙН САНГИЙН БҮТЭЦ  (Tables + харилцаа + хязгаарлалт)
   ========================================================================= */
CREATE TABLE dbo.Users (
    Id        INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    Username  NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
    Password  NVARCHAR(100) NOT NULL,
    FullName  NVARCHAR(100) NOT NULL,
    Email     NVARCHAR(100) NOT NULL,
    Role      NVARCHAR(20)  NOT NULL DEFAULT(N'Customer')
              CONSTRAINT CK_Users_Role CHECK (Role IN (N'Admin', N'Customer')),
    CreatedAt DATETIME NOT NULL DEFAULT(GETDATE())
);
GO

CREATE TABLE dbo.Categories (
    Id   INT IDENTITY(1,1) CONSTRAINT PK_Categories PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL CONSTRAINT UQ_Categories_Name UNIQUE
);
GO

CREATE TABLE dbo.Products (
    Id          INT IDENTITY(1,1) CONSTRAINT PK_Products PRIMARY KEY,
    Code        NVARCHAR(20)  NOT NULL CONSTRAINT UQ_Products_Code UNIQUE,
    Name        NVARCHAR(100) NOT NULL,
    CategoryId  INT NOT NULL CONSTRAINT FK_Products_Categories REFERENCES dbo.Categories(Id),
    Price       DECIMAL(18,2) NOT NULL CONSTRAINT CK_Products_Price CHECK (Price >= 0),
    Stock       INT NOT NULL CONSTRAINT CK_Products_Stock CHECK (Stock >= 0),
    Description NVARCHAR(200) NOT NULL DEFAULT(N'')
);
GO

CREATE TABLE dbo.Orders (
    Id        INT IDENTITY(1,1) CONSTRAINT PK_Orders PRIMARY KEY,
    UserId    INT NOT NULL CONSTRAINT FK_Orders_Users REFERENCES dbo.Users(Id),
    OrderDate DATETIME NOT NULL DEFAULT(GETDATE()),
    Status    NVARCHAR(20) NOT NULL DEFAULT(N'Баталгаажсан')
);
GO

CREATE TABLE dbo.OrderItems (
    Id        INT IDENTITY(1,1) CONSTRAINT PK_OrderItems PRIMARY KEY,
    OrderId   INT NOT NULL CONSTRAINT FK_OrderItems_Orders REFERENCES dbo.Orders(Id),
    ProductId INT NOT NULL CONSTRAINT FK_OrderItems_Products REFERENCES dbo.Products(Id),
    Quantity  INT NOT NULL CONSTRAINT CK_OrderItems_Qty CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL
);
GO

-- Live лог: хэн, ямар код, ямар бараа, хэзээ
CREATE TABLE dbo.ActivityLog (
    Id          INT IDENTITY(1,1) CONSTRAINT PK_ActivityLog PRIMARY KEY,
    UserName    NVARCHAR(50)  NOT NULL,
    ActionCode  NVARCHAR(20)  NOT NULL,   -- LOGIN / REGISTER / ORDER / PRICE
    ProductCode NVARCHAR(20)  NULL,       -- аль барааны код
    Details     NVARCHAR(200) NULL,
    AtTime      DATETIME NOT NULL DEFAULT(GETDATE())
);
GO
CREATE INDEX IX_ActivityLog_AtTime ON dbo.ActivityLog(AtTime DESC);
GO
PRINT N'3. 6 хүснэгт, 5 foreign key, 6 check/unique хязгаарлалт үүслээ.';
GO

/* =========================================================================
   4. ӨГӨГДӨЛ ОРУУЛАХ  (Excel файлаас авсан өгөгдөл — Create-Excel.ps1)
   ========================================================================= */
SET IDENTITY_INSERT dbo.Users ON;
INSERT INTO dbo.Users (Id, Username, Password, FullName, Email, Role) VALUES
 (1, N'admin', N'admin123', N'Админ', N'admin@shop.mn', N'Admin'),
 (2, N'bold',  N'bold123',  N'Болд',  N'bold@shop.mn',  N'Customer'),
 (3, N'saran', N'saran123', N'Сараа', N'saran@shop.mn', N'Customer');
SET IDENTITY_INSERT dbo.Users OFF;
GO

SET IDENTITY_INSERT dbo.Categories ON;
INSERT INTO dbo.Categories (Id, Name) VALUES
  (1, N'Утас'),
  (2, N'Компьютер'),
  (3, N'Хувцас'),
  (4, N'Ном'),
  (5, N'Гэр ахуй'),
  (6, N'Спорт'),
  (7, N'Гоо сайхан'),
  (8, N'Хүүхэд'),
  (9, N'Хоол унд'),
  (10, N'Автомашин');
SET IDENTITY_INSERT dbo.Categories OFF;
GO

SET IDENTITY_INSERT dbo.Products ON;
INSERT INTO dbo.Products (Id, Code, Name, CategoryId, Price, Stock, Description) VALUES
  (1, N'P001', N'iPhone 15', 1, 25000000.00, 20, N'Apple утас'),
  (2, N'P002', N'Samsung Galaxy S24', 1, 22000000.00, 8, N'Android утас'),
  (3, N'P003', N'Xiaomi 14', 1, 12000000.00, 10, N'Android утас'),
  (4, N'P004', N'Dell XPS 13', 2, 32000000.00, 3, N'Зөөврийн компьютер'),
  (5, N'P005', N'Lenovo ThinkPad', 2, 26000000.00, 4, N'Зөөврийн компьютер'),
  (6, N'P006', N'HP Pavilion', 2, 18000000.00, 6, N'Зөөврийн компьютер'),
  (7, N'P007', N'Монгол хувцас', 3, 150000.00, 20, N'Үндэсний хувцас'),
  (8, N'P008', N'Хүрэм', 3, 320000.00, 15, N'Өвлийн хүрэм'),
  (9, N'P009', N'Парка', 3, 450000.00, 12, N'Өвлийн парка'),
  (10, N'P010', N'Programming 101', 4, 45000.00, 30, N'Програмчлалын ном'),
  (11, N'P011', N'Өгөгдлийн сангийн систем', 4, 55000.00, 25, N'SQL ном'),
  (12, N'P012', N'Математикийн ном', 4, 38000.00, 40, N'Математик'),
  (13, N'P013', N'Google Pixel 8', 1, 19900000.00, 6, N'Android утас'),
  (14, N'P014', N'OnePlus 12', 1, 17500000.00, 5, N'Android утас'),
  (15, N'P015', N'iPhone 13', 1, 15000000.00, 9, N'Apple утас'),
  (16, N'P016', N'Samsung Galaxy A55', 1, 7500000.00, 14, N'Android утас'),
  (17, N'P017', N'Nokia G42', 1, 4500000.00, 12, N'Android утас'),
  (18, N'P018', N'Xiaomi Redmi Note 13', 1, 5200000.00, 16, N'Android утас'),
  (19, N'P019', N'MacBook Air M3', 2, 34000000.00, 4, N'Зөөврийн компьютер'),
  (20, N'P020', N'Asus Zenbook 14', 2, 28000000.00, 5, N'Зөөврийн компьютер'),
  (21, N'P021', N'Acer Aspire 5', 2, 19000000.00, 7, N'Зөөврийн компьютер'),
  (22, N'P022', N'MSI Katana 15', 2, 26000000.00, 3, N'Тоглоомын компьютер'),
  (23, N'P023', N'iMac 24', 2, 42000000.00, 2, N'Ширээний компьютер'),
  (24, N'P024', N'Dell OptiPlex 7010', 5, 22000000.00, 6, N'Гэрийн ширээний компьютер'),
  (25, N'P025', N'LG UltraGear монитор', 2, 8500000.00, 9, N'Монитор'),
  (26, N'P026', N'Logitech MX Master 3', 2, 450000.00, 20, N'Хулгана'),
  (27, N'P027', N'Жинсэн өмд', 3, 120000.00, 25, N'Өмд'),
  (28, N'P028', N'Цамц', 3, 85000.00, 30, N'Цамц'),
  (29, N'P029', N'Сүлжмэл цамц', 3, 180000.00, 18, N'Цамц'),
  (30, N'P030', N'Спортын хувцас', 3, 220000.00, 15, N'Спортын хувцас'),
  (31, N'P031', N'Малгай', 3, 45000.00, 40, N'Малгай'),
  (32, N'P032', N'Оймс', 3, 15000.00, 60, N'Оймс'),
  (33, N'P033', N'SQL Server сургалт', 4, 65000.00, 22, N'Өгөгдлийн сангийн ном'),
  (34, N'P034', N'C# програмчлал', 4, 72000.00, 18, N'Програмчлалын ном'),
  (35, N'P035', N'Веб хөгжүүлэлт', 4, 68000.00, 20, N'Веб ном'),
  (36, N'P036', N'Монгол түүх', 4, 52000.00, 26, N'Түүх'),
  (37, N'P037', N'Бизнесийн удирдлага', 4, 78000.00, 14, N'Бизнес'),
  (38, N'P038', N'Кофе машин', 5, 1200000.00, 8, N'Гэр ахуй'),
  (39, N'P039', N'Тоос сорогч', 5, 950000.00, 10, N'Гэр ахуй'),
  (40, N'P040', N'Шалны сүү', 5, 450000.00, 15, N'Гэр ахуй'),
  (41, N'P041', N'Гал тогооны хутга', 5, 180000.00, 20, N'Гал тогоо'),
  (42, N'P042', N'Гантель', 6, 350000.00, 12, N'Фитнес'),
  (43, N'P043', N'Йогын дэвсгэр', 6, 120000.00, 25, N'Фитнес'),
  (44, N'P044', N'Хөл бөмбөг', 6, 180000.00, 18, N'Спорт'),
  (45, N'P045', N'Унадаг дугуй', 6, 1800000.00, 6, N'Спорт'),
  (46, N'P046', N'Шампунь', 7, 45000.00, 40, N'Гоо сайхан'),
  (47, N'P047', N'Нүүрний тос', 7, 120000.00, 22, N'Гоо сайхан'),
  (48, N'P048', N'Хүүхдийн тоглоом', 8, 85000.00, 30, N'Тоглоом'),
  (49, N'P049', N'Хүүхдийн ном', 8, 35000.00, 35, N'Хүүхдийн ном'),
  (50, N'P050', N'Кофены шош', 9, 65000.00, 50, N'Ундаа'),
  (51, N'P051', N'Машины дугуй', 10, 350000.00, 14, N'Автомашин'),
  (52, N'P052', N'Машины тос', 10, 85000.00, 30, N'Автомашин'),
  (53, N'P053', N'Samsung Galaxy Z Flip 6', 1, 21000000.00, 7, N'Эвхэгддэг утас'),
  (54, N'P054', N'Ажлын хувцас', 3, 190000.00, 20, N'Ажлын хувцас'),
  (55, N'P055', N'Физикийн ном', 4, 48000.00, 24, N'Физик'),
  (56, N'P056', N'Химийн ном', 4, 50000.00, 22, N'Хими'),
  (57, N'P057', N'Угаалгын машин', 5, 1400000.00, 6, N'Гэр ахуй'),
  (58, N'P058', N'Хөргөгч', 5, 2200000.00, 5, N'Гэр ахуй'),
  (59, N'P059', N'Микроволновк', 5, 750000.00, 9, N'Гал тогоо'),
  (60, N'P060', N'Усны халаагч', 5, 650000.00, 8, N'Гэр ахуй'),
  (61, N'P061', N'Шүүр', 5, 35000.00, 40, N'Цэвэрлэгээ'),
  (62, N'P062', N'Теннисний цохиур', 6, 280000.00, 14, N'Теннис'),
  (63, N'P063', N'Бадминтоны цохиур', 6, 180000.00, 16, N'Бадминтон'),
  (64, N'P064', N'Гүйлтийн зам', 6, 1900000.00, 4, N'Фитнес'),
  (65, N'P065', N'Спортын цүнх', 6, 150000.00, 20, N'Спорт'),
  (66, N'P066', N'Бөмбөгийн насос', 6, 45000.00, 30, N'Спорт'),
  (67, N'P067', N'Эспандер', 6, 95000.00, 25, N'Фитнес'),
  (68, N'P068', N'Саван', 7, 12000.00, 60, N'Гоо сайхан'),
  (69, N'P069', N'Шүдний оо', 7, 18000.00, 50, N'Амны халамж'),
  (70, N'P070', N'Биеийн лосон', 7, 55000.00, 30, N'Арьсны халамж'),
  (71, N'P071', N'Нүүрний маск', 7, 35000.00, 35, N'Арьсны халамж'),
  (72, N'P072', N'Үсний кондиционер', 7, 42000.00, 28, N'Үсний халамж'),
  (73, N'P073', N'Хумсны лак', 7, 28000.00, 40, N'Гоо сайхан'),
  (74, N'P074', N'Нарны тос', 7, 48000.00, 32, N'Арьсны хамгаалалт'),
  (75, N'P075', N'Эфирийн тос', 7, 65000.00, 24, N'Ароматерапи'),
  (76, N'P076', N'Хүүхдийн цамц', 8, 35000.00, 40, N'Хүүхдийн хувцас'),
  (77, N'P077', N'Хүүхдийн өмд', 8, 40000.00, 38, N'Хүүхдийн хувцас'),
  (78, N'P078', N'Хүүхдийн гутал', 8, 75000.00, 26, N'Хүүхдийн гутал'),
  (79, N'P079', N'Хүүхдийн малгай', 8, 25000.00, 45, N'Хүүхдийн хувцас'),
  (80, N'P080', N'Хүүхдийн сав суулга', 8, 55000.00, 30, N'Хүүхдийн хэрэгсэл'),
  (81, N'P081', N'Хүүхдийн суудлын бүс', 8, 220000.00, 12, N'Хүүхдийн аюулгүй байдал'),
  (82, N'P082', N'Хүүхдийн унадаг дугуй', 8, 320000.00, 10, N'Хүүхдийн спорт'),
  (83, N'P083', N'Хүүхдийн унтлагын хувцас', 8, 45000.00, 34, N'Хүүхдийн хувцас'),
  (84, N'P084', N'Цай', 9, 15000.00, 60, N'Ундаа'),
  (85, N'P085', N'Элсэн чихэр', 9, 3500.00, 80, N'Хоол'),
  (86, N'P086', N'Гурил', 9, 45000.00, 28, N'Хоол'),
  (87, N'P087', N'Ундны ус', 9, 2500.00, 100, N'Ундаа'),
  (88, N'P088', N'Жимсний шүүс', 9, 4500.00, 55, N'Ундаа'),
  (89, N'P089', N'Сүү', 9, 3500.00, 70, N'Ундаа'),
  (90, N'P090', N'Талх', 9, 2500.00, 90, N'Хоол'),
  (91, N'P091', N'Шоколад', 9, 8000.00, 65, N'Хоол'),
  (92, N'P092', N'Хатаасан жимс', 9, 18000.00, 42, N'Хоол'),
  (93, N'P093', N'Машины аккумулятор', 10, 380000.00, 12, N'Автомашин'),
  (94, N'P094', N'Машины агаар шүүгч', 10, 85000.00, 22, N'Автомашин'),
  (95, N'P095', N'Машины тормозны дэвсгэр', 10, 160000.00, 18, N'Автомашин'),
  (96, N'P096', N'Машины угаалгын шингэн', 10, 25000.00, 40, N'Автомашин'),
  (97, N'P097', N'Машины гэрлийн чийдэн', 10, 55000.00, 26, N'Автомашин'),
  (98, N'P098', N'Машины шилэн угаагч', 10, 18000.00, 50, N'Автомашин'),
  (99, N'P099', N'Машины суудлын бүрээс', 10, 240000.00, 9, N'Автомашин'),
  (100, N'P100', N'Машины сэлбэгийн багц', 10, 420000.00, 7, N'Автомашин');
SET IDENTITY_INSERT dbo.Products OFF;
GO

CREATE OR ALTER VIEW dbo.v_OrderDetails AS
SELECT
    o.Id AS OrderId,
    o.OrderDate,
    o.Status,
    u.Id AS UserId,
    u.Username AS [НэвтрэхНэр],
    u.FullName AS [Хэрэглэгч],
    p.Code AS [БарааныКод],
    p.Name AS [Бараа],
    oi.Quantity AS [Тоо],
    oi.UnitPrice AS [НэгжийнҮнэ],
    CAST(oi.Quantity AS decimal(18,2)) * oi.UnitPrice AS [Дүн],
    CAST(u.FullName + N' ' + p.Name + N' захиалсан (' + CAST(oi.Quantity AS nvarchar(10)) + N' ширхэг)' AS nvarchar(300)) AS [Тайлбар]
FROM dbo.Orders o
JOIN dbo.Users u ON u.Id = o.UserId
JOIN dbo.OrderItems oi ON oi.OrderId = o.Id
JOIN dbo.Products p ON p.Id = oi.ProductId;
GO
PRINT N'4. 10 ангилал, 100 бараа (ангилал тус бүр 10) гажуудалгүй орлоо.';
GO
/* =========================================================================
   7. STORED PROCEDURES, FUNCTIONS, TRIGGERS
   ========================================================================= */
-- Хэрэглэгч бүртгэх
CREATE PROCEDURE dbo.sp_RegisterUser
    @Username NVARCHAR(50), @Password NVARCHAR(100),
    @FullName NVARCHAR(100), @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username)
    BEGIN
        SELECT 0 AS Ok, 0 AS UserId, N'Ийм нэрэвш байна' AS Message;
        RETURN;
    END
    INSERT INTO dbo.Users (Username, Password, FullName, Email)
    VALUES (@Username, @Password, @FullName, @Email);
    DECLARE @NewId INT = SCOPE_IDENTITY();

    INSERT INTO dbo.ActivityLog (UserName, ActionCode, Details)
    VALUES (@Username, N'REGISTER', N'Шинэ хэрэглэгч бүртгэгдлээ');

    SELECT 1 AS Ok, @NewId AS UserId, N'Бүртгэл амжилттай' AS Message;
END
GO

-- Нэвтрэх
CREATE PROCEDURE dbo.sp_LoginUser
    @Username NVARCHAR(50), @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @Role NVARCHAR(20), @Name NVARCHAR(100);
    SELECT @Id = Id, @Role = Role, @Name = FullName
    FROM dbo.Users WHERE Username = @Username AND Password = @Password;

    IF @Id IS NULL
    BEGIN
        INSERT INTO dbo.ActivityLog (UserName, ActionCode, Details)
        VALUES (@Username, N'LOGIN_FAIL', N'Нэр эсвэл нууц үг буруу');
        SELECT 0 AS Ok, 0 AS UserId, N'' AS UserName, N'' AS FullName,
               N'' AS Role, N'Нэр эсвэл нууц үг буруу' AS Message;
        RETURN;
    END

    INSERT INTO dbo.ActivityLog (UserName, ActionCode, Details)
    VALUES (@Username, N'LOGIN', N'Системд амжилттай нэвтрэв');
    SELECT 1 AS Ok, @Id AS UserId, @Username AS UserName, @Name AS FullName,
           @Role AS Role, N'Амжилттай' AS Message;
END
GO

-- Бараа захиалах (түгжээ/транзакцтай)
CREATE PROCEDURE dbo.sp_PlaceOrder
    @UserId INT, @ProductId INT, @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Stock INT, @Price DECIMAL(18,2);
    SELECT @Stock = Stock, @Price = Price FROM dbo.Products WHERE Id = @ProductId;

    IF @Stock IS NULL OR @Stock < @Quantity
    BEGIN
        SELECT 0 AS Ok, 0 AS OrderId, N'Бараа хүрэлцэхгүй байна' AS Message;
        RETURN;
    END

    BEGIN TRAN;
        INSERT INTO dbo.Orders (UserId) VALUES (@UserId);
        DECLARE @OrderId INT = SCOPE_IDENTITY();
        INSERT INTO dbo.OrderItems (OrderId, ProductId, Quantity, UnitPrice)
        VALUES (@OrderId, @ProductId, @Quantity, @Price);
        UPDATE dbo.Products SET Stock = Stock - @Quantity WHERE Id = @ProductId;
    COMMIT TRAN;

    -- ORDER лог нь доорх trigger-ээс автоматаар бичигдэнэ.
    SELECT 1 AS Ok, @OrderId AS OrderId, N'Захиалга баталгаажлаа' AS Message;
END
GO

-- Функц 1: захиалгын нийт дүн
CREATE FUNCTION dbo.fn_OrderTotal(@OrderId INT) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2);
    SELECT @Total = ISNULL(SUM(Quantity * UnitPrice), 0)
    FROM dbo.OrderItems WHERE OrderId = @OrderId;
    RETURN @Total;
END
GO

-- Функц 2: хэрэглэгчийн нэр
CREATE FUNCTION dbo.fn_UserName(@UserId INT) RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Name NVARCHAR(50);
    SELECT @Name = Username FROM dbo.Users WHERE Id = @UserId;
    RETURN ISNULL(@Name, N'-');
END
GO

-- Trigger 1: захиалга хийгдэхэд лог бичнэ (хэн / ямар код / ямар бараа / хэзээ)
CREATE TRIGGER dbo.trg_OrderItem_Log ON dbo.OrderItems AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ActivityLog (UserName, ActionCode, ProductCode, Details)
    SELECT dbo.fn_UserName(o.UserId), N'ORDER', p.Code,
           CONCAT(N'захиалга #', i.OrderId, N' — ', i.Quantity, N' ширхэг')
    FROM inserted i
    JOIN dbo.Orders   o ON o.Id = i.OrderId
    JOIN dbo.Products p ON p.Id = i.ProductId;
END
GO

-- Trigger 2: барааны үнэ өөрчлөгдөхөд лог бичнэ
CREATE TRIGGER dbo.trg_Product_PriceLog ON dbo.Products AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ActivityLog (UserName, ActionCode, ProductCode, Details)
    SELECT N'систем', N'PRICE', i.Code,
           CONCAT(N'үнэ: ', d.Price, N' -> ', i.Price)
    FROM inserted i
    JOIN deleted d ON d.Id = i.Id
    WHERE i.Price <> d.Price;
END
GO
PRINT N'7. 3 procedure, 2 function, 2 trigger бэлэн.';
GO

/* --- Жишээ үйлдлүүд: лог болон тайланд өгөгдөл байхаар --- */
EXEC dbo.sp_LoginUser  @Username = N'bold',  @Password = N'bold123';
EXEC dbo.sp_PlaceOrder @UserId = 2, @ProductId = 1,  @Quantity = 1;
EXEC dbo.sp_PlaceOrder @UserId = 3, @ProductId = 7,  @Quantity = 2;
EXEC dbo.sp_PlaceOrder @UserId = 2, @ProductId = 11, @Quantity = 1;
GO

PRINT N'БҮХ ЗҮЙЛ БЭЛЭН. Website-ийг Web хавтаснаас ажиллуулна.';
GO
