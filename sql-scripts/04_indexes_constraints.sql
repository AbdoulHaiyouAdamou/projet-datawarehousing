/*
=============================================================================
  SCRIPT 04 — Index, Contraintes et Optimisation
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Cible    : AdventureWorks_DW.gold.*
=============================================================================
  Description :
    - Index columnstore clustered sur la table de faits (optimisation OLAP)
    - Contraintes de clés étrangères (FK) pour l'intégrité référentielle
    - Index non-clustered sur les colonnes fréquemment filtrées
    - Partitionnement par année (optionnel, pour les performances)
=============================================================================
*/

USE [AdventureWorks_DW];
GO

-- =============================================================================
-- 1. CLÉ PRIMAIRE sur la table de faits
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'PK_FactVentes')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT PK_FactVentes PRIMARY KEY NONCLUSTERED (SalesKey);
END
GO

-- =============================================================================
-- 2. INDEX COLUMNSTORE CLUSTERED sur FactVentes
--    Optimise les requêtes analytiques (agrégation, scan complet)
-- =============================================================================
-- Note : On ne peut pas avoir un CCI et un CI en même temps.
-- On utilise un CCI pour les performances OLAP.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'CCI_FactVentes' AND object_id = OBJECT_ID('gold.FactVentes'))
    DROP INDEX CCI_FactVentes ON gold.FactVentes;
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX CCI_FactVentes
ON gold.FactVentes
(
    DateKey, ProductKey, CustomerKey, TerritoryKey, PromotionKey,
    OrderQuantity, UnitPrice, SalesAmount, TotalProductCost, Profit,
    TaxAmount, Freight
);
GO

PRINT '  ✅ Index Columnstore sur FactVentes créé';
GO

-- =============================================================================
-- 3. CONTRAINTES DE CLÉS ÉTRANGÈRES (FK)
-- =============================================================================

-- FK → DimDate
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentes_DimDate')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT FK_FactVentes_DimDate
        FOREIGN KEY (DateKey) REFERENCES gold.DimDate(DateKey);
END
GO

-- FK → DimProduct
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentes_DimProduct')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT FK_FactVentes_DimProduct
        FOREIGN KEY (ProductKey) REFERENCES gold.DimProduct(ProductKey);
END
GO

-- FK → DimCustomer
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentes_DimCustomer')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT FK_FactVentes_DimCustomer
        FOREIGN KEY (CustomerKey) REFERENCES gold.DimCustomer(CustomerKey);
END
GO

-- FK → DimTerritory
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentes_DimTerritory')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT FK_FactVentes_DimTerritory
        FOREIGN KEY (TerritoryKey) REFERENCES gold.DimTerritory(TerritoryKey);
END
GO

-- FK → DimPromotion
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentes_DimPromotion')
BEGIN
    ALTER TABLE gold.FactVentes
        ADD CONSTRAINT FK_FactVentes_DimPromotion
        FOREIGN KEY (PromotionKey) REFERENCES gold.DimPromotion(PromotionKey);
END
GO

PRINT '  ✅ 5 contraintes FK créées sur FactVentes';
GO

-- =============================================================================
-- 4. INDEX NON-CLUSTERED sur les clés étrangères de FactVentes
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVentes_DateKey')
    CREATE NONCLUSTERED INDEX IX_FactVentes_DateKey
    ON gold.FactVentes(DateKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVentes_ProductKey')
    CREATE NONCLUSTERED INDEX IX_FactVentes_ProductKey
    ON gold.FactVentes(ProductKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVentes_CustomerKey')
    CREATE NONCLUSTERED INDEX IX_FactVentes_CustomerKey
    ON gold.FactVentes(CustomerKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVentes_TerritoryKey')
    CREATE NONCLUSTERED INDEX IX_FactVentes_TerritoryKey
    ON gold.FactVentes(TerritoryKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVentes_PromotionKey')
    CREATE NONCLUSTERED INDEX IX_FactVentes_PromotionKey
    ON gold.FactVentes(PromotionKey);
GO

PRINT '  ✅ 5 index NC sur les FK de FactVentes créés';
GO

-- =============================================================================
-- 5. INDEX sur les dimensions (recherche fréquente)
-- =============================================================================

-- DimDate : recherche par année, mois
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DimDate_YearMonth')
    CREATE NONCLUSTERED INDEX IX_DimDate_YearMonth
    ON gold.DimDate([Year], [Month]) INCLUDE (QuarterName, MonthName);
GO

-- DimProduct : recherche par catégorie
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DimProduct_Category')
    CREATE NONCLUSTERED INDEX IX_DimProduct_Category
    ON gold.DimProduct(CategoryName, SubCategoryName) INCLUDE (ProductName, ListPrice);
GO

-- DimProduct : recherche par business key (SCD lookup)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DimProduct_ProductID')
    CREATE NONCLUSTERED INDEX IX_DimProduct_ProductID
    ON gold.DimProduct(ProductID, IsCurrent) INCLUDE (ProductKey);
GO

-- DimCustomer : recherche par type et pays
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DimCustomer_Type_Country')
    CREATE NONCLUSTERED INDEX IX_DimCustomer_Type_Country
    ON gold.DimCustomer(CustomerType, CountryName) INCLUDE (FullName);
GO

-- DimTerritory : recherche par groupe
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DimTerritory_Group')
    CREATE NONCLUSTERED INDEX IX_DimTerritory_Group
    ON gold.DimTerritory(GroupName) INCLUDE (TerritoryName, CountryName);
GO

PRINT '  ✅ Index sur les dimensions créés';
GO

-- =============================================================================
-- 6. STATISTIQUES
-- =============================================================================
UPDATE STATISTICS gold.FactVentes;
UPDATE STATISTICS gold.DimDate;
UPDATE STATISTICS gold.DimProduct;
UPDATE STATISTICS gold.DimCustomer;
UPDATE STATISTICS gold.DimTerritory;
UPDATE STATISTICS gold.DimPromotion;
GO

PRINT '';
PRINT '═══════════════════════════════════════════';
PRINT '✅ INDEX ET CONTRAINTES CRÉÉS AVEC SUCCÈS';
PRINT '═══════════════════════════════════════════';
GO
