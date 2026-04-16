USE PharmaceuticalProcessingManagementSystem;
GO

-- 1. Values & Logs
IF OBJECT_ID('BatchProcessParameterValues', 'U') IS NOT NULL DROP TABLE BatchProcessParameterValues;
IF OBJECT_ID('BatchProcessLogs', 'U') IS NOT NULL DROP TABLE BatchProcessLogs;

-- 2. Usages & Batches
IF OBJECT_ID('MaterialUsage', 'U') IS NOT NULL DROP TABLE MaterialUsage;
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DROP TABLE ProductionBatches;

-- 3. Steps & Parameters
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DROP TABLE StepParameters;

-- 4. Orders & Routings
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DROP TABLE ProductionOrders;
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DROP TABLE RecipeRouting;
IF OBJECT_ID('RecipeBOM', 'U') IS NOT NULL DROP TABLE RecipeBOM;

-- 5. Recipes & Inventory
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DROP TABLE Recipes;
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DROP TABLE InventoryLots;

-- 6. Materials & Conversions
IF OBJECT_ID('Materials', 'U') IS NOT NULL DROP TABLE Materials;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DROP TABLE UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DROP TABLE UnitOfMeasure;

-- 7. Master Data
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DROP TABLE Equipments;
IF OBJECT_ID('SystemAuditLog', 'U') IS NOT NULL DROP TABLE SystemAuditLog;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DROP TABLE AppUsers;
GO
