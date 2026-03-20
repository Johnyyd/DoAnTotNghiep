USE [GMP_WHO_DB];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT 'Seeding Unified GMP-WHO System Master Data (including NLC 3 Capsule for Mobile App Testing)...';

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
-- 1. Unit of Measure
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
-- 2. App Users
-- =====================================================
PRINT 'Seeding App Users...';
INSERT INTO AppUsers (UserCode, Username, FullName, Email, Role, IsActive) VALUES
('USR-ADMIN-01', 'admin', 'Nguyễn Văn Admin', 'admin@gmp.local', 'Admin', 1),
('USR-QC-01', 'qc_specialist', 'Trần Thị Kiểm Tra', 'qc@gmp.local', 'QualityControl', 1),
('USR-MGR-01', 'production_mgr', 'Lê Văn Quản Lý', 'mgr@gmp.local', 'Manager', 1),
('USR-OP-001', 'operator1', 'Phạm Công Nhân', 'op1@gmp.local', 'Operator', 1);

-- =====================================================
-- 3. Equipments
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
-- 4. Materials (Focusing on NLC 3 Capsule workflow)
-- =====================================================
PRINT 'Seeding Materials...';
INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, Description, MinStockLevel, MaxStockLevel) VALUES
-- Raw Materials (ID 1 -> 6)
('MAT-NLC3', 'NLC 3 (Active Ingredient)', 'RawMaterial', 3, 'Medicinal powder', 10, 500),
('MAT-TD1', 'Tá dược TD 1', 'RawMaterial', 3, 'Binder/Excipient', 10, 200),
('MAT-TD3', 'Tá dược TD 3', 'RawMaterial', 3, 'Filler/Excipient', 10, 200),
('MAT-TD4', 'Tá dược TD 4', 'RawMaterial', 3, 'Glidant', 5, 100),
('MAT-TD5', 'Tá dược TD 5', 'RawMaterial', 3, 'Disintegrant', 5, 100),
('MAT-TD8', 'Tá dược TD 8', 'RawMaterial', 3, 'Lubricant', 5, 100),
-- Packaging (ID 7)
('MAT-NLP6', 'Vỏ nang số 0 (NLP 6)', 'Packaging', 6, 'Hard capsule shells', 10000, 1000000),
-- Finished Good (ID 8)
('FG-NLC3-CAP', 'Viên nang NLC 3 hộp 3200v', 'FinishedGood', 8, 'Finished product case', 0, 10000);

-- =====================================================
-- 5. Inventory Lots
-- =====================================================
PRINT 'Seeding Inventory Lots...';
INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierBatchNumber, Location) VALUES
(1, 'LOT-NLC3-001', 500.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-NLC3-001', 'Kho Nguyên Liệu A'),
(2, 'LOT-TD1-001', 200.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-TD-001', 'Kho Nguyên Liệu B'),
(3, 'LOT-TD3-001', 200.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-TD-002', 'Kho Nguyên Liệu B'),
(4, 'LOT-TD4-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-TD-003', 'Kho Nguyên Liệu C'),
(5, 'LOT-TD5-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-TD-004', 'Kho Nguyên Liệu C'),
(6, 'LOT-TD8-001', 100.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released', 'SUP-TD-005', 'Kho Nguyên Liệu C'),
(7, 'LOT-CAPS-001', 500000, GETDATE(), DATEADD(YEAR, 5, GETDATE()), 'Released', 'SUP-PKG-001', 'Kho Bao Bì');

-- =====================================================
-- 6. Recipes
-- =====================================================
PRINT 'Seeding Recipes...';
-- MaterialId 8 is FG-NLC3-CAP
INSERT INTO Recipes (RecipeCode, RecipeName, MaterialId, VersionNumber, Status, ApprovedBy, ApprovedDate, BatchSize) VALUES
('REC-NLC3-V1', 'Công thức Viên nang NLC 3', 8, 1, 'Approved', 1, GETDATE(), 100000);

DECLARE @RecipeID INT = SCOPE_IDENTITY();

-- =====================================================
-- 7. Recipe BOM
-- =====================================================
PRINT 'Seeding Recipe BOM...';
INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, Unit, Note, TolerancePercent) VALUES
(@RecipeID, 1, 50.0, 'kg', 'Hoạt chất NLC 3', 2),
(@RecipeID, 2, 10.0, 'kg', 'Tá dược 1', 5),
(@RecipeID, 3, 5.0,  'kg', 'Tá dược 3', 5),
(@RecipeID, 4, 15.0, 'kg', 'Tá dược 4', 5),
(@RecipeID, 5, 2.5,  'kg', 'Tá dược 5', 5),
(@RecipeID, 6, 1.5,  'kg', 'Tá dược 8', 5),
(@RecipeID, 7, 100000, 'Tablet/Capsule', 'Vỏ nang', 1);

-- =====================================================
-- 8. Recipe Routing
-- =====================================================
PRINT 'Seeding Recipe Routing...';
-- Ensure matching IDs:
-- 1 = Weighing
-- 2 = Cân
-- Wait, the mobile app expects certain steps logic. The PDF says: Cân -> Sấy -> Trộn
INSERT INTO RecipeRouting (RecipeId, StepOrder, StepName, EquipmentId, DurationMin, QcRequired, Description) VALUES
(@RecipeID, 1, 'Cân Nguyên Liệu', 5, 60, 1, 'Weighing all raw materials using PMA-5000 and IW2-60'),
(@RecipeID, 2, 'Sấy Nguyên Liệu', 1, 120, 1, 'Drying NLC 3 and TD 8 at 75°C'),
(@RecipeID, 3, 'Trộn Khô', 2, 30, 1, 'Mixing powder at 15 RPM for 15-30 minutes'),
(@RecipeID, 4, 'Đóng Nang', 3, 240, 1, 'Automatic capsule filling'),
(@RecipeID, 5, 'Xát Bóng Nang', 4, 60, 0, 'Polishing capsules'),
(@RecipeID, 6, 'Ép Vỉ & Nhập Kho', NULL, 120, 1, 'Final packaging into cases of 3200');

-- =====================================================
-- 9. Production Orders & Batches (Mapping to PDF)
-- =====================================================
PRINT 'Seeding Production Orders & Batches...';
-- PDF states: Lô xo (Batch No): 112026
INSERT INTO ProductionOrders (OrderNumber, ProductId, RecipeId, PlannedQuantity, PlannedStartDate, Status, CreatedBy, CreatedAt) VALUES
('PO-NLC3-001', 8, @RecipeID, 3200, GETDATE(), 'Approved', 3, GETDATE());

DECLARE @OrderID INT = SCOPE_IDENTITY();

INSERT INTO ProductionBatches (OrderId, BatchNumber, PlannedQuantity, Status, ManufacturerDate, ExpiryDate) VALUES
(@OrderID, '112026', 3200, 'In-Progress', GETDATE(), DATEADD(YEAR, 3, GETDATE()));

-- BatchId will be 1
-- StepId for Cân = 1, Sấy = 2, Trộn = 3

PRINT 'Unified Seeding completed successfully!';
GO
