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
 (4, N'Ном');
SET IDENTITY_INSERT dbo.Categories OFF;
GO

SET IDENTITY_INSERT dbo.Products ON;
INSERT INTO dbo.Products (Id, Code, Name, CategoryId, Price, Stock, Description) VALUES
 (1,  N'P001', N'iPhone 15',              1, 25000000.00,  5, N'Apple утас'),
 (2,  N'P002', N'Samsung Galaxy S24',     1, 22000000.00,  8, N'Android утас'),
 (3,  N'P003', N'Xiaomi 14',              1, 12000000.00, 10, N'Android утас'),
 (4,  N'P004', N'Dell XPS 13',            2, 32000000.00,  3, N'Зөөврийн компьютер'),
 (5,  N'P005', N'Lenovo ThinkPad',        2, 26000000.00,  4, N'Зөөврийн компьютер'),
 (6,  N'P006', N'HP Pavilion',            2, 18000000.00,  6, N'Зөөврийн компьютер'),
 (7,  N'P007', N'Монгол хувцас',          3,   150000.00, 20, N'Үндэсний хувцас'),
 (8,  N'P008', N'Хүрэм',                  3,   320000.00, 15, N'Өвлийн хүрэм'),
 (9,  N'P009', N'Парка',                  3,   450000.00, 12, N'Өвлийн парка'),
 (10, N'P010', N'Programming 101',        4,    45000.00, 30, N'Програмчлалын ном'),
 (11, N'P011', N'Өгөгдлийн сангийн систем', 4,   55000.00, 25, N'SQL ном'),
 (12, N'P012', N'Математикийн ном',       4,    38000.00, 40, N'Математик');
SET IDENTITY_INSERT dbo.Products OFF;
GO
PRINT N'4. Excel-ийн 3 хэрэглэгч, 4 ангилал, 12 бараа гажуудалгүй орлоо.';
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
