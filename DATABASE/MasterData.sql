-- B?ng ??n v? tính (kg, mg, tablet, blister...)
CREATE TABLE UnitOfMeasure (
    UomID INT PRIMARY KEY IDENTITY(1,1),
    UomName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200)
);

-- B?ng Nguyên li?u & Thành ph?m (Qu?n lý chung ?? d? truy xu?t)
CREATE TABLE Materials (
    MaterialID INT PRIMARY KEY IDENTITY(1,1),
    MaterialCode VARCHAR(50) NOT NULL UNIQUE, -- Mã SKU
    MaterialName NVARCHAR(200) NOT NULL,
    Type NVARCHAR(50) CHECK (Type IN ('RawMaterial', 'Packaging', 'FinishedGood', 'Intermediate')), -- Lo?i: Nguyên li?u, Bao bì, Thành ph?m, Bán thành ph?m
    BaseUomID INT REFERENCES UnitOfMeasure(UomID),
    IsActive BIT DEFAULT 1,
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2
);

-- B?ng Máy móc/Thi?t b? (GMP yêu c?u ghi rõ làm trên máy nào)
CREATE TABLE Equipments (
    EquipmentID INT PRIMARY KEY IDENTITY(1,1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE,
    EquipmentName NVARCHAR(200) NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Ready', -- Ready, Maintenance, Running
    LastMaintenanceDate DATETIME2
);


DELETE FROM Materials WHERE MaterialCode = 'MAT-001';

SELECT * FROM Materials;

SELECT MaterialId, MaterialCode, MaterialName FROM Materials

SELECT * FROM UnitOfMeasure;
SELECT * FROM Materials;
SELECT * FROM Equipments;
SELECT * FROM AppUsers;
SELECT * FROM ProductionOrders;
SELECT * FROM ProductionBatches;
SELECT * FROM RecipeBOM;
SELECT * FROM RecipeRouting;
SELECT * FROM Recipes;
SELECT * FROM InventoryLots;
SELECT * FROM MaterialUsage;
SELECT * FROM BatchProcessLogs;
SELECT * FROM SystemAuditLog;
SELECT * FROM UomConversions;


-- 1. Xóa d? li?u các b?ng con (B?ng ph? thu?c) tr??c
DELETE FROM MaterialUsage;       -- Xóa l?ch s? c?p phát
DELETE FROM BatchProcessLogs;    -- Xóa nh?t ký s?n xu?t
DELETE FROM InventoryLots;       -- Xóa t?n kho
DELETE FROM ProductionBatches;   -- Xóa lô s?n xu?t
DELETE FROM ProductionOrders;    -- Xóa l?nh s?n xu?t
DELETE FROM RecipeBom;           -- Xóa chi ti?t công th?c
DELETE FROM Recipes;             -- Xóa công th?c
DELETE FROM Materials;           -- Xóa nguyên li?u
DELETE FROM RecipeRouting;     -- Xóa quy trình s?n xu?t
DELETE FROM Equipments;        -- Xóa thi?t b?
DELETE FROM UomConversions;   -- Xóa quy ??i ??n v?
DELETE FROM SystemAuditLog;  -- Xóa log h? th?ng

-- 2. Reset b? ??m ID v? 0 (?? b?n ghi ti?p theo s? b?t ??u là 1)
-- L?u ý: N?u b?ng nào ch?a có d? li?u thì l?nh này v?n ch?y an toàn
DBCC CHECKIDENT ('MaterialUsage', RESEED, 0);
DBCC CHECKIDENT ('BatchProcessLogs', RESEED, 0);
DBCC CHECKIDENT ('InventoryLots', RESEED, 0);
DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
-- RecipeBom th??ng dùng ID ph?c h?p ho?c t? t?ng, n?u t? t?ng thì thêm dòng d??i:
-- DBCC CHECKIDENT ('RecipeBom', RESEED, 0); 
DBCC CHECKIDENT ('Recipes', RESEED, 0);
DBCC CHECKIDENT ('Materials', RESEED, 0);
DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
DBCC CHECKIDENT ('Equipments', RESEED, 0);
DBCC CHECKIDENT ('SystemAuditLog', RESEED, 0);


PRINT '>>> ?Ã XÓA S?CH D? LI?U VÀ RESET ID THÀNH CÔNG! <<<';


