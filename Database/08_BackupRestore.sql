/* 8. ӨГӨГДЛИЙН САНГ НӨӨЦЛӨХ, СЭРГЭЭХ */
USE master;
GO

-- НӨӨЦЛӨХ (backup)
DECLARE @bak NVARCHAR(400) = N'C:\Users\dell\Documents\Default Project\OnlineShop\Database\Backups\OnlineShopDB.bak';
BACKUP DATABASE [OnlineShopDB]
    TO DISK = @bak
    WITH INIT, COMPRESSION, STATS = 20;
GO

-- СЭРГЭЭХ (restore) — жишээ болгон өөр нэрээр сэргээж шалгана
IF DB_ID(N'OnlineShopDB_Restore') IS NOT NULL
    ALTER DATABASE [OnlineShopDB_Restore] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
IF DB_ID(N'OnlineShopDB_Restore') IS NOT NULL
    DROP DATABASE [OnlineShopDB_Restore];
GO

RESTORE DATABASE [OnlineShopDB_Restore]
    FROM DISK = N'C:\Users\dell\Documents\Default Project\OnlineShop\Database\Backups\OnlineShopDB.bak'
    WITH MOVE N'OnlineShopDB'     TO N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\OnlineShopDB_Restore.mdf',
         MOVE N'OnlineShopDB_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\OnlineShopDB_Restore_log.ldf',
         REPLACE, STATS = 20;
GO

-- Сэргээсэн сан зөв эсэхийг шалгах
SELECT COUNT(*) AS [Сэргээсэн бараа] FROM [OnlineShopDB_Restore].dbo.Products;
SELECT COUNT(*) AS [Сэргээсэн лог]   FROM [OnlineShopDB_Restore].dbo.ActivityLog;
GO

-- Туршилтын санг устгаж, зөвхөн .bak файлыг үлдээнэ
DROP DATABASE [OnlineShopDB_Restore];
GO
PRINT N'8. Нөөцлөх, сэргээх амжилттай.';
GO
