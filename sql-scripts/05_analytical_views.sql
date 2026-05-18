/*
=============================================================================
  SCRIPT 05 — Vues Analytiques Métier
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Cible    : AdventureWorks_DW.gold.*
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- VUE 1 : Analyse complète des ventes
IF OBJECT_ID('gold.vw_SalesAnalysis', 'V') IS NOT NULL DROP VIEW gold.vw_SalesAnalysis;
GO

CREATE VIEW gold.vw_SalesAnalysis
AS
SELECT
    d.FullDate, d.[Year], d.Quarter, d.QuarterName, d.[Month], d.MonthName,
    d.MonthNameShort, d.DayName, d.IsWeekend, d.FiscalYear, d.FiscalQuarter, d.YearMonth,
    p.ProductName, p.ProductNumber, p.Color, p.Size, p.CategoryName, p.SubCategoryName,
    p.ProductLine, p.Class AS ProductClass, p.ListPrice, p.StandardCost,
    c.FullName AS CustomerName, c.CustomerType, c.StoreName, c.City,
    c.StateProvinceName, c.CountryName AS CustomerCountry, c.EmailAddress,
    t.TerritoryName, t.CountryName AS TerritoryCountry, t.GroupName AS TerritoryGroup,
    pr.PromotionName, pr.DiscountPct, pr.Type AS PromotionType,
    f.OrderQuantity, f.UnitPrice, f.UnitPriceDiscount, f.SalesAmount,
    f.TotalProductCost, f.Profit, f.TaxAmount, f.Freight,
    f.OrderChannel, f.SalesOrderID, f.SalesOrderDetailID
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
INNER JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
INNER JOIN gold.DimCustomer c ON f.CustomerKey = c.CustomerKey
INNER JOIN gold.DimTerritory t ON f.TerritoryKey = t.TerritoryKey
INNER JOIN gold.DimPromotion pr ON f.PromotionKey = pr.PromotionKey;
GO

-- VUE 2 : Tendance mensuelle du CA
IF OBJECT_ID('gold.vw_MonthlySalesTrend', 'V') IS NOT NULL DROP VIEW gold.vw_MonthlySalesTrend;
GO

CREATE VIEW gold.vw_MonthlySalesTrend
AS
SELECT
    d.[Year], d.[Month], d.MonthName, d.YearMonth, d.FiscalYear, d.FiscalQuarter,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes,
    SUM(f.OrderQuantity) AS TotalQuantity,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(f.TotalProductCost) AS DECIMAL(18,2)) AS Cout,
    CAST(SUM(f.Profit)*100.0/NULLIF(SUM(f.SalesAmount),0) AS DECIMAL(5,2)) AS MargePct,
    CAST(SUM(f.SalesAmount)*1.0/NULLIF(COUNT(DISTINCT f.SalesOrderID),0) AS DECIMAL(18,2)) AS PanierMoyen
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.[Year], d.[Month], d.MonthName, d.YearMonth, d.FiscalYear, d.FiscalQuarter;
GO

-- VUE 3 : Top Produits
IF OBJECT_ID('gold.vw_TopProducts', 'V') IS NOT NULL DROP VIEW gold.vw_TopProducts;
GO

CREATE VIEW gold.vw_TopProducts
AS
SELECT
    p.ProductName, p.ProductNumber, p.CategoryName, p.SubCategoryName,
    p.Color, p.ListPrice, p.StandardCost,
    SUM(f.OrderQuantity) AS TotalQuantitySold,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS TotalCA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS TotalProfit,
    CAST(SUM(f.Profit)*100.0/NULLIF(SUM(f.SalesAmount),0) AS DECIMAL(5,2)) AS MargePct,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes,
    COUNT(DISTINCT f.CustomerKey) AS NbClients
FROM gold.FactVentes f
INNER JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, p.ProductNumber, p.CategoryName,
         p.SubCategoryName, p.Color, p.ListPrice, p.StandardCost;
GO

-- VUE 4 : Analyse Géographique
IF OBJECT_ID('gold.vw_GeographicSales', 'V') IS NOT NULL DROP VIEW gold.vw_GeographicSales;
GO

CREATE VIEW gold.vw_GeographicSales
AS
SELECT
    t.GroupName AS Region, t.CountryName, t.TerritoryName, d.[Year],
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes,
    SUM(f.OrderQuantity) AS TotalQuantity,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(f.Profit)*100.0/NULLIF(SUM(f.SalesAmount),0) AS DECIMAL(5,2)) AS MargePct,
    COUNT(DISTINCT f.CustomerKey) AS NbClients
FROM gold.FactVentes f
INNER JOIN gold.DimTerritory t ON f.TerritoryKey = t.TerritoryKey
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY t.GroupName, t.CountryName, t.TerritoryName, d.[Year];
GO

-- VUE 5 : Segmentation Clients
IF OBJECT_ID('gold.vw_CustomerSegmentation', 'V') IS NOT NULL DROP VIEW gold.vw_CustomerSegmentation;
GO

CREATE VIEW gold.vw_CustomerSegmentation
AS
SELECT
    c.CustomerKey, c.CustomerID, c.FullName, c.CustomerType,
    c.City, c.StateProvinceName, c.CountryName,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes,
    SUM(f.OrderQuantity) AS TotalQuantity,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS TotalCA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS TotalProfit,
    CAST(MIN(d.FullDate) AS DATE) AS PremierAchat,
    CAST(MAX(d.FullDate) AS DATE) AS DernierAchat,
    CASE
        WHEN SUM(f.SalesAmount) >= 10000 THEN 'Premium'
        WHEN SUM(f.SalesAmount) >= 2000 THEN 'Regular'
        WHEN SUM(f.SalesAmount) >= 500 THEN 'Occasional'
        ELSE 'New'
    END AS Segment
FROM gold.FactVentes f
INNER JOIN gold.DimCustomer c ON f.CustomerKey = c.CustomerKey
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY c.CustomerKey, c.CustomerID, c.FullName, c.CustomerType,
         c.City, c.StateProvinceName, c.CountryName;
GO

-- VUE 6 : Analyse par Canal de Vente
IF OBJECT_ID('gold.vw_SalesByChannel', 'V') IS NOT NULL DROP VIEW gold.vw_SalesByChannel;
GO

CREATE VIEW gold.vw_SalesByChannel
AS
SELECT
    f.OrderChannel, d.[Year], d.QuarterName,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes,
    SUM(f.OrderQuantity) AS TotalQuantity,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(f.Profit)*100.0/NULLIF(SUM(f.SalesAmount),0) AS DECIMAL(5,2)) AS MargePct,
    COUNT(DISTINCT f.CustomerKey) AS NbClients
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY f.OrderChannel, d.[Year], d.QuarterName;
GO

PRINT '✅ 6 VUES ANALYTIQUES CRÉÉES AVEC SUCCÈS';
GO
