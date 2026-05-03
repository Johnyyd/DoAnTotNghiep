/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   FULL SEED DATA v3.2 - Fully Synchronized with Schema.sql
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =====================================================================
-- 0. VÔ HIỆU HÓA RÀNG BUỘC VÀ TRIGGER ĐỂ DỌN DẸP DỮ LIỆU
-- =====================================================================
PRINT 'Disabling Constraints and Triggers...';
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
EXEC sp_msforeachtable 'ALTER TABLE ? DISABLE TRIGGER ALL';
GO

-- =====================================================================
-- XÓA DỮ LIỆU CŨ (THEO THỨ TỰ NGƯỢC KHÓA NGOẠI)
-- =====================================================================
PRINT 'Deleting existing data...';
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
IF OBJECT_ID('ProductionAreas', 'U') IS NOT NULL DELETE FROM ProductionAreas;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DELETE FROM UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DELETE FROM UnitOfMeasure;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DELETE FROM AppUsers;
GO
PRINT 'Delete Data Completed Successfully!';

-- =====================================================================
-- RESET IDENTITY (Đảm bảo ID bắt đầu từ 1)
-- =====================================================================
PRINT 'Resetting Identities...';
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DBCC CHECKIDENT ('AppUsers', RESEED, 0);
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DBCC CHECKIDENT ('UnitOfMeasure', RESEED, 0);
IF OBJECT_ID('ProductionAreas', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionAreas', RESEED, 0);
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DBCC CHECKIDENT ('UomConversions', RESEED, 0);
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DBCC CHECKIDENT ('Equipments', RESEED, 0);
IF OBJECT_ID('Materials', 'U') IS NOT NULL DBCC CHECKIDENT ('Materials', RESEED, 0);
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DBCC CHECKIDENT ('Recipes', RESEED, 0);
IF OBJECT_ID('RecipeBom', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeBom', RESEED, 0);
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DBCC CHECKIDENT ('StepParameters', RESEED, 0);
IF OBJECT_ID('BatchProcessParameterValue', 'U') IS NOT NULL DBCC CHECKIDENT ('BatchProcessParameterValue', RESEED, 0);
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DBCC CHECKIDENT ('InventoryLots', RESEED, 0);
GO
PRINT 'Reset Identity Completed Successfully!';

-- =====================================================================
-- 1. AppUsers
-- =====================================================================
SET IDENTITY_INSERT AppUsers ON;
INSERT INTO AppUsers (UserId, Username, FullName, Role, IsActive, PasswordHash, CreatedAt, PinCode)
VALUES
(1, 'admin',   N'Admin Hệ Thống',           'Admin',             1, '$2b$11$hyVSDA5K2Qg1FVUosjSk4e76FBcJhE7DbNG/KDELUBotFzcSt5xIW', DATEADD(DAY,-90,GETDATE()), '123456'),
(2, 'qc01',    N'Trần Thị Kiểm Tra',        'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-60,GETDATE()), '123456'),
(3, 'op01',    N'Nguyễn Văn Công Nhân',     'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-60,GETDATE()), '123456'),
(4, 'mgr01',   N'Lê Quang Quản Lý',         'ProductionManager', 1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-90,GETDATE()), '123456'),
(5, 'qc02',    N'Phạm Thị Chất Lượng',      'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-30,GETDATE()), '123456'),
(6, 'op02',    N'Hoàng Văn Thao Tác',       'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-30,GETDATE()), '123456');
SET IDENTITY_INSERT AppUsers OFF;
GO

-- =====================================================================
-- 2. UnitOfMeasure
-- =====================================================================
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description) VALUES
(1, 'kg',      N'Kilogram'),
(2, 'g',       N'Gram'),
(3, 'L',       N'Lít'),
(4, 'Viên',    N'Viên'),
(5, 'Vỉ',      N'Vỉ (10 viên/vỉ)'),
(6, 'Hộp',     N'Hộp (10 vỉ/hộp)'),
(7, 'Thùng',   N'Thùng (12 hộp/thùng)'),
(8, N'Cái',    N'Đơn vị cái');
SET IDENTITY_INSERT UnitOfMeasure OFF;
GO

-- =====================================================================
-- 3. ProductionAreas
-- =====================================================================
SET IDENTITY_INSERT ProductionAreas ON;
INSERT INTO ProductionAreas (AreaId, AreaCode, AreaName, Description)
VALUES 
(1, 'PHONG-PHA-CHE', N'Phòng pha chế', N'Khu vực pha chế'),
(2, 'PHONG-CAN', N'Phòng cân', N'Khu vực cân'),
(3, 'PHONG-TRON-KHO', N'Phòng trộn khô', N'Khu vực trộn'),
(4, 'PHONG-DONG-GOI', N'Phòng đóng gói', N'Khu vực đóng gói');
SET IDENTITY_INSERT ProductionAreas OFF;
GO

-- =====================================================================
-- 4. UomConversions
-- =====================================================================
SET IDENTITY_INSERT UomConversions ON;
INSERT INTO UomConversions (ConversionId, FromUomId, ToUomId, ConversionFactor, Note) VALUES
(1, 1, 2,  1000.0, N'1 kg = 1000 g'),
(2, 2, 1,  0.001,  N'1 g = 0.001 kg'),
(3, 6, 5,  10.0,   N'1 hộp = 10 vỉ'),
(4, 7, 6,  12.0,   N'1 thùng = 12 hộp'),
(5, 5, 4,  10.0,   N'1 vỉ = 10 viên');
SET IDENTITY_INSERT UomConversions OFF;
GO

-- =====================================================================
-- 5. Equipments
-- =====================================================================
SET IDENTITY_INSERT Equipments ON;
INSERT INTO Equipments (EquipmentId, EquipmentCode, EquipmentName, TechnicalSpecification, UsagePurpose, AreaId) VALUES
(1,  'IW2-60',        N'Cân điện tử',            N'60 kg; 5 g',           N'Cân nguyên liệu và tá dược', 2),
(2,  'PMA-5000',      N'Cân điện tử',            N'5 kg; 0,1 g',          N'Cân tá dược',                 2),
(3,  'TE-212',        N'Cân điện tử',            N'210 g; 0,01 g',        N'Kiểm tra khối lượng viên',    2),
(4,  'AD-LP-200',     N'Máy trộn lập phương',    N'200 kg/ mẻ',           N'Trộn đồng nhất',              3),
(5,  'NJP-1200 D',    N'Máy đóng nang tự động',  N'72.000 viên/ giờ',     N'Cấp thuốc vào nang',          1),
(6,  'IPJ',           N'Máy lau nang',           N'100.000 viên/ giờ',    N'Làm sạch viên thuốc',         1),
(7,  'KW-102',        N'Máy đóng chai',          N'500 chai/ giờ',        N'Đếm viên thuốc vào chai',     1),
(8,  'CNTB-TSC',      N'Tủ sấy chai',            N'1,5 m³',               N'Sấy khô chai',                1),
(9,  'VIDEOJET-1220', N'Máy in số lô',           N'250 nhãn/ giờ',        N'In số lô, ngày SX, hạn dùng', 1),
(10, 'ABL-M',         N'Máy dán nhãn tự động',   N'1.500 nhãn/ giờ',      N'Dán nhãn vào thân chai',      1),
(11, 'F-262',         N'Máy gấp toa',            N'10.000 toa/ giờ',      N'Bế tờ HDSD',                  1),
(12, 'KBC-TS-50',     N'Máy sấy tầng sôi',       N'50 kg/ mẻ',            N'Sấy khô dược liệu',           1);

SET IDENTITY_INSERT Equipments OFF;
GO

-- =====================================================================
-- 6. Materials
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification, CreatedAt) VALUES
(1,  'NLC-3',   N'Cao khô Trinh nữ',                   'RawMaterial',  1, 1, N'TCCS', GETDATE()),
(2,  'TD-1',    N'Aerosil',                            'RawMaterial',  2, 1, N'USP 30', GETDATE()),
(3,  'TD-3',    N'Sodium starch glycolate',            'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(4,  'TD-4',    N'Talc',                               'RawMaterial',  2, 1, N'DĐVN V', GETDATE()),
(5,  'TD-5',    N'Magie Stearat',                      'RawMaterial',  2, 1, N'DĐVN V', GETDATE()),
(6,  'TD-8',    N'Tinh bột ngô (Filler)',              'RawMaterial',  1, 1, N'DĐVN V', GETDATE()),
(7,  'NLP-6',   N'Vỏ nang cứng',                       'RawMaterial', 4, 1, N'DĐVN V', GETDATE()),
(8,  'PVP',     N'PVP K30',                            'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(9,  'PARA',    N'Bột Paracetamol tinh khiết',         'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(10, 'LAC',     N'Lactose kết dính',                   'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(11, 'WATER',   N'Nước cất pha tiêm',                  'RawMaterial',  3, 1, N'DĐVN V', GETDATE()),
(12, 'AMP',     N'Ống thủy tinh 2ml',                  'Packaging',    8, 1, N'USP 30', GETDATE()),
(13, 'ALU',     N'Màng nhôm ép vỉ',                    'Packaging',    1, 1, N'DĐVN V', GETDATE()),
(14, 'PVC',     N'Màng PVC trong suốt',                'Packaging',    1, 1, N'DĐVN V', GETDATE()),
(15, 'TP-CRILA',N'Viên nang Crila',                    'FinishedGood', 4, 1, N'DĐVN V', GETDATE()),
(16, 'TP-PARA', N'Viên nén Paracetamol 500mg',         'FinishedGood', 4, 1, N'DĐVN V', GETDATE()),
(17, 'TP-DIPY', N'Thuốc ống Dipyridamole 10mg/2ml',    'FinishedGood', 4, 1, N'DĐVN V', GETDATE());
SET IDENTITY_INSERT Materials OFF;
GO

-- =====================================================================
-- 7. Recipes
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, EffectiveDate, Note) VALUES
(1, 15, 1, 54000.00,  'Approved', 2, DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-45,GETDATE()), DATEADD(DAY,-25,GETDATE()), N'NLC 3 mẻ 100k viên.'),
(2, 16, 2, 500000.00, 'Approved', 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-35,GETDATE()), DATEADD(DAY,-15,GETDATE()), N'Paracetamol 500mg.'),
(3, 15, 2, 100000.00, 'Draft',    NULL, NULL,                    DATEADD(DAY,-5, GETDATE()), NULL,                      N'Cải tiến tá dược.'),
(4, 17, 1, 10000.00,  'Approved', 2, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-5, GETDATE()), N'Dipyridamole tiêm.'),
(5, 16, 3, 200000.00, 'Approved', 2, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,1, GETDATE()),  N'Paracetamol tầng sôi.');
SET IDENTITY_INSERT Recipes OFF;
GO

-- =====================================================================
-- 8. RecipeBOM
-- =====================================================================
SET IDENTITY_INSERT RecipeBOM ON;
INSERT INTO RecipeBOM (BomId, RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note) VALUES
(1,  1, 1,  25000.00, 2, 0.20, N'NLC 3'),
(2,  1, 2,   162.00,  2, 0.10, N'Aerosil'),
(3,  1, 3,  2970.00,  2, 0.20, N'SSG'),
(4,  1, 4,   405.00,  2, 0.10, N'Talc'),
(5,  1, 5,   405.00,  2, 0.10, N'Magnesi stearat'),
(6,  1, 6,  25058.00, 2, 0.50, N'Tinh bột'),
(7,  1, 7,  100000.00, 4, 0.10, N'Vỏ nang'),
(8,  2, 9,  250000.00, 2, 0.30, N'Paracetamol'),
(9,  2, 6,  150000.00, 2, 1.00, N'Tinh bột ngô'),
(10, 2, 10, 80000.00, 2, 0.50, N'Lactose'),
(11, 2, 5,   5000.00, 2, 0.10, N'Magie stearat'),
(12, 2, 8,  10000.00, 2, 0.20, N'PVP K30');
SET IDENTITY_INSERT RecipeBOM OFF;
GO

-- =====================================================================
-- 9. RecipeRouting
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, OrderId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description, NumberOfRouting) VALUES
-- Recipe 1: Viên nang NLC 3 (Existing)
(1, 1, NULL, 1, N'Sấy Tá Dược 8 (TD 8)',              2, 180, N'Sấy tinh bột TD 8 tại 75°C, 180p. Độ ẩm < 5%.', 1),
(2, 1, NULL, 2, N'Sấy Cao Khô NLC 3',                2, 180, N'Sấy cao khô Trinh nữ tại 75°C, 180p. Độ ẩm < 3%.', 1),
(3, 1, NULL, 3, N'Cân Nguyên Liệu',                  1, 90,  N'Cân chính xác 6 loại theo BOM động (Section 4 BMR). Đối chiếu nhãn phụ.', 1),
(4, 1, NULL, 4, N'Trộn Khô',                         3, 15,  N'Trộn premix bột tá dược trước. Trộn chính 15 phút, 15 vòng/phút.', 1),
(7, 1, NULL, 5, N'Đóng Nang',                        7, 120, N'Đóng nang số 0, khối lượng đích 540mg/viên.', 1),
-- Recipe 2: Paracetamol (Existing)
(5, 2, NULL, 1, N'Cân Paracetamol',   1, 90,  NULL, 1),
(6, 2, NULL, 2, N'Dập Viên',          4, 180, NULL, 1),
-- Recipe 4: Thuốc ống Dipyridamole (New)
(10, 4, NULL, 1, N'Pha chế dung dịch', 8, 60, N'Trộn hoạt chất Dipyridamole vào nước cất vô trùng.', 1),
(11, 4, NULL, 2, N'Lọc vô trùng',      NULL, 45, N'Lọc qua màng lọc 0.22 micron.', 1),
(12, 4, NULL, 3, N'Đóng ống - Hàn ống', NULL, 120, N'Đóng 2ml/ống, hàn kín bằng ngọn lửa.', 1),
(13, 4, NULL, 4, N'Tiệt trùng',        NULL, 90, N'Tiệt trùng bằng hơi nước (Autoclave) 121°C.', 1),
(14, 4, NULL, 5, N'Soi kiểm tra',      NULL, 180, N'Kiểm tra độ trong và các vật thể lạ bằng mắt.', 1),
-- Recipe 5: Viên nén Paracetamol (New - Với bước Sấy hạt có thể lặp)
(15, 5, NULL, 1, N'Cân nguyên liệu',   1, 90,  N'Cân Paracetamol và tá dược.', 1),
(16, 5, NULL, 2, N'Trộn khô',          3, 15,  N'Trộn đều bột Paracetamol và tá dược độn.', 1),
(17, 5, NULL, 3, N'Tạo hạt ướt',       NULL, 60, N'Thêm dung dịch PVP K30 tạo khối ẩm.', 1),
(18, 5, NULL, 4, N'Sấy hạt tầng sôi',  2, 120, N'Sấy hạt đến khi độ ẩm đạt < 5%. CÓ THỂ LẶP LẠI NẾU CẦN.', 2),
(19, 5, NULL, 5, N'Sửa hạt',           NULL, 60, N'Rây hạt qua lưới rây chuẩn.', 1),
(20, 5, NULL, 6, N'Dập viên',          4, 180, N'Dập viên nén 500mg.', 1);
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- =====================================================================
-- 10. StepParameters
-- =====================================================================
SET IDENTITY_INSERT StepParameters ON;
INSERT INTO StepParameters (ParameterId, RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical, Note) VALUES
(1, 1, N'Nhiệt độ phòng', '°C', 21, 25, 1, NULL),
(2, 1, N'Độ ẩm phòng',   '%',  45, 70, 1, NULL),
(4, 1, N'Nhiệt độ sấy',  '°C', 73, 77, 1, NULL),
(20, 1, N'Thời gian sấy', 'phút', 170, 190, 1, NULL),
(24, 2, N'Nhiệt độ sấy',  '°C', 73, 77, 1, NULL),
(7, 4, N'Tốc độ trộn',   'v/p', 14, 16, 1, NULL),
(50, 18, N'Nhiệt độ sấy', '°C', 60, 70, 1, NULL);
SET IDENTITY_INSERT StepParameters OFF;
GO

-- =====================================================================
-- 11. ProductionOrders
/*
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, ActualQuantity, StartDate, EndDate, Status, CreatedBy, CreatedAt, Note) VALUES
(1,  'PO-26-001', 1, 100000.00, 100050.00, DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-2,GETDATE()), 'Completed',  4, GETDATE(), N'Lệnh xong.'),
(2,  'PO-26-002', 1, 300000.00, NULL,      DATEADD(DAY,-1,GETDATE()), DATEADD(DAY,3, GETDATE()), 'InProcess', 4, GETDATE(), N'Đang chạy.'),
(4,  'PO-26-004', 2, 200000.00, NULL,      DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,2, GETDATE()), 'InProcess', 4, GETDATE(), N'Para lô 1.'),
(7,  'PO-26-007', 2, 200000.00, 197800.00, DATEADD(DAY,-10,GETDATE()),DATEADD(DAY,-7,GETDATE()), 'Completed',  4, GETDATE(), N'Lô cũ.');
SET IDENTITY_INSERT ProductionOrders OFF;
*/
GO

-- =====================================================================
-- 12. ProductionBatches
/*
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep, CreatedAt) VALUES
(1, 1, 'B26-001-01', 'Completed', DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-2,GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, GETDATE()),
(2, 2, 'B26-002-01', 'InProcess', DATEADD(HOUR,-24,GETDATE()),DATEADD(HOUR,-12,GETDATE()),DATEADD(YEAR,2,GETDATE()), 5, GETDATE()),
(4, 2, 'B26-002-02', 'Hold', GETDATE(), NULL, NULL, 2, GETDATE());
SET IDENTITY_INSERT ProductionBatches OFF;
*/
GO

-- =====================================================================
-- 13. InventoryLotsHold
-- =====================================================================
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierName, CreatedAt) VALUES
(1, 1, 'L-NLC3-01', 2.00, DATEADD(DAY,-60,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Dược liệu TW', GETDATE()),
(2, 2, 'L-AEROSIL-01', 5.00, DATEADD(DAY,-55,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp A', GETDATE()),
(3, 3, 'L-SSG-01', 3.00, DATEADD(DAY,-50,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp B', GETDATE()),
(4, 4, 'L-TALC-01', 5.00, DATEADD(DAY,-45,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp C', GETDATE()),
(5, 5, 'L-MAGIE-01', 3.00, DATEADD(DAY,-40,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp D', GETDATE()),
(6, 6, 'L-STR-01', 2.00, DATEADD(DAY,-45,GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Released', N'Đồng Nai', GETDATE()),
(7, 7, 'L-NANG-01', 50.00, DATEADD(DAY,-35,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp E', GETDATE()),
(8, 8, 'L-PVP-01', 10.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp F', GETDATE()),
(9, 9, 'L-PARA-01', 3.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Released', N'Ấn Độ', GETDATE()),
(10, 10, 'L-LAC-01', 15.00, DATEADD(DAY,-25,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp G', GETDATE()),
(11, 13, 'L-ALU-01', 20.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp H', GETDATE()),
(12, 14, 'L-PVC-01', 20.00, DATEADD(DAY,-15,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp I', GETDATE()),
(15, 11, 'L-WATER-01', 100.00, DATEADD(DAY,-5,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp J', GETDATE()),
(16, 12, 'L-AMP-01', 50.00, DATEADD(DAY,-2,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp K', GETDATE()),
(17, 13, 'L-ALU-02', 12.00, DATEADD(DAY,-1,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp H2', GETDATE()),
(18, 14, 'L-PVC-02', 14.00, DATEADD(DAY,-1,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Nhà cung cấp I2', GETDATE());
SET IDENTITY_INSERT InventoryLots OFF;
GO

-- =====================================================================
-- 14. MaterialUsage
/*
SET IDENTITY_INSERT MaterialUsage ON;
INSERT INTO MaterialUsage (UsageId, BatchId, InventoryLotId, ActualAmount, UsedDate, DispensedBy, Note) VALUES
(1, 1, 1, 1.50, DATEADD(DAY,-5,GETDATE()), 3, N'Xuất NLC3'),
(2, 1, 6, 1.00, DATEADD(DAY,-5,GETDATE()), 3, N'Xuất Tinh bột');
SET IDENTITY_INSERT MaterialUsage OFF;
*/
GO

-- =====================================================================
-- 15. BatchProcessLogs
/*
SET IDENTITY_INSERT BatchProcessLogs ON;
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData, Notes, IsDeviation, VerifiedById, VerifiedDate, NumberOfRouting) VALUES
(1, 1, 1, 2, 3, DATEADD(HOUR,-124,GETDATE()), DATEADD(HOUR,-122,GETDATE()), 'Passed', N'{"nhietDo":75}', NULL, 0, 2, GETDATE(), 1),
(2, 1, 2, 2, 3, DATEADD(HOUR,-122,GETDATE()), DATEADD(HOUR,-120,GETDATE()), 'Passed', N'{"nhietDo":75}', NULL, 0, 2, GETDATE(), 1);
SET IDENTITY_INSERT BatchProcessLogs OFF;
*/
GO

-- =====================================================================
-- 16. KHÔI PHỤC RÀNG BUỘC VÀ TRIGGER
-- =====================================================================
PRINT 'Enabling Constraints and Triggers...';
EXEC sp_msforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';
EXEC sp_msforeachtable 'ALTER TABLE ? ENABLE TRIGGER ALL';
GO

-- =====================================================================
-- 17. BỔ SUNG TRIGGER AUDIT (NẾU CHƯA CÓ)
-- =====================================================================
IF OBJECT_ID('dbo.trg_Audit_InventoryLots', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_InventoryLots ON dbo.InventoryLots AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''InventoryLots'', CAST(COALESCE(i.LotId,d.LotId) AS NVARCHAR(50)),
CASE WHEN i.LotId IS NOT NULL AND d.LotId IS NULL THEN ''Create''
     WHEN i.LotId IS NOT NULL AND d.LotId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.LotId IS NULL THEN NULL ELSE CONCAT(''Lot='', d.LotNumber, '';Qty='', d.QuantityCurrent) END,
CASE WHEN i.LotId IS NULL THEN NULL ELSE CONCAT(''Lot='', i.LotNumber, '';Qty='', i.QuantityCurrent) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.LotId = d.LotId; END');

IF OBJECT_ID('dbo.trg_Audit_Equipments', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_Equipments ON dbo.Equipments AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''Equipments'', CAST(COALESCE(i.EquipmentId,d.EquipmentId) AS NVARCHAR(50)),
CASE WHEN i.EquipmentId IS NOT NULL AND d.EquipmentId IS NULL THEN ''Create''
     WHEN i.EquipmentId IS NOT NULL AND d.EquipmentId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.EquipmentId IS NULL THEN NULL ELSE CONCAT(''Code='', d.EquipmentCode) END,
CASE WHEN i.EquipmentId IS NULL THEN NULL ELSE CONCAT(''Code='', i.EquipmentCode) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.EquipmentId = d.EquipmentId; END');
GO

PRINT 'GMP Database Initialization & Full Seeding Completed Successfully!';

