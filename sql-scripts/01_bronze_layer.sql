/*
=============================================================================
  SCRIPT 01 — Couche BRONZE (Staging)
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Source   : AdventureWorks2022
  Cible    : AdventureWorks_DW.bronze.*
=============================================================================
  Description :
    Copie brute des tables transactionnelles de la source vers le schéma
    bronze. Chaque table conserve la structure d'origine avec des colonnes
    de traçabilité ajoutées :
      - _LoadDate     : date/heure du chargement
      - _SourceSystem : nom de la base source
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- =============================================
-- 1. BRONZE — Sales.SalesOrderHeader
-- =============================================
IF OBJECT_ID('bronze.SalesOrderHeader', 'U') IS NOT NULL DROP TABLE bronze.SalesOrderHeader;
GO

CREATE TABLE bronze.SalesOrderHeader
(
    SalesOrderID        INT             NOT NULL,
    RevisionNumber      TINYINT         NULL,
    OrderDate           DATETIME        NOT NULL,
    DueDate             DATETIME        NOT NULL,
    ShipDate            DATETIME        NULL,
    [Status]            TINYINT         NOT NULL,
    OnlineOrderFlag     BIT             NOT NULL,
    SalesOrderNumber    NVARCHAR(25)    NULL,
    PurchaseOrderNumber NVARCHAR(25)    NULL,
    AccountNumber       NVARCHAR(15)    NULL,
    CustomerID          INT             NOT NULL,
    SalesPersonID       INT             NULL,
    TerritoryID         INT             NULL,
    BillToAddressID     INT             NULL,
    ShipToAddressID     INT             NULL,
    ShipMethodID        INT             NULL,
    CreditCardID        INT             NULL,
    CreditCardApprovalCode NVARCHAR(15) NULL,
    CurrencyRateID      INT             NULL,
    SubTotal            MONEY           NOT NULL,
    TaxAmt              MONEY           NOT NULL,
    Freight             MONEY           NOT NULL,
    TotalDue            MONEY           NOT NULL,
    Comment             NVARCHAR(128)   NULL,
    ModifiedDate        DATETIME        NULL,
    -- Colonnes de traçabilité
    _LoadDate           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem       NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 2. BRONZE — Sales.SalesOrderDetail
-- =============================================
IF OBJECT_ID('bronze.SalesOrderDetail', 'U') IS NOT NULL DROP TABLE bronze.SalesOrderDetail;
GO

CREATE TABLE bronze.SalesOrderDetail
(
    SalesOrderID          INT             NOT NULL,
    SalesOrderDetailID    INT             NOT NULL,
    CarrierTrackingNumber NVARCHAR(25)    NULL,
    OrderQty              SMALLINT        NOT NULL,
    ProductID             INT             NOT NULL,
    SpecialOfferID        INT             NOT NULL,
    UnitPrice             MONEY           NOT NULL,
    UnitPriceDiscount     MONEY           NOT NULL,
    LineTotal             MONEY           NOT NULL,
    ModifiedDate          DATETIME        NULL,
    -- Colonnes de traçabilité
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 3. BRONZE — Production.Product
-- =============================================
IF OBJECT_ID('bronze.Product', 'U') IS NOT NULL DROP TABLE bronze.Product;
GO

CREATE TABLE bronze.Product
(
    ProductID             INT             NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    ProductNumber         NVARCHAR(25)    NOT NULL,
    MakeFlag              BIT             NOT NULL,
    FinishedGoodsFlag     BIT             NOT NULL,
    Color                 NVARCHAR(15)    NULL,
    SafetyStockLevel      SMALLINT        NOT NULL,
    ReorderPoint          SMALLINT        NOT NULL,
    StandardCost          MONEY           NOT NULL,
    ListPrice             MONEY           NOT NULL,
    Size                  NVARCHAR(5)     NULL,
    SizeUnitMeasureCode   NCHAR(3)        NULL,
    WeightUnitMeasureCode NCHAR(3)        NULL,
    Weight                DECIMAL(8,2)    NULL,
    DaysToManufacture     INT             NOT NULL,
    ProductLine           NCHAR(2)        NULL,
    Class                 NCHAR(2)        NULL,
    Style                 NCHAR(2)        NULL,
    ProductSubcategoryID  INT             NULL,
    ProductModelID        INT             NULL,
    SellStartDate         DATETIME        NOT NULL,
    SellEndDate           DATETIME        NULL,
    DiscontinuedDate      DATETIME        NULL,
    ModifiedDate          DATETIME        NULL,
    -- Colonnes de traçabilité
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 4. BRONZE — Production.ProductCategory
-- =============================================
IF OBJECT_ID('bronze.ProductCategory', 'U') IS NOT NULL DROP TABLE bronze.ProductCategory;
GO

CREATE TABLE bronze.ProductCategory
(
    ProductCategoryID     INT             NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 5. BRONZE — Production.ProductSubcategory
-- =============================================
IF OBJECT_ID('bronze.ProductSubcategory', 'U') IS NOT NULL DROP TABLE bronze.ProductSubcategory;
GO

CREATE TABLE bronze.ProductSubcategory
(
    ProductSubcategoryID  INT             NOT NULL,
    ProductCategoryID     INT             NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 6. BRONZE — Sales.Customer
-- =============================================
IF OBJECT_ID('bronze.Customer', 'U') IS NOT NULL DROP TABLE bronze.Customer;
GO

CREATE TABLE bronze.Customer
(
    CustomerID            INT             NOT NULL,
    PersonID              INT             NULL,
    StoreID               INT             NULL,
    TerritoryID           INT             NULL,
    AccountNumber         NVARCHAR(10)    NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 7. BRONZE — Person.Person
-- =============================================
IF OBJECT_ID('bronze.Person', 'U') IS NOT NULL DROP TABLE bronze.Person;
GO

CREATE TABLE bronze.Person
(
    BusinessEntityID      INT             NOT NULL,
    PersonType            NCHAR(2)        NOT NULL,
    Title                 NVARCHAR(8)     NULL,
    FirstName             NVARCHAR(50)    NOT NULL,
    MiddleName            NVARCHAR(50)    NULL,
    LastName              NVARCHAR(50)    NOT NULL,
    Suffix                NVARCHAR(10)    NULL,
    EmailPromotion        INT             NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 8. BRONZE — Person.EmailAddress
-- =============================================
IF OBJECT_ID('bronze.EmailAddress', 'U') IS NOT NULL DROP TABLE bronze.EmailAddress;
GO

CREATE TABLE bronze.EmailAddress
(
    BusinessEntityID      INT             NOT NULL,
    EmailAddressID        INT             NOT NULL,
    EmailAddress          NVARCHAR(50)    NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 9. BRONZE — Person.Address
-- =============================================
IF OBJECT_ID('bronze.Address', 'U') IS NOT NULL DROP TABLE bronze.Address;
GO

CREATE TABLE bronze.Address
(
    AddressID             INT             NOT NULL,
    AddressLine1          NVARCHAR(60)    NOT NULL,
    AddressLine2          NVARCHAR(60)    NULL,
    City                  NVARCHAR(30)    NOT NULL,
    StateProvinceID       INT             NOT NULL,
    PostalCode            NVARCHAR(15)    NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 10. BRONZE — Person.StateProvince
-- =============================================
IF OBJECT_ID('bronze.StateProvince', 'U') IS NOT NULL DROP TABLE bronze.StateProvince;
GO

CREATE TABLE bronze.StateProvince
(
    StateProvinceID       INT             NOT NULL,
    StateProvinceCode     NCHAR(3)        NOT NULL,
    CountryRegionCode     NVARCHAR(3)     NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    TerritoryID           INT             NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 11. BRONZE — Person.CountryRegion
-- =============================================
IF OBJECT_ID('bronze.CountryRegion', 'U') IS NOT NULL DROP TABLE bronze.CountryRegion;
GO

CREATE TABLE bronze.CountryRegion
(
    CountryRegionCode     NVARCHAR(3)     NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 12. BRONZE — Sales.SalesTerritory
-- =============================================
IF OBJECT_ID('bronze.SalesTerritory', 'U') IS NOT NULL DROP TABLE bronze.SalesTerritory;
GO

CREATE TABLE bronze.SalesTerritory
(
    TerritoryID           INT             NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    CountryRegionCode     NVARCHAR(3)     NOT NULL,
    [Group]               NVARCHAR(50)    NOT NULL,
    SalesYTD              MONEY           NOT NULL,
    SalesLastYear         MONEY           NOT NULL,
    CostYTD               MONEY           NOT NULL,
    CostLastYear          MONEY           NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 13. BRONZE — Sales.SpecialOffer
-- =============================================
IF OBJECT_ID('bronze.SpecialOffer', 'U') IS NOT NULL DROP TABLE bronze.SpecialOffer;
GO

CREATE TABLE bronze.SpecialOffer
(
    SpecialOfferID        INT             NOT NULL,
    Description           NVARCHAR(255)   NOT NULL,
    DiscountPct           SMALLMONEY      NOT NULL,
    Type                  NVARCHAR(50)    NOT NULL,
    Category              NVARCHAR(50)    NOT NULL,
    StartDate             DATETIME        NOT NULL,
    EndDate               DATETIME        NOT NULL,
    MinQty                INT             NOT NULL,
    MaxQty                INT             NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 14. BRONZE — Sales.SpecialOfferProduct
-- =============================================
IF OBJECT_ID('bronze.SpecialOfferProduct', 'U') IS NOT NULL DROP TABLE bronze.SpecialOfferProduct;
GO

CREATE TABLE bronze.SpecialOfferProduct
(
    SpecialOfferID        INT             NOT NULL,
    ProductID             INT             NOT NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================
-- 15. BRONZE — Sales.Store
-- =============================================
IF OBJECT_ID('bronze.Store', 'U') IS NOT NULL DROP TABLE bronze.Store;
GO

CREATE TABLE bronze.Store
(
    BusinessEntityID      INT             NOT NULL,
    Name                  NVARCHAR(50)    NOT NULL,
    SalesPersonID         INT             NULL,
    ModifiedDate          DATETIME        NULL,
    _LoadDate             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    _SourceSystem         NVARCHAR(50)    NOT NULL DEFAULT 'AdventureWorks2022'
);
GO

-- =============================================================================
-- CHARGEMENT BRONZE : Copie brute depuis AdventureWorks2022
-- =============================================================================
-- Note : En production, ce chargement serait fait via SSIS.
-- Ces INSERT INTO simulent le chargement initial pour validation.
-- =============================================================================

PRINT '📥 Chargement des données Bronze en cours...';
GO

-- 1. SalesOrderHeader
TRUNCATE TABLE bronze.SalesOrderHeader;
INSERT INTO bronze.SalesOrderHeader
    (SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, [Status],
     OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber, AccountNumber,
     CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID,
     ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID,
     SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate)
SELECT
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, [Status],
    OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber, AccountNumber,
    CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID,
    ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID,
    SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
FROM [AdventureWorks2022].Sales.SalesOrderHeader;
PRINT '  ✅ bronze.SalesOrderHeader : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 2. SalesOrderDetail
TRUNCATE TABLE bronze.SalesOrderDetail;
INSERT INTO bronze.SalesOrderDetail
    (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty,
     ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, LineTotal, ModifiedDate)
SELECT
    SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty,
    ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, LineTotal, ModifiedDate
FROM [AdventureWorks2022].Sales.SalesOrderDetail;
PRINT '  ✅ bronze.SalesOrderDetail : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 3. Product
TRUNCATE TABLE bronze.Product;
INSERT INTO bronze.Product
    (ProductID, Name, ProductNumber, MakeFlag, FinishedGoodsFlag, Color,
     SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, Size,
     SizeUnitMeasureCode, WeightUnitMeasureCode, Weight, DaysToManufacture,
     ProductLine, Class, Style, ProductSubcategoryID, ProductModelID,
     SellStartDate, SellEndDate, DiscontinuedDate, ModifiedDate)
SELECT
    ProductID, Name, ProductNumber, MakeFlag, FinishedGoodsFlag, Color,
    SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, Size,
    SizeUnitMeasureCode, WeightUnitMeasureCode, Weight, DaysToManufacture,
    ProductLine, Class, Style, ProductSubcategoryID, ProductModelID,
    SellStartDate, SellEndDate, DiscontinuedDate, ModifiedDate
FROM [AdventureWorks2022].Production.Product;
PRINT '  ✅ bronze.Product : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 4. ProductCategory
TRUNCATE TABLE bronze.ProductCategory;
INSERT INTO bronze.ProductCategory (ProductCategoryID, Name, ModifiedDate)
SELECT ProductCategoryID, Name, ModifiedDate
FROM [AdventureWorks2022].Production.ProductCategory;
PRINT '  ✅ bronze.ProductCategory : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 5. ProductSubcategory
TRUNCATE TABLE bronze.ProductSubcategory;
INSERT INTO bronze.ProductSubcategory (ProductSubcategoryID, ProductCategoryID, Name, ModifiedDate)
SELECT ProductSubcategoryID, ProductCategoryID, Name, ModifiedDate
FROM [AdventureWorks2022].Production.ProductSubcategory;
PRINT '  ✅ bronze.ProductSubcategory : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 6. Customer
TRUNCATE TABLE bronze.Customer;
INSERT INTO bronze.Customer (CustomerID, PersonID, StoreID, TerritoryID, AccountNumber, ModifiedDate)
SELECT CustomerID, PersonID, StoreID, TerritoryID, AccountNumber, ModifiedDate
FROM [AdventureWorks2022].Sales.Customer;
PRINT '  ✅ bronze.Customer : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 7. Person
TRUNCATE TABLE bronze.Person;
INSERT INTO bronze.Person
    (BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName,
     Suffix, EmailPromotion, ModifiedDate)
SELECT
    BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName,
    Suffix, EmailPromotion, ModifiedDate
FROM [AdventureWorks2022].Person.Person;
PRINT '  ✅ bronze.Person : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 8. EmailAddress
TRUNCATE TABLE bronze.EmailAddress;
INSERT INTO bronze.EmailAddress (BusinessEntityID, EmailAddressID, EmailAddress, ModifiedDate)
SELECT BusinessEntityID, EmailAddressID, EmailAddress, ModifiedDate
FROM [AdventureWorks2022].Person.EmailAddress;
PRINT '  ✅ bronze.EmailAddress : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 9. Address
TRUNCATE TABLE bronze.Address;
INSERT INTO bronze.Address (AddressID, AddressLine1, AddressLine2, City, StateProvinceID, PostalCode, ModifiedDate)
SELECT AddressID, AddressLine1, AddressLine2, City, StateProvinceID, PostalCode, ModifiedDate
FROM [AdventureWorks2022].Person.[Address];
PRINT '  ✅ bronze.Address : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 10. StateProvince
TRUNCATE TABLE bronze.StateProvince;
INSERT INTO bronze.StateProvince (StateProvinceID, StateProvinceCode, CountryRegionCode, Name, TerritoryID, ModifiedDate)
SELECT StateProvinceID, StateProvinceCode, CountryRegionCode, Name, TerritoryID, ModifiedDate
FROM [AdventureWorks2022].Person.StateProvince;
PRINT '  ✅ bronze.StateProvince : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 11. CountryRegion
TRUNCATE TABLE bronze.CountryRegion;
INSERT INTO bronze.CountryRegion (CountryRegionCode, Name, ModifiedDate)
SELECT CountryRegionCode, Name, ModifiedDate
FROM [AdventureWorks2022].Person.CountryRegion;
PRINT '  ✅ bronze.CountryRegion : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 12. SalesTerritory
TRUNCATE TABLE bronze.SalesTerritory;
INSERT INTO bronze.SalesTerritory
    (TerritoryID, Name, CountryRegionCode, [Group], SalesYTD, SalesLastYear,
     CostYTD, CostLastYear, ModifiedDate)
SELECT
    TerritoryID, Name, CountryRegionCode, [Group], SalesYTD, SalesLastYear,
    CostYTD, CostLastYear, ModifiedDate
FROM [AdventureWorks2022].Sales.SalesTerritory;
PRINT '  ✅ bronze.SalesTerritory : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 13. SpecialOffer
TRUNCATE TABLE bronze.SpecialOffer;
INSERT INTO bronze.SpecialOffer
    (SpecialOfferID, Description, DiscountPct, Type, Category,
     StartDate, EndDate, MinQty, MaxQty, ModifiedDate)
SELECT
    SpecialOfferID, Description, DiscountPct, Type, Category,
    StartDate, EndDate, MinQty, MaxQty, ModifiedDate
FROM [AdventureWorks2022].Sales.SpecialOffer;
PRINT '  ✅ bronze.SpecialOffer : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 14. SpecialOfferProduct
TRUNCATE TABLE bronze.SpecialOfferProduct;
INSERT INTO bronze.SpecialOfferProduct (SpecialOfferID, ProductID, ModifiedDate)
SELECT SpecialOfferID, ProductID, ModifiedDate
FROM [AdventureWorks2022].Sales.SpecialOfferProduct;
PRINT '  ✅ bronze.SpecialOfferProduct : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- 15. Store
TRUNCATE TABLE bronze.Store;
INSERT INTO bronze.Store (BusinessEntityID, Name, SalesPersonID, ModifiedDate)
SELECT BusinessEntityID, Name, SalesPersonID, ModifiedDate
FROM [AdventureWorks2022].Sales.Store;
PRINT '  ✅ bronze.Store : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

PRINT '';
PRINT '═══════════════════════════════════════════';
PRINT '✅ COUCHE BRONZE CHARGÉE AVEC SUCCÈS';
PRINT '═══════════════════════════════════════════';
GO
