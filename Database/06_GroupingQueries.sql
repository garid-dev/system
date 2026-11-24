/* 6. GROUPING AND SUMMARIZING — бүлэглэх, дүгнэх запросууд */
USE [OnlineShopDB];
GO

-- 1) Ангилал тус бүрийн борлуулалт
SELECT c.Name AS [Ангилал],
       SUM(oi.Quantity) AS [Ширхэг],
       SUM(oi.Quantity * oi.UnitPrice) AS [Дүн]
FROM dbo.OrderItems oi
JOIN dbo.Products   p ON p.Id = oi.ProductId
JOIN dbo.Categories c ON c.Id = p.CategoryId
GROUP BY c.Name
ORDER BY [Дүн] DESC;
GO

-- 2) Хэрэглэгч тус бүрийн захиалга (функц ашигласан)
SELECT dbo.fn_UserName(o.UserId) AS [Хэрэглэгч],
       COUNT(*) AS [Захиалга],
       SUM(dbo.fn_OrderTotal(o.Id)) AS [Нийт дүн]
FROM dbo.Orders o
GROUP BY o.UserId
ORDER BY [Нийт дүн] DESC;
GO

-- 3) Өдрөөр дүгнэх
SELECT CAST(o.OrderDate AS DATE) AS [Огноо],
       COUNT(*) AS [Захиалга],
       SUM(dbo.fn_OrderTotal(o.Id)) AS [Дүн]
FROM dbo.Orders o
GROUP BY CAST(o.OrderDate AS DATE)
ORDER BY [Огноо];
GO

-- 4) Хамгийн их зарагдсан 5 бараа
SELECT TOP 5 p.Code AS [Код], p.Name AS [Бараа],
       SUM(oi.Quantity) AS [Борлуулсан ширхэг],
       SUM(oi.Quantity * oi.UnitPrice) AS [Дүн]
FROM dbo.OrderItems oi
JOIN dbo.Products p ON p.Id = oi.ProductId
GROUP BY p.Code, p.Name
ORDER BY [Борлуулсан ширхэг] DESC;
GO

-- 5) Live лог: ямар код хэд удаа бичигдсэн бэ
SELECT ActionCode AS [Үйлдлийн код],
       COUNT(*) AS [Тоо],
       MIN(AtTime) AS [Эхлэл],
       MAX(AtTime) AS [Сүүл]
FROM dbo.ActivityLog
GROUP BY ActionCode
ORDER BY [Тоо] DESC;
GO
