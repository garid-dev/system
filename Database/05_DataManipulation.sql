/* 5. ӨГӨГДӨЛТЭЙ АЖИЛЛАХ  (Data manipulation: INSERT / UPDATE / DELETE) */
USE [OnlineShopDB];
GO

-- INSERT: шинэ ангилал нэмье
INSERT INTO dbo.Categories (Name) VALUES (N'Хобби');
GO

-- UPDATE: P012 барааны үнийг 1000₮ нэмэгдүүлье (PRICE trigger ажиллана)
UPDATE dbo.Products SET Price = Price + 1000 WHERE Code = N'P012';
GO

-- DELETE: туршилтын ангиллаа устгая
DELETE FROM dbo.Categories WHERE Name = N'Хобби';
GO

-- Анхны утгад буцааж, үр дүнг шалгая
UPDATE dbo.Products SET Price = 38000.00 WHERE Code = N'P012';
GO
SELECT Code, Name, Price, Stock FROM dbo.Products WHERE Code = N'P012';
SELECT COUNT(*) AS Categories FROM dbo.Categories;
SELECT TOP 3 ActionCode, ProductCode, Details, AtTime
FROM dbo.ActivityLog ORDER BY Id DESC;
GO
