/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   FULL SEED DATA v2.0 - Phủ kín 15 Bảng, Đa Kịch bản A-Z
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================
-- XÓA DỮ LIỆU CŨ (THEO THỨ TỰ NGƯỢC KHÓA NGOẠI)
-- =====================================================================
DELETE FROM SystemAuditLog;
DELETE FROM MaterialUsage;
DELETE FROM BatchProcessLogs;
DELETE FROM ProductionBatches;
DELETE FROM ProductionOrders;
DELETE FROM InventoryLots;
DELETE FROM RecipeRouting;
DELETE FROM RecipeBOM;
DELETE FROM Recipes;
DELETE FROM Materials;
DELETE FROM Equipments;
DELETE FROM UomConversions;
DELETE FROM UnitOfMeasure;
DELETE FROM AppUsers;
GO

-- RESET IDENTITY
DBCC CHECKIDENT ('AppUsers', RESEED, 0);
DBCC CHECKIDENT ('UnitOfMeasure', RESEED, 0);
DBCC CHECKIDENT ('UomConversions', RESEED, 0);
DBCC CHECKIDENT ('Equipments', RESEED, 0);
DBCC CHECKIDENT ('Materials', RESEED, 0);
DBCC CHECKIDENT ('Recipes', RESEED, 0);
DBCC CHECKIDENT ('RecipeBOM', RESEED, 0);
DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
DBCC CHECKIDENT ('InventoryLots', RESEED, 0);
GO

-- =====================================================================
-- 1. AppUsers (6 users: Admin, 2 QC, 2 Operator, 1 Manager)
-- Passwords: Admin@123 | Qc@123456 | Op@123456 | Mgr@123456
-- =====================================================================
SET IDENTITY_INSERT AppUsers ON;
INSERT INTO AppUsers (UserId, Username, FullName, Role, IsActive, PasswordHash, CreatedAt)
VALUES
(1, 'admin',   N'Admin Hệ Thống',           'Admin',             1, '$2b$11$hyVSDA5K2Qg1FVUosjSk4e76FBcJhE7DbNG/KDELUBotFzcSt5xIW', DATEADD(DAY,-90,GETDATE())),
(2, 'qc01',    N'Trần Thị Kiểm Tra',        'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-60,GETDATE())),
(3, 'op01',    N'Nguyễn Văn Công Nhân',     'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-60,GETDATE())),
(4, 'mgr01',   N'Lê Quang Quản Lý',         'ProductionManager', 1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-90,GETDATE())),
(5, 'qc02',    N'Phạm Thị Chất Lượng',      'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-30,GETDATE())),
(6, 'op02',    N'Hoàng Văn Thao Tác',       'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-30,GETDATE()));
SET IDENTITY_INSERT AppUsers OFF;
GO

-- =====================================================================
-- 2. UnitOfMeasure (7 đơn vị)
-- =====================================================================
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description) VALUES
(1, 'kg',      N'Kilogram'),
(2, 'g',       N'Gram'),
(3, 'L',       N'Lít'),
(4, 'Tablets', N'Viên'),
(5, 'Blister', N'Vỉ (10 viên/vỉ)'),
(6, 'Box',     N'Hộp (10 vỉ/hộp)'),
(7, 'Carton',  N'Thùng (12 hộp/thùng)');
SET IDENTITY_INSERT UnitOfMeasure OFF;
GO

-- =====================================================================
-- 3. UomConversions
-- =====================================================================
SET IDENTITY_INSERT UomConversions ON;
INSERT INTO UomConversions (ConversionID, FromUomID, ToUomID, Factor) VALUES
(1, 1, 2,  1000.0),
(2, 2, 1,  0.001),
(3, 6, 5,  10.0),
(4, 7, 6,  12.0),
(5, 5, 4,  10.0);
SET IDENTITY_INSERT UomConversions OFF;
GO

-- =====================================================================
-- 4. Equipments (8 thiết bị)
-- =====================================================================
SET IDENTITY_INSERT Equipments ON;
INSERT INTO Equipments (EquipmentId, EquipmentCode, EquipmentName, Status, LastMaintenanceDate) VALUES
(1, 'EQP-WGH-01', N'Cân điện tử Mettler Toledo',        'Ready',       DATEADD(DAY,-15,GETDATE())),
(2, 'EQP-DRY-01', N'Máy sấy tầng sôi Glatt (KBC-60)',   'Ready',       DATEADD(DAY,-20,GETDATE())),
(3, 'EQP-MIX-01', N'Máy trộn lập phương IBC 500L',      'Ready',       DATEADD(DAY,-10,GETDATE())),
(4, 'EQP-TAB-01', N'Máy dập viên tròn xoay Fette',      'Ready',       DATEADD(DAY,-5, GETDATE())),
(5, 'EQP-BLS-01', N'Máy ép vỉ nhôm Uhlmann',            'Maintenance', DATEADD(DAY,-3, GETDATE())),
(6, 'EQP-WGH-02', N'Cân kiểm tra trọng lượng Sartorius','Ready',       DATEADD(DAY,-7, GETDATE())),
(7, 'EQP-DRY-02', N'Máy sấy tầng sôi KBC-30 (phụ)',     'Ready',       DATEADD(DAY,-25,GETDATE())),
(8, 'EQP-MIX-02', N'Máy trộn lập phương IBC 200L (phụ)','Running',     DATEADD(DAY,-12,GETDATE()));
SET IDENTITY_INSERT Equipments OFF;
GO

-- =====================================================================
-- 5. Materials (11 loại vật tư)
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, Description) VALUES
(1,  'MAT-NLC3',   N'Hoạt chất NLC 3',            'RawMaterial',  1, 1, N'Bảo quản 15-25°C, tránh ánh sáng'),
(2,  'MAT-PARA',   N'Bột Paracetamol tinh khiết',  'RawMaterial',  1, 1, N'USP Grade, bảo quản nơi khô ráo'),
(3,  'MAT-TINBT',  N'Tinh bột ngô (Maize starch)', 'RawMaterial',  1, 1, N'Tá dược độn, %ẩm <14%'),
(4,  'MAT-LACTO',  N'Lactose Monohydrate',         'RawMaterial',  1, 1, N'Tá dược độn/kết dính, %ẩm <0.5%'),
(5,  'MAT-MGST',   N'Magie Stearat',               'RawMaterial',  2, 1, N'Tá dược trơn, dùng liều nhỏ'),
(6,  'MAT-VANG',  N'Vỏ nang gelatin cứng (cỡ 0)', 'RawMaterial',  4, 1, N'Phân hủy sinh học, bảo quản <25°C'),
(7,  'MAT-PVPK',   N'PVP K30 (Povidone)',          'RawMaterial',  1, 1, N'Tá dược kết dính, tan trong nước'),
(8,  'PKG-ALU',    N'Màng nhôm ép vỉ (Alu foil)', 'Packaging',    2, 1, N'Cuộn 200m, dày 20 micron'),
(9,  'PKG-PVC',    N'Màng PVC cứng (blister film)','Packaging',    2, 1, N'Cuộn 200m, dày 250 micron'),
(10, 'FG-NLC3-CAP',N'Viên nang cứng NLC 3 (250mg)','FinishedGood', 4, 1, N'Thành phẩm đầu ra, đóng vỉ 10 viên'),
(11, 'FG-PARA-TAB',N'Viên nén Paracetamol 500mg', 'FinishedGood', 4, 1, N'Thành phẩm đầu ra, đóng vỉ 10 viên');
SET IDENTITY_INSERT Materials OFF;
GO

-- =====================================================================
-- 6. Recipes (3 công thức)
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, Note) VALUES
(1, 10, 1, 100000.00, 'Approved', 2, DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-45,GETDATE()), N'Công thức viên nang NLC 3 chuẩn GMP-WHO. Mẻ 100kg bột.'),
(2, 11, 2, 500000.00, 'Approved', 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-35,GETDATE()), N'Công thức viên nén Paracetamol 500mg. Mẻ 500kg.'),
(3, 10, 2, 100000.00, 'Draft',    NULL, NULL,                    DATEADD(DAY,-5, GETDATE()), N'Phiên bản thử nghiệm cải tiến tỷ lệ tá dược - Chưa phê duyệt.');
SET IDENTITY_INSERT Recipes OFF;
GO

-- =====================================================================
-- 7. RecipeBOM (Định mức vật tư - BOM)
-- =====================================================================
SET IDENTITY_INSERT RecipeBOM ON;
INSERT INTO RecipeBOM (BomId, RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note) VALUES
-- Recipe 1: Viên nang NLC 3 (mẻ 100kg bột)
(1,  1, 1,  30000.00, 2, 0.50, N'Hoạt chất chính, kiểm soát chặt chẽ'),
(2,  1, 3,  40000.00, 2, 1.00, N'Tinh bột ngô làm chất độn'),
(3,  1, 4,  20000.00, 2, 0.50, N'Lactose làm chất kết dính'),
(4,  1, 5,   1000.00, 2, 0.10, N'Magie stearat bôi trơn, thêm sau cùng'),
(5,  1, 7,   2000.00, 2, 0.20, N'PVP K30 kết dính hạt'),
(6,  1, 6, 100200.00, 4, 0.20, N'Vỏ nang cứng cỡ 0, dư 200 viên đề phòng'),
-- Recipe 2: Viên nén Paracetamol 500mg (mẻ 500kg bột)
(7,  2, 2, 250000.00, 2, 0.30, N'Paracetamol hoạt chất chính 50%'),
(8,  2, 3, 150000.00, 2, 1.00, N'Tinh bột ngô làm chất độn'),
(9,  2, 4,  80000.00, 2, 0.50, N'Lactose kết dính'),
(10, 2, 5,   5000.00, 2, 0.10, N'Magie stearat bôi trơn'),
(11, 2, 7,  10000.00, 2, 0.20, N'PVP K30 tạo hạt ướt');
SET IDENTITY_INSERT RecipeBOM OFF;
GO

-- =====================================================================
-- 8. RecipeRouting (Quy trình công đoạn)
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description) VALUES
-- Recipe 1: Viên nang NLC 3
(1, 1, 1, N'Cân Nguyên Liệu',       1, 60,  N'Cân chính xác từng thành phần theo BOM. Đối chiếu phiếu cân 2 lần.'),
(2, 1, 2, N'Sấy Nguyên Liệu NLC 3', 2, 120, N'Sấy hoạt chất ở 60°C đến khi %ẩm < 3.5%. Lấy mẫu kiểm tra mỗi 30 phút.'),
(3, 1, 3, N'Trộn Khô',              3, 45,  N'Trộn tất cả bột khô trong IBC 500L. Tốc độ 15rpm trong 30 phút đầu.'),
-- Recipe 2: Viên nén Paracetamol
(4, 2, 1, N'Cân Bột Paracetamol',   1, 90,  N'Cân và kiểm tra hàm lượng bột theo chứng nhận CoA của nhà cung cấp.'),
(5, 2, 2, N'Tạo Hạt Ướt & Sấy',    2, 150, N'Hòa tan PVP K30 vào nước, phun lên bột, sấy ở 55°C đến ẩm < 2%.'),
(6, 2, 3, N'Dập Viên',              4, 180, N'Dập viên hình tam giác, trọng lượng 550±10mg/viên, kiểm tra 20 viên/giờ.');
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- =====================================================================
-- 9. ProductionOrders (10 kịch bản đa dạng)
-- =====================================================================
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, ActualQuantity, Status, CreatedBy, StartDate, EndDate, CreatedAt) VALUES
(1,  'PO-2026-001', 1, 100000.00, 100050.00, 'Completed',  4, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-7,GETDATE())),
(2,  'PO-2026-002', 1, 300000.00, NULL,       'In-Process', 4, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,3, GETDATE()),  DATEADD(DAY,-2,GETDATE())),
(3,  'PO-2026-003', 1, 150000.00, NULL,       'Hold',       4, GETDATE(),                  DATEADD(DAY,4, GETDATE()),  DATEADD(DAY,-1,GETDATE())),
(4,  'PO-2026-004', 2, 200000.00, NULL,       'In-Process', 4, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,2, GETDATE()),  DATEADD(DAY,-3,GETDATE())),
(5,  'PO-2026-005', 1, 500000.00, NULL,       'Pending QC', 4, GETDATE(),                  DATEADD(DAY,7, GETDATE()),  GETDATE()),
(6,  'PO-2026-006', 2, 500000.00, NULL,       'In-Process', 4, DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,5, GETDATE()),  DATEADD(DAY,-4,GETDATE())),
(7,  'PO-2026-007', 2, 200000.00, 197800.00,  'Completed',  4, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-12,GETDATE())),
(8,  'PO-2026-008', 1, 100000.00, NULL,       'Draft',      4, DATEADD(DAY,3, GETDATE()),  DATEADD(DAY,7, GETDATE()),  GETDATE()),
(9,  'PO-2026-009', 1, 100000.00, NULL,       'Approved',   4, DATEADD(DAY,1, GETDATE()),  DATEADD(DAY,4, GETDATE()),  GETDATE()),
(10, 'PO-2026-010', 1, 100000.00, NULL,       'Cancelled',  4, GETDATE(),                  NULL,                       GETDATE());
SET IDENTITY_INSERT ProductionOrders OFF;
GO

-- =====================================================================
-- 10. ProductionBatches (11 mẻ sản xuất)
-- =====================================================================
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep) VALUES
-- PO-001 (Completed): 1 mẻ hoàn chỉnh
(1,  1,  'B26-001-01', 'Completed', DATEADD(DAY,-5,GETDATE()),    DATEADD(DAY,-2,GETDATE()),  DATEADD(YEAR,2,GETDATE()),  3),
-- PO-002 (In-Process): 3 mẻ, 2 xong 1 chạy
(2,  2,  'B26-002-01', 'Completed', DATEADD(HOUR,-24,GETDATE()),  DATEADD(HOUR,-12,GETDATE()), DATEADD(YEAR,2,GETDATE()), 3),
(3,  2,  'B26-002-02', 'Completed', DATEADD(HOUR,-18,GETDATE()),  DATEADD(HOUR,-6,GETDATE()),  DATEADD(YEAR,2,GETDATE()), 3),
(4,  2,  'B26-002-03', 'InProcess', GETDATE(),                    NULL,                         NULL,                      2),
-- PO-003 (Hold): 1 mẻ bị dừng
(5,  3,  'B26-003-01', 'OnHold',    DATEADD(HOUR,-6,GETDATE()),   NULL,                         NULL,                      2),
-- PO-004 (In-Process): 2 mẻ Paracetamol
(6,  4,  'B26-004-01', 'InProcess', DATEADD(HOUR,-8,GETDATE()),   NULL,                         NULL,                      3),
(7,  4,  'B26-004-02', 'Scheduled', NULL,                          NULL,                         NULL,                      1),
-- PO-006 (In-Process): 1 mẻ đang cân
(8,  6,  'B26-006-01', 'InProcess', GETDATE(),                    NULL,                         NULL,                      1),
-- PO-007 (Completed): 2 mẻ Paracetamol hoàn thành
(9,  7,  'B26-007-01', 'Completed', DATEADD(DAY,-10,GETDATE()),   DATEADD(DAY,-8,GETDATE()),   DATEADD(YEAR,2,GETDATE()),  3),
(10, 7,  'B26-007-02', 'Completed', DATEADD(DAY,-9,GETDATE()),    DATEADD(DAY,-7,GETDATE()),   DATEADD(YEAR,2,GETDATE()),  3),
-- PO-005 (Pending QC): 1 mẻ chờ QC duyệt
(11, 5,  'B26-005-01', 'InProcess', GETDATE(),                    NULL,                         NULL,                      1);
SET IDENTITY_INSERT ProductionBatches OFF;
GO

-- =====================================================================
-- 11. InventoryLots (12 lô nguyên liệu)
-- =====================================================================
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus) VALUES
-- Hoạt chất NLC 3
(1,  1,  'LOT-NLC3-001',  85000.00, DATEADD(DAY,-60,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
(2,  1,  'LOT-NLC3-002',  50000.00, DATEADD(DAY,-10,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Pending'),
-- Bột Paracetamol
(3,  2,  'LOT-PARA-001', 250000.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(4,  2,  'LOT-PARA-002', 120000.00, DATEADD(DAY,-5, GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
-- Tinh bột ngô
(5,  3,  'LOT-STR-001',   80000.00, DATEADD(DAY,-45,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
-- Lactose (1 lô hết hạn/rejected để test nhánh lỗi)
(6,  4,  'LOT-LAC-001',   60000.00, DATEADD(DAY,-90,GETDATE()), DATEADD(YEAR,1,GETDATE()),  'Released'),
(7,  4,  'LOT-LAC-002',    5000.00, DATEADD(DAY,-400,GETDATE()),DATEADD(DAY,-30,GETDATE()),  'Rejected'),
-- Magie Stearat
(8,  5,  'LOT-MGS-001',   10000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
-- Vỏ nang
(9,  6,  'LOT-CAP-001', 500000.00,  DATEADD(DAY,-15,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
-- PVP K30
(10, 7,  'LOT-PVP-001',   15000.00, DATEADD(DAY,-25,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
-- Màng nhôm & PVC
(11, 8,  'LOT-ALU-001', 2000000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(12, 9,  'LOT-PVC-001', 2000000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released');
SET IDENTITY_INSERT InventoryLots OFF;
GO

-- =====================================================================
-- 12. MaterialUsage (Xuất kho cho các mẻ)
-- =====================================================================
SET IDENTITY_INSERT MaterialUsage ON;
INSERT INTO MaterialUsage (UsageId, BatchId, InventoryLotId, PlannedAmount, ActualAmount, Timestamp, DispensedBy, Note) VALUES
-- Batch 1 (B26-001-01, PO-001 Completed)
(1,  1, 1,  30000.00,  30015.00, DATEADD(DAY,-5,GETDATE()), 3, N'Cân lần 1 theo BOM'),
(2,  1, 5,  40000.00,  40200.00, DATEADD(DAY,-5,GETDATE()), 3, N'Tinh bột ngô, thêm 0.5% bù hao'),
(3,  1, 6,  20000.00,  20100.00, DATEADD(DAY,-5,GETDATE()), 3, N'Lactose lô LOT-LAC-001'),
(4,  1, 8,   1000.00,   1005.00, DATEADD(DAY,-5,GETDATE()), 3, N'Magie Stearat thêm sau trộn'),
(5,  1, 9, 100200.00, 100200.00, DATEADD(DAY,-5,GETDATE()), 3, N'Vỏ nang Qualicaps số 0'),
-- Batch 2 (B26-002-01, PO-002 Completed)
(6,  2, 1,  30000.00,  30010.00, DATEADD(HOUR,-24,GETDATE()), 3, NULL),
(7,  2, 5,  40000.00,  40050.00, DATEADD(HOUR,-24,GETDATE()), 3, NULL),
(8,  2, 6,  20000.00,  20080.00, DATEADD(HOUR,-24,GETDATE()), 3, NULL),
-- Batch 3 (B26-002-02, PO-002 Completed)
(9,  3, 1,  30000.00,  30020.00, DATEADD(HOUR,-18,GETDATE()), 6, NULL),
(10, 3, 5,  40000.00,  40100.00, DATEADD(HOUR,-18,GETDATE()), 6, NULL),
-- Batch 9 (B26-007-01, PO-007 Completed - Paracetamol)
(11, 9, 3, 250000.00, 250300.00, DATEADD(DAY,-10,GETDATE()), 3, N'Paracetamol, bù 0.12% hao'),
(12, 9, 5, 150000.00, 150500.00, DATEADD(DAY,-10,GETDATE()), 3, N'Tinh bột ngô'),
-- Batch 10 (B26-007-02, PO-007 Completed - Paracetamol)
(13, 10, 3, 250000.00, 250000.00, DATEADD(DAY,-9,GETDATE()),  3, NULL),
(14, 10, 4, 120000.00, 120000.00, DATEADD(DAY,-9,GETDATE()),  3, N'Dùng lô PARA-002 bổ sung');
SET IDENTITY_INSERT MaterialUsage OFF;
GO

-- (Bảng QualityTests không tồn tại trong schema thực tế của DB này - đã bỏ qua)

-- =====================================================================
-- 14. BatchProcessLogs (Nhật ký eBMR với JSON Parameters đầy đủ)
-- =====================================================================
SET IDENTITY_INSERT BatchProcessLogs ON;

-- ▶ PO-2026-001 / B26-001-01 (Hoàn thành 3/3 công đoạn - Passed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(1, 1, 1, 1, 3,
 DATEADD(HOUR,-120,GETDATE()), DATEADD(HOUR,-119,GETDATE()),
 'Passed',
 N'{"maSanPham":"FG-NLC3-CAP","tenSanPham":"Viên nang NLC 3","soLo":"B26-001-01","ngaySanXuat":"2026-04-01","soLuongKe":"100000","mayCan":"EQP-WGH-01","soCan":1,"mauHieuCan":"MT-2601","nguoiCan":"op01","nguoiKiemTra":"qc01","nguyenLieu":[{"ten":"Hoạt chất NLC 3","loSX":"LOT-NLC3-001","khLT":30000,"khTT":30015,"saiSo":0.05,"ketQua":"Dat"},{"ten":"Tinh bột ngô","loSX":"LOT-STR-001","khLT":40000,"khTT":40200,"saiSo":0.50,"ketQua":"Dat"},{"ten":"Lactose Monohydrate","loSX":"LOT-LAC-001","khLT":20000,"khTT":20100,"saiSo":0.50,"ketQua":"Dat"},{"ten":"Magie Stearat","loSX":"LOT-MGS-001","khLT":1000,"khTT":1005,"saiSo":0.50,"ketQua":"Dat"}],"phieuKiemNghiem":"PN-B26001-001","trangThaiMoiTruong":"Dat","nhiemVuXuong":"Ky hop dong xuat khau"}'),

(2, 1, 2, 2, 3,
 DATEADD(HOUR,-118,GETDATE()), DATEADD(HOUR,-116,GETDATE()),
 'Passed',
 N'{"soLo":"B26-001-01","maySay":"EQP-DRY-01","loaiMay":"KBC-60","nhietDoGio":60,"nhietDoSay":65,"tgSay":120,"tocDoGio":1200,"nguoiVanHanh":"op01","nguoiKiemTra":"qc01","mauDo":[{"thoiGian":30,"doAm":5.20,"nhietDo":63.5,"datYeuCau":"Chua"},{"thoiGian":60,"doAm":4.10,"nhietDo":64.1,"datYeuCau":"Chua"},{"thoiGian":90,"doAm":3.20,"nhietDo":64.8,"datYeuCau":"Chua"},{"thoiGian":120,"doAm":2.85,"nhietDo":65.2,"datYeuCau":"Dat"}],"doAmCuoi":2.85,"doAmYeuCau":3.50,"ketQua":"Dat","nhiemVu":"Day kho NLC 3 den khi %am du tieu chuan"}'),

(3, 1, 3, 3, 3,
 DATEADD(HOUR,-115,GETDATE()), DATEADD(HOUR,-114,GETDATE()),
 'Passed',
 N'{"soLo":"B26-001-01","mayTron":"EQP-MIX-01","dungTich":"500L","tocDoTron":15,"tgGiaiDoan1":30,"tgGiaiDoan2":15,"nguoiVanHanh":"op01","nguoiKiemTra":"qc01","tieuChuanTron":"RSD <5%","kiemTraDongNhat":[{"vi_tri":"Tren","doAm":2.82,"tyLeHoatChat":30.05},{"vi_tri":"Giua","doAm":2.86,"tyLeHoatChat":29.98},{"vi_tri":"Duoi","doAm":2.81,"tyLeHoatChat":30.02}],"RSD":0.11,"ketQua":"Dat","ghiChu":"Them Magie Stearat o phut thu 30"}');

-- ▶ PO-2026-002 / B26-002-01 (Hoàn thành)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(4, 2, 1, 1, 6, DATEADD(HOUR,-24,GETDATE()), DATEADD(HOUR,-23,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-01","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Hoạt chất NLC 3","loSX":"LOT-NLC3-001","khLT":30000,"khTT":30010,"ketQua":"Dat"},{"ten":"Tinh bột ngô","loSX":"LOT-STR-001","khLT":40000,"khTT":40050,"ketQua":"Dat"},{"ten":"Lactose","loSX":"LOT-LAC-001","khLT":20000,"khTT":20080,"ketQua":"Dat"},{"ten":"Magie Stearat","loSX":"LOT-MGS-001","khLT":1000,"khTT":1003,"ketQua":"Dat"}],"nguoiCan":"op02","nguoiKiemTra":"qc01"}'),

(5, 2, 2, 2, 6, DATEADD(HOUR,-23,GETDATE()), DATEADD(HOUR,-21,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-01","maySay":"EQP-DRY-01","nhietDoSay":65,"tgSay":120,"mauDo":[{"thoiGian":60,"doAm":4.50,"datYeuCau":"Chua"},{"thoiGian":120,"doAm":3.10,"datYeuCau":"Dat"}],"doAmCuoi":3.10,"doAmYeuCau":3.50,"ketQua":"Dat"}'),

(6, 2, 3, 3, 6, DATEADD(HOUR,-21,GETDATE()), DATEADD(HOUR,-20,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-01","mayTron":"EQP-MIX-01","tocDoTron":15,"tgTong":45,"RSD":0.18,"ketQua":"Dat"}');

-- ▶ PO-2026-002 / B26-002-02 (Hoàn thành)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(7,  3, 1, 1, 3, DATEADD(HOUR,-18,GETDATE()), DATEADD(HOUR,-17,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-02","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Hoạt chất NLC 3","khLT":30000,"khTT":30020,"ketQua":"Dat"},{"ten":"Tinh bột ngô","khLT":40000,"khTT":40100,"ketQua":"Dat"},{"ten":"Lactose","khLT":20000,"khTT":19980,"ketQua":"Dat"}],"nguoiCan":"op01","nguoiKiemTra":"qc02"}'),
(8,  3, 2, 7, 3, DATEADD(HOUR,-17,GETDATE()), DATEADD(HOUR,-15,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-02","maySay":"EQP-DRY-02","nhietDoSay":63,"tgSay":130,"doAmCuoi":3.05,"doAmYeuCau":3.50,"ketQua":"Dat"}'),
(9,  3, 3, 8, 3, DATEADD(HOUR,-14,GETDATE()), DATEADD(HOUR,-13,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-02","mayTron":"EQP-MIX-02","tocDoTron":15,"tgTong":45,"RSD":0.22,"ketQua":"Dat"}');

-- ▶ PO-2026-002 / B26-002-03 (Đang chạy - Bước 1 xong, bước 2 đang chạy)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(10, 4, 1, 6, 3, DATEADD(HOUR,-2,GETDATE()), DATEADD(HOUR,-1,GETDATE()), 'Passed',
 N'{"soLo":"B26-002-03","mayCan":"EQP-WGH-02","danhSachCan":[{"ten":"Hoạt chất NLC 3","khLT":30000,"khTT":30005,"ketQua":"Dat"},{"ten":"Tinh bột ngô","khLT":40000,"khTT":40060,"ketQua":"Dat"}],"nguoiCan":"op01","nguoiKiemTra":"qc01"}');

-- ▶ PO-2026-003 / B26-003-01 (OnHold - Bước 1 xong, bước 2 bị dừng vì Lactose reject)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(11, 5, 1, 1, 6, DATEADD(HOUR,-7,GETDATE()), DATEADD(HOUR,-6,GETDATE()), 'Passed',
 N'{"soLo":"B26-003-01","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Hoạt chất NLC 3","khLT":30000,"khTT":30008,"ketQua":"Dat"},{"ten":"Lactose","loSX":"LOT-LAC-002","khLT":20000,"khTT":20000,"ketQua":"Dat"}],"ghiChu":"LOT-LAC-002 chua nhan reject QC luc can - CANH BAO: Phat hien bi reject sau khi can"}'),
(12, 5, 2, 2, 6, DATEADD(HOUR,-5,GETDATE()), NULL, 'OnHold',
 N'{"soLo":"B26-003-01","lyDoDung":"Nguyen lieu Lactose LOT-LAC-002 khong dat QC. Cho phe duyet thay the tu QA."}');

-- ▶ PO-2026-004 / B26-004-01 (Paracetamol - Bước 1+2 đang chạy, bước 3 đang dập viên)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(13, 6, 4, 1, 3, DATEADD(HOUR,-9,GETDATE()), DATEADD(HOUR,-8,GETDATE()), 'Passed',
 N'{"soLo":"B26-004-01","tenSanPham":"Viên nén Paracetamol 500mg","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Bột Paracetamol","loSX":"LOT-PARA-001","khLT":250000,"khTT":250300,"ketQua":"Dat"},{"ten":"Tinh bột ngô","loSX":"LOT-STR-001","khLT":150000,"khTT":150500,"ketQua":"Dat"},{"ten":"Lactose","loSX":"LOT-LAC-001","khLT":80000,"khTT":80050,"ketQua":"Dat"},{"ten":"PVP K30","loSX":"LOT-PVP-001","khLT":10000,"khTT":10020,"ketQua":"Dat"}],"nguoiCan":"op01","nguoiKiemTra":"qc02"}'),
(14, 6, 5, 2, 3, DATEADD(HOUR,-7,GETDATE()), DATEADD(HOUR,-4,GETDATE()), 'Passed',
 N'{"soLo":"B26-004-01","maySay":"EQP-DRY-01","nhietDoSay":55,"tgSay":150,"mucPVP":"2% trong nuoc","mauDo":[{"thoiGian":50,"doAm":3.50,"datYeuCau":"Chua"},{"thoiGian":100,"doAm":2.10,"datYeuCau":"Chua"},{"thoiGian":150,"doAm":1.75,"datYeuCau":"Dat"}],"doAmCuoi":1.75,"doAmYeuCau":2.00,"ketQua":"Dat"}'),
(15, 6, 6, 4, 3, DATEADD(HOUR,-3,GETDATE()), NULL, 'Running',
 NULL);

-- ▶ PO-2026-006 / B26-006-01 (Bước 1 cân đang chạy)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus)
VALUES
(16, 8, 4, 6, 6, DATEADD(MINUTE,-30,GETDATE()), NULL, 'Running');

-- ▶ PO-2026-007 / B26-007-01 (Hoàn thành - Paracetamol)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(17, 9,  4, 1, 3, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()), 'Passed',
 N'{"soLo":"B26-007-01","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Bột Paracetamol","loSX":"LOT-PARA-001","khLT":250000,"khTT":250300,"ketQua":"Dat"},{"ten":"Tinh bột ngô","khLT":150000,"khTT":150500,"ketQua":"Dat"}],"nguoiCan":"op01","nguoiKiemTra":"qc01"}'),
(18, 9,  5, 2, 3, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-9,GETDATE()),  'Passed',
 N'{"soLo":"B26-007-01","nhietDoSay":55,"tgSay":145,"doAmCuoi":1.90,"ketQua":"Dat"}'),
(19, 9,  6, 4, 3, DATEADD(DAY,-9,GETDATE()),  DATEADD(DAY,-8,GETDATE()),  'Passed',
 N'{"soLo":"B26-007-01","mayDapVien":"EQP-TAB-01","troiLuongMucTieu":550,"troiLuongDCC":552.3,"kiemTraDinhKy":[{"gio":0,"tbTroi":551.2,"datTC":"Dat"},{"gio":1,"tbTroi":550.8,"datTC":"Dat"},{"gio":2,"tbTroi":552.5,"datTC":"Dat"}],"soVienDap":1000200,"soVienKhongDat":125,"tyLeKhongDat":"0.012%","ketQua":"Dat"}');

-- PO-2026-007 / B26-007-02 (Hoàn thành)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(20, 10, 4, 1, 6, DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-9,GETDATE()), 'Passed',
 N'{"soLo":"B26-007-02","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Bột Paracetamol","loSX":"LOT-PARA-002","khLT":250000,"khTT":250000,"ketQua":"Dat"},{"ten":"Lactose","loSX":"LOT-LAC-001","khLT":80000,"khTT":80000,"ketQua":"Dat"}],"nguoiCan":"op02","nguoiKiemTra":"qc02"}'),
(21, 10, 5, 7, 6, DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-8,GETDATE()), 'Passed',
 N'{"soLo":"B26-007-02","nhrietDoSay":56,"doAmCuoi":1.82,"ketQua":"Dat"}'),
(22, 10, 6, 4, 6, DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-7,GETDATE()), 'Passed',
 N'{"soLo":"B26-007-02","mayDapVien":"EQP-TAB-01","troiLuongDCC":549.8,"ketQua":"Dat"}');

SET IDENTITY_INSERT BatchProcessLogs OFF;
GO

-- =====================================================================
-- 15. SystemAuditLog (Dấu vết kiểm toán - minh họa)
-- =====================================================================
SET IDENTITY_INSERT SystemAuditLog ON;
INSERT INTO SystemAuditLog (AuditId, TableName, RecordId, Action, OldValue, NewValue, ChangedBy, ChangedDate)
VALUES
(1, 'Recipes', '1', 'UPDATE',
 N'{"Status":"Draft","ApprovedBy":null}',
 N'{"Status":"Approved","ApprovedBy":2,"ApprovedDate":"'+ CONVERT(NVARCHAR,DATEADD(DAY,-30,GETDATE()),120) +N'"}',
 2, DATEADD(DAY,-30,GETDATE())),

(2, 'ProductionOrders', '3', 'UPDATE',
 N'{"Status":"In-Process"}',
 N'{"Status":"Hold","Note":"Lactose LOT-LAC-002 bị reject QC"}',
 2, DATEADD(DAY,-1,GETDATE())),

(3, 'AppUsers', '6', 'INSERT',
 NULL,
 N'{"UserId":6,"Username":"op02","FullName":"Hoàng Văn Thao Tác","Role":"Operator","IsActive":1}',
 1, DATEADD(DAY,-30,GETDATE())),

(4, 'InventoryLots', '7', 'UPDATE',
 N'{"QCStatus":"Pending"}',
 N'{"QCStatus":"Rejected","Note":"Độ ẩm 1.85% vượt ngưỡng 0.5%"}',
 5, DATEADD(DAY,-5,GETDATE())),

(5, 'ProductionOrders', '5', 'UPDATE',
 N'{"Status":"Approved"}',
 N'{"Status":"Pending QC"}',
 3, GETDATE());
SET IDENTITY_INSERT SystemAuditLog OFF;
GO
