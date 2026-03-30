/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   DỮ LIỆU MẪU (FULL SEED DATA - 10 SCENARIOS)
   Mục đích: Khởi tạo dữ liệu chuẩn cho 10 kịch bản sản xuất thực tế.
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- XÓA DỮ LIỆU CŨ (THEO THỨ TỰ NGƯỢC LẠI CỦA KHÓA NGOẠI)
DELETE FROM BatchProcessLogs;
DELETE FROM ProductionBatches;
DELETE FROM ProductionOrders;
DELETE FROM RecipeRouting;
DELETE FROM RecipeBom;
DELETE FROM Recipes;
DELETE FROM Materials;
DELETE FROM Equipments;
DELETE FROM UnitOfMeasure;
DELETE FROM AppUsers;
GO

-- RESET IDENTITY
DBCC CHECKIDENT ('AppUsers', RESEED, 0);
DBCC CHECKIDENT ('UnitOfMeasure', RESEED, 0);
DBCC CHECKIDENT ('Equipments', RESEED, 0);
DBCC CHECKIDENT ('Materials', RESEED, 0);
DBCC CHECKIDENT ('Recipes', RESEED, 0);
DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
GO

-- -------------------------------------------------------------------------
-- 1. AppUsers (Passwords: Admin@123, Qc@123456, Op@123456)
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT AppUsers ON;
INSERT INTO AppUsers (UserId, Username, FullName, Role, IsActive, PasswordHash, CreatedAt)
VALUES 
(1, 'admin', N'Admin System', 'Admin', 1, '$2b$11$hyVSDA5K2Qg1FVUosjSk4e76FBcJhE7DbNG/KDELUBotFzcSt5xIW', GETDATE()),
(2, 'qc01', N'Trần Kiểm Tra', 'QA_QC', 1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', GETDATE()),
(3, 'op01', N'Nguyễn Công Nhân', 'Operator', 1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', GETDATE());
SET IDENTITY_INSERT AppUsers OFF;
GO

-- -------------------------------------------------------------------------
-- 2. UnitOfMeasure
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description)
VALUES 
(1, 'kg', N'Kilogram'),
(2, 'Tablets', N'Viên'),
(3, 'Box', N'Hộp');
SET IDENTITY_INSERT UnitOfMeasure OFF;
GO

-- -------------------------------------------------------------------------
-- 3. Equipments
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT Equipments ON;
INSERT INTO Equipments (EquipmentId, EquipmentCode, EquipmentName, Status)
VALUES 
(1, 'EQP-WGH-01', N'Cân điện tử', 'Ready'),
(2, 'EQP-DRY-01', N'Máy sấy tầng sôi', 'Ready'),
(3, 'EQP-MIX-01', N'Máy trộn lập phương', 'Ready');
SET IDENTITY_INSERT Equipments OFF;
GO

-- -------------------------------------------------------------------------
-- 4. Materials
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive)
VALUES 
(1, 'MAT-NLC3', N'Hoạt chất NLC 3', 'RawMaterial', 1, 1),
(2, 'FG-NLC3', N'Viên nang NLC 3', 'FinishedGood', 3, 1),
(3, 'MAT-PARA', N'Bột Paracetamol', 'RawMaterial', 1, 1),
(4, 'FG-PARA', N'Viên nén Paracetamol', 'FinishedGood', 3, 1);
SET IDENTITY_INSERT Materials OFF;
GO

-- -------------------------------------------------------------------------
-- 5. Recipes & Routings
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt)
VALUES 
(1, 2, 1, 100000.00, 'Approved', 1, GETDATE(), GETDATE()),
(2, 4, 1, 500000.00, 'Approved', 1, GETDATE(), GETDATE());
SET IDENTITY_INSERT Recipes OFF;
GO

SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId)
VALUES 
(1, 1, 1, N'Cân Nguyên Liệu', 1),
(2, 1, 2, N'Sấy Nguyên Liệu', 2),
(3, 1, 3, N'Trộn Khô', 3),
(4, 2, 1, N'Cân Bột', 1),
(5, 2, 2, N'Dập Viên', 3);
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- -------------------------------------------------------------------------
-- 6. ProductionOrders (10 Scenarios)
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, ActualQuantity, Status, CreatedBy, StartDate, EndDate, CreatedAt)
VALUES 
(1, 'PO-001', 1, 100000.00, 100050.00, 'Completed', 1, DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, -1, GETDATE()), GETDATE()),
(2, 'PO-002', 1, 300000.00, NULL, 'In-Process', 1, GETDATE(), NULL, GETDATE()),
(3, 'PO-003', 1, 150000.00, NULL, 'Hold', 1, GETDATE(), NULL, GETDATE()),
(4, 'PO-004', 1, 200000.00, NULL, 'In-Process', 1, GETDATE(), NULL, GETDATE()),
(5, 'PO-005', 1, 500000.00, NULL, 'Approved', 1, DATEADD(DAY, 7, GETDATE()), NULL, GETDATE()),
(6, 'PO-006', 2, 500000.00, NULL, 'In-Process', 1, GETDATE(), NULL, GETDATE()),
(7, 'PO-007', 2, 1000000.00, NULL, 'Approved', 1, DATEADD(DAY, 30, GETDATE()), NULL, GETDATE()),
(8, 'PO-008', 1, 100000.00, NULL, 'Draft', 1, GETDATE(), NULL, GETDATE()),
(9, 'PO-009', 1, 100000.00, NULL, 'Cancelled', 1, GETDATE(), NULL, GETDATE()),
(10, 'PO-010', 1, 100000.00, NULL, 'Draft', 1, GETDATE(), NULL, GETDATE());
SET IDENTITY_INSERT ProductionOrders OFF;
GO

-- -------------------------------------------------------------------------
-- 7. ProductionBatches
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, EndTime, CurrentStep)
VALUES 
(1, 1, 'B26001', 'Completed', DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, -1, GETDATE()), 3),
(2, 2, 'B26002-A', 'Completed', DATEADD(HOUR, -12, GETDATE()), DATEADD(HOUR, -10, GETDATE()), 3),
(3, 2, 'B26002-B', 'Completed', DATEADD(HOUR, -8, GETDATE()), DATEADD(HOUR, -6, GETDATE()), 3),
(4, 2, 'B26002-C', 'InProcess', GETDATE(), NULL, 2),
(5, 3, 'B26003', 'OnHold', GETDATE(), NULL, 2),
(6, 4, 'B26004-X', 'InProcess', GETDATE(), NULL, 2),
(7, 6, 'BPARA-01', 'InProcess', GETDATE(), NULL, 1);
SET IDENTITY_INSERT ProductionBatches OFF;
GO

-- -------------------------------------------------------------------------
-- 8. BatchProcessLogs (Sequential Logic - GMP Standard)
-- -------------------------------------------------------------------------
SET IDENTITY_INSERT BatchProcessLogs ON;
-- PO-001 / B26001 (All Passed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES 
(1, 1, 1, 1, 3, DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, -1.9, GETDATE()), 'Passed', '{"weight": 100.05, "unit": "kg"}'),
(2, 1, 2, 2, 3, DATEADD(DAY, -1.8, GETDATE()), DATEADD(DAY, -1.5, GETDATE()), 'Passed', '{"temp": 60.5, "humidity": 3.2}'),
(3, 1, 3, 3, 3, DATEADD(DAY, -1.4, GETDATE()), DATEADD(DAY, -1.1, GETDATE()), 'Passed', '{"speed": 30, "time": 45}');

-- PO-002 / B26002-A (All Passed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(4, 2, 1, 1, 3, DATEADD(HOUR, -12, GETDATE()), DATEADD(HOUR, -11.5, GETDATE()), 'Passed'),
(5, 2, 2, 2, 3, DATEADD(HOUR, -11.4, GETDATE()), DATEADD(HOUR, -10.5, GETDATE()), 'Passed'),
(6, 2, 3, 3, 3, DATEADD(HOUR, -10.4, GETDATE()), DATEADD(HOUR, -10, GETDATE()), 'Passed');

-- PO-002 / B26002-B (All Passed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(7, 3, 1, 1, 3, DATEADD(HOUR, -8, GETDATE()), DATEADD(HOUR, -7.5, GETDATE()), 'Passed'),
(8, 3, 2, 2, 3, DATEADD(HOUR, -7.4, GETDATE()), DATEADD(HOUR, -6.5, GETDATE()), 'Passed'),
(9, 3, 3, 3, 3, DATEADD(HOUR, -6.4, GETDATE()), DATEADD(HOUR, -6, GETDATE()), 'Passed');

-- PO-002 / B26002-C (Step 1 Passed, Step 2 Running)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(10, 4, 1, 1, 3, DATEADD(HOUR, -1, GETDATE()), DATEADD(HOUR, -0.5, GETDATE()), 'Passed'),
(11, 4, 2, 2, 3, DATEADD(HOUR, -0.4, GETDATE()), NULL, 'Running');

-- PO-003 / B26003 (Step 1 Passed, Step 2 OnHold)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(12, 5, 1, 1, 3, DATEADD(HOUR, -2, GETDATE()), DATEADD(HOUR, -1.5, GETDATE()), 'Passed'),
(13, 5, 2, 2, 3, DATEADD(HOUR, -1.4, GETDATE()), NULL, 'OnHold');

-- PO-004 / B26004-X (Step 1 Passed, Step 2 Failed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(14, 6, 1, 1, 3, DATEADD(HOUR, -3, GETDATE()), DATEADD(HOUR, -2, GETDATE()), 'Passed'),
(15, 6, 2, 2, 3, DATEADD(HOUR, -1.9, GETDATE()), NULL, 'Failed');

-- PO-006 / BPARA-01 (Step 1 Running)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES 
(16, 7, 4, 1, 3, GETDATE(), NULL, 'Running');

SET IDENTITY_INSERT BatchProcessLogs OFF;
GO
