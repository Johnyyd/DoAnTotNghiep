-- =====================================================
-- GMP-WHO System Seed Data
-- =====================================================
PRINT 'Seeding GMP Database with sample data...';

-- =====================================================
-- 1. Units of Measure
-- =====================================================
INSERT INTO UnitOfMeasure (UomName, Description) VALUES
('mg', 'Milligram'),
('g', 'Gram'),
('kg', 'Kilogram'),
('ml', 'Milliliter'),
('L', 'Liter'),
('tablet', 'Tablet'),
('blister', 'Blister pack'),
('box', 'Carton box'),
('batch', 'Production batch');

-- =====================================================
-- 2. Materials (Raw Materials, Packaging, Finished Goods)
-- =====================================================
INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomID, Description) VALUES
-- Raw Materials
('RAW-API-001', 'Paracetamol API', 'RawMaterial', 1, 'Active Pharmaceutical Ingredient - Paracetamol 500mg'),
('RAW-EXC-001', 'Microcrystalline Cellulose', 'RawMaterial', 2, 'Excipient - binder/filler'),
('RAW-LUB-001', 'Magnesium Stearate', 'RawMaterial', 2, 'Excipient - lubricant'),
('RAW-FILM-001', 'HPMC Film', 'Packaging', 7, 'Film coating material'),
-- Finished Goods
('FG-PAR-500', 'Paracetamol 500mg Tablet', 'FinishedGood', 6, 'Finished product - Paracetamol 500mg'),
('FG-PAR-BOX', 'Paracetamol 500mg Box (10 blisters)', 'FinishedGood', 8, 'Carton box containing 10 blister packs');

-- =====================================================
-- 3. Equipments
-- =====================================================
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('MIX-001', 'V-Shaped Mixer 500L', 'Ready'),
('TAB-001', 'Tablet Press Machine KORU-550', 'Ready'),
('COAT-001', 'Film Coater GLATT-300', 'Ready'),
('PACK-001', 'Blister Packing Machine ATM-200', 'Ready'),
('CART-001', 'Cartoning Machine PK-200', 'Ready');

-- =====================================================
-- 4. Users (with roles)
-- =====================================================
INSERT INTO AppUsers (UserCode, UserName, Email, Role, IsActive) VALUES
('USR-ADMIN-001', 'Nguyen Van Admin', 'admin@gmp-system.local', 'Admin', 1),
('USR-QC-001', 'Le Thi QC', 'qc@gmp-system.local', 'QualityControl', 1),
('USR-OP-001', 'Tran Cong Worker', 'worker@gmp-system.local', 'Operator', 1),
('USR-MGR-001', 'Pham Van Manager', 'manager@gmp-system.local', 'Manager', 1);

-- =====================================================
-- 5. Recipes (Công thức sản xuất)
-- =====================================================
INSERT INTO Recipes (RecipeCode, RecipeName, Version, Status, ApprovedBy, ApprovedDate) VALUES
('REC-PAR-500-V1', 'Paracetamol 500mg Tablet - Version 1', '1.0', 'Approved', 1, GETDATE());

-- =====================================================
-- 6. Recipe BOM (Định mức nguyên liệu)
-- =====================================================
INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, Unit, TolerancePercent, ParentItemId) VALUES
-- Level 1: Finished product BOM
(1, 1, 500.0, 'mg', 2.0, NULL), -- Paracetamol API
(1, 2, 150.0, 'mg', 3.0, NULL), -- Microcrystalline Cellulose
(1, 3, 5.0, 'mg', 10.0, NULL), -- Magnesium Stearate
(1, 4, 10.0, 'mg', 5.0, NULL);  -- HPMC Film

-- =====================================================
-- 7. Recipe Routing (Quy trình sản xuất)
-- =====================================================
INSERT INTO RecipeRouting (RecipeId, StepOrder, StepName, EquipmentId, DurationMin, QcRequired, Description) VALUES
(1, 1, 'Weighing & Dispensing', NULL, 30, 1, 'Weigh all raw materials according to BOM'),
(1, 2, 'Mixing', 1, 120, 1, 'V-Shape mixing for homogeneity'),
(1, 3, 'Tablet Compression', 2, 90, 1, 'Compress into tablets'),
(1, 4, 'Film Coating', 3, 60, 1, 'Apply film coating'),
(1, 5, 'Blister Packing', 4, 45, 1, 'Pack tablets into blisters'),
(1, 6, 'Cartoning', 5, 30, 0, 'Pack blisters into cartons');

-- =====================================================
-- 8. Production Orders
-- =====================================================
INSERT INTO ProductionOrders (OrderNumber, ProductId, PlannedQuantity, PlannedStartDate, PlannedEndDate, Status, RecipeId, CreatedBy) VALUES
('PO-2025-001', 2, 10000, GETDATE(), DATEADD(DAY, 3, GETDATE()), 'Approved', 1, 1);

-- =====================================================
-- 9. Material Batches (Lô nhập nguyên liệu)
-- =====================================================
INSERT INTO MaterialBatches (BatchNumber, MaterialId, Quantity, Unit, ManufactureDate, ExpiryDate, QcStatus, QcDate, QcBy) VALUES
('BATCH-API-2025-001', 1, 100000, 'mg', GETDATE(), DATEADD(MONTH, 24, GETDATE()), 'Passed', GETDATE(), 2),
('BATCH-EXC-2025-001', 2, 50000, 'mg', GETDATE(), DATEADD(MONTH, 12, GETDATE()), 'Passed', GETDATE(), 2),
('BATCH-LUB-2025-001', 3, 10000, 'mg', GETDATE(), DATEADD(MONTH, 18, GETDATE()), 'Passed', GETDATE(), 2);

-- =====================================================
-- 10. Production Batches (Mẻ sản xuất)
-- =====================================================
INSERT INTO ProductionBatches (OrderId, BatchNumber, PlannedQuantity, ActualStartDate, OperatorId) VALUES
(1, 'BATCH-PROD-2025-001', 10000, GETDATE(), 3);

-- =====================================================
-- 11. Inventory Lots (Tồn kho)
-- =====================================================
INSERT INTO InventoryLots (MaterialBatchId, Location, QuantityOnHand, Status) VALUES
(1, 'Warehouse-A1', 100000, 'Available'),
(2, 'Warehouse-A2', 50000, 'Available'),
(3, 'Warehouse-A3', 10000, 'Available');

PRINT 'Seed data completed successfully!';
