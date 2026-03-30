-- PharmaceuticalProcessingManagementSystem Seed Data
-- Batch-friendly version (No GO, No USE)

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

PRINT '---------------------------------------------------------';
PRINT '💊 DANG KHOI TAO DU LIEU MAU CHO HE THONG GMP-WHO';
PRINT '---------------------------------------------------------';

-- 1. CLEANUP
PRINT 'Dang xoa du lieu cu va reset ID...';
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
DELETE FROM UnitOfMeasure;
DELETE FROM SystemAuditLog;
DELETE FROM UomConversions;

EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Reset Identity
DECLARE @TableName NVARCHAR(255);
DECLARE table_cursor CURSOR FOR 
SELECT name FROM sys.tables WHERE OBJECTPROPERTY(object_id, 'TableHasIdentity') = 1;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('DBCC CHECKIDENT (''' + @TableName + ''', RESEED, 0)');
    FETCH NEXT FROM table_cursor INTO @TableName;
END
CLOSE table_cursor;
DEALLOCATE table_cursor;

-- 2. UNIT OF MEASURE
INSERT INTO UnitOfMeasure (UomName, Description) VALUES
('mg', 'Milligram'), ('g', 'Gram'), ('kg', 'Kilogram'), ('ml', 'Milliliter'), ('L', 'Liter'),
('Tablet/Capsule', N'Viên (nén/nang)'), ('Blister', N'Vỉ (10 viên)'), ('Box', N'Hộp');

-- 4. EQUIPMENTS
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('EQP-DRY-02', N'Máy sấy tầng sôi KBC-TS-50', 'Ready'),
('EQP-MIX-02', N'Máy trộn lập phương AD-LP-200', 'Ready'),
('EQP-FIL-01', N'Máy đóng nang tự động NJP-1200 D', 'Ready'),
('EQP-POL-01', N'Máy xát bóng IPJ', 'Ready'),
('EQP-WGH-01', N'Cân điện tử PMA-5000', 'Ready'),
('EQP-WGH-02', N'Cân phân tích IW2-60', 'Ready');

-- 5. MATERIALS
DECLARE @Uom_kg INT = (SELECT TOP 1 UomId FROM UnitOfMeasure WHERE UomName = 'kg');
DECLARE @Uom_Capsule INT = (SELECT TOP 1 UomId FROM UnitOfMeasure WHERE UomName = 'Tablet/Capsule');
DECLARE @Uom_Box INT = (SELECT TOP 1 UomId FROM UnitOfMeasure WHERE UomName = 'Box');

INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, Description, IsActive) VALUES
('MAT-NLC3', N'Hoạt chất NLC 3', 'RawMaterial', @Uom_kg, 'Medicinal powder', 1),
('MAT-TD1', N'Tá dược rã (TD 1)', 'RawMaterial', @Uom_kg, 'Binder/Excipient', 1),
('MAT-TD3', N'Tá dược độn (TD 3)', 'RawMaterial', @Uom_kg, 'Filler/Excipient', 1),
('MAT-TD4', N'Tá dược trơn (TD 4)', 'RawMaterial', @Uom_kg, 'Glidant', 1),
('MAT-TD5', N'Tá dược dính (TD 5)', 'RawMaterial', @Uom_kg, 'Disintegrant', 1),
('MAT-TD8', N'Tá dược bóng (TD 8)', 'RawMaterial', @Uom_kg, 'Lubricant', 1),
('MAT-NLP6', N'Vỏ nang số 0 (NLP 6)', 'Packaging', @Uom_Capsule, 'Hard capsule shells', 1),
('FG-NLC3-CAP', N'Viên nang NLC 3 (Hộp 3200v)', 'FinishedGood', @Uom_Box, 'Finished product case', 1);

-- 6. INVENTORY LOTS
INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus)
SELECT MaterialId, 'LOT-' + MaterialCode + '-2026', 1000.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'
FROM Materials WHERE Type = 'RawMaterial';

INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus)
SELECT MaterialId, 'LOT-CAPS-2026', 1000000, GETDATE(), DATEADD(YEAR, 5, GETDATE()), 'Released'
FROM Materials WHERE MaterialCode = 'MAT-NLP6';

-- 7. RECIPES
DECLARE @Mat_FG INT = (SELECT TOP 1 MaterialId FROM Materials WHERE MaterialCode = 'FG-NLC3-CAP');
DECLARE @AdminID INT = (SELECT TOP 1 UserID FROM AppUsers WHERE Username = 'admin');

INSERT INTO Recipes (MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt) VALUES
(@Mat_FG, 1, 100000, 'Approved', @AdminID, GETDATE(), GETDATE());

DECLARE @RecipeID INT = SCOPE_IDENTITY();

INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, UomId, Note)
SELECT @RecipeID, MaterialId, 50.0, @Uom_kg, 'Hoat chat chinh' FROM Materials WHERE MaterialCode = 'MAT-NLC3' UNION ALL
SELECT @RecipeID, MaterialId, 10.0, @Uom_kg, 'Ta duoc 1' FROM Materials WHERE MaterialCode = 'MAT-TD1' UNION ALL
SELECT @RecipeID, MaterialId, 5.0,  @Uom_kg, 'Ta duoc 3' FROM Materials WHERE MaterialCode = 'MAT-TD3' UNION ALL
SELECT @RecipeID, MaterialId, 100000, @Uom_Capsule, 'Vo nang' FROM Materials WHERE MaterialCode = 'MAT-NLP6';

-- 8. ROUTING
DECLARE @Eqp_Dry INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-DRY-02');
DECLARE @Eqp_Mix INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-MIX-02');

INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentID, EstimatedTimeMinutes, Description) VALUES
(@RecipeID, 1, N'Cân Nguyên Liệu', NULL, 60, N'Cân nguyên liệu theo lệnh'),
(@RecipeID, 2, N'Sấy Nguyên Liệu', @Eqp_Dry, 120, N'Sấy đạt ẩm quy định'),
(@RecipeID, 3, N'Trộn Khô', @Eqp_Mix, 30, N'Trộn đều hỗn hợp bột');

-- 9. MOCK PRODUCTION DATA
DECLARE @Now DATETIME2 = GETDATE();

-- 9.1. PO-2026-NLC-001 (Completed)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, ActualQuantity, StartDate, EndDate, Status, CreatedBy, Note)
VALUES ('PO-2026-NLC-001', @RecipeID, 100000, 99850, DATEADD(DAY, -5, @Now), DATEADD(DAY, -4, @Now), 'Completed', @AdminID, N'Lô sản xuất thử nghiệm thành công');

DECLARE @OrderId_Done INT = SCOPE_IDENTITY();
INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep)
VALUES (@OrderId_Done, 'B260301', 'Completed', DATEADD(DAY, -5, @Now), DATEADD(DAY, -4, @Now), DATEADD(YEAR, 2, @Now), 3);

DECLARE @BatchId_Done INT = SCOPE_IDENTITY();
DECLARE @OpID INT = (SELECT TOP 1 UserID FROM AppUsers WHERE Username = 'op01');

INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData) VALUES
(@BatchId_Done, 1, 5, @OpID, DATEADD(HOUR, -100, @Now), DATEADD(HOUR, -99, @Now), 'Passed', '{"weight": 50.2, "unit": "kg"}'),
(@BatchId_Done, 2, 1, @OpID, DATEADD(HOUR, -98, @Now), DATEADD(HOUR, -96, @Now), 'Passed', '{"temp": 60, "moisture": 3.5}'),
(@BatchId_Done, 3, 2, @OpID, DATEADD(HOUR, -95, @Now), DATEADD(HOUR, -94, @Now), 'Passed', '{"speed": 30, "time": 30}');

-- 9.2. PO-2026-NLC-002 (InProcess)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, StartDate, Status, CreatedBy, Note)
VALUES ('PO-2026-NLC-002', @RecipeID, 200000, @Now, 'InProcess', @AdminID, N'Lệnh sản xuất chính thức tháng 3');

DECLARE @OrderId_Running INT = SCOPE_IDENTITY();
INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep)
VALUES (@OrderId_Running, 'B260302', 'Completed', DATEADD(DAY, -1, @Now), @Now, DATEADD(YEAR, 2, @Now), 3);
DECLARE @BatchId_Running1 INT = SCOPE_IDENTITY();
INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus) VALUES
(@BatchId_Running1, 1, 5, @OpID, DATEADD(HOUR, -24, @Now), DATEADD(HOUR, -23, @Now), 'Passed'),
(@BatchId_Running1, 2, 1, @OpID, DATEADD(HOUR, -22, @Now), DATEADD(HOUR, -20, @Now), 'Passed'),
(@BatchId_Running1, 3, 2, @OpID, DATEADD(HOUR, -19, @Now), DATEADD(HOUR, -18, @Now), 'Passed');

INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, ExpiryDate, CurrentStep)
VALUES (@OrderId_Running, 'B260303', 'InProcess', @Now, DATEADD(YEAR, 2, @Now), 2);
DECLARE @BatchId_Running2 INT = SCOPE_IDENTITY();
INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData) VALUES
(@BatchId_Running2, 1, 6, @OpID, DATEADD(HOUR, -2, @Now), DATEADD(HOUR, -1, @Now), 'Passed', '{"weight": 50.05, "deviation": 0.01}');

-- 9.3. PO-2026-NLC-003 (Hold)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, StartDate, Status, CreatedBy, Note)
VALUES ('PO-2026-NLC-003', @RecipeID, 150000, DATEADD(DAY, -2, @Now), 'Hold', @AdminID, N'Tạm dừng do thiết bị lỗi');

DECLARE @OrderId_Hold INT = SCOPE_IDENTITY();
INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, ExpiryDate, CurrentStep)
VALUES (@OrderId_Hold, 'B260304', 'OnHold', DATEADD(DAY, -2, @Now), DATEADD(YEAR, 2, @Now), 2);
DECLARE @BatchId_Hold INT = SCOPE_IDENTITY();
INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, Notes) VALUES
(@BatchId_Hold, 1, 5, @OpID, DATEADD(DAY, -2, @Now), DATEADD(DAY, -2, @Now), 'Passed', 'OK'),
(@BatchId_Hold, 2, 1, @OpID, DATEADD(DAY, -1, @Now), DATEADD(DAY, -1, @Now), 'Failed', N'Nhiệt độ không ổn định');

-- 9.4. PO-2026-NLC-004 (Approved)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, StartDate, Status, CreatedBy)
VALUES ('PO-2026-NLC-004', @RecipeID, 300000, DATEADD(DAY, 2, @Now), 'Approved', @AdminID);

-- 9.5. PO-2026-NLC-005 (Draft)
INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, StartDate, Status, CreatedBy)
VALUES ('PO-2026-NLC-005', @RecipeID, 50000, DATEADD(DAY, 10, @Now), 'Draft', @AdminID);

PRINT '---------------------------------------------------------';
PRINT '✅ KHOI TAO DU LIEU THANH CONG!';
PRINT '---------------------------------------------------------';
