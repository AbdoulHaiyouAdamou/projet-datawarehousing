# 📊 Plateforme Décisionnelle | Analyse des Ventes
## Projet de Fin de Module · Data Warehousing

> Plateforme BI complète pour l'analyse des ventes d'**Adventure Works**, construite avec une architecture **Medallion** (Bronze → Silver → Gold) sur SQL Server.

---

## 🎯 Objectif

Centraliser, nettoyer et modéliser les données transactionnelles d'Adventure Works afin de fournir aux décideurs :
- Un **reporting consolidé** et des **tableaux de bord interactifs**
- Le suivi des **KPI métiers** : CA, marge, performance produits, analyse géographique
- L'identification des **tendances** et l'aide à la décision stratégique

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ AdventureWorks  │────▶│   BRONZE    │────▶│   SILVER    │────▶│    GOLD     │
│  2022 (OLTP)    │SSIS │  (Staging)  │SSIS │  (Nettoyé)  │SSIS │  (Étoile)  │
└─────────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                       │
                                                          ┌────────────┼────────────┐
                                                          │            │            │
                                                     ┌────▼────┐ ┌────▼────┐ ┌────▼────┐
                                                     │  SSAS   │ │Power BI │ │Requêtes │
                                                     │  Cube   │ │Dashboard│ │   SQL   │
                                                     └─────────┘ └─────────┘ └─────────┘
```

## 🛠️ Prérequis

| Outil | Version | Usage |
|-------|---------|-------|
| SQL Server | 2022 Express | Moteur de base de données |
| SSMS | 22+ | Administration + SSIS/SSAS |
| SSIS | via SSMS 22 BI | Packages ETL |
| SSAS | via SSMS 22 BI | Cube OLAP |
| Power BI Desktop | Dernière version | Dashboards |

## 📦 Installation

### 1. Restaurer la base source
```sql
RESTORE DATABASE [AdventureWorks2022]
FROM DISK = N'C:\SQLBackups\AdventureWorks2022.bak'
WITH MOVE 'AdventureWorks2022' TO 'C:\...\DATA\AdventureWorks2022.mdf',
     MOVE 'AdventureWorks2022_log' TO 'C:\...\DATA\AdventureWorks2022_log.ldf',
     REPLACE;
```

### 2. Créer le Data Warehouse
Exécuter les scripts dans l'ordre :
```
sql-scripts/00_create_database.sql      → Création base + schémas
sql-scripts/01_bronze_layer.sql         → Tables staging
sql-scripts/02_silver_layer.sql         → Tables nettoyées
sql-scripts/03_gold_layer.sql           → Schéma en étoile
sql-scripts/04_indexes_constraints.sql  → Index et contraintes FK
sql-scripts/05_analytical_views.sql     → Vues métier
sql-scripts/06_kpi_queries.sql          → Requêtes KPI de validation
```

### 3. Configurer SSIS

### 4. Déployer le cube SSAS


### 5. Connecter Power BI


## 📁 Structure du projet

```
├── sql-scripts/           Scripts SQL (Bronze/Silver/Gold, index, vues, KPIs)
├── ssis-packages/         Packages SSIS organisés par couche Medallion
├── ssas-cube/             Solution SSAS et fichiers de déploiement
├── powerbi/               Rapports Power BI et thème personnalisé
├── diagrams/              Schémas d'architecture, MCD, flux de données
├── docs/                  Documentation technique et fonctionnelle
└── README.md              Ce fichier
```

## 📐 Modèle en étoile (Gold Layer)

| Table | Type | Description |
|-------|------|-------------|
| `gold.FactVentes` | Fait | Lignes de commandes avec CA, coût, marge, quantité |
| `gold.DimDate` | Dimension | Calendrier (année, trimestre, mois, jour, semaine) |
| `gold.DimProduct` | Dimension | Produits avec catégorie/sous-catégorie (SCD Type 2) |
| `gold.DimCustomer` | Dimension | Clients (Individual / Store) avec adresse |
| `gold.DimTerritory` | Dimension | Territoires et régions géographiques |
| `gold.DimPromotion` | Dimension | Offres spéciales et promotions |

## 📊 KPIs principaux

- **Chiffre d'Affaires (CA)** — total, par période, par région
- **Marge bénéficiaire** — profit / CA
- **Quantité vendue** — par produit, par catégorie
- **Top produits** — classement par CA
- **Analyse géographique** — CA par territoire / pays
- **Croissance YoY** — comparaison année N vs N-1
- **Panier moyen** — CA / nombre de commandes

## 👥 Équipe

| Membre | Rôle | Périmètre |
|--------|------|-----------|
| Étudiant 1 | Data Engineer | Architecture Medallion, scripts SQL |
| Étudiant 2 | ETL Developer | Packages SSIS, chargement des données |
| Étudiant 3 | BI Developer | Cube SSAS, mesures, dimensions |
| Étudiant 4 | Data Analyst | Power BI, documentation, rapport |

## 📄 Licence

Projet académique — Données source : [AdventureWorks2022](https://github.com/Microsoft/sql-server-samples) (Microsoft)
