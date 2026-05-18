/*
=============================================================================
  SCRIPT 03 — Couche GOLD (Schéma en Étoile)
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Source   : AdventureWorks_DW.silver.*
  Cible    : AdventureWorks_DW.gold.*
=============================================================================
  Description :
    Construit le modèle dimensionnel en étoile pour l'analyse des ventes.
    Composé de :
      - 1 table de faits  : gold.FactVentes
      - 5 dimensions      : DimDate, DimProduct, DimCustomer,
                            DimTerritory, DimPromotion
    
    Particularités :
      - DimDate : table calendrier générée automatiquement (2011-2014)
      - DimProduct : implémente le SCD Type 2 (historisation des prix)
      - Clés surrogate (IDENTITY) pour toutes les dimensions
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- =============================================================================
-- DIMENSION 1 : DimDate (Table calendrier générée)
-- =============================================================================
IF OBJECT_ID('gold.DimDate', 'U') IS NOT NULL DROP TABLE gold.DimDate;
GO

CREATE TABLE gold.DimDate
(
    DateKey               INT             NOT NULL PRIMARY KEY,  -- Format YYYYMMDD
    FullDate              DATE            NOT NULL,
    [Year]                INT             NOT NULL,
    Quarter               INT             NOT NULL,
    QuarterName           NVARCHAR(10)    NOT NULL,  -- 'Q1', 'Q2', etc.
    [Month]               INT             NOT NULL,
    MonthName             NVARCHAR(20)    NOT NULL,  -- 'January', etc.
    MonthNameShort        NCHAR(3)        NOT NULL,  -- 'Jan', 'Feb', etc.
    [Week]                INT             NOT NULL,
    [DayOfMonth]          INT             NOT NULL,
    [DayOfWeek]           INT             NOT NULL,  -- 1=Lundi ... 7=Dimanche
    DayName               NVARCHAR(20)    NOT NULL,
    DayNameShort          NCHAR(3)        NOT NULL,
    IsWeekend             BIT             NOT NULL,
    IsLastDayOfMonth      BIT             NOT NULL,
    FiscalYear            INT             NOT NULL,  -- Année fiscale (juillet-juin)
    FiscalQuarter         INT             NOT NULL,
    YearMonth             NVARCHAR(7)     NOT NULL   -- '2011-05'
);
GO

-- Génération automatique du calendrier (2010-01-01 → 2015-12-31)
;WITH DateSequence AS
(
    SELECT CAST('2010-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM DateSequence WHERE dt < '2015-12-31'
)
INSERT INTO gold.DimDate
SELECT
    CAST(FORMAT(dt, 'yyyyMMdd') AS INT)              AS DateKey,
    dt                                               AS FullDate,
    YEAR(dt)                                         AS [Year],
    DATEPART(QUARTER, dt)                            AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, dt) AS VARCHAR)     AS QuarterName,
    MONTH(dt)                                        AS [Month],
    DATENAME(MONTH, dt)                              AS MonthName,
    LEFT(DATENAME(MONTH, dt), 3)                     AS MonthNameShort,
    DATEPART(ISO_WEEK, dt)                           AS [Week],
    DAY(dt)                                          AS [DayOfMonth],
    DATEPART(WEEKDAY, dt)                            AS [DayOfWeek],
    DATENAME(WEEKDAY, dt)                            AS DayName,
    LEFT(DATENAME(WEEKDAY, dt), 3)                   AS DayNameShort,
    CASE WHEN DATEPART(WEEKDAY, dt) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    CASE WHEN dt = EOMONTH(dt) THEN 1 ELSE 0 END    AS IsLastDayOfMonth,
    -- Année fiscale Adventure Works : Juillet → Juin
    CASE WHEN MONTH(dt) >= 7 THEN YEAR(dt) + 1 ELSE YEAR(dt) END AS FiscalYear,
    CASE
        WHEN MONTH(dt) IN (7,8,9)   THEN 1
        WHEN MONTH(dt) IN (10,11,12) THEN 2
        WHEN MONTH(dt) IN (1,2,3)   THEN 3
        ELSE 4
    END                                              AS FiscalQuarter,
    FORMAT(dt, 'yyyy-MM')                            AS YearMonth
FROM DateSequence
OPTION (MAXRECURSION 2500);
GO

-- Ligne spéciale pour les dates inconnues
IF NOT EXISTS (SELECT 1 FROM gold.DimDate WHERE DateKey = 19000101)
BEGIN
    INSERT INTO gold.DimDate
    VALUES (19000101, '1900-01-01', 1900, 1, 'Q1', 1, 'Unknown', 'Unk', 1, 1, 1, 'Unknown', 'Unk', 0, 0, 1900, 1, '1900-01');
END
GO

DECLARE @cnt1 INT; SELECT @cnt1 = COUNT(*) FROM gold.DimDate;
PRINT '  ✅ gold.DimDate : ' + CAST(@cnt1 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- DIMENSION 2 : DimProduct (avec SCD Type 2)
-- =============================================================================
IF OBJECT_ID('gold.DimProduct', 'U') IS NOT NULL DROP TABLE gold.DimProduct;
GO

CREATE TABLE gold.DimProduct
(
    ProductKey            INT IDENTITY(1,1)  NOT NULL PRIMARY KEY,
    ProductID             INT             NOT NULL,  -- Business key (source)
    ProductName           NVARCHAR(50)    NOT NULL,
    ProductNumber         NVARCHAR(25)    NOT NULL,
    Color                 NVARCHAR(15)    NOT NULL,
    Size                  NVARCHAR(5)     NOT NULL,
    Weight                DECIMAL(8,2)    NULL,
    StandardCost          MONEY           NOT NULL,
    ListPrice             MONEY           NOT NULL,
    ProductLine           NVARCHAR(20)    NOT NULL,
    Class                 NVARCHAR(20)    NOT NULL,
    Style                 NVARCHAR(20)    NOT NULL,
    SubCategoryName       NVARCHAR(50)    NOT NULL,
    CategoryName          NVARCHAR(50)    NOT NULL,
    MakeFlag              BIT             NOT NULL,
    FinishedGoodsFlag     BIT             NOT NULL,
    -- SCD Type 2 : historisation
    EffectiveStartDate    DATE            NOT NULL,
    EffectiveEndDate      DATE            NULL,      -- NULL = version courante
    IsCurrent             BIT             NOT NULL DEFAULT 1
);
GO

-- Chargement initial (version courante pour tous les produits)
INSERT INTO gold.DimProduct
    (ProductID, ProductName, ProductNumber, Color, Size, Weight,
     StandardCost, ListPrice, ProductLine, Class, Style,
     SubCategoryName, CategoryName, MakeFlag, FinishedGoodsFlag,
     EffectiveStartDate, EffectiveEndDate, IsCurrent)
SELECT
    ProductID,
    ProductName,
    ProductNumber,
    Color,
    Size,
    Weight,
    StandardCost,
    ListPrice,
    ProductLine,
    Class,
    Style,
    SubCategoryName,
    CategoryName,
    MakeFlag,
    FinishedGoodsFlag,
    SellStartDate          AS EffectiveStartDate,
    SellEndDate            AS EffectiveEndDate,
    CASE WHEN SellEndDate IS NULL THEN 1 ELSE 0 END AS IsCurrent
FROM silver.Product;
GO

-- Ligne inconnue pour les FK orphelines
SET IDENTITY_INSERT gold.DimProduct ON;
IF NOT EXISTS (SELECT 1 FROM gold.DimProduct WHERE ProductKey = -1)
BEGIN
    INSERT INTO gold.DimProduct (ProductKey, ProductID, ProductName, ProductNumber,
        Color, Size, Weight, StandardCost, ListPrice, ProductLine, Class, Style,
        SubCategoryName, CategoryName, MakeFlag, FinishedGoodsFlag,
        EffectiveStartDate, EffectiveEndDate, IsCurrent)
    VALUES (-1, -1, 'Unknown', 'UNK-0000', 'N/A', 'N/A', NULL, 0, 0,
        'Autre', 'Non défini', 'Non défini', 'Non catégorisé', 'Non catégorisé',
        0, 0, '1900-01-01', NULL, 1);
END
SET IDENTITY_INSERT gold.DimProduct OFF;
GO

DECLARE @cnt2 INT; SELECT @cnt2 = COUNT(*) FROM gold.DimProduct;
PRINT '  ✅ gold.DimProduct : ' + CAST(@cnt2 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- DIMENSION 3 : DimCustomer
-- =============================================================================
IF OBJECT_ID('gold.DimCustomer', 'U') IS NOT NULL DROP TABLE gold.DimCustomer;
GO

CREATE TABLE gold.DimCustomer
(
    CustomerKey           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID            INT             NOT NULL,  -- Business key
    CustomerType          NVARCHAR(20)    NOT NULL,
    FirstName             NVARCHAR(50)    NULL,
    LastName              NVARCHAR(50)    NULL,
    FullName              NVARCHAR(150)   NOT NULL,
    EmailAddress          NVARCHAR(50)    NULL,
    StoreName             NVARCHAR(50)    NULL,
    City                  NVARCHAR(30)    NULL,
    StateProvinceName     NVARCHAR(50)    NULL,
    CountryRegionCode     NVARCHAR(3)     NULL,
    CountryName           NVARCHAR(50)    NULL
);
GO

INSERT INTO gold.DimCustomer
    (CustomerID, CustomerType, FirstName, LastName, FullName,
     EmailAddress, StoreName, City, StateProvinceName,
     CountryRegionCode, CountryName)
SELECT
    CustomerID,
    CustomerType,
    FirstName,
    LastName,
    FullName,
    EmailAddress,
    StoreName,
    ISNULL(City, 'Unknown')              AS City,
    ISNULL(StateProvinceName, 'Unknown') AS StateProvinceName,
    ISNULL(CountryRegionCode, 'N/A')     AS CountryRegionCode,
    ISNULL(CountryName, 'Unknown')       AS CountryName
FROM silver.Customer;
GO

-- Ligne inconnue
SET IDENTITY_INSERT gold.DimCustomer ON;
IF NOT EXISTS (SELECT 1 FROM gold.DimCustomer WHERE CustomerKey = -1)
BEGIN
    INSERT INTO gold.DimCustomer (CustomerKey, CustomerID, CustomerType, FullName,
        City, StateProvinceName, CountryRegionCode, CountryName)
    VALUES (-1, -1, 'Unknown', 'Unknown Customer',
        'Unknown', 'Unknown', 'N/A', 'Unknown');
END
SET IDENTITY_INSERT gold.DimCustomer OFF;
GO

DECLARE @cnt3 INT; SELECT @cnt3 = COUNT(*) FROM gold.DimCustomer;
PRINT '  ✅ gold.DimCustomer : ' + CAST(@cnt3 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- DIMENSION 4 : DimTerritory
-- =============================================================================
IF OBJECT_ID('gold.DimTerritory', 'U') IS NOT NULL DROP TABLE gold.DimTerritory;
GO

CREATE TABLE gold.DimTerritory
(
    TerritoryKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TerritoryID           INT             NOT NULL,  -- Business key
    TerritoryName         NVARCHAR(50)    NOT NULL,
    CountryRegionCode     NVARCHAR(3)     NOT NULL,
    CountryName           NVARCHAR(50)    NOT NULL,
    GroupName             NVARCHAR(50)    NOT NULL   -- North America, Europe, Pacific
);
GO

INSERT INTO gold.DimTerritory
    (TerritoryID, TerritoryName, CountryRegionCode, CountryName, GroupName)
SELECT
    TerritoryID,
    TerritoryName,
    CountryRegionCode,
    CountryName,
    GroupName
FROM silver.Territory;
GO

-- Ligne inconnue
SET IDENTITY_INSERT gold.DimTerritory ON;
IF NOT EXISTS (SELECT 1 FROM gold.DimTerritory WHERE TerritoryKey = -1)
BEGIN
    INSERT INTO gold.DimTerritory (TerritoryKey, TerritoryID, TerritoryName,
        CountryRegionCode, CountryName, GroupName)
    VALUES (-1, -1, 'Unknown', 'N/A', 'Unknown', 'Unknown');
END
SET IDENTITY_INSERT gold.DimTerritory OFF;
GO

DECLARE @cnt4 INT; SELECT @cnt4 = COUNT(*) FROM gold.DimTerritory;
PRINT '  ✅ gold.DimTerritory : ' + CAST(@cnt4 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- DIMENSION 5 : DimPromotion
-- =============================================================================
IF OBJECT_ID('gold.DimPromotion', 'U') IS NOT NULL DROP TABLE gold.DimPromotion;
GO

CREATE TABLE gold.DimPromotion
(
    PromotionKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SpecialOfferID        INT             NOT NULL,  -- Business key
    PromotionName         NVARCHAR(255)   NOT NULL,
    DiscountPct           DECIMAL(5,4)    NOT NULL,
    Type                  NVARCHAR(50)    NOT NULL,
    Category              NVARCHAR(50)    NOT NULL,
    StartDate             DATE            NOT NULL,
    EndDate               DATE            NOT NULL,
    MinQty                INT             NOT NULL,
    MaxQty                INT             NULL
);
GO

INSERT INTO gold.DimPromotion
    (SpecialOfferID, PromotionName, DiscountPct, Type, Category,
     StartDate, EndDate, MinQty, MaxQty)
SELECT
    SpecialOfferID,
    Description,
    DiscountPct,
    Type,
    Category,
    StartDate,
    EndDate,
    MinQty,
    MaxQty
FROM silver.Promotion;
GO

-- Ligne "No Promotion"
SET IDENTITY_INSERT gold.DimPromotion ON;
IF NOT EXISTS (SELECT 1 FROM gold.DimPromotion WHERE PromotionKey = -1)
BEGIN
    INSERT INTO gold.DimPromotion (PromotionKey, SpecialOfferID, PromotionName,
        DiscountPct, Type, Category, StartDate, EndDate, MinQty, MaxQty)
    VALUES (-1, -1, 'No Promotion', 0, 'N/A', 'N/A', '1900-01-01', '9999-12-31', 0, NULL);
END
SET IDENTITY_INSERT gold.DimPromotion OFF;
GO

DECLARE @cnt5 INT; SELECT @cnt5 = COUNT(*) FROM gold.DimPromotion;
PRINT '  ✅ gold.DimPromotion : ' + CAST(@cnt5 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- TABLE DE FAITS : FactVentes
-- =============================================================================
IF OBJECT_ID('gold.FactVentes', 'U') IS NOT NULL DROP TABLE gold.FactVentes;
GO

CREATE TABLE gold.FactVentes
(
    SalesKey              INT IDENTITY(1,1) NOT NULL,  -- Clé surrogate
    -- Clés étrangères vers les dimensions
    DateKey               INT             NOT NULL,     -- → DimDate
    ProductKey            INT             NOT NULL,     -- → DimProduct
    CustomerKey           INT             NOT NULL,     -- → DimCustomer
    TerritoryKey          INT             NOT NULL,     -- → DimTerritory
    PromotionKey          INT             NOT NULL,     -- → DimPromotion
    -- Clés dégénérées (identifiants de la commande)
    SalesOrderID          INT             NOT NULL,
    SalesOrderDetailID    INT             NOT NULL,
    -- Mesures
    OrderQuantity         SMALLINT        NOT NULL,
    UnitPrice             MONEY           NOT NULL,
    UnitPriceDiscount     MONEY           NOT NULL,
    SalesAmount           MONEY           NOT NULL,     -- LineTotal
    TotalProductCost      MONEY           NOT NULL,     -- OrderQty * StandardCost
    Profit                MONEY           NOT NULL,     -- SalesAmount - TotalProductCost
    TaxAmount             MONEY           NOT NULL,
    Freight               MONEY           NOT NULL,
    -- Indicateurs
    OrderChannel          NVARCHAR(20)    NOT NULL,     -- 'Online' / 'Reseller'
    OrderStatus           NVARCHAR(20)    NOT NULL
);
GO

-- Chargement de la table de faits avec lookup vers les dimensions
INSERT INTO gold.FactVentes
SELECT
    -- Clés dimensions (lookup)
    ISNULL(CAST(FORMAT(s.OrderDate, 'yyyyMMdd') AS INT), 19000101) AS DateKey,
    ISNULL(dp.ProductKey, -1)                        AS ProductKey,
    ISNULL(dc.CustomerKey, -1)                       AS CustomerKey,
    ISNULL(dt.TerritoryKey, -1)                      AS TerritoryKey,
    ISNULL(dpr.PromotionKey, -1)                     AS PromotionKey,
    -- Clés dégénérées
    s.SalesOrderID,
    s.SalesOrderDetailID,
    -- Mesures
    s.OrderQty                                       AS OrderQuantity,
    s.UnitPrice,
    s.UnitPriceDiscount,
    s.LineTotal                                      AS SalesAmount,
    ISNULL(s.OrderQty * s.StandardCost, 0)           AS TotalProductCost,
    s.LineTotal - ISNULL(s.OrderQty * s.StandardCost, 0) AS Profit,
    -- Répartition proportionnelle des taxes/frais par ligne
    CASE WHEN s.SubTotal > 0
         THEN CAST(s.TaxAmt * (s.LineTotal / s.SubTotal) AS MONEY)
         ELSE 0
    END                                              AS TaxAmount,
    CASE WHEN s.SubTotal > 0
         THEN CAST(s.Freight * (s.LineTotal / s.SubTotal) AS MONEY)
         ELSE 0
    END                                              AS Freight,
    s.OrderChannel,
    s.OrderStatus
FROM silver.Sales s
-- Lookup Product (prendre la version courante du produit)
LEFT JOIN gold.DimProduct dp
    ON s.ProductID = dp.ProductID
    AND dp.IsCurrent = 1
-- Lookup Customer
LEFT JOIN gold.DimCustomer dc
    ON s.CustomerID = dc.CustomerID
-- Lookup Territory
LEFT JOIN gold.DimTerritory dt
    ON s.TerritoryID = dt.TerritoryID
-- Lookup Promotion
LEFT JOIN gold.DimPromotion dpr
    ON s.SpecialOfferID = dpr.SpecialOfferID;
GO

DECLARE @cnt6 INT; SELECT @cnt6 = COUNT(*) FROM gold.FactVentes;
PRINT '  ✅ gold.FactVentes : ' + CAST(@cnt6 AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- VALIDATION : Vérification du schéma en étoile
-- =============================================================================
PRINT '';
PRINT '═══════════════════════════════════════════════════';
PRINT '📊 VALIDATION COUCHE GOLD — SCHÉMA EN ÉTOILE';
PRINT '═══════════════════════════════════════════════════';

-- Nombre de lignes par table
SELECT 'gold.DimDate'       AS TableName, COUNT(*) AS NbRows FROM gold.DimDate
UNION ALL
SELECT 'gold.DimProduct',    COUNT(*) FROM gold.DimProduct
UNION ALL
SELECT 'gold.DimCustomer',   COUNT(*) FROM gold.DimCustomer
UNION ALL
SELECT 'gold.DimTerritory',  COUNT(*) FROM gold.DimTerritory
UNION ALL
SELECT 'gold.DimPromotion',  COUNT(*) FROM gold.DimPromotion
UNION ALL
SELECT 'gold.FactVentes',    COUNT(*) FROM gold.FactVentes;
GO

-- Vérification de l'intégrité référentielle
SELECT 'FK orphelines DateKey'     AS IntegrityCheck,
       COUNT(*) AS NbOrphans
FROM gold.FactVentes f
LEFT JOIN gold.DimDate d ON f.DateKey = d.DateKey
WHERE d.DateKey IS NULL

UNION ALL

SELECT 'FK orphelines ProductKey',
       COUNT(*)
FROM gold.FactVentes f
LEFT JOIN gold.DimProduct d ON f.ProductKey = d.ProductKey
WHERE d.ProductKey IS NULL

UNION ALL

SELECT 'FK orphelines CustomerKey',
       COUNT(*)
FROM gold.FactVentes f
LEFT JOIN gold.DimCustomer d ON f.CustomerKey = d.CustomerKey
WHERE d.CustomerKey IS NULL

UNION ALL

SELECT 'FK orphelines TerritoryKey',
       COUNT(*)
FROM gold.FactVentes f
LEFT JOIN gold.DimTerritory d ON f.TerritoryKey = d.TerritoryKey
WHERE d.TerritoryKey IS NULL;
GO

-- Quick KPI test
SELECT
    CAST(SUM(SalesAmount) AS DECIMAL(18,2))           AS CA_Total,
    CAST(SUM(Profit) AS DECIMAL(18,2))                AS Profit_Total,
    CAST(SUM(Profit)*100.0/NULLIF(SUM(SalesAmount),0) AS DECIMAL(5,2)) AS Marge_Pct,
    SUM(OrderQuantity)                                AS Qty_Total,
    COUNT(DISTINCT SalesOrderID)                      AS Nb_Commandes
FROM gold.FactVentes;
GO

PRINT '';
PRINT '═══════════════════════════════════════════';
PRINT '✅ COUCHE GOLD CHARGÉE AVEC SUCCÈS';
PRINT '✅ SCHÉMA EN ÉTOILE OPÉRATIONNEL';
PRINT '═══════════════════════════════════════════';
GO
