/*
=============================================================================
  SCRIPT 02 — Couche SILVER (Nettoyage et Transformation)
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Source   : AdventureWorks_DW.bronze.*
  Cible    : AdventureWorks_DW.silver.*
=============================================================================
  Description :
    Transforme les données brutes de la couche Bronze en données nettoyées,
    dédupliquées et enrichies. Les traitements incluent :
      - Suppression des doublons
      - Gestion des valeurs NULL (remplacement par des valeurs par défaut)
      - Jointures entre tables liées
      - Standardisation des formats
      - Enrichissement (calcul de colonnes dérivées)
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- =============================================
-- 1. SILVER — Ventes (jointure Header + Detail enrichie)
-- =============================================
IF OBJECT_ID('silver.Sales', 'U') IS NOT NULL DROP TABLE silver.Sales;
GO

CREATE TABLE silver.Sales
(
    SalesOrderID          INT             NOT NULL,
    SalesOrderDetailID    INT             NOT NULL,
    OrderDate             DATE            NOT NULL,
    DueDate               DATE            NOT NULL,
    ShipDate              DATE            NULL,
    OrderStatus           NVARCHAR(20)    NOT NULL,  -- Libellé au lieu du code
    OnlineOrderFlag       BIT             NOT NULL,
    OrderChannel          NVARCHAR(20)    NOT NULL,  -- 'Online' / 'Reseller'
    CustomerID            INT             NOT NULL,
    TerritoryID           INT             NULL,
    ProductID             INT             NOT NULL,
    SpecialOfferID        INT             NOT NULL,
    OrderQty              SMALLINT        NOT NULL,
    UnitPrice             MONEY           NOT NULL,
    UnitPriceDiscount     MONEY           NOT NULL,
    LineTotal             MONEY           NOT NULL,
    StandardCost          MONEY           NULL,
    SubTotal              MONEY           NOT NULL,
    TaxAmt                MONEY           NOT NULL,
    Freight               MONEY           NOT NULL,
    TotalDue              MONEY           NOT NULL,
    -- Colonnes de traçabilité
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'Bronze'
);
GO

-- Chargement Silver.Sales : jointure + nettoyage + enrichissement
INSERT INTO silver.Sales
SELECT
    h.SalesOrderID,
    d.SalesOrderDetailID,
    CAST(h.OrderDate AS DATE)                       AS OrderDate,
    CAST(h.DueDate AS DATE)                         AS DueDate,
    CAST(h.ShipDate AS DATE)                        AS ShipDate,
    -- Transformation du statut numérique en libellé
    CASE h.[Status]
        WHEN 1 THEN 'In Process'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Backordered'
        WHEN 4 THEN 'Rejected'
        WHEN 5 THEN 'Shipped'
        WHEN 6 THEN 'Cancelled'
        ELSE 'Unknown'
    END                                              AS OrderStatus,
    h.OnlineOrderFlag,
    -- Canal de vente dérivé
    CASE WHEN h.OnlineOrderFlag = 1
         THEN 'Online'
         ELSE 'Reseller'
    END                                              AS OrderChannel,
    h.CustomerID,
    h.TerritoryID,
    d.ProductID,
    d.SpecialOfferID,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    d.LineTotal,
    p.StandardCost,
    h.SubTotal,
    h.TaxAmt,
    h.Freight,
    h.TotalDue,
    SYSDATETIME(),
    'Bronze'
FROM bronze.SalesOrderHeader h
INNER JOIN bronze.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID
LEFT JOIN bronze.Product p
    ON d.ProductID = p.ProductID
WHERE h.[Status] NOT IN (4, 6)  -- Exclure les commandes rejetées/annulées
;
GO

PRINT '  ✅ silver.Sales : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- =============================================
-- 2. SILVER — Produits (enrichis avec catégories)
-- =============================================
IF OBJECT_ID('silver.Product', 'U') IS NOT NULL DROP TABLE silver.Product;
GO

CREATE TABLE silver.Product
(
    ProductID             INT             NOT NULL,
    ProductName           NVARCHAR(50)    NOT NULL,
    ProductNumber         NVARCHAR(25)    NOT NULL,
    Color                 NVARCHAR(15)    NOT NULL,  -- NULL → 'N/A'
    Size                  NVARCHAR(5)     NOT NULL,  -- NULL → 'N/A'
    Weight                DECIMAL(8,2)    NULL,
    StandardCost          MONEY           NOT NULL,
    ListPrice             MONEY           NOT NULL,
    ProductLine           NVARCHAR(20)    NOT NULL,  -- Code → Libellé
    Class                 NVARCHAR(20)    NOT NULL,  -- Code → Libellé
    Style                 NVARCHAR(20)    NOT NULL,  -- Code → Libellé
    SubCategoryName       NVARCHAR(50)    NOT NULL,  -- NULL → 'Non catégorisé'
    CategoryName          NVARCHAR(50)    NOT NULL,  -- NULL → 'Non catégorisé'
    MakeFlag              BIT             NOT NULL,
    FinishedGoodsFlag     BIT             NOT NULL,
    SellStartDate         DATE            NOT NULL,
    SellEndDate           DATE            NULL,
    IsActive              BIT             NOT NULL,  -- Produit encore actif ?
    -- Colonnes de traçabilité
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'Bronze'
);
GO

INSERT INTO silver.Product
SELECT
    p.ProductID,
    p.Name                                           AS ProductName,
    p.ProductNumber,
    ISNULL(p.Color, 'N/A')                           AS Color,
    ISNULL(p.Size, 'N/A')                            AS Size,
    p.Weight,
    p.StandardCost,
    p.ListPrice,
    -- Décodage ProductLine
    CASE p.ProductLine
        WHEN 'R'  THEN 'Road'
        WHEN 'M'  THEN 'Mountain'
        WHEN 'T'  THEN 'Touring'
        WHEN 'S'  THEN 'Standard'
        ELSE 'Autre'
    END                                              AS ProductLine,
    -- Décodage Class
    CASE LTRIM(RTRIM(p.Class))
        WHEN 'H'  THEN 'High'
        WHEN 'M'  THEN 'Medium'
        WHEN 'L'  THEN 'Low'
        ELSE 'Non défini'
    END                                              AS Class,
    -- Décodage Style
    CASE LTRIM(RTRIM(p.Style))
        WHEN 'U'  THEN 'Universal'
        WHEN 'M'  THEN 'Men'
        WHEN 'W'  THEN 'Women'
        ELSE 'Non défini'
    END                                              AS Style,
    ISNULL(sc.Name, 'Non catégorisé')                AS SubCategoryName,
    ISNULL(c.Name, 'Non catégorisé')                 AS CategoryName,
    p.MakeFlag,
    p.FinishedGoodsFlag,
    CAST(p.SellStartDate AS DATE)                    AS SellStartDate,
    CAST(p.SellEndDate AS DATE)                      AS SellEndDate,
    CASE WHEN p.SellEndDate IS NULL THEN 1 ELSE 0 END AS IsActive,
    SYSDATETIME(),
    'Bronze'
FROM bronze.Product p
LEFT JOIN bronze.ProductSubcategory sc
    ON p.ProductSubcategoryID = sc.ProductSubcategoryID
LEFT JOIN bronze.ProductCategory c
    ON sc.ProductCategoryID = c.ProductCategoryID;
GO

PRINT '  ✅ silver.Product : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- =============================================
-- 3. SILVER — Clients (enrichis avec infos personnelles et adresses)
-- =============================================
IF OBJECT_ID('silver.Customer', 'U') IS NOT NULL DROP TABLE silver.Customer;
GO

CREATE TABLE silver.Customer
(
    CustomerID            INT             NOT NULL,
    PersonID              INT             NULL,
    StoreID               INT             NULL,
    CustomerType          NVARCHAR(20)    NOT NULL,  -- 'Individual' / 'Store'
    FirstName             NVARCHAR(50)    NULL,
    LastName              NVARCHAR(50)    NULL,
    FullName              NVARCHAR(150)   NOT NULL,
    EmailAddress          NVARCHAR(50)    NULL,
    StoreName             NVARCHAR(50)    NULL,
    TerritoryID           INT             NULL,
    City                  NVARCHAR(30)    NULL,
    StateProvinceName     NVARCHAR(50)    NULL,
    CountryRegionCode     NVARCHAR(3)     NULL,
    CountryName           NVARCHAR(50)    NULL,
    -- Colonnes de traçabilité
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'Bronze'
);
GO

INSERT INTO silver.Customer
SELECT
    c.CustomerID,
    c.PersonID,
    c.StoreID,
    CASE
        WHEN c.PersonID IS NOT NULL AND c.StoreID IS NULL THEN 'Individual'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END                                              AS CustomerType,
    p.FirstName,
    p.LastName,
    CASE
        WHEN c.StoreID IS NOT NULL THEN ISNULL(s.Name, 'Unknown Store')
        WHEN p.FirstName IS NOT NULL THEN CONCAT(p.FirstName, ' ', p.LastName)
        ELSE 'Unknown Customer'
    END                                              AS FullName,
    e.EmailAddress,
    s.Name                                           AS StoreName,
    c.TerritoryID,
    a.City,
    sp.Name                                          AS StateProvinceName,
    sp.CountryRegionCode,
    cr.Name                                          AS CountryName,
    SYSDATETIME(),
    'Bronze'
FROM bronze.Customer c
LEFT JOIN bronze.Person p
    ON c.PersonID = p.BusinessEntityID
LEFT JOIN bronze.EmailAddress e
    ON c.PersonID = e.BusinessEntityID
    AND e.EmailAddressID = 1  -- Prendre le 1er email uniquement
LEFT JOIN bronze.Store s
    ON c.StoreID = s.BusinessEntityID
LEFT JOIN bronze.SalesTerritory t
    ON c.TerritoryID = t.TerritoryID
-- Adresse : via BusinessEntityAddress (on prend l'adresse principale)
LEFT JOIN [AdventureWorks2022].Person.BusinessEntityAddress bea
    ON COALESCE(c.PersonID, c.StoreID) = bea.BusinessEntityID
    AND bea.AddressTypeID = 2  -- Home address
LEFT JOIN bronze.Address a
    ON bea.AddressID = a.AddressID
LEFT JOIN bronze.StateProvince sp
    ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN bronze.CountryRegion cr
    ON sp.CountryRegionCode = cr.CountryRegionCode;
GO

PRINT '  ✅ silver.Customer : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- =============================================
-- 4. SILVER — Territoires (nettoyés)
-- =============================================
IF OBJECT_ID('silver.Territory', 'U') IS NOT NULL DROP TABLE silver.Territory;
GO

CREATE TABLE silver.Territory
(
    TerritoryID           INT             NOT NULL,
    TerritoryName         NVARCHAR(50)    NOT NULL,
    CountryRegionCode     NVARCHAR(3)     NOT NULL,
    CountryName           NVARCHAR(50)    NOT NULL,
    GroupName             NVARCHAR(50)    NOT NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'Bronze'
);
GO

INSERT INTO silver.Territory
SELECT
    t.TerritoryID,
    t.Name                                           AS TerritoryName,
    t.CountryRegionCode,
    cr.Name                                          AS CountryName,
    t.[Group]                                        AS GroupName,
    SYSDATETIME(),
    'Bronze'
FROM bronze.SalesTerritory t
INNER JOIN bronze.CountryRegion cr
    ON t.CountryRegionCode = cr.CountryRegionCode;
GO

PRINT '  ✅ silver.Territory : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- =============================================
-- 5. SILVER — Promotions (nettoyées)
-- =============================================
IF OBJECT_ID('silver.Promotion', 'U') IS NOT NULL DROP TABLE silver.Promotion;
GO

CREATE TABLE silver.Promotion
(
    SpecialOfferID        INT             NOT NULL,
    Description           NVARCHAR(255)   NOT NULL,
    DiscountPct           DECIMAL(5,4)    NOT NULL,
    Type                  NVARCHAR(50)    NOT NULL,
    Category              NVARCHAR(50)    NOT NULL,
    StartDate             DATE            NOT NULL,
    EndDate               DATE            NOT NULL,
    MinQty                INT             NOT NULL,
    MaxQty                INT             NULL,
    IsActive              BIT             NOT NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'Bronze'
);
GO

INSERT INTO silver.Promotion
SELECT
    SpecialOfferID,
    Description,
    CAST(DiscountPct AS DECIMAL(5,4)),
    Type,
    Category,
    CAST(StartDate AS DATE),
    CAST(EndDate AS DATE),
    MinQty,
    MaxQty,
    CASE WHEN CAST(EndDate AS DATE) >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS IsActive,
    SYSDATETIME(),
    'Bronze'
FROM bronze.SpecialOffer;
GO

PRINT '  ✅ silver.Promotion : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- =============================================================================
-- VALIDATION : Vérification de la couche Silver
-- =============================================================================
PRINT '';
PRINT '═══════════════════════════════════════════════════';
PRINT '📊 VALIDATION COUCHE SILVER';
PRINT '═══════════════════════════════════════════════════';

SELECT 'silver.Sales'     AS TableName, COUNT(*) AS NbRows FROM silver.Sales
UNION ALL
SELECT 'silver.Product',   COUNT(*) FROM silver.Product
UNION ALL
SELECT 'silver.Customer',  COUNT(*) FROM silver.Customer
UNION ALL
SELECT 'silver.Territory', COUNT(*) FROM silver.Territory
UNION ALL
SELECT 'silver.Promotion', COUNT(*) FROM silver.Promotion;
GO

-- Vérification : aucun NULL sur les colonnes critiques
SELECT 'NULLs in Sales.OrderDate'     AS Check_Name, COUNT(*) AS NbNulls FROM silver.Sales WHERE OrderDate IS NULL
UNION ALL
SELECT 'NULLs in Product.ProductName', COUNT(*) FROM silver.Product WHERE ProductName IS NULL
UNION ALL
SELECT 'NULLs in Customer.FullName',   COUNT(*) FROM silver.Customer WHERE FullName IS NULL;
GO

PRINT '';
PRINT '═══════════════════════════════════════════';
PRINT '✅ COUCHE SILVER CHARGÉE AVEC SUCCÈS';
PRINT '═══════════════════════════════════════════';
GO
