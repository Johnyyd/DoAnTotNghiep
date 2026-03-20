USE [GMP_WHO_DB];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT 'Seeding Unified GMP-WHO System Master Data (Fixed Schema)...';

-- Disable constraints to allow cleanup
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
DELETE FROM MaterialUsage;
DELETE FROM BatchProcessLogs;
DELETE FROM ProductionBatches;
DELETE FROM ProductionOrders;
DELETE FROM RecipeBOM;
DELETE FROM RecipeRouting;
DELETE FROM Recipes;
DELETE FROM InventoryLots;
DELETE FROM Materials;
DELETE FROM Equipments;
DELETE FROM AppUsers;
DELETE FROM UnitOfMeasure;
DELETE FROM SystemAuditLog;
DELETE FROM UomConversions;
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Reset Identities
DECLARE @TableName NVARCHAR(255);
DECLARE table_cursor CURSOR FOR 
SELECT name FROM sys.tables WHERE OBJECTPROPERTY(object_id, 'TableHasIdentity') = 1;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName;
WHILE @@FETCH_STATUS = 0
BEGIN
    DBCC CHECKIDENT (@TableName, RESEED, 0);
    FETCH NEXT FROM table_cursor INTO @TableName;
END
CLOSE table_cursor;
DEALLOCATE table_cursor;

-- =====================================================
-- 1. Unit of Measure (ID 1-8)
-- =====================================================
PRINT 'Seeding Units of Measure...';
INSERT INTO UnitOfMeasure (UomName, Description) VALUES
('mg', 'Milligram'),
('g', 'Gram'),
('kg', 'Kilogram'),
('ml', 'Milliliter'),
('L', 'Liter'),
('Tablet/Capsule', 'Single pill unit'),
('Blister', 'Plastic/Foil strip'),
('Box', 'Outer cardboard box');

-- =====================================================
-- 2. App Users (ID 1-4)
-- =================)
PRINT 'Seeding App Users...';
INSERT INTO AppUsers (Username, FullName, Role, IsActive) VALUES
('admin', 'Nguyễn Văn Admin', 'Admin', 1),
('qc_specialist', 'Trần Thị Kiểm Tra', 'QA_QC', 1),
('production_mgr', 'Lê Văn Quản Lý', 'ProductionManager', 1),
('operator1', 'Phạm Công Nhân', 'Operator', 1);

-- =====================================================
-- 3. Equipments (ID 1-6)
-- =====================================================
PRINT 'Seeding Equipments...';
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('EQP-DRY-02', 'Máy sấy tầng sôi KBC-TS-50', 'Ready'),
('EQP-MIX-02', 'Máy trộn lập phương AD-LP-200', 'Ready'),
('EQP-FIL-01', 'Máy đóng nang tự động NJP-1200 D', 'Ready'),
('EQP-POL-01', 'Máy xát bóng IPJ', 'Ready'),
('EQP-WGH-01', 'Cân điện tử PMA-5000', 'Ready'),
('EQP-WGH-02', 'Cân phân tích IW2-60', 'Ready');

-- =====================================================
-- 4. Materials (ID 1-8)
-- =====================================================
PRINT 'Seeding Materials...';
INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, Description, IsActive) VALUES
-- Raw Materials (ID 1 -> 6)
('MAT-NLC3', 'NLC 3 (Active Ingredient)', 'RawMaterial', 3, 'Medicinal powder', 1),
('MAT-TD1', 'Tá dược TD 1', 'RawMaterial', 3, 'Binder/Excipient', 1),
('MAT-TD3', 'Tá dược TD 3', 'RawMaterial', 3, 'Filler/Excipient', 1),
('MAT-TD4', 'Tá dược TD 4', 'RawMaterial', 3, 'Glidant', 1),
('MAT-TD5', 'Tá dược TD 5', 'RawMaterial', 3, 'Disintegrant', 1),
('MAT-TD8', 'Tá dược TD 8', 'RawMaterial', 3, 'Lubricant', 1),
-- Packaging (ID 7)
('MAT-NLP6', 'Vỏ nang số 0 (NLP 6)', 'Packaging', 6, 'Hard capsule shells', 1),
-- Finished Good (ID 8)
('FG-NLC3-CAP', 'Viên nang NLC 3 hộp 3200v', 'FinishedGood', 8, 'Finished product case', 1);

-- =====================================================
-- 5. Inventory Lots (ID 1-7)
-- =====================================================
PRINT 'Seeding Inventory Lots...';
INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus) VALUES
(1, 'LOT-NLC3-001', 500.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(2, 'LOT-TD1-001', 200.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(3, 'LOT-TD3-001', 200.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(4, 'LOT-TD4-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(5, 'LOT-TD5-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(6, 'LOT-TD8-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'),
(7, 'LOT-CAPS-001', 500000, GETDATE(), DATEADD(YEAR, 5, GETDATE()), 'Released');

-- =====================================================
-- 6. Recipes (ID 1)
-- =====================================================
PRINT 'Seeding Recipes...';
INSERT INTO Recipes (MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt) VALUES
(8, 1, 100000, 'Approved', 1, GETDATE(), GETDATE());

DECLARE @RecipeID INT = SCOPE_IDENTITY();

-- =====================================================
-- 7. Recipe BOM
-- =====================================================
PRINT 'Seeding Recipe BOM...';
INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, UomId, Note, WastePercentage) VALUES
(@RecipeID, 1, 50.0, 3, 'Hoạt chất NLC 3', 0),
(@RecipeID, 2, 10.0, 3, 'Tá dược 1', 0),
(@RecipeID, 3, 5.0,  3, 'Tá dược 3', 0),
(@RecipeID, 4, 15.0, 3, 'Tá dược 4', 0),
(@RecipeID, 5, 2.5,  3, 'Tá dược 5', 0),
(@RecipeID, 6, 1.5,  3, 'Tá dược 8', 0),
(@RecipeID, 7, 100000, 6, 'Vỏ nang', 0);

-- =====================================================
-- 8. Recipe Routing (ID 1-6)
-- =====================================================
PRINT 'Seeding Recipe Routing...';
INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentID, EstimatedTimeMinutes, Description) VALUES
(@RecipeID, 1, 'Cân Nguyên Liệu', 5, 60, 'Weighing all raw materials using PMA-5000 and IW2-60'),
(@RecipeID, 2, 'Sấy Nguyên Liệu', 1, 120, 'Drying NLC 3 and TD 8 at 75°C'),
(@RecipeID, 3, 'Trộn Khô', 2, 30, 'Mixing powder at 15 RPM for 15-30 minutes'),
(@RecipeID, 4, 'Đóng Nang', 3, 240, 'Automatic capsule filling'),
(@RecipeID, 5, 'Xát Bóng Nang', 4, 60, 'Polishing capsules'),
(@RecipeID, 6, 'Ép Vỉ & Nhập Kho', NULL, 120, 'Final packaging into cases of 3200');

-- =====================================================
-- 9. Production Orders & Batches (ID 1)
-- =====================================================
PRINT 'Seeding Production Orders & Batches...';
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, StartDate, Status, CreatedBy) VALUES
('PO-NLC3-001', @RecipeID, 3200, GETDATE(), 'Approved', 1);

DECLARE @OrderID INT = SCOPE_IDENTITY();

INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, ExpiryDate) VALUES
(@OrderID, '112026', 'In-Process', GETDATE(), DATEADD(YEAR, 3, GETDATE()));

PRINT 'Unified Seeding completed successfully!';
GO
