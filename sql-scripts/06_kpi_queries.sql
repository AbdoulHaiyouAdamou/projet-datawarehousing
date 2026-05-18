/*
=============================================================================
  SCRIPT 06 — Requêtes KPI de Validation
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
=============================================================================
  Description :
    Requêtes analytiques pour valider le Data Warehouse et démontrer
    les capacités décisionnelles lors de la soutenance.
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- =============================================================================
-- KPI 1 : Chiffre d'Affaires global
-- =============================================================================
PRINT '📊 KPI 1 — CA Global';
SELECT
    CAST(SUM(SalesAmount) AS DECIMAL(18,2)) AS CA_Total,
    CAST(SUM(Profit) AS DECIMAL(18,2)) AS Profit_Total,
    CAST(SUM(Profit)*100.0/NULLIF(SUM(SalesAmount),0) AS DECIMAL(5,2)) AS Marge_Pct,
    SUM(OrderQuantity) AS Qty_Total,
    COUNT(DISTINCT SalesOrderID) AS Nb_Commandes,
    COUNT(DISTINCT CustomerKey) AS Nb_Clients,
    CAST(SUM(SalesAmount)/NULLIF(COUNT(DISTINCT SalesOrderID),0) AS DECIMAL(18,2)) AS Panier_Moyen
FROM gold.FactVentes;
GO

-- =============================================================================
-- KPI 2 : CA par Année
-- =============================================================================
PRINT '📊 KPI 2 — CA par Année';
SELECT
    d.[Year],
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(f.Profit)*100.0/NULLIF(SUM(f.SalesAmount),0) AS DECIMAL(5,2)) AS Marge_Pct,
    COUNT(DISTINCT f.SalesOrderID) AS Nb_Commandes
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.[Year]
ORDER BY d.[Year];
GO

-- =============================================================================
-- KPI 3 : Croissance Year-over-Year (YoY)
-- =============================================================================
PRINT '📊 KPI 3 — Croissance YoY';
WITH YearlySales AS (
    SELECT d.[Year],
           CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA
    FROM gold.FactVentes f
    INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
    GROUP BY d.[Year]
)
SELECT
    curr.[Year],
    curr.CA AS CA_Actuel,
    prev.CA AS CA_Precedent,
    CAST((curr.CA - prev.CA) AS DECIMAL(18,2)) AS Variation,
    CAST((curr.CA - prev.CA)*100.0/NULLIF(prev.CA,0) AS DECIMAL(5,2)) AS Croissance_Pct
FROM YearlySales curr
LEFT JOIN YearlySales prev ON curr.[Year] = prev.[Year] + 1
ORDER BY curr.[Year];
GO

-- =============================================================================
-- KPI 4 : Top 10 Produits par CA
-- =============================================================================
PRINT '📊 KPI 4 — Top 10 Produits';
SELECT TOP 10
    p.ProductName,
    p.CategoryName,
    p.SubCategoryName,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    SUM(f.OrderQuantity) AS QuantiteVendue,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes
FROM gold.FactVentes f
INNER JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, p.CategoryName, p.SubCategoryName
ORDER BY CA DESC;
GO

-- =============================================================================
-- KPI 5 : Ventes par Catégorie de Produit
-- =============================================================================
PRINT '📊 KPI 5 — CA par Catégorie';
SELECT
    p.CategoryName,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(f.SalesAmount)*100.0 /
         NULLIF(SUM(SUM(f.SalesAmount)) OVER(), 0) AS DECIMAL(5,2)) AS Part_CA_Pct,
    SUM(f.OrderQuantity) AS QuantiteVendue,
    COUNT(DISTINCT p.ProductKey) AS NbProduits
FROM gold.FactVentes f
INNER JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.CategoryName
ORDER BY CA DESC;
GO

-- =============================================================================
-- KPI 6 : Analyse Géographique — CA par Territoire
-- =============================================================================
PRINT '📊 KPI 6 — CA par Territoire';
SELECT
    t.GroupName AS Region,
    t.CountryName,
    t.TerritoryName,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    COUNT(DISTINCT f.CustomerKey) AS NbClients,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes
FROM gold.FactVentes f
INNER JOIN gold.DimTerritory t ON f.TerritoryKey = t.TerritoryKey
GROUP BY t.GroupName, t.CountryName, t.TerritoryName
ORDER BY CA DESC;
GO

-- =============================================================================
-- KPI 7 : Analyse par Canal (Online vs Reseller)
-- =============================================================================
PRINT '📊 KPI 7 — CA par Canal';
SELECT
    OrderChannel,
    CAST(SUM(SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(Profit) AS DECIMAL(18,2)) AS Profit,
    CAST(SUM(SalesAmount)*100.0/NULLIF(SUM(SUM(SalesAmount)) OVER(),0) AS DECIMAL(5,2)) AS Part_Pct,
    COUNT(DISTINCT SalesOrderID) AS NbCommandes,
    COUNT(DISTINCT CustomerKey) AS NbClients
FROM gold.FactVentes
GROUP BY OrderChannel;
GO

-- =============================================================================
-- KPI 8 : Tendance trimestrielle
-- =============================================================================
PRINT '📊 KPI 8 — Tendance Trimestrielle';
SELECT
    d.[Year],
    d.QuarterName,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA,
    CAST(SUM(f.Profit) AS DECIMAL(18,2)) AS Profit,
    COUNT(DISTINCT f.SalesOrderID) AS NbCommandes
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.[Year], d.QuarterName, d.Quarter
ORDER BY d.[Year], d.Quarter;
GO

-- =============================================================================
-- KPI 9 : Segmentation Clients
-- =============================================================================
PRINT '📊 KPI 9 — Segmentation Clients';
SELECT
    Segment,
    COUNT(*) AS NbClients,
    CAST(SUM(TotalCA) AS DECIMAL(18,2)) AS CA_Total,
    CAST(AVG(TotalCA) AS DECIMAL(18,2)) AS CA_Moyen,
    CAST(AVG(NbCommandes) AS DECIMAL(10,1)) AS Commandes_Moy
FROM gold.vw_CustomerSegmentation
GROUP BY Segment
ORDER BY CA_Total DESC;
GO

-- =============================================================================
-- KPI 10 : Comparaison des plans d'exécution (avant/après index)
-- =============================================================================
PRINT '📊 KPI 10 — Performance (pour la soutenance)';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Requête typique : CA mensuel par catégorie pour 2013
SELECT
    d.YearMonth,
    p.CategoryName,
    CAST(SUM(f.SalesAmount) AS DECIMAL(18,2)) AS CA
FROM gold.FactVentes f
INNER JOIN gold.DimDate d ON f.DateKey = d.DateKey
INNER JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
WHERE d.[Year] = 2013
GROUP BY d.YearMonth, p.CategoryName
ORDER BY d.YearMonth, p.CategoryName;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT '';
PRINT '═══════════════════════════════════════════';
PRINT '✅ 10 REQUÊTES KPI EXÉCUTÉES AVEC SUCCÈS';
PRINT '═══════════════════════════════════════════';
GO
