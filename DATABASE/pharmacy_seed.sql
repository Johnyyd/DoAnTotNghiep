USE [GMP_WHO_DB];
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT 'Seeding GMP Database with sample data...';
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

PRINT 'Seeding Units of Measure...';
INSERT INTO UnitOfMeasure (UomName, Description) VALUES
('mg', 'Milligram'),
('g', 'Gram'),
('kg', 'Kilogram'),
('ml', 'Milliliter'),
('L', 'Liter'),
('Tablet', 'Single Tablet unit'),
('Vial', 'Glass container for injectables'),
('Ampoule', 'Sealed glass capsule'),
('Blister', 'Plastic/Foil strip of tablets'),
('Box', 'Outer cardboard packaging'),
('Batch', 'Production batch unit');

PRINT 'Seeding App Users...';
INSERT INTO AppUsers (Username, FullName, Role, IsActive) VALUES
('admin', 'Nguyễn Văn Admin', 'Admin', 1),
('qc_specialist', 'Trần Thị Kiểm Tra', 'QualityControl', 1),
('production_mgr', 'Lê Văn Quản Lý', 'Manager', 1),
('operator1', 'Phạm Văn Vận Hành', 'Operator', 1),
('operator2', 'Hoàng Văn Máy Móc', 'Operator', 1);

PRINT 'Seeding Materials...';
-- Material(MaterialCode, MaterialName, Type, BaseUomId, Description)
INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, Description) VALUES
-- Raw Materials (APIs)
('API-AMO-500', 'Amoxicillin Trihydrate', 'RawMaterial', 3, 'Active Pharmaceutical Ingredient for antibiotics'),
('API-CLAV-125', 'Potassium Clavulanate', 'RawMaterial', 3, 'Beta-lactamase inhibitor'),
-- Excipients
('EXC-MCC-101', 'Microcrystalline Cellulose PH101', 'RawMaterial', 3, 'Binder/Filler for direct compression'),
('EXC-MAG-ST', 'Magnesium Stearate', 'RawMaterial', 3, 'Lubricant for tablet pressing'),
-- Packaging
('PKG-ALU-72', 'Alu-Alu Foil 72mm', 'Packaging', 5, 'Cold form foil for blisters'),
('PKG-BOX-AUG', 'Augmentin 625mg Box', 'Packaging', 10, 'Folded carton box for 2x7 blisters'),
-- Finished Goods
('FG-AUG-625', 'Augmentin 625mg Tablet', 'FinishedGood', 6, 'Finished antibiotic tablet (500mg/125mg)');

PRINT 'Seeding Equipments...';
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('MIX-DRY-01', 'Bin Blender - High Shear', 'Ready'),
('TAB-PRS-01', 'Rotary Tablet Press - 32 Station', 'Ready'),
('COAT-PAN-01', 'Auto Coater 120kg', 'Ready'),
('BLIS-PKG-01', 'High Speed Alu-Alu Blister Machine', 'Ready'),
('CART-MAC-01', 'Horizontal Cartoning Machine', 'Maintenance'),
('HVAC-SYS-01', 'Central AHU - Cleanroom Grade A', 'Ready');

PRINT 'Seeding Recipes...';
-- Recipe(MaterialId, VersionNumber, Status, ApprovedBy, BatchSize)
-- FG-AUG-625 is MaterialID 7
INSERT INTO Recipes (MaterialId, VersionNumber, Status, ApprovedBy, ApprovedDate, BatchSize) VALUES
(7, 1, 'Approved', 1, GETDATE(), 50000);

PRINT 'Seeding Recipe BOM...';
-- BOM(RecipeId, MaterialId, Quantity, UomId)
INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, UomId, Note) VALUES
(1, 1, 25.0, 3, 'Amoxicillin base'),
(1, 2, 6.25, 3, 'Clavulanate base'),
(1, 3, 15.0, 3, 'Filler'),
(1, 4, 0.5, 3, 'Lubricant');

PRINT 'Seeding Recipe Routing...';
-- Routing(RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes)
INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes) VALUES
(1, 1, 'Weighing API & Excipients', NULL, 60),
(1, 2, 'Granulation & Blending', 1, 120),
(1, 4, 'Tablet Compression', 2, 240),
(1, 5, 'Quality Check (In-process)', NULL, 30),
(1, 6, 'Blister Packaging', 4, 180);

PRINT 'Seeding Inventory Lots...';
-- InventoryLot(MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus)
INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus) VALUES
(1, 'LOT-AMO-X01', 500.0, '2025-01-10', '2027-01-10', 'Released'),
(1, 'LOT-AMO-X02', 200.0, '2025-02-15', '2027-02-15', 'Quarantine'),
(2, 'LOT-CLAV-A01', 100.0, '2025-01-20', '2026-07-20', 'Released'),
(3, 'LOT-MCC-B05', 1000.0, '2024-12-01', '2026-12-01', 'Released'),
(4, 'LOT-MAG-C12', 50.0, '2025-03-01', '2028-03-01', 'Released');

PRINT 'Seeding Production Orders...';
-- ProductionOrder(OrderCode, RecipeId, PlannedQuantity, Status, CreatedBy)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, Status, CreatedBy, CreatedAt) VALUES
('PO-2026-001', 1, 50000, 'Completed', 3, '2026-02-15'),
('PO-2026-002', 1, 50000, 'In-Progress', 3, '2026-03-10'),
('PO-2026-003', 1, 25000, 'Approved', 3, '2026-03-16');

PRINT 'Seeding Production Batches...';
-- ProductionBatch(OrderId, BatchNumber, Status, ManufactureDate, CurrentStep)
INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, CurrentStep) VALUES
(1, 'BATCH-AUG-X001', 'Completed', '2026-02-17', 5),
(2, 'BATCH-AUG-X002', 'In-Progress', '2026-03-12', 3);

PRINT 'Seeding System Audit Logs...';
INSERT INTO SystemAuditLog (TableName, RecordId, Action, ChangedBy, ChangedDate, OldValue, NewValue) VALUES
('InventoryLots', '1', 'Update', 2, '2026-03-15 09:00:00', 'Quarantine', 'Released'),
('ProductionOrders', '2', 'Update', 3, '2026-03-10 14:30:00', 'Approved', 'In-Progress'),
('Equipments', '5', 'Update', 1, '2026-03-16 08:00:00', 'Ready', 'Maintenance');

PRINT 'Seeding completed successfully!';
GO
