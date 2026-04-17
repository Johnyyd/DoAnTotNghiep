/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   FULL SEED DATA v2.0 - Phủ kín 15 Bảng, Đa Kịch bản A-Z
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Vô hiệu hóa Trigger để dọn dẹp dữ liệu
IF OBJECT_ID('trg_Lock_Finalized_Logs', 'TR') IS NOT NULL DISABLE TRIGGER trg_Lock_Finalized_Logs ON BatchProcessLogs;
IF OBJECT_ID('trg_Check_Material_QC', 'TR') IS NOT NULL DISABLE TRIGGER trg_Check_Material_QC ON MaterialUsage;
IF OBJECT_ID('trg_Validate_Drying_Limit', 'TR') IS NOT NULL DISABLE TRIGGER trg_Validate_Drying_Limit ON BatchProcessParameterValues;
GO

-- =====================================================================
-- XÓA DỮ LIỆU CŨ (THEO THỨ TỰ NGƯỢC KHÓA NGOẠI)
-- =====================================================================
IF OBJECT_ID('BatchProcessParameterValues', 'U') IS NOT NULL DELETE FROM BatchProcessParameterValues;
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DELETE FROM StepParameters;
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DELETE FROM QualityTests;
IF OBJECT_ID('SystemAuditLog', 'U') IS NOT NULL DELETE FROM SystemAuditLog;
IF OBJECT_ID('MaterialUsage', 'U') IS NOT NULL DELETE FROM MaterialUsage;
IF OBJECT_ID('BatchProcessLogs', 'U') IS NOT NULL DELETE FROM BatchProcessLogs;
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DELETE FROM ProductionBatches;
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DELETE FROM ProductionOrders;
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DELETE FROM InventoryLots;
IF OBJECT_ID('RecipeBOM', 'U') IS NOT NULL DELETE FROM RecipeBOM;
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
IF OBJECT_ID('RecipeBOM', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeBOM', RESEED, 0);
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DBCC CHECKIDENT ('RecipeRouting', RESEED, 0);
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DBCC CHECKIDENT ('StepParameters', RESEED, 0);
IF OBJECT_ID('BatchProcessParameterValues', 'U') IS NOT NULL DBCC CHECKIDENT ('BatchProcessParameterValues', RESEED, 0);
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
-- 2. UnitOfMeasure
-- =====================================================================
SET IDENTITY_INSERT UnitOfMeasure ON;
INSERT INTO UnitOfMeasure (UomId, UomName, Description) VALUES
(1, 'kg',      N'Kilogram'),
(2, 'g',       N'Gram'),
(3, 'L',       N'Lít'),
(4, 'Tablets', N'Viên'),
(5, 'Blister', N'Vỉ (10 viên/vỉ)'),
(6, 'Box',     N'Hộp (10 vỉ/hộp)'),
(7, 'Carton',  N'Thùng (12 hộp/thùng)'),
(8, 'Sachet',  N'Gói (3g/gói)'); 
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
-- 4. Equipments
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
(8, 'EQP-MIX-02', N'Máy trộn IBC 200L (phụ)',             'Running',     DATEADD(DAY,-12,GETDATE())),
(9, 'EQP-PACK-03',N'Máy đóng gói cốm tự động',            'Ready',       DATEADD(DAY,-30,GETDATE()));
SET IDENTITY_INSERT Equipments OFF;
GO

-- =====================================================================
-- 5. Materials
-- =====================================================================
SET IDENTITY_INSERT Materials ON;
INSERT INTO Materials (MaterialId, MaterialCode, MaterialName, Type, BaseUomId, IsActive, Description) VALUES
(1,  'MAT-NLC3',   N'Hoạt chất NLC 3 (Cao khô Trinh nữ)', 'RawMaterial',  1, 1, N'Bảo quản 15-25°C, tránh ánh sáng'),
(2,  'MAT-PARA',   N'Bột Paracetamol tinh khiết',         'RawMaterial',  1, 1, N'USP Grade, bảo quản nơi khô ráo'),
(3,  'MAT-TD8',    N'Tinh bột ngô (Filler)',              'RawMaterial',  1, 1, N'TD 8 - Tá dược độn bù trừ'),
(4,  'MAT-LAC',    N'Lactose kết dính',                   'RawMaterial',  1, 1, N'Tá dược độn kết dính'),
(5,  'MAT-TD5',    N'Magie Stearat',                      'RawMaterial',  2, 1, N'TD 5 - Tá dược trơn'),
(6,  'MAT-NLP6',   N'Vỏ nang cứng (Cỡ 0)',                'RawMaterial',  4, 1, N'NLP 6 - Vỏ nang gelatin'),
(7,  'MAT-PVP',    N'PVP K30',                            'RawMaterial',  1, 1, N'Tá dược tạo hạt ướt'),
(8,  'MAT-ALU',    N'Màng nhôm ép vỉ',                    'PackagingMaterial', 1, 1, N'Màng ép vỉ nhôm'),
(9,  'MAT-PVC',    N'Màng PVC trong suốt',                'PackagingMaterial', 1, 1, N'Màng PVC ép vỉ'),
(10, 'FG-NLC3-CAP',N'Viên nang NLC 3 (540mg)',            'FinishedGood', 4, 1, N'Thành phẩm đầu ra'),
(11, 'FG-PARA-TAB',N'Viên nén Paracetamol 500mg',         'FinishedGood', 4, 1, N'Finished Good'),
(12, 'MAT-TD1',    N'Aerosil',                            'RawMaterial',  2, 1, N'TD 1 - TD trơn chảy'),
(13, 'MAT-TD3',    N'Sodium starch glycolate',            'RawMaterial',  1, 1, N'TD 3 - Tá dược rã'),
(14, 'MAT-TD4',    N'Talc',                               'RawMaterial',  2, 1, N'TD 4 - Tá dược trơn'),
(15, 'MAT-WATER',  N'Nước cất pha tiêm',                  'RawMaterial',  3, 1, N'Nước cất vô trùng'),
(16, 'MAT-AMP',    N'Ống thủy tinh 2ml',                  'PackagingMaterial', 4, 1, N'Bao bì sơ cấp thuốc tiêm'),
(17, 'FG-DIPY-AMP',N'Thuốc ống Dipyridamole 10mg/2ml',     'FinishedGood', 4, 1, N'Thành phẩm thuốc ống'),
(18, 'MAT-PROB',   N'Men vi sinh Bacillus subtilis',      'RawMaterial',  2, 1, N'Bột men vi sinh đậm đặc'),
(19, 'MAT-SACH',   N'Màng nhôm đóng gói cốm',             'PackagingMaterial', 1, 1, N'Màng phức hợp Al/PE'),
(20, 'FG-BIO-PLUS',N'Cốm vi sinh Bio-Plus (3g)',          'FinishedGood', 8, 1, N'Thành phẩm dạng gói cốm');
SET IDENTITY_INSERT Materials OFF;
GO

-- =====================================================================
-- 6. Recipes
-- =====================================================================
SET IDENTITY_INSERT Recipes ON;
INSERT INTO Recipes (RecipeId, MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, Note) VALUES
(1, 10, 1, 54000.00, 'Approved', 2, DATEADD(DAY,-30,GETDATE()), DATEADD(DAY,-45,GETDATE()), N'Công thức viên nang NLC 3 chuẩn GMP-WHO. Mẻ 100,000 viên (54kg).'),
(2, 11, 2, 500000.00, 'Approved', 2, DATEADD(DAY,-20,GETDATE()), DATEADD(DAY,-35,GETDATE()), N'Công thức Paracetamol 500mg.'),
(3, 10, 2, 100000.00, 'Draft',    NULL, NULL,                    DATEADD(DAY,-5, GETDATE()), N'Phiên bản thử nghiệm cải tiến tỷ lệ tá dược - Chưa phê duyệt.'),
(4, 17, 1, 10000.00, 'Approved', 2, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-15,GETDATE()), N'Công thức thuốc ống Dipyridamole 10mg/2ml.'),
(5, 11, 3, 200000.00, 'Approved', 2, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-10,GETDATE()), N'Quy trình sản xuất viên nén Paracetamol (Dây chuyền tầng sôi).'),
(6, 20, 1, 30000.00,  'Approved', 2, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-5,GETDATE()),  N'Công thức cốm vi sinh Bio-Plus.'),
(100, 10, 3, 3200.00, 'Approved', 2, GETDATE(), GETDATE(), N'Công thức quy chuẩn 1 thùng (3200 viên). Tối ưu mẻ sấy 50kg.');
SET IDENTITY_INSERT Recipes OFF;
GO

-- =====================================================================
-- 7. RecipeBOM
-- =====================================================================
SET IDENTITY_INSERT RecipeBOM ON;
INSERT INTO RecipeBOM (BomId, RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note) VALUES
(1,  1, 1,  25000.00, 2, 0.20, N'NLC 3 (250mg/viên)'),
(2,  1, 12,   162.00, 2, 0.10, N'TD 1 - Aerosil (1.62mg/viên)'),
(3,  1, 13,  2970.00, 2, 0.20, N'TD 3 - SSG (29.70mg/viên)'),
(4,  1, 14,   405.00, 2, 0.10, N'TD 4 - Talc (4.05mg/viên)'),
(5,  1, 5,    405.00, 2, 0.10, N'TD 5 - Magnesi stearat (4.05mg/viên)'),
(6,  1, 3,  25058.00, 2, 0.50, N'TD 8 - Tinh bột (250.58mg/viên) - Bù trừ'),
(7,  1, 6, 100000.00, 4, 0.10, N'NLP 6 - Vỏ nang cứng (1 viên/viên)'),
(8,  2, 2, 250000.00, 2, 0.30, N'Paracetamol hoạt chất chính 50%'),
(9,  2, 3, 150000.00, 2, 1.00, N'Tinh bột ngô làm chất độn'),
(10, 2, 4,  80000.00, 2, 0.50, N'Lactose kết dính'),
(11, 2, 5,   5000.00, 2, 0.10, N'Magie stearat bôi trơn'),
(12, 2, 7,  10000.00, 2, 0.20, N'PVP K30 tạo hạt ướt'),
(13, 6, 18, 10000.00, 2, 0.05, N'Men vi sinh (1g/gói)'),
(14, 6, 4,  20000.00, 2, 0.10, N'Lactose (2g/gói)'),
(15, 6, 19, 10000.00, 8, 0.02, N'Màng nhôm (1 gói/gói)'),
-- BOM cho Recipe 100 (3,200 viên)
(1001, 100, 1,   800.00, 2, 0.00, N'NLC 3 (250mg/v)'),
(1002, 100, 12,    5.184, 2, 0.00, N'TD 1 - Aerosil (1.62mg/v)'),
(1003, 100, 13,   95.04, 2, 0.00, N'TD 3 - SSG (29.70mg/v)'),
(1004, 100, 14,   12.96, 2, 0.00, N'TD 4 - Talc (4.05mg/v)'),
(1005, 100, 5,    12.96, 2, 0.00, N'TD 5 - Magnesi stearat (4.05mg/v)'),
(1006, 100, 3,   801.856, 2, 0.00, N'TD 8 - Tinh bột (250.58mg/v)'),
(1007, 100, 6,  3200.00, 4, 0.00, N'Vỏ nang NLP 6');
SET IDENTITY_INSERT RecipeBOM OFF;
GO

-- =====================================================================
-- 8. RecipeRouting
-- =====================================================================
SET IDENTITY_INSERT RecipeRouting ON;
INSERT INTO RecipeRouting (RoutingId, RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description, NumberOfRouting) VALUES
(1, 1, 1, N'Sấy Tá Dược 8 (TD 8)',              2, 180, N'Sấy tinh bột TD 8 tại 75°C, 180p. Độ ẩm < 5%.', 1),
(2, 1, 2, N'Sấy Cao Khô NLC 3',                2, 180, N'Sấy cao khô Trinh nữ tại 75°C, 180p. Độ ẩm < 3%.', 1),
(3, 1, 3, N'Cân Nguyên Liệu',                  1, 90,  N'Cân chính xác 6 loại theo BOM động (Section 4 BMR). Đối chiếu nhãn phụ.', 1),
(4, 1, 4, N'Trộn Khô',                         3, 15,  N'Trộn premix bột tá dược trước. Trộn chính 15 phút, 15 vòng/phút.', 1),
(7, 1, 5, N'Đóng Nang',                        7, 120, N'Đóng nang số 0, khối lượng đích 540mg/viên.', 1),
(5, 2, 1, N'Cân Paracetamol',   1, 90,  NULL, 1),
(6, 2, 2, N'Dập Viên',          4, 180, NULL, 1),
(10, 4, 1, N'Pha chế dung dịch', 8, 60, N'Trộn hoạt chất Dipyridamole vào nước cất vô trùng.', 1),
(11, 4, 2, N'Lọc vô trùng',      NULL, 45, N'Lọc qua màng lọc 0.22 micron.', 1),
(12, 4, 3, N'Đóng ống - Hàn ống', NULL, 120, N'Đóng 2ml/ống, hàn kín bằng ngọn lửa.', 1),
(13, 4, 4, N'Tiệt trùng',        NULL, 90, N'Tiệt trùng bằng hơi nước (Autoclave) 121°C.', 1),
(14, 4, 5, N'Soi kiểm tra',      NULL, 180, N'Kiểm tra độ trong và các vật thể lạ bằng mắt.', 1),
(15, 5, 1, N'Cân nguyên liệu',   1, 90,  N'Cân Paracetamol và tá dược.', 1),
(16, 5, 2, N'Trộn khô',          3, 15,  N'Trộn đều bột Paracetamol và tá dược độn.', 1),
(17, 5, 3, N'Tạo hạt ướt',       NULL, 60, N'Thêm dung dịch PVP K30 tạo khối ẩm.', 1),
(18, 5, 4, N'Sấy hạt tầng sôi',  2, 120, N'Sấy hạt đến khi độ ẩm đạt < 5%. CÓ THỂ LẶP LẠI NẾU CẦN.', 10),
(19, 5, 5, N'Sửa hạt',           NULL, 60, N'Rây hạt qua lưới rây chuẩn.', 1),
(20, 5, 6, N'Dập viên',          4, 180, N'Dập viên nén 500mg.', 1),
(21, 6, 1, N'Cân Nguyên Liệu',   6, 60,  N'Cân men vi sinh và tá dược.', 1),
(22, 6, 2, N'Đóng Gói',         9, 240, N'Đóng gói 3g/gói tự động.', 1),
-- Quy trình cho Recipe 100 (Sản phẩm viên nang số 0 - Quy chuẩn 1 thùng)
(100, 100, 1, N'Sấy Tá Dược', 1, 180, N'Sấy dưới 50kg/mẻ. Độ ẩm < 5%', 10),
(101, 100, 2, N'Cân Nguyên Liệu', 1, 30, N'Cân chính xác theo BOM', 1),
(102, 100, 3, N'Trộn Bột Ngoài', 1, 45, N'Trộn đều hỗn hợp bột', 1),
(103, 100, 4, N'Đóng Nang', 1, 120, N'Đóng vào nang số 0', 1),
(104, 100, 5, N'Đóng Gói', 1, 60, N'Đóng chai 40 viên', 1);
SET IDENTITY_INSERT RecipeRouting OFF;
GO

-- =====================================================================
-- 9. StepParameters
-- =====================================================================
SET IDENTITY_INSERT StepParameters ON;
INSERT INTO StepParameters (ParameterId, RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical) VALUES
(1, 1, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(2, 1, N'Độ ẩm phòng',   '%',  45, 70, 1),
(3, 1, N'Áp lực phòng',  'Pa', 10, 50, 1),
(4, 1, N'Nhiệt độ sấy',  '°C', 73, 77, 1),
(20, 1, N'Thời gian sấy', 'phút', 170, 190, 1),
(21, 2, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(22, 2, N'Độ ẩm phòng',   '%',  45, 70, 1),
(23, 2, N'Áp lực phòng',  'Pa', 10, 50, 1),
(24, 2, N'Nhiệt độ sấy',  '°C', 73, 77, 1),
(25, 2, N'Thời gian sấy', 'phút', 170, 190, 1),
(5, 3, N'Nhiệt độ phòng', '°C', 21, 25, 1),
(6, 3, N'Độ ẩm phòng',   '%',  45, 70, 1),
(7, 4, N'Tốc độ trộn',   'v/p', 14, 16, 1),
(8, 4, N'Thời gian trộn', 'phút', 14, 16, 1),
(40, 10, N'Tốc độ cánh khuấy', 'v/p', 50, 60, 1),
(41, 10, N'Thời gian pha', 'phút', 30, 45, 1),
(42, 13, N'Nhiệt độ tiệt trùng', '°C', 121, 122, 1),
(50, 18, N'Nhiệt độ sấy tầng sôi', '°C', 60, 70, 1),
(51, 18, N'Độ ẩm hạt sau sấy', '%', NULL, 5.0, 1),
(52, 22, N'Thời gian trộn', 'phút', 25, 35, 1),
(53, 22, N'Khối lượng gói', 'g', 2.9, 3.1, 1),
-- Bổ sung thông số khối lượng cho các công đoạn sấy
(60, 1, N'Khối lượng trước sấy', 'kg', 0.1, 50.0, 1),
(61, 1, N'Khối lượng sau sấy',   'kg', 0.1, 50.0, 1),
(62, 2, N'Khối lượng trước sấy', 'kg', 0.1, 50.0, 1),
(63, 2, N'Khối lượng sau sấy',   'kg', 0.1, 50.0, 1),
(64, 18, N'Khối lượng trước sấy', 'kg', 0.1, 50.0, 1),
(65, 18, N'Khối lượng sau sấy',   'kg', 0.1, 50.0, 1),
-- Thông số cho Recipe 100 (Điều chỉnh theo quy trình Sấy -> Cân -> Trộn)
(110, 100, N'Khối lượng trước sấy', 'kg', 0.1, 50.0, 1),
(111, 100, N'Nhiệt độ sấy', '°C', 70, 80, 1),
(112, 100, N'Thời gian sấy', 'phút', 150, 200, 1),
(114, 100, N'Độ ẩm sau sấy', '%', NULL, 5.0, 1),
(113, 102, N'Tốc độ trộn', 'v/p', 15, 25, 1);
SET IDENTITY_INSERT StepParameters OFF;
GO

-- =====================================================================
-- 10. ProductionOrders
-- =====================================================================
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, ActualQuantity, Status, CreatedBy, StartDate, EndDate, CreatedAt) VALUES
(1,  'PO-CAP-26-001', 1, 54000.00, 54050.00, 'Completed',  4, DATEADD(DAY,-5,GETDATE()),  DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,-7,GETDATE())),
(2,  'PO-CAP-26-002', 1, 162000.00, NULL,       'InProcess', 4, DATEADD(DAY,-1,GETDATE()),  DATEADD(DAY,3, GETDATE()),  DATEADD(DAY,-2,GETDATE())),
(3,  'PO-CAP-26-003', 1, 54000.00, NULL,       'Hold',       4, GETDATE(),                  DATEADD(DAY,4, GETDATE()),  DATEADD(DAY,-1,GETDATE())),
(4,  'PO-TAB-26-004', 2, 1000000.00, NULL,       'InProcess', 4, DATEADD(DAY,-2,GETDATE()),  DATEADD(DAY,2, GETDATE()),  DATEADD(DAY,-3,GETDATE())),
(5,  'PO-CAP-26-005', 1, 54000.00, NULL,       'PendingQC', 4, GETDATE(),                  DATEADD(DAY,7, GETDATE()),  GETDATE()),
(6,  'PO-TAB-26-006', 2, 500000.00, NULL,       'InProcess', 4, DATEADD(DAY,-3,GETDATE()),  DATEADD(DAY,5, GETDATE()),  DATEADD(DAY,-4,GETDATE())),
(7,  'PO-TAB-26-007', 2, 1000000.00, 997800.00,  'Completed',  4, DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-7,GETDATE()),  DATEADD(DAY,-12,GETDATE())),
(8,  'PO-CAP-26-008', 1, 54000.00, NULL,       'Draft',      4, DATEADD(DAY,3, GETDATE()),  DATEADD(DAY,7, GETDATE()),  GETDATE()),
(9,  'PO-CAP-26-009', 1, 54000.00, NULL,       'Approved',   4, DATEADD(DAY,1, GETDATE()),  DATEADD(DAY,4, GETDATE()),  GETDATE()),
(10, 'PO-CAP-26-010', 1, 54000.00, NULL,       'Cancelled',  4, GETDATE(),                  NULL,                       GETDATE()),
(11, 'PO-COM-26-011', 6, 30000.00,  NULL,       'InProcess', 4, DATEADD(HOUR,-12,GETDATE()),NULL,                       GETDATE()),
(12, 'PO-COM-26-012', 6, 30000.00,  29985.00,   'Completed',  4, DATEADD(DAY,-4,GETDATE()),  DATEADD(DAY,-1,GETDATE()),  GETDATE());
SET IDENTITY_INSERT ProductionOrders OFF;
GO

-- =====================================================================
-- 11. ProductionBatches
-- =====================================================================
SET IDENTITY_INSERT ProductionBatches ON;
INSERT INTO ProductionBatches (BatchId, OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep) VALUES
(1,  1,  'B26-001-01', 'Completed', DATEADD(DAY,-5,GETDATE()),    DATEADD(DAY,-2,GETDATE()),  DATEADD(YEAR,2,GETDATE()),  5),
(2,  2,  'B26-002-01', 'Completed', DATEADD(HOUR,-24,GETDATE()),  DATEADD(HOUR,-12,GETDATE()), DATEADD(YEAR,2,GETDATE()), 5),
(3,  2,  'B26-002-02', 'Completed', DATEADD(HOUR,-18,GETDATE()),  DATEADD(HOUR,-6,GETDATE()),  DATEADD(YEAR,2,GETDATE()), 5),
(4,  2,  'B26-002-03', 'Scheduled', GETDATE(),                    NULL,                         NULL,                      1),
(5,  3,  'B26-003-01', 'OnHold',    DATEADD(HOUR,-6,GETDATE()),   NULL,                         NULL,                      2),
(6,  4,  'B26-004-01', 'InProcess', DATEADD(HOUR,-8,GETDATE()),   NULL,                         NULL,                      3),
(7,  4,  'B26-004-02', 'Scheduled', NULL,                          NULL,                         NULL,                      1),
(8,  6,  'B26-006-01', 'InProcess', GETDATE(),                    NULL,                         NULL,                      1),
(9,  7,  'B26-007-01', 'Completed', DATEADD(DAY,-10,GETDATE()),   DATEADD(DAY,-8,GETDATE()),   DATEADD(YEAR,2,GETDATE()),  5),
(10, 7,  'B26-007-02', 'Completed', DATEADD(DAY,-9,GETDATE()),    DATEADD(DAY,-7,GETDATE()),   DATEADD(YEAR,2,GETDATE()),  5),
(11, 5,  'B26-005-01', 'InProcess', GETDATE(),                    NULL,                         NULL,                      1),
(12, 8,  'B26-008-01', 'Draft',     GETDATE(),                    NULL,                         NULL,                      1),
(13, 11, 'B26-011-01', 'InProcess', DATEADD(HOUR,-10,GETDATE()),  NULL,                         NULL,                      2),
(14, 12, 'B26-012-01', 'Completed', DATEADD(DAY,-4,GETDATE()),    DATEADD(DAY,-1,GETDATE()),  DATEADD(YEAR,2,GETDATE()),  3);
SET IDENTITY_INSERT ProductionBatches OFF;
GO

-- =====================================================================
-- 12. InventoryLots
-- =====================================================================
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus) VALUES
(1,  1,  'LOT-NLC3-001',  85000.00, DATEADD(DAY,-60,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
(2,  1,  'LOT-NLC3-002',  50000.00, DATEADD(DAY,-10,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Pending'),
(3,  2,  'LOT-PARA-001', 250000.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(4,  2,  'LOT-PARA-002', 120000.00, DATEADD(DAY,-5, GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(5,  3,  'LOT-STR-001',   80000.00, DATEADD(DAY,-45,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(6,  4,  'LOT-LAC-001',   60000.00, DATEADD(DAY,-90,GETDATE()), DATEADD(YEAR,1,GETDATE()),  'Released'),
(7,  4,  'LOT-LAC-002',    5000.00, DATEADD(DAY,-400,GETDATE()),DATEADD(DAY,-30,GETDATE()),  'Rejected'),
(8,  5,  'LOT-MGS-001',   10000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
(9,  6,  'LOT-CAP-001', 500000.00,  DATEADD(DAY,-15,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(10, 7,  'LOT-PVP-001',   15000.00, DATEADD(DAY,-25,GETDATE()), DATEADD(YEAR,3,GETDATE()),  'Released'),
(11, 8,  'LOT-ALU-001', 2000000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(12, 9,  'LOT-PVC-001', 2000000.00, DATEADD(DAY,-20,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released'),
(13, 18, 'LOT-BIO-001',   50000.00, DATEADD(DAY,-15,GETDATE()), DATEADD(YEAR,1,GETDATE()),  'Released'),
(14, 4,  'LOT-LAC-003',  200000.00, DATEADD(DAY,-30,GETDATE()), DATEADD(YEAR,2,GETDATE()),  'Released');
SET IDENTITY_INSERT InventoryLots OFF;
GO

-- =====================================================================
-- 13. MaterialUsage
-- =====================================================================
INSERT INTO MaterialUsage (BatchID, InventoryLotID, ActualAmount, Timestamp, DispensedBy, Note) VALUES
(1,  1, 25000.00, DATEADD(DAY,-5,GETDATE()), 3, N'NLC 3'),
(1,  5, 25058.00, DATEADD(DAY,-5,GETDATE()), 3, N'Tinh bột'),
(1,  8, 405.00,   DATEADD(DAY,-5,GETDATE()), 3, N'Magie Stearat'),
(9,  3, 250000.00,DATEADD(DAY,-10,GETDATE()), 3, N'Paracetamol'),
(13, 13, 1000.5, DATEADD(HOUR,-10,GETDATE()), 3, N'Men vi sinh');
GO

-- =====================================================================
-- 14. BatchProcessLogs
-- =====================================================================
SET IDENTITY_INSERT BatchProcessLogs ON;
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
-- 15. SystemAuditLog
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

-- =====================================================================
-- 🚀 ADDITIONAL REAL-WORLD SCENARIOS (v4.0)
-- Bổ sung kịch bản 100 thùng, nhiều mẻ, nhiều biến thể
-- =====================================================================

-- 1. Các Lệnh sản xuất mới
SET IDENTITY_INSERT ProductionOrders ON;
INSERT INTO ProductionOrders (OrderId, OrderCode, RecipeId, PlannedQuantity, Status, CreatedBy, StartDate, EndDate, CreatedAt) VALUES
(100, 'PO-NCR-21-100', 100, 6400.00, 'InProcess', 4, DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,5,GETDATE()), GETDATE()),
(200, 'PO-NCR-21-200', 100, 32000.00, 'Approved', 4, DATEADD(DAY,1,GETDATE()),  DATEADD(DAY,7,GETDATE()), GETDATE()),
(300, 'PO-COM-21-300', 6, 150000.00,  'InProcess', 4, GETDATE(),                DATEADD(DAY,10,GETDATE()),GETDATE());
SET IDENTITY_INSERT ProductionOrders OFF;

-- 2. Hệ thống Mẻ sản xuất phong phú (20+ mẻ)
-- PO-100: 2 mẻ lớn (160k viên/mẻ = 50 thùng)
INSERT INTO ProductionBatches (BatchNumber, OrderId, Status, ManufactureDate, CurrentStep) VALUES
('B100-M01', 100, 'Completed', DATEADD(DAY,-2,GETDATE()), 5),
('B100-M02', 100, 'InProcess', GETDATE(), 3);

-- PO-200: 10 mẻ nhỏ (16k viên/mẻ = 5 thùng) để test phân trang
INSERT INTO ProductionBatches (BatchNumber, OrderId, Status, ManufactureDate, CurrentStep) VALUES
('B200-M01', 200, 'Scheduled', NULL, 1),
('B200-M02', 200, 'Scheduled', NULL, 1),
('B200-M03', 200, 'Scheduled', NULL, 1),
('B200-M04', 200, 'Scheduled', NULL, 1),
('B200-M05', 200, 'OnHold',    GETDATE(), 1), -- Mẻ gặp sự cố sensor
('B200-M06', 200, 'Scheduled', NULL, 1),
('B200-M07', 200, 'Scheduled', NULL, 1),
('B200-M08', 200, 'Scheduled', NULL, 1),
('B200-M09', 200, 'Scheduled', NULL, 1),
('B200-M10', 200, 'Scheduled', NULL, 1);

-- PO-300: 5 mẻ cốm
INSERT INTO ProductionBatches (BatchNumber, OrderId, Status, ManufactureDate, CurrentStep) VALUES
('B300-M01', 300, 'Completed', DATEADD(DAY,-1,GETDATE()), 2),
('B300-M02', 300, 'InProcess', GETDATE(), 2),
('B300-M03', 300, 'Scheduled', NULL, 1),
('B300-M04', 300, 'Scheduled', NULL, 1),
('B300-M05', 300, 'Scheduled', NULL, 1);

-- 3. Bổ sung tồn kho khổng lồ cho các kịch bản test
SET IDENTITY_INSERT InventoryLots ON;
INSERT INTO InventoryLots (LotId, MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus) VALUES
(201, 1,  'LOT-NLC3-MAX', 1000000.0, GETDATE(), DATEADD(YEAR,3,GETDATE()), 'Released'),
(203, 3,  'LOT-STR-MAX',  1000000.0, GETDATE(), DATEADD(YEAR,2,GETDATE()), 'Released'),
(212, 12, 'LOT-TD1-MAX',   100000.0, GETDATE(), DATEADD(YEAR,3,GETDATE()), 'Released'),
(213, 13, 'LOT-TD3-MAX',   100000.0, GETDATE(), DATEADD(YEAR,3,GETDATE()), 'Released'),
(214, 14, 'LOT-TD4-MAX',   100000.0, GETDATE(), DATEADD(YEAR,3,GETDATE()), 'Released');
SET IDENTITY_INSERT InventoryLots OFF;

-- 4. Nhật ký công đoạn eBMR chi tiết
-- Mẻ B100-M01: Có đầy đủ tham số tính toán
INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData)
SELECT TOP 1 BatchId, 3, 6, 3, DATEADD(HOUR,-48,GETDATE()), DATEADD(HOUR,-47,GETDATE()), 'Passed', 
 N'{"A":40000,"C":0.625,"X":250,"Y":0.2,"Q":200000,"klCan":[{"ten":"NLC3","kl":40000},{"ten":"TD8","kl":40092}]}'
FROM ProductionBatches WHERE BatchNumber = 'B100-M01';

-- Mẻ B200-M05: Ghi nhận sai lệch (Deviation)
INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, IsDeviation, Notes, ParametersData)
SELECT TOP 1 BatchId, 1, 2, 6, GETDATE(), NULL, 'OnHold', 1, N'Lỗi sensor nhiệt độ sấy vọt quá 85 độ.', N'{"temp_max":85.5,"sensor_fail":true}'
FROM ProductionBatches WHERE BatchNumber = 'B200-M05';
GO

-- Kích hoạt lại Trigger sau khi Seed xong
IF OBJECT_ID('trg_Lock_Finalized_Logs', 'TR') IS NOT NULL ENABLE TRIGGER trg_Lock_Finalized_Logs ON BatchProcessLogs;
IF OBJECT_ID('trg_Check_Material_QC', 'TR') IS NOT NULL ENABLE TRIGGER trg_Check_Material_QC ON MaterialUsage;
IF OBJECT_ID('trg_Validate_Drying_Limit', 'TR') IS NOT NULL ENABLE TRIGGER trg_Validate_Drying_Limit ON BatchProcessParameterValues;
GO
