/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   Schema Cơ sở dữ liệu cơ bản - v3.5 (Robust Build)
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -------------------------------------------------------------------------
-- 00. XÓA TOÀN BỘ RÀNG BUỘC KHÓA NGOẠI
-- -------------------------------------------------------------------------
PRINT 'Dropping all foreign key constraints...';
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' DROP CONSTRAINT ' + QUOTENAME(f.name) + ';'
FROM sys.foreign_keys AS f
INNER JOIN sys.tables AS t ON f.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id;
EXEC sp_executesql @sql;
GO

-- -------------------------------------------------------------------------
-- 0. DỌN DẸP BẢNG CŨ
-- -------------------------------------------------------------------------
PRINT 'Cleaning up existing tables...';
IF OBJECT_ID('BatchProcessParameterValue', 'U') IS NOT NULL DROP TABLE BatchProcessParameterValue;
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DROP TABLE QualityTests;
IF OBJECT_ID('SystemAuditLog', 'U') IS NOT NULL DROP TABLE SystemAuditLog;
IF OBJECT_ID('MaterialUsage', 'U') IS NOT NULL DROP TABLE MaterialUsage;
IF OBJECT_ID('BatchProcessLogs', 'U') IS NOT NULL DROP TABLE BatchProcessLogs;
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DROP TABLE ProductionBatches;
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DROP TABLE ProductionOrders;
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DROP TABLE InventoryLots;
IF OBJECT_ID('RecipeBom', 'U') IS NOT NULL DROP TABLE RecipeBom;
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DROP TABLE StepParameters;
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DROP TABLE RecipeRouting;
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DROP TABLE Recipes;
IF OBJECT_ID('Materials', 'U') IS NOT NULL DROP TABLE Materials;
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DROP TABLE Equipments;
IF OBJECT_ID('ProductionAreas', 'U') IS NOT NULL DROP TABLE ProductionAreas;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DROP TABLE UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DROP TABLE UnitOfMeasure;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DROP TABLE AppUsers;
GO

-- -------------------------------------------------------------------------
-- 1. AppUsers
-- -------------------------------------------------------------------------
CREATE TABLE AppUsers (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE,
    FullName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50) NOT NULL,
    IsActive BIT DEFAULT 1,
    PasswordHash NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    LastLogin DATETIME2
);
GO

-- -------------------------------------------------------------------------
-- 1b. SystemAuditLog
-- -------------------------------------------------------------------------
CREATE TABLE SystemAuditLog (
    AuditId BIGINT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100) NOT NULL,
    RecordId NVARCHAR(100) NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ChangedBy INT,
    ChangedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- -------------------------------------------------------------------------
-- 2. UnitOfMeasure
-- -------------------------------------------------------------------------
CREATE TABLE UnitOfMeasure (
    UomId INT PRIMARY KEY IDENTITY(1,1),
    UomName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200)
);
GO

-- -------------------------------------------------------------------------
-- 3. UomConversions
-- -------------------------------------------------------------------------
CREATE TABLE UomConversions (
    ConversionId INT PRIMARY KEY IDENTITY(1,1),
    FromUomId INT REFERENCES UnitOfMeasure(UomId),
    ToUomId INT REFERENCES UnitOfMeasure(UomId),
    ConversionFactor DECIMAL(18, 6) NOT NULL,
    Note NVARCHAR(200)
);
GO

-- -------------------------------------------------------------------------
-- 4. ProductionAreas
-- -------------------------------------------------------------------------
CREATE TABLE ProductionAreas (
    AreaId INT PRIMARY KEY IDENTITY(1,1),
    AreaCode VARCHAR(50) NOT NULL UNIQUE,
    AreaName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500)
);
GO

-- -------------------------------------------------------------------------
-- 5. Equipments
-- -------------------------------------------------------------------------
CREATE TABLE Equipments (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE,
    EquipmentName NVARCHAR(200) NOT NULL,
    TechnicalSpecification NVARCHAR(300),
    UsagePurpose NVARCHAR(300),
    AreaId INT REFERENCES ProductionAreas(AreaId)
);
GO

-- -------------------------------------------------------------------------
-- 6. Materials
-- -------------------------------------------------------------------------
CREATE TABLE Materials (
    MaterialId INT PRIMARY KEY IDENTITY(1,1),
    MaterialCode VARCHAR(50) NOT NULL UNIQUE,
    MaterialName NVARCHAR(200) NOT NULL,
    Type NVARCHAR(50) CHECK (Type IN ('RawMaterial', 'Packaging', 'FinishedGood', 'Intermediate')),
    BaseUomId INT REFERENCES UnitOfMeasure(UomId),
    IsActive BIT DEFAULT 1,
    TechnicalSpecification NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2
);
GO

-- -------------------------------------------------------------------------
-- 7. Recipes
-- -------------------------------------------------------------------------
CREATE TABLE Recipes (
    RecipeId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId),
    VersionNumber INT DEFAULT 1,
    BatchSize DECIMAL(18, 2) NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Draft',
    ApprovedBy INT REFERENCES AppUsers(UserId),
    ApprovedDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    EffectiveDate DATETIME2,
    Note NVARCHAR(500)
);
GO

-- -------------------------------------------------------------------------
-- 8. RecipeBom
-- -------------------------------------------------------------------------
CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    MaterialId INT REFERENCES Materials(MaterialId),
    Quantity DECIMAL(18, 4) NOT NULL,
    UomId INT REFERENCES UnitOfMeasure(UomId),
    WastePercentage DECIMAL(5, 2) DEFAULT 0,
    Note NVARCHAR(200)
);
GO

-- -------------------------------------------------------------------------
-- 9. ProductionOrders (Moved up to support RecipeRouting FK)
-- -------------------------------------------------------------------------
CREATE TABLE ProductionOrders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE,
    RecipeId INT REFERENCES Recipes(RecipeId),
    PlannedQuantity DECIMAL(18, 4) NOT NULL,
    ActualQuantity DECIMAL(18, 4),
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(50) DEFAULT 'Draft',
    CreatedBy INT REFERENCES AppUsers(UserId),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(500)
);
GO

-- -------------------------------------------------------------------------
-- 10. RecipeRouting
-- -------------------------------------------------------------------------
CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    OrderId INT NULL REFERENCES ProductionOrders(OrderId),
    StepNumber INT NOT NULL,
    StepName NVARCHAR(100) NOT NULL,
    DefaultEquipmentId INT REFERENCES Equipments(EquipmentId),
    EstimatedTimeMinutes INT,
    Description NVARCHAR(500),
    NumberOfRouting INT DEFAULT 1,
    CONSTRAINT CK_RecipeRouting_NumberOfRouting CHECK (NumberOfRouting >= 1)
);
GO

-- -------------------------------------------------------------------------
-- 11. StepParameters
-- -------------------------------------------------------------------------
CREATE TABLE StepParameters (
    ParameterId INT PRIMARY KEY IDENTITY(1,1),
    RoutingId INT REFERENCES RecipeRouting(RoutingId),
    ParameterName NVARCHAR(100) NOT NULL,
    Unit NVARCHAR(50),
    MinValue DECIMAL(18, 4),
    MaxValue DECIMAL(18, 4),
    IsCritical BIT DEFAULT 1,
    Note NVARCHAR(200)
);
GO

-- -------------------------------------------------------------------------
-- 12. ProductionBatches
-- -------------------------------------------------------------------------
CREATE TABLE ProductionBatches (
    BatchId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT REFERENCES ProductionOrders(OrderId),
    BatchNumber VARCHAR(50) NOT NULL UNIQUE,
    Status NVARCHAR(50) DEFAULT 'Scheduled',
    ManufactureDate DATETIME2,
    EndTime DATETIME2,
    ExpiryDate DATETIME2,
    CurrentStep INT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- -------------------------------------------------------------------------
-- 13. BatchProcessLogs
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessLogs (
    LogId BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    RoutingId INT REFERENCES RecipeRouting(RoutingId),
    EquipmentId INT REFERENCES Equipments(EquipmentId),
    OperatorId INT REFERENCES AppUsers(UserId),
    StartTime DATETIME2,
    EndTime DATETIME2,
    ResultStatus NVARCHAR(50),
    ParametersData NVARCHAR(MAX),
    Notes NVARCHAR(MAX),
    IsDeviation BIT DEFAULT 0,
    VerifiedById INT REFERENCES AppUsers(UserId),
    VerifiedDate DATETIME2,
    NumberOfRouting INT DEFAULT 1
);
GO

-- -------------------------------------------------------------------------
-- 14. BatchProcessParameterValue
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessParameterValue (
    ValueId BIGINT PRIMARY KEY IDENTITY(1,1),
    LogId BIGINT REFERENCES BatchProcessLogs(LogId),
    ParameterId INT REFERENCES StepParameters(ParameterId),
    ActualValue DECIMAL(18, 4),
    RecordedDate DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(500)
);
GO

-- -------------------------------------------------------------------------
-- 15. InventoryLots
-- -------------------------------------------------------------------------
CREATE TABLE InventoryLots (
    LotId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId),
    LotNumber VARCHAR(50) NOT NULL UNIQUE,
    QuantityCurrent DECIMAL(18, 4) NOT NULL,
    ManufactureDate DATETIME2,
    ExpiryDate DATETIME2 NOT NULL,
    QCStatus NVARCHAR(50) DEFAULT 'Pending',
    SupplierName NVARCHAR(200),
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- -------------------------------------------------------------------------
-- 16. MaterialUsage
-- -------------------------------------------------------------------------
CREATE TABLE MaterialUsage (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    PlannedAmount DECIMAL(18, 4),
    ActualAmount DECIMAL(18, 4) NOT NULL,
    UsedDate DATETIME2 DEFAULT GETDATE(),
    DispensedBy INT REFERENCES AppUsers(UserId),
    Timestamp DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(200)
);
GO

-- -------------------------------------------------------------------------
-- 17. QualityTests
-- -------------------------------------------------------------------------
CREATE TABLE QualityTests (
    TestId INT PRIMARY KEY IDENTITY(1,1),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    TestName NVARCHAR(100),
    ResultValue NVARCHAR(200),
    PassStatus BIT DEFAULT 1,
    TestedBy INT REFERENCES AppUsers(UserId),
    TestDate DATETIME2 DEFAULT GETDATE()
);
GO

PRINT 'Centralized Master Schema Created Successfully.';
GO