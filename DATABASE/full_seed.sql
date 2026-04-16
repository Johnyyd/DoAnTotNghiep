/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   FULL SEED DATA v5.0 - ĐA DẠNG HÓA TỐI ĐA (DIVERSIFIED)
   Baseline: Quy trình Crila (CamScanner.pdf) + Sản phẩm mẫu (Demo)
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================
-- 1. AppUsers
-- =====================================================================
SET IDENTITY_INSERT AppUsers ON;
INSERT INTO AppUsers (UserId, Username, FullName, Role, IsActive, PasswordHash, CreatedAt) VALUES
(1, 'admin', N'Quản trị hệ thống', 'Admin', 1, '$2a$11$r64eZiC37zHkCaJ3Tzi7Ne3qJf98W5gcgPFm49.VqeiLds80H09sm', GETDATE()),
(2, 'qc01',  N'Trần Thị Kiểm Tra', 'QA_QC', 1, '$2a$11$Gdg5lIchl6HzbwNOv0SdA.Zgn/jVbSGIyMb68GFnijICy8Mmxjb2W', GETDATE()),
(3, 'op01',  N'Nguyễn Văn Vận Hành', 'Operator', 1, '$2a$11$CWA.vlpVc/QL3JMJVdHXRu.28gV35NFyY39CANxjIVzohGLxAPbsu', GETDATE()),
(4, 'mgr01', N'Lê Văn Quản Lý', 'ProductionManager', 1, '$2a$11$r64eZiC37zHkCaJ3Tzi7Ne3qJf98W5gcgPFm49.VqeiLds80H09sm', GETDATE());
SET IDENTITY_INSERT AppUsers OFF;
GO

-- =====================================================================
-- 2. UnitOfMeasure
-- =====================================================================
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description) VALUES
(1, N'kg',   N'Kilogram'),
(2, N'g',    N'Gram'),
(3, N'lít',  N'Lít'),
(4, N'viên', N'Viên nén/nang'),
(5, N'vỉ',   N'Vỉ thuốc'),
(6, N'hộp',  N'Hộp thành phẩm'),
(7, N'thùng', N'Thùng carton'),
(8, N'mg',   N'Miligram');
SET IDENTITY_INSERT UnitOfMeasure OFF;
GO

-- =====================================================================
-- 3. UomConversions
-- =====================================================================
SET IDENTITY_INSERT UomConversions ON;
INSERT INTO UomConversions (ConversionId, FromUomId, ToUomId, Factor, Note) VALUES
(1, 1, 2, 1000.0, N'1kg = 1000g'),
(2, 2, 8, 1000.0, N'1g = 1000mg'),
(3, 7, 6, 80.0,   N'1 thùng = 80 chai'),
(4, 6, 4, 40.0,   N'1 chai = 40 viên');
SET IDENTITY_INSERT UomConversions OFF;
GO

-- =====================================================================
-- 4. Equipments
-- =====================================================================
SET IDENTITY_INSERT Equipments ON;
INSERT INTO Equipments (EquipmentId, EquipmentCode, EquipmentName, Status, LastMaintenanceDate) VALUES
(1, 'IW2-60', N'Cân điện tử 60 kg', 'Ready', GETDATE()),
(2, 'PMA-5000', N'Cân điện tử 5 kg', 'Ready', GETDATE()),
(3, 'TE-212', N'Cân điện tử 210 g', 'Ready', GETDATE()),
(4, 'KBC-TS-50', N'Máy sấy tầng sôi', 'Ready', GETDATE()),
(5, 'AD-LP-200', N'Máy trộn lập phương', 'Ready', GETDATE()),
(6, 'NJP-1200D', N'Máy đóng nang tự động', 'Ready', GETDATE()),
(7, 'IPJ', N'Máy lau nang', 'Ready', GETDATE()),
(8, 'TAB-001', N'Máy dập viên nén', 'Ready', GETDATE());
SET IDENTITY_INSERT Equipments OFF;
GO

-- =====================================================================
-- 5. Materials
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, Description) VALUES
-- Crila components
(1, 'NLC-3', N'Cao khô Trinh nữ Crila', 'RawMaterial', 8, 1, N'Theo PDF CamScanner'),
(2, 'TD-1', N'Aerosil', 'RawMaterial', 8, 1, N'Tá dược trơn'),
(3, 'TD-3', N'Sodium starch glycolate', 'RawMaterial', 8, 1, N'Tá dược rã'),
(4, 'TD-4', N'Talc', 'RawMaterial', 8, 1, N'Tá dược bao'),
(5, 'TD-5', N'Magnesi stearat', 'RawMaterial', 8, 1, N'Tá dược trơn'),
(6, 'TD-8', N'Tinh bột', 'RawMaterial', 8, 1, N'Tá dược độn'),
-- Para & VitC
(10, 'FG-CRILA', N'Trinh nữ Crila (Viên nang)', 'FinishedGood', 4, 1, N'Theo PDF CamScanner'),
(11, 'FG-PARA-500', N'Paracetamol 500mg', 'FinishedGood', 4, 1, N'Viên nén Paracetamol'),
(12, 'FG-VITC-500', N'Vitamin C 500mg', 'FinishedGood', 4, 1, N'Viên sủi Vitamin C');
SET IDENTITY_INSERT Materials OFF;
GO

-- =====================================================================
-- 6. Recipes
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, EffectiveDate) VALUES
(1, 10, 1, 100000.00, 'Approved', 2, GETDATE(), GETDATE(), GETDATE()),
(2, 11, 1, 50000.00, 'Approved', 2, GETDATE(), GETDATE(), GETDATE()),
(3, 12, 2, 20000.00, 'Approved', 2, GETDATE(), GETDATE(), GETDATE());
SET IDENTITY_INSERT Recipes OFF;
GO

-- =====================================================================
-- 7. RecipeBom (Simplified for diversification)
-- =====================================================================
SET IDENTITY_INSERT RecipeBom ON;
INSERT INTO RecipeBom (BomId, RecipeId, MaterialId, Quantity, UomId, WastePercentage) VALUES
-- Crila BOM
(1, 1, 1, 250.00, 8, 0.5),
(2, 1, 6, 250.58, 8, 1.0),
-- Para BOM (Sample)
(3, 2, 1, 500.0, 8, 0.5);
SET IDENTITY_INSERT RecipeBom OFF;
GO

-- =====================================================================
-- 8. RecipeRouting
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, NumberOfRouting) VALUES
-- Crila Routing (6 steps)
(1, 1, 1, N'Sấy TD 8 (Tinh bột)', 4, 180, 1),
(2, 1, 2, N'Sấy NLC 3 (Cao khô)', 4, 180, 1),
(3, 1, 3, N'Cân nguyên liệu', 1, 60, 1),
(4, 1, 4, N'Trộn khô (Cube Mixer)', 5, 15, 1),
(5, 1, 5, N'Đóng nang', 6, 120, 1),
(6, 1, 6, N'Lau nang & Đóng chai', 7, 120, 1),
-- Para Routing (3 steps)
(7, 2, 1, N'Phối trộn bột', 5, 60, 1),
(8, 2, 2, N'Dập viên nén', 8, 180, 1),
(9, 2, 3, N'Ép vỉ', 8, 120, 1);
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- =====================================================================
-- 10. ProductionOrders (Diverse Statuses)
-- =====================================================================
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, PlannedCartons, ActualQuantity, StartDate, EndDate, Status, CreatedBy, CreatedAt, ApprovedBy, ApprovedDate, IsPriority, Note) VALUES
(1, 'PO-CRILA-2026-01', 1, 100000.0, 32, NULL, GETDATE(), DATEADD(DAY,5,GETDATE()), 'In-Process', 4, GETDATE(), 2, GETDATE(), 1, N'Đang chạy mẻ Crila #1'),
(2, 'PO-CRILA-2026-02', 1, 50000.0, 16, NULL, DATEADD(DAY,1,GETDATE()), DATEADD(DAY,6,GETDATE()), 'Approved', 4, GETDATE(), 2, GETDATE(), 0, N'Lệnh Crila chờ sản xuất'),
(3, 'PO-PARA-2026-03', 2, 50000.0, 10, 50100.0, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-8,GETDATE()), 'Completed', 4, GETDATE(), 2, GETDATE(), 0, N'Đã hoàn thành xuất kho'),
(4, 'PO-VITC-2026-04', 3, 20000.0, 5, NULL, GETDATE(), DATEADD(DAY,3,GETDATE()), 'Hold', 4, GETDATE(), 2, GETDATE(), 1, N'Đang tạm dừng do QC kiểm tra vật tư'),
(5, 'PO-PARA-2026-05', 2, 100000.0, 20, NULL, DATEADD(DAY,-2,GETDATE()), GETDATE(), 'Cancelled', 4, GETDATE(), 2, GETDATE(), 0, N'Hủy do thay đổi kế hoạch kinh doanh'),
(6, 'PO-CRILA-2026-06', 1, 80000.0, 25, NULL, GETDATE(), DATEADD(DAY,5,GETDATE()), 'In-Process', 4, GETDATE(), 2, GETDATE(), 1, N'Đang chạy mẻ Crila #2 (Đóng nang)');
SET IDENTITY_INSERT ProductionOrders OFF;
GO

-- =====================================================================
-- 11. ProductionBatches
-- =====================================================================
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, CurrentStep, PlannedQuantity, CreatedAt) VALUES
-- Batches for Order 1 (In-Process)
(1, 1, 'BATCH-CRI-001', 'In-Process', GETDATE(), 3, 50000.0, GETDATE()), -- Step: Cân
(2, 1, 'BATCH-CRI-002', 'Scheduled', NULL, 1, 50000.0, GETDATE()),
-- Batches for Order 3 (Completed)
(3, 3, 'BATCH-PARA-DONE', 'Completed', DATEADD(DAY,-9,GETDATE()), 9, 50000.0, GETDATE()),
-- Batches for Order 6 (In-Process, Near end)
(4, 6, 'BATCH-CRI-NEAR', 'In-Process', GETDATE(), 5, 80000.0, GETDATE()); -- Step: Đóng nang
SET IDENTITY_INSERT ProductionBatches OFF;
GO

-- =====================================================================
-- 12. InventoryLots
-- =====================================================================
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierName) VALUES
(1, 1, 'LOT-NLC3-001', 1000000.0, DATEADD(MONTH,-1,GETDATE()), DATEADD(MONTH,23,GETDATE()), 'Released', N'Dược liệu TW'),
(2, 6, 'LOT-TD8-001', 5000000.0, DATEADD(MONTH,-2,GETDATE()), DATEADD(MONTH,34,GETDATE()), 'Released', N'Nông sản A');
SET IDENTITY_INSERT InventoryLots OFF;
GO

-- =====================================================================
-- 13. MaterialUsage
-- =====================================================================
SET IDENTITY_INSERT MaterialUsage ON;
INSERT INTO MaterialUsage (UsageId, BatchId, InventoryLotId, PlannedAmount, ActualAmount, Timestamp, DispensedBy, Note) VALUES
(1, 1, 1, 12500.0, 12500.0, GETDATE(), 3, NULL),
(2, 3, 1, 25000.0, 25050.0, DATEADD(DAY,-9,GETDATE()), 3, NULL);
SET IDENTITY_INSERT MaterialUsage OFF;
GO
