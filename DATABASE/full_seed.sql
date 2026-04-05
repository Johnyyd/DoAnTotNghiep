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
IF OBJECT_ID('BatchProcessParameterValue', 'U') IS NOT NULL DELETE FROM BatchProcessParameterValue;
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DELETE FROM StepParameters;
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DELETE FROM QualityTests;
IF OBJECT_ID('SystemAuditLog', 'U') IS NOT NULL DELETE FROM SystemAuditLog;
IF OBJECT_ID('MaterialUsage', 'U') IS NOT NULL DELETE FROM MaterialUsage;
IF OBJECT_ID('BatchProcessLogs', 'U') IS NOT NULL DELETE FROM BatchProcessLogs;
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DELETE FROM ProductionBatches;
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DELETE FROM ProductionOrders;
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DELETE FROM InventoryLots;
IF OBJECT_ID('RecipeBom', 'U') IS NOT NULL DELETE FROM RecipeBom;
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DELETE FROM RecipeRouting;
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DELETE FROM Recipes;
IF OBJECT_ID('Materials', 'U') IS NOT NULL DELETE FROM Materials;
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DELETE FROM Equipments;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DELETE FROM UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DELETE FROM UnitOfMeasure;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DELETE FROM AppUsers;
GO

-- RESET IDENTITY
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DBCC CHECKIDENT ('AppUsers', RESEED, 0);
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DBCC CHECKIDENT ('UnitOfMeasure', RESEED, 0);
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DBCC CHECKIDENT ('UomConversions', RESEED, 0);
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DBCC CHECKIDENT ('Equipments', RESEED, 0);
IF OBJECT_ID('Materials', 'U') IS NOT NULL DBCC CHECKIDENT ('Materials', RESEED, 0);
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DBCC CHECKIDENT ('Recipes', RESEED, 0);
IF OBJECT_ID('RecipeBom', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeBom', RESEED, 0);
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DBCC CHECKIDENT ('StepParameters', RESEED, 0);
IF OBJECT_ID('BatchProcessParameterValue', 'U') IS NOT NULL DBCC CHECKIDENT ('BatchProcessParameterValue', RESEED, 0);
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DBCC CHECKIDENT ('QualityTests', RESEED, 0);
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DBCC CHECKIDENT ('InventoryLots', RESEED, 0);
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
(1, 'IW2-60',     N'Cân điện tử IW2-60 (Cân thô)',        'Ready',       DATEADD(DAY,-15,GETDATE())),
(2, 'KBC-TS-50',  N'Máy sấy tầng sôi KBC-TS-50',          'Ready',       DATEADD(DAY,-20,GETDATE())),
(3, 'AD-LP-200',  N'Máy trộn lập phương AD-LP-200',       'Ready',       DATEADD(DAY,-10,GETDATE())),
(4, 'EQP-TAB-01', N'Máy dập viên tròn xoay Fette',         'Ready',       DATEADD(DAY,-5, GETDATE())),
(5, 'EQP-BLS-01', N'Máy ép vỉ nhôm Uhlmann',               'Maintenance', DATEADD(DAY,-3, GETDATE())),
(6, 'PMA-5000',   N'Cân điện tử PMA-5000 (Cân chính xác)', 'Ready',       DATEADD(DAY,-7, GETDATE())),
(7, 'EQP-CAP-01', N'Máy đóng nang tự động NJP-1200',      'Ready',       DATEADD(DAY,-25,GETDATE())),
(8, 'EQP-MIX-02', N'Máy trộn IBC 200L (phụ)',             'Running',     DATEADD(DAY,-12,GETDATE()));
SET IDENTITY_INSERT Equipments OFF;
GO

-- =====================================================================
-- 5. Materials (11 loại vật tư)
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, Description) VALUES
(1,  'MAT-NLC3',   N'Hoạt chất NLC 3 (Cao khô Trinh nữ)', 'RawMaterial',  1, 1, N'Bảo quản 15-25°C, tránh ánh sáng'),
(2,  'MAT-PARA',   N'Bột Paracetamol tinh khiết',         'RawMaterial',  1, 1, N'USP Grade, bảo quản nơi khô ráo'),
(3,  'MAT-TD8',    N'Tinh bột (Filler)',                  'RawMaterial',  1, 1, N'TD 8 - Tá dược độn bù trừ'),
(12, 'MAT-TD1',    N'Aerosil',                            'RawMaterial',  2, 1, N'TD 1 - TD trơn chảy'),
(13, 'MAT-TD3',    N'Sodium starch glycolate',            'RawMaterial',  1, 1, N'TD 3 - Tá dược rã'),
(14, 'MAT-TD4',    N'Talc',                               'RawMaterial',  2, 1, N'TD 4 - Tá dược trơn'),
(5,  'MAT-TD5',    N'Magie Stearat',                      'RawMaterial',  2, 1, N'TD 5 - Tá dược trơn'),
(6,  'MAT-NLP6',   N'Vỏ nang cứng (Cỡ 0)',                'RawMaterial',  4, 1, N'NLP 6 - Vỏ nang gelatin'),
(10, 'FG-NLC3-CAP',N'Viên nang NLC 3 (540mg)',            'FinishedGood', 4, 1, N'Thành phẩm đầu ra'),
(11, 'FG-PARA-TAB',N'Viên nén Paracetamol 500mg',         'FinishedGood', 4, 1, N'Finished Good');
SET IDENTITY_INSERT Materials OFF;
GO

-- =====================================================================
-- 6. Recipes (3 công thức)
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, Note) VALUES
(1, 10, 1, 54000.00, 'Approved', 2, DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-45,GETDATE()), N'Công thức viên nang NLC 3 chuẩn GMP-WHO. Mẻ 100,000 viên (54kg).'),
(2, 11, 2, 500000.00, 'Approved', 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-35,GETDATE()), N'Công thức Paracetamol 500mg.'),
(3, 10, 2, 100000.00, 'Draft',    NULL, NULL,                    DATEADD(DAY,-5, GETDATE()), N'Phiên bản thử nghiệm cải tiến tỷ lệ tá dược - Chưa phê duyệt.');
SET IDENTITY_INSERT Recipes OFF;
GO

-- =====================================================================
-- 7. RecipeBOM (Định mức vật tư - BOM)
-- =====================================================================
SET IDENTITY_INSERT RecipeBOM ON;
INSERT INTO RecipeBOM (BomId, RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note) VALUES
-- Recipe 1: Viên nang NLC 3 (100,000 viên x 540mg = 54,000g)
(1,  1, 1,  25000.00, 2, 0.20, N'NLC 3 (250mg/viên)'),
(2,  1, 12,   162.00, 2, 0.10, N'TD 1 - Aerosil (1.62mg/viên)'),
(3,  1, 13,  2970.00, 2, 0.20, N'TD 3 - SSG (29.70mg/viên)'),
(4,  1, 14,   405.00, 2, 0.10, N'TD 4 - Talc (4.05mg/viên)'),
(5,  1, 5,    405.00, 2, 0.10, N'TD 5 - Magnesi stearat (4.05mg/viên)'),
(6,  1, 3,  25058.00, 2, 0.50, N'TD 8 - Tinh bột (250.58mg/viên) - Bù trừ'),
(7,  1, 6, 100000.00, 4, 0.10, N'NLP 6 - Vỏ nang cứng (1 viên/viên)'),
-- Recipe 2: Paracetamol 500mg (mẻ 500kg bột)
(8,  2, 2, 250000.00, 2, 0.30, N'Paracetamol hoạt chất chính 50%'),
(9,  2, 3, 150000.00, 2, 1.00, N'Tinh bột ngô làm chất độn'),
(10, 2, 4,  80000.00, 2, 0.50, N'Lactose kết dính'),
(11, 2, 5,   5000.00, 2, 0.10, N'Magie stearat bôi trơn'),
(12, 2, 7,  10000.00, 2, 0.20, N'PVP K30 tạo hạt ướt');
SET IDENTITY_INSERT RecipeBOM OFF;
GO

-- =====================================================================
-- 8. RecipeRouting (Quy trình công đoạn)
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description) VALUES
-- Recipe 1: Viên nang NLC 3
(1, 1, 1, N'Sấy Tá Dược 8 (TD 8)',              2, 180, N'Sấy tinh bột TD 8 tại 75°C, 180p. Độ ẩm < 5%.'),
(2, 1, 2, N'Sấy Cao Khô NLC 3',                2, 180, N'Sấy cao khô Trinh nữ tại 75°C, 180p. Độ ẩm < 3%.'),
(3, 1, 3, N'Cân Nguyên Liệu',                  1, 90,  N'Cân chính xác 6 loại theo BOM động (Section 4 BMR). Đối chiếu nhãn phụ.'),
(4, 1, 4, N'Trộn Khô',                         3, 15,  N'Trộn premix bột tá dược trước. Trộn chính 15 phút, 15 vòng/phút.'),
(7, 1, 5, N'Đóng Nang',                        7, 120, N'Đóng nang số 0, khối lượng đích 540mg/viên.'),
-- Recipe 2: Paracetamol
(5, 2, 1, N'Cân Paracetamol',   1, 90,  NULL),
(6, 2, 2, N'Dập Viên',          4, 180, NULL);
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- =====================================================================
-- 12. StepParameters (Dữ liệu chốt GMP - Cấu trúc bảng và Seeding)
-- Bảng này thường thiếu trong seed cũ, cần nạp để Mobile check Deviation.
-- =====================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='StepParameters' AND xtype='U')
BEGIN
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
END

SET IDENTITY_INSERT StepParameters ON;
INSERT INTO StepParameters (ParameterId, RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical) VALUES
-- Step 1 (Sấy TD 8) của Recipe 1
(1, 1, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(2, 1, N'Độ ẩm phòng',   '%',  45, 70, 1),
(3, 1, N'Áp lực phòng',  'Pa', 10, 50, 1),
(4, 1, N'Nhiệt độ sấy',  '°C', 73, 77, 1),
(20, 1, N'Thời gian sấy', 'phút', 170, 190, 1),
-- Step 2 (Sấy NLC 3) của Recipe 1
(21, 2, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(22, 2, N'Độ ẩm phòng',   '%',  45, 70, 1),
(23, 2, N'Áp lực phòng',  'Pa', 10, 50, 1),
(24, 2, N'Nhiệt độ sấy',  '°C', 73, 77, 1),
(25, 2, N'Thời gian sấy', 'phút', 170, 190, 1),
-- Step 3 (Weighing) của Recipe 1
(5, 3, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(6, 3, N'Độ ẩm phòng',   '%',  45, 70, 1),
-- Step 4 (Mixing) của Recipe 1
(7, 4, N'Tốc độ trộn',   'v/p', 14, 16, 1),
(8, 4, N'Thời gian trộn', 'phút', 14, 16, 1);
SET IDENTITY_INSERT StepParameters OFF;
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
(11, 5,  'B26-005-01', 'InProcess', GETDATE(),                    NULL,                         NULL,                      1),
-- PO-008 (Draft): 1 mẻ dự thảo
(12, 8,  'B26-008-01', 'Draft',     GETDATE(),                    NULL,                         NULL,                      1);
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
-- Batch 1 (B26-001-01)
(1,  1, 1,  25000.00,  25015.00, DATEADD(DAY,-5,GETDATE()), 3, N'NLC 3 lot LOT-NLC3-001'),
(2,  1, 5,  25058.00,  25100.00, DATEADD(DAY,-5,GETDATE()), 3, N'Tinh bột TD 8 lot LOT-STR-001'),
(3,  1, 8,    405.00,    405.00, DATEADD(DAY,-5,GETDATE()), 3, N'Magie Stearat'),
-- Batch 9 (B26-007-01 - Paracetamol)
(4,  9, 3, 250000.00, 250300.00, DATEADD(DAY,-10,GETDATE()), 3, N'Paracetamol');
SET IDENTITY_INSERT MaterialUsage OFF;
GO

-- (Bảng QualityTests không tồn tại trong schema thực tế của DB này - đã bỏ qua)

-- =====================================================================
-- 14. BatchProcessLogs (Nhật ký eBMR với JSON Parameters đầy đủ)
-- =====================================================================
SET IDENTITY_INSERT BatchProcessLogs ON;

-- ▶ PO-2026-001 / B26-001-01 (Hoàn thành 4/4 công đoạn - Passed)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(1, 1, 1, 2, 3, DATEADD(HOUR,-124,GETDATE()), DATEADD(HOUR,-122,GETDATE()), 'Passed', 
 N'{"soLo":"B26-001-01","maySay":"KBC-TS-50","nhietDo":23.5,"doAm":52.0,"apLuc":25.0,"nhietDoSay":75.0,"tgSay":180,"ketQua":"Dat"}'),
(2, 1, 2, 2, 3, DATEADD(HOUR,-122,GETDATE()), DATEADD(HOUR,-120,GETDATE()), 'Passed', 
 N'{"soLo":"B26-001-01","maySay":"KBC-TS-50","nhietDo":23.8,"doAm":51.5,"apLuc":26.0,"nhietDoSay":75.2,"tgSay":180,"ketQua":"Dat"}'),
(3, 1, 3, 1, 3, DATEADD(HOUR,-120,GETDATE()), DATEADD(HOUR,-119,GETDATE()), 'Passed',
 N'{"soLo":"B26-001-01","mayCan":"IW2-60","nguoiCan":"op01","nguyenLieu":[{"ten":"Hoạt chất NLC 3","khTT":30015,"ketQua":"Dat"},{"ten":"Tinh bột ngô","khTT":40200,"ketQua":"Dat"}]}'),
(4, 1, 4, 3, 3, DATEADD(HOUR,-118,GETDATE()), DATEADD(HOUR,-117,GETDATE()), 'Passed',
 N'{"soLo":"B26-001-01","mayTron":"AD-LP-200","tocDoTron":15,"tgGiaiDoan1":30,"RSD":0.11,"ketQua":"Dat"}');

-- ▶ PO-2026-002 / B26-002-01 (Hoàn thành)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(5, 2, 1, 2, 6, DATEADD(HOUR,-26,GETDATE()), DATEADD(HOUR,-24,GETDATE()), 'Passed', 
 N'{"soLo":"B26-002-01","nhietDo":24.1,"doAm":48.0,"ketQua":"Dat"}'),
(6, 2, 2, 2, 6, DATEADD(HOUR,-24,GETDATE()), DATEADD(HOUR,-22,GETDATE()), 'Passed', 
 N'{"soLo":"B26-002-01","nhietDo":24.3,"doAm":47.5,"ketQua":"Dat"}'),
(7, 2, 3, 1, 6, DATEADD(HOUR,-22,GETDATE()), DATEADD(HOUR,-21,GETDATE()), 'Passed', 
 N'{"soLo":"B26-002-01","mayCan":"IW2-60","khTT":30010,"ketQua":"Dat"}'),
(8, 2, 4, 3, 6, DATEADD(HOUR,-21,GETDATE()), DATEADD(HOUR,-20,GETDATE()), 'Passed', 
 N'{"soLo":"B26-002-01","mayTron":"AD-LP-200","tocDoTron":15,"tgTong":45,"ketQua":"Dat"}');

-- ▶ PO-2026-002 / B26-002-02 (Hoàn thành)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(9,  3, 1, 2, 3, DATEADD(HOUR,-18,GETDATE()), DATEADD(HOUR,-17,GETDATE()), 'Passed', NULL),
(10, 3, 2, 2, 3, DATEADD(HOUR,-17,GETDATE()), DATEADD(HOUR,-16,GETDATE()), 'Passed', NULL),
(11, 3, 3, 1, 3, DATEADD(HOUR,-16,GETDATE()), DATEADD(HOUR,-15,GETDATE()), 'Passed', NULL),
(12, 3, 4, 3, 3, DATEADD(HOUR,-15,GETDATE()), DATEADD(HOUR,-14,GETDATE()), 'Passed', NULL);

-- ▶ PO-2026-002 / B26-002-03 (Sấy TD 8 xong, đang Sấy NLC 3)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(13, 4, 1, 2, 3, DATEADD(HOUR,-3,GETDATE()), DATEADD(HOUR,-2,GETDATE()), 'Passed', NULL),
(14, 4, 2, 2, 3, DATEADD(HOUR,-2,GETDATE()), NULL, 'Running', NULL);

-- ▶ PO-2026-003 / B26-003-01 (Sấy TD 8 xong, Sấy NLC 3 bị dừng)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(15, 5, 1, 2, 6, DATEADD(HOUR,-8,GETDATE()), DATEADD(HOUR,-7,GETDATE()), 'Passed', NULL),
(16, 5, 2, 2, 6, DATEADD(HOUR,-7,GETDATE()), NULL, 'OnHold', N'{"lyDoDung":"Lỗi máy sấy"}');

-- ▶ PO-2026-004 / B26-004-01 (Paracetamol - Recipe 2)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(17, 6, 5, 1, 3, DATEADD(HOUR,-9,GETDATE()), DATEADD(HOUR,-8,GETDATE()), 'Passed', NULL),
(18, 6, 6, 4, 3, DATEADD(HOUR,-7,GETDATE()), NULL, 'Running', NULL);

-- ▶ PO-2026-007 / B26-007-01 (Paracetamol)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(19, 9, 5, 1, 3, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-10,GETDATE()), 'Passed', NULL),
(20, 9, 6, 4, 3, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-9,GETDATE()), 'Passed', NULL);

-- ▶ PO-2026-007 / B26-007-02 (Paracetamol)
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
VALUES
(21, 10, 5, 1, 6, DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-9,GETDATE()), 'Passed',
 N'{"soLo":"B26-007-02","mayCan":"EQP-WGH-01","danhSachCan":[{"ten":"Bột Paracetamol","loSX":"LOT-PARA-002","khLT":250000,"khTT":250000,"ketQua":"Dat"},{"ten":"Lactose","loSX":"LOT-LAC-001","khLT":80000,"khTT":80000,"ketQua":"Dat"}],"nguoiCan":"op02","nguoiKiemTra":"qc02"}'),
(22, 10, 6, 4, 6, DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-8,GETDATE()), 'Passed',
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
