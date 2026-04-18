/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   FULL SEED DATA v3.0 - Đã đồng bộ hoàn toàn với Schema.sql
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
IF OBJECT_ID('ProductionAreas', 'U') IS NOT NULL DELETE FROM ProductionAreas;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DELETE FROM UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DELETE FROM UnitOfMeasure;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DELETE FROM AppUsers;
GO
PRINT 'Delete Data Completed Successfully!';
-- RESET IDENTITY
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
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DBCC CHECKIDENT ('QualityTests', RESEED, 0);
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionOrders', RESEED, 0);
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DBCC CHECKIDENT ('ProductionBatches', RESEED, 0);
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DBCC CHECKIDENT ('InventoryLots', RESEED, 0);
GO
PRINT 'Reset Identity Completed Successfully!';
-- =====================================================================
-- 1. AppUsers (6 users: Admin, 2 QC, 2 Operator, 1 Manager)
-- Passwords: Admin@123 | Qc@123456 | Op@123456 | Mgr@123456
-- =====================================================================
SET IDENTITY_INSERT AppUsers ON;
INSERT INTO AppUsers (UserId, Username, FullName, Role, IsActive, PasswordHash, CreatedAt, LastLogin)
VALUES
(1, 'admin',   N'Admin Hệ Thống',           'Admin',             1, '$2b$11$hyVSDA5K2Qg1FVUosjSk4e76FBcJhE7DbNG/KDELUBotFzcSt5xIW', DATEADD(DAY,-90,GETDATE()), NULL),
(2, 'qc01',    N'Trần Thị Kiểm Tra',        'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-60,GETDATE()), NULL),
(3, 'op01',    N'Nguyễn Văn Công Nhân',     'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-60,GETDATE()), NULL),
(4, 'mgr01',   N'Lê Quang Quản Lý',         'ProductionManager', 1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-90,GETDATE()), NULL),
(5, 'qc02',    N'Phạm Thị Chất Lượng',      'QA_QC',             1, '$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK', DATEADD(DAY,-30,GETDATE()), NULL),
(6, 'op02',    N'Hoàng Văn Thao Tác',       'Operator',          1, '$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW', DATEADD(DAY,-30,GETDATE()), NULL);
SET IDENTITY_INSERT AppUsers OFF;
GO
PRINT 'Insert AppUsers Completed Successfully!';
-- =====================================================================
-- 2. UnitOfMeasure (7 đơn vị)
-- =====================================================================
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description) VALUES
(1, 'kg',      N'Kilogram'),
(2, 'g',       N'Gram'),
(3, 'L',       N'Lít'),
(4, 'Viên',    N'Viên'),
(5, 'Vỉ',      N'Vỉ (10 viên/vỉ)'),
(6, 'Hộp',     N'Hộp (10 vỉ/hộp)'),
(7, 'Thùng',   N'Thùng (12 hộp/thùng)');
SET IDENTITY_INSERT UnitOfMeasure OFF;
GO
PRINT 'Insert UnitOfMeasure Completed Successfully!';
-- =====================================================================
-- 3. ProductionAreas
-- =====================================================================
SET IDENTITY_INSERT ProductionAreas ON;
INSERT INTO ProductionAreas (AreaId, AreaCode, AreaName, Description)
VALUES 
(1, 'PHA-CHE', N'Phòng pha chế', N'Khu vực pha chế'),
(2, 'PHONG-CAN', N'Phòng cân', N'Khu vực cân'),
(3, 'TRON-KHO', N'Phòng trộn khô', N'Khu vực trộn');
SET IDENTITY_INSERT ProductionAreas OFF;
GO
PRINT 'Insert ProductionAreas Completed Successfully!';
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
PRINT 'Insert UomConversions Completed Successfully!';
-- =====================================================================
-- 5. Equipments (8 thiết bị)
-- =====================================================================
SET IDENTITY_INSERT Equipments ON;
INSERT INTO Equipments (EquipmentId, EquipmentCode, EquipmentName, TechnicalSpecification, UsagePurpose, AreaId, Status) VALUES
(1,  'IW2-60',        N'Cân điện tử',            N'60 kg; 5 g',           N'Cân nguyên liệu và tá dược', 2, 'Ready'),
(2,  'PMA-5000',      N'Cân điện tử',            N'5 kg; 0,1 g',          N'Cân tá dược',                 2, 'Ready'),
(3,  'TE-212',        N'Cân điện tử',            N'210 g; 0,01 g',        N'Kiểm tra khối lượng viên',    2, 'Ready'),
(4,  'AD-LP-200',     N'Máy trộn lập phương',    N'200 kg/ mẻ',           N'Trộn đồng nhất',              3, 'Ready'),
(5,  'NJP-1200 D',    N'Máy đóng nang tự động',  N'72.000 viên/ giờ',     N'Cấp thuốc vào nang',          1, 'Ready'),
(6,  'IPJ',           N'Máy lau nang',           N'100.000 viên/ giờ',    N'Làm sạch viên thuốc',         1, 'Ready'),
(7,  'KW-102',        N'Máy đóng chai',          N'500 chai/ giờ',        N'Đếm viên thuốc vào chai',     1, 'Ready'),
(8,  'CNTB-TSC',      N'Tủ sấy chai',            N'1,5 m³',               N'Sấy khô chai',                1, 'Ready'),
(9,  'VIDEOJET-1220', N'Máy in số lô',           N'250 nhãn/ giờ',        N'In số lô, ngày SX, hạn dùng', 1, 'Ready'),
(10, 'ABL-M',         N'Máy dán nhãn tự động',   N'1.500 nhãn/ giờ',      N'Dán nhãn vào thân chai',      1, 'Ready'),
(11, 'F-262',         N'Máy gấp toa',            N'10.000 toa/ giờ',      N'Bế tờ HDSD',                  1, 'Ready');
SET IDENTITY_INSERT Equipments OFF;
GO
PRINT 'Insert Equipments Completed Successfully!';
-- =====================================================================
-- 6. Materials (11 loại vật tư)
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification, CreatedAt) VALUES
(1,  'MAT-NLC-3',   N'Cao khô Trinh nữ',                   'RawMaterial',  1, 1, N'TCCS', GETDATE()),
(2,  'MAT-TD-1',    N'Aerosil',                            'RawMaterial',  2, 1, N'USP 30', GETDATE()),
(3,  'MAT-TD-3',    N'Sodium starch glycolate',            'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(4,  'MAT-TD-4',    N'Talc',                               'RawMaterial',  2, 1, N'DĐVN V', GETDATE()),
(5,  'MAT-TD-5',    N'Magie Stearat',                      'RawMaterial',  2, 1, N'DĐVN V', GETDATE()),
(6,  'MAT-TD-8',    N'Tinh bột ngô (Filler)',              'RawMaterial',  1, 1, N'DĐVN V', GETDATE()),
(7,  'MAT-NLP-6',   N'Vỏ nang cứng',                       'FinishedGood', 4, 1, N'DĐVN V', GETDATE()),
(8,  'MAT-PVP',     N'PVP K30',                            'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(9,  'MAT-PARA',    N'Bột Paracetamol tinh khiết',         'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(10, 'MAT-LAC',     N'Lactose kết dính',                   'RawMaterial',  1, 1, N'USP 30', GETDATE()),
(11, 'MAT-ALU',     N'Màng nhôm ép vỉ',                    'Packaging',    1, 1, N'DĐVN V', GETDATE()),
(12, 'MAT-PVC',     N'Màng PVC trong suốt',                'Packaging',    1, 1, N'DĐVN V', GETDATE()),
(13, 'FG-NLC3-CAP', N'Viên nang NLC 3 (540mg)',            'FinishedGood', 4, 1, N'DĐVN V', GETDATE()),
(14, 'FG-PARA-TAB', N'Viên nén Paracetamol 500mg',         'FinishedGood', 4, 1, N'DĐVN V', GETDATE()),
(15, 'MAT-WATER',   N'Nước cất pha tiêm',                  'RawMaterial',  3, 1, N'DĐVN V', GETDATE()),
(16, 'MAT-AMP',     N'Ống thủy tinh 2ml',                  'Packaging',    4, 1, N'USP 30', GETDATE()),
(17, 'FG-DIPY-AMP', N'Thuốc ống Dipyridamole 10mg/2ml',    'FinishedGood', 4, 1, N'DĐVN V', GETDATE());
SET IDENTITY_INSERT Materials OFF;
GO
PRINT 'Insert Materials Completed Successfully!';
-- =====================================================================
-- 7. Recipes (3 công thức)
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, EffectiveDate, Note) VALUES
(1, 13, 1, 54000.00,  'Approved', 2, DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-45,GETDATE()), DATEADD(DAY,-25,GETDATE()), N'NLC 3 mẻ 100k viên.'),
(2, 14, 2, 500000.00, 'Approved', 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-35,GETDATE()), DATEADD(DAY,-15,GETDATE()), N'Paracetamol 500mg.'),
(3, 13, 2, 100000.00, 'Draft',    NULL, NULL,                    DATEADD(DAY,-5, GETDATE()), NULL,                      N'Cải tiến tá dược.'),
(4, 17, 1, 10000.00,  'Approved', 2, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-5, GETDATE()), N'Dipyridamole tiêm.'),
(5, 14, 3, 200000.00, 'Approved', 2, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,1, GETDATE()),  N'Paracetamol tầng sôi.');
SET IDENTITY_INSERT Recipes OFF;
GO
PRINT 'Insert Recipes Completed Successfully!';
-- =====================================================================
-- 8. RecipeBOM (Định mức vật tư - BOM)
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
PRINT 'Insert RecipeBOM Completed Successfully!';
-- =====================================================================
-- 9. RecipeRouting (Quy trình công đoạn)
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description, NumberOfRouting) VALUES
-- Recipe 1: Viên nang NLC 3 (Existing)
(1, 1, 1, N'Sấy Tá Dược 8 (TD 8)',              2, 180, N'Sấy tinh bột TD 8 tại 75°C, 180p. Độ ẩm < 5%.', 1),
(2, 1, 2, N'Sấy Cao Khô NLC 3',                2, 180, N'Sấy cao khô Trinh nữ tại 75°C, 180p. Độ ẩm < 3%.', 1),
(3, 1, 3, N'Cân Nguyên Liệu',                  1, 90,  N'Cân chính xác 6 loại theo BOM động (Section 4 BMR). Đối chiếu nhãn phụ.', 1),
(4, 1, 4, N'Trộn Khô',                         3, 15,  N'Trộn premix bột tá dược trước. Trộn chính 15 phút, 15 vòng/phút.', 1),
(7, 1, 5, N'Đóng Nang',                        7, 120, N'Đóng nang số 0, khối lượng đích 540mg/viên.', 1),
-- Recipe 2: Paracetamol (Existing)
(5, 2, 1, N'Cân Paracetamol',   1, 90,  NULL, 1),
(6, 2, 2, N'Dập Viên',          4, 180, NULL, 1),
-- Recipe 4: Thuốc ống Dipyridamole (New)
(10, 4, 1, N'Pha chế dung dịch', 8, 60, N'Trộn hoạt chất Dipyridamole vào nước cất vô trùng.', 1),
(11, 4, 2, N'Lọc vô trùng',      NULL, 45, N'Lọc qua màng lọc 0.22 micron.', 1),
(12, 4, 3, N'Đóng ống - Hàn ống', NULL, 120, N'Đóng 2ml/ống, hàn kín bằng ngọn lửa.', 1),
(13, 4, 4, N'Tiệt trùng',        NULL, 90, N'Tiệt trùng bằng hơi nước (Autoclave) 121°C.', 1),
(14, 4, 5, N'Soi kiểm tra',      NULL, 180, N'Kiểm tra độ trong và các vật thể lạ bằng mắt.', 1),
-- Recipe 5: Viên nén Paracetamol (New - Với bước Sấy hạt có thể lặp)
(15, 5, 1, N'Cân nguyên liệu',   1, 90,  N'Cân Paracetamol và tá dược.', 1),
(16, 5, 2, N'Trộn khô',          3, 15,  N'Trộn đều bột Paracetamol và tá dược độn.', 1),
(17, 5, 3, N'Tạo hạt ướt',       NULL, 60, N'Thêm dung dịch PVP K30 tạo khối ẩm.', 1),
(18, 5, 4, N'Sấy hạt tầng sôi',  2, 120, N'Sấy hạt đến khi độ ẩm đạt < 5%. CÓ THỂ LẶP LẠI NẾU CẦN.', 2),
(19, 5, 5, N'Sửa hạt',           NULL, 60, N'Rây hạt qua lưới rây chuẩn.', 1),
(20, 5, 6, N'Dập viên',          4, 180, N'Dập viên nén 500mg.', 1);
SET IDENTITY_INSERT RecipeRouting OFF;
GO
PRINT 'Insert RecipeRouting Completed Successfully!';
-- =====================================================================
-- 10. StepParameters (Dữ liệu chốt GMP - Cấu trúc bảng và Seeding)
-- Bảng này thường thiếu trong seed cũ, cần nạp để Mobile check Deviation.
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
PRINT 'Insert StepParameters Completed Successfully!';
-- =====================================================================
-- 11. ProductionOrders (Đa dạng 10 kịch bản lệnh sản xuất)
-- =====================================================================
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, ActualQuantity, StartDate, EndDate, Status, CreatedBy, CreatedAt, Note) VALUES
(1,  'PO-26-001', 1, 100000.00, 100050.00, DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-12,GETDATE()), 'Completed',  4, DATEADD(DAY,-16,GETDATE()), N'Sản xuất viên nang NLC 3 (Hoàn thành)'),
(2,  'PO-26-002', 1, 300000.00, 298500.00, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-6, GETDATE()), 'Completed',  4, DATEADD(DAY,-11,GETDATE()), N'Sản xuất lô lớn NLC 3'),
(3,  'PO-26-003', 1, 150000.00, NULL,      DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,2, GETDATE()),  'InProcess',  4, DATEADD(DAY,-2,GETDATE()),  N'Sản xuất NLC 3 (Đang chạy mẻ 1)'),
(4,  'PO-26-004', 2, 200000.00, 199000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-18,GETDATE()), 'Completed',  4, DATEADD(DAY,-21,GETDATE()), N'Para 500mg (Hoàn thành)'),
(5,  'PO-26-005', 2, 500000.00, NULL,      DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,5, GETDATE()),  'InProcess',  4, DATEADD(DAY,-3,GETDATE()),  N'Para 500mg, chạy 5 mẻ.'),
(6,  'PO-26-006', 4, 20000.00,  19800.00,  DATEADD(DAY,-8,GETDATE()),  DATEADD(DAY,-7, GETDATE()), 'Completed',  4, DATEADD(DAY,-9,GETDATE()),  N'Dipyridamole tiêm lô 1'),
(7,  'PO-26-007', 4, 30000.00,  NULL,      DATEADD(DAY,1, GETDATE()),  DATEADD(DAY,4, GETDATE()),  'Approved',   4, GETDATE(),                  N'Dipyridamole chuẩn bị chạy'),
(8,  'PO-26-008', 5, 200000.00, NULL,      DATEADD(DAY,2, GETDATE()),  DATEADD(DAY,6, GETDATE()),  'Draft',      4, GETDATE(),                  N'Lệnh thử nghiệm Para tầng sôi mới'),
(9,  'PO-26-009', 2, 100000.00, NULL,      DATEADD(DAY,-5,GETDATE()),  NULL,                       'Hold',       4, DATEADD(DAY,-6,GETDATE()),  N'Tạm dừng do thiếu nguyên liệu'),
(10, 'PO-26-010', 1, 50000.00,  NULL,      DATEADD(DAY,-1,GETDATE()),  NULL,                       'Cancelled',  4, DATEADD(DAY,-2,GETDATE()),  N'Hủy lệnh do thay đổi kế hoạch');
SET IDENTITY_INSERT ProductionOrders OFF;
GO
PRINT 'Insert ProductionOrders Completed Successfully!';

-- =====================================================================
-- 12. ProductionBatches (Các mẻ thuộc các lệnh đa dạng)
-- =====================================================================
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep, CreatedAt) VALUES
-- Lệnh 1 (Completed)
(1, 1, 'B26-001-01', 'Completed', DATEADD(DAY,-15,GETDATE()), DATEADD(DAY,-12,GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, DATEADD(DAY,-15,GETDATE())),
-- Lệnh 2 (Completed) -> 3 mẻ (mẻ 2, 3, 4)
(2, 2, 'B26-002-01', 'Completed', DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-9, GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, DATEADD(DAY,-10,GETDATE())),
(3, 2, 'B26-002-02', 'Completed', DATEADD(DAY,-9, GETDATE()), DATEADD(DAY,-8, GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, DATEADD(DAY,-9,GETDATE())),
(4, 2, 'B26-002-03', 'Completed', DATEADD(DAY,-8, GETDATE()), DATEADD(DAY,-6, GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, DATEADD(DAY,-8,GETDATE())),
-- Lệnh 3 (InProcess) -> 2 mẻ, mẻ đang tiến hành
(5, 3, 'B26-003-01', 'InProcess', DATEADD(DAY,-1,GETDATE()),  NULL,                       DATEADD(YEAR,2,GETDATE()), 2, DATEADD(DAY,-1,GETDATE())),
(6, 3, 'B26-003-02', 'Scheduled', NULL,                       NULL,                       NULL,                      1, DATEADD(DAY,-1,GETDATE())),
-- Lệnh 4 (Completed)
(7, 4, 'B26-004-01', 'Completed', DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-18,GETDATE()), DATEADD(YEAR,2,GETDATE()), 2, DATEADD(DAY,-20,GETDATE())),
-- Lệnh 5 (InProcess) -> Mẻ 500k
(8, 5, 'B26-005-01', 'Completed', DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  DATEADD(YEAR,2,GETDATE()), 2, DATEADD(DAY,-2,GETDATE())),
(9, 5, 'B26-005-02', 'InProcess', GETDATE(),                  NULL,                       DATEADD(YEAR,2,GETDATE()), 1, GETDATE()),
-- Lệnh 6 (Tiêm Completed)
(10,6, 'B26-006-01', 'Completed', DATEADD(DAY,-8, GETDATE()), DATEADD(DAY,-7, GETDATE()), DATEADD(YEAR,2,GETDATE()), 5, DATEADD(DAY,-8,GETDATE())),
-- Các lệnh còn lại
(11, 7, 'B26-007-01', 'Scheduled', NULL, NULL, NULL, 1, GETDATE()),
(12, 8, 'B26-008-01', 'Scheduled', NULL, NULL, NULL, 1, GETDATE()),
(13, 9, 'B26-009-01', 'OnHold', DATEADD(DAY,-5,GETDATE()), NULL, DATEADD(YEAR,2,GETDATE()), 3, GETDATE()),
(14, 10, 'B26-010-01', 'Cancelled', DATEADD(DAY,-1,GETDATE()), NULL, NULL, 1, GETDATE());
SET IDENTITY_INSERT ProductionBatches OFF;
PRINT 'Insert ProductionBatches Completed Successfully!';

-- =====================================================================
-- 13. InventoryLots (Đa dạng kho nguyên liệu)
-- =====================================================================
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierName, CreatedAt) VALUES
(1, 1, 'L-NLC3-01', 85000.00, DATEADD(DAY,-60,GETDATE()), DATEADD(YEAR,3,GETDATE()), 'Released', N'Dược liệu TW', GETDATE()),
(2, 2, 'L-AERO-01', 5000.00,  DATEADD(DAY,-50,GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Released', N'Hóa chất Đức', GETDATE()),
(3, 9, 'L-PARA-01', 250000.00,DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Released', N'Ấn Độ', GETDATE()),
(4, 9, 'L-PARA-02', 500000.00,DATEADD(DAY,-5, GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Pending',  N'Ấn Độ', GETDATE()),
(5, 6, 'L-STR-01',  80000.00, DATEADD(DAY,-45,GETDATE()), DATEADD(YEAR,2,GETDATE()), 'Released', N'Đồng Nai', GETDATE()),
(6, 17,'L-DIPY-01', 15000.00, DATEADD(DAY,-40,GETDATE()), DATEADD(YEAR,1,GETDATE()), 'Released', N'Hàn Quốc', GETDATE()),
(7, 15,'L-WATER-1', 2000.00,  DATEADD(DAY,-10,GETDATE()), DATEADD(MONTH,6,GETDATE()),'Released', N'Nội bộ', GETDATE()),
(8, 16,'L-AMP-01',  50000.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,5,GETDATE()), 'Released', N'Thủy tinh ĐN', GETDATE());
SET IDENTITY_INSERT InventoryLots OFF;
PRINT 'Insert InventoryLots Completed Successfully!';

-- =====================================================================
-- 14. MaterialUsage (Xuất kho cho các mẻ)
-- =====================================================================
SET IDENTITY_INSERT MaterialUsage ON;
INSERT INTO MaterialUsage (UsageId, BatchId, InventoryLotId, ActualAmount, UsedDate, DispensedBy, Note) VALUES
(1, 1, 1, 25015.00, DATEADD(DAY,-15,GETDATE()), 3, N'Xuất NLC3 lô 1'),
(2, 1, 5, 25100.00, DATEADD(DAY,-15,GETDATE()), 3, N'Xuất Tinh bột lô 1'),
(3, 5, 1, 25000.00, DATEADD(DAY,-1,GETDATE()),  3, N'Xuất NLC3 lô mẻ 1 của lệnh 3'),
(4, 10,6, 5000.00,  DATEADD(DAY,-8, GETDATE()),  3, N'Xuất Dipy lô 1'),
(5, 10,7, 500.00,   DATEADD(DAY,-8, GETDATE()),  3, N'Xuất Nước cất lô 1');
SET IDENTITY_INSERT MaterialUsage OFF;
PRINT 'Insert MaterialUsage Completed Successfully!';
-- (Bảng QualityTests không tồn tại trong schema thực tế của DB này - đã bỏ qua)

-- =====================================================================
-- 15. BatchProcessLogs (Nhật ký eBMR với JSON Parameters đầy đủ)
-- =====================================================================
SET IDENTITY_INSERT BatchProcessLogs ON;
INSERT INTO BatchProcessLogs (LogId, BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData, Notes, IsDeviation, VerifiedById, VerifiedDate, NumberOfRouting) VALUES
(1, 1, 1, 2, 3, DATEADD(HOUR,-360,GETDATE()), DATEADD(HOUR,-357,GETDATE()), 'Passed', N'{"Nhiệt độ phòng":23,"Độ ẩm phòng":50,"Nhiệt độ sấy":75}', NULL, 0, 2, DATEADD(HOUR,-357,GETDATE()), 1),
(2, 1, 2, 2, 3, DATEADD(HOUR,-357,GETDATE()), DATEADD(HOUR,-354,GETDATE()), 'Passed', N'{"Nhiệt độ sấy":75,"Thời gian sấy":180}', NULL, 0, 2, DATEADD(HOUR,-354,GETDATE()), 1),
(3, 1, 3, 1, 3, DATEADD(HOUR,-354,GETDATE()), DATEADD(HOUR,-352,GETDATE()), 'Passed', N'{}', NULL, 0, 2, DATEADD(HOUR,-352,GETDATE()), 1),
(4, 1, 4, 3, 3, DATEADD(HOUR,-352,GETDATE()), DATEADD(HOUR,-351,GETDATE()), 'Passed', N'{"Tốc độ trộn":15}', NULL, 0, 2, DATEADD(HOUR,-351,GETDATE()), 1),
(5, 1, 7, 7, 3, DATEADD(HOUR,-351,GETDATE()), DATEADD(HOUR,-349,GETDATE()), 'Passed', N'{}', N'Đóng nang xuất sắc', 0, 2, DATEADD(HOUR,-349,GETDATE()), 1),
(6, 5, 1, 2, 3, DATEADD(HOUR,-24,GETDATE()),  DATEADD(HOUR,-21,GETDATE()),  'Passed', N'{"Nhiệt độ phòng":24,"Độ ẩm phòng":55,"Nhiệt độ sấy":76}', NULL, 0, 2, DATEADD(HOUR,-21,GETDATE()), 1);
SET IDENTITY_INSERT BatchProcessLogs OFF;
PRINT 'Insert BatchProcessLogs Completed Successfully!';
-- =====================================================================
-- 16. SystemAuditLog (Dấu vết kiểm toán - minh họa)
-- =====================================================================
SET IDENTITY_INSERT SystemAuditLog ON;
INSERT INTO SystemAuditLog (AuditId, TableName, RecordId, Action, OldValue, NewValue, ChangedBy, ChangedDate) VALUES
(1, 'Recipes', '1', 'UPDATE', N'{"Status":"Draft"}', N'{"Status":"Approved"}', 2, DATEADD(DAY,-30,GETDATE()));
SET IDENTITY_INSERT SystemAuditLog OFF;
GO
PRINT 'Insert SystemAuditLog Completed Successfully!';

PRINT 'GMP Database Initialization & Full Seeding Completed Successfully!';
