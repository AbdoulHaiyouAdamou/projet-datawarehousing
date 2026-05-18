/*
=============================================================================
  SCRIPT 00 — Création de la base de données et des schémas
  Projet  : Plateforme Décisionnelle — Analyse des Ventes
  Source   : AdventureWorks2022
  Cible    : AdventureWorks_DW (Data Warehouse)
  Auteur   : Équipe Analyse des Ventes
  Date     : Mai 2026
=============================================================================
  Description :
    Ce script crée la base de données cible (AdventureWorks_DW) ainsi que
    les trois schémas de l'architecture Medallion :
      - bronze : données brutes importées telles quelles (staging)
      - silver : données nettoyées, dédupliquées, enrichies
      - gold   : modèle en étoile (faits + dimensions) prêt pour l'analyse
=============================================================================
*/

-- =============================================
-- 1. Création de la base de données
-- =============================================
USE [master];
GO

-- Supprimer la base si elle existe déjà (pour les réexécutions)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'AdventureWorks_DW')
BEGIN
    ALTER DATABASE [AdventureWorks_DW] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [AdventureWorks_DW];
END
GO

CREATE DATABASE [AdventureWorks_DW];
GO

-- =============================================
-- 2. Configuration de la base
-- =============================================
ALTER DATABASE [AdventureWorks_DW] SET RECOVERY SIMPLE;
ALTER DATABASE [AdventureWorks_DW] SET AUTO_SHRINK OFF;
ALTER DATABASE [AdventureWorks_DW] SET AUTO_UPDATE_STATISTICS ON;
GO

USE [AdventureWorks_DW];
GO

-- =============================================
-- 3. Création des schémas Medallion
-- =============================================

-- Schéma BRONZE : données brutes (staging)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA [bronze]');
GO

-- Schéma SILVER : données nettoyées et enrichies
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA [silver]');
GO

-- Schéma GOLD : modèle en étoile (faits + dimensions)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA [gold]');
GO

-- =============================================
-- 4. Table de métadonnées pour le suivi ETL
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_LoadLog' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ETL_LoadLog
    (
        LoadID          INT IDENTITY(1,1)   PRIMARY KEY,
        LoadDate        DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
        LayerName       NVARCHAR(20)        NOT NULL,  -- 'Bronze', 'Silver', 'Gold'
        TableName       NVARCHAR(128)       NOT NULL,
        RowsInserted    INT                 NULL,
        RowsUpdated     INT                 NULL,
        RowsDeleted     INT                 NULL,
        Status          NVARCHAR(20)        NOT NULL DEFAULT 'Running', -- Running, Success, Failed
        ErrorMessage    NVARCHAR(MAX)       NULL,
        StartTime       DATETIME2           NOT NULL DEFAULT SYSDATETIME(),
        EndTime         DATETIME2           NULL,
        DurationSeconds AS DATEDIFF(SECOND, StartTime, EndTime)
    );
END
GO

PRINT '✅ Base AdventureWorks_DW créée avec succès.';
PRINT '✅ Schémas bronze, silver, gold créés.';
PRINT '✅ Table de log ETL créée.';
GO
