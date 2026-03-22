USE [PharmaceuticalProcessingManagementSystem];
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '---------------------------------------------------------';
PRINT '💊 DANG KHOI TAO DU LIEU MAU CHO HE THONG GMP-WHO';
PRINT '---------------------------------------------------------';

-- ============================================================================
-- 1. XÓA DỮ LIỆU CŨ VÀ RESET TRẠNG THÁI (CLEANUP)
-- ============================================================================
PRINT 'Dang xoa du lieu cu va reset ID...';

-- Vô hiệu hóa các ràng buộc khóa ngoại để xóa dữ liệu dễ dàng
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
DELETE FROM UomConversions;

-- Kích hoạt lại các ràng buộc khóa ngoại
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Reset các cột Identity về 0
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

-- ============================================================================
-- 2. ĐƠN VỊ TÍNH (Unit of Measure)
-- ============================================================================
PRINT 'Dang tao danh muc Don vi tinh...';
INSERT INTO UnitOfMeasure (UomName, Description) VALUES
('mg', 'Milligram'),
('g', 'Gram'),
('kg', 'Kilogram'),
('ml', 'Milliliter'),
('L', 'Liter'),
('Tablet/Capsule', N'Viên (nén/nang)'),
('Blister', N'Vỉ (10 viên)'),
('Box', N'Hộp');

-- ============================================================================
-- 3. NGƯỜI DÙNG HỆ THỐNG (App Users)
-- ============================================================================
PRINT 'Dang tao danh sach Nguoi dung...';
-- Mật khẩu mặc định: admin/Admin@123, op/123456
INSERT INTO AppUsers (Username, FullName, Role, IsActive, PasswordHash) VALUES
('admin', N'Nguyễn Văn Quản Trị', 'Admin', 1, NULL),
('qc_specialist', N'Trần Thị Kiểm Tra (QC)', 'QA_QC', 1, NULL),
('production_mgr', N'Lê Văn Quản Lý', 'ProductionManager', 1, NULL),
('operator1', N'Phạm Công Nhân', 'Operator', 1, NULL),
('op01', N'Công nhân 01', 'Operator', 1, NULL),
('qc01', N'Kiểm tra viên 01', 'QA_QC', 1, NULL);

-- ============================================================================
-- 4. THIẾT BỊ SẢN XUẤT (Equipments)
-- ============================================================================
PRINT 'Dang tao danh muc Thiet bi...';
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('EQP-DRY-02', N'Máy sấy tầng sôi KBC-TS-50', 'Ready'),
('EQP-MIX-02', N'Máy trộn lập phương AD-LP-200', 'Ready'),
('EQP-FIL-01', N'Máy đóng nang tự động NJP-1200 D', 'Ready'),
('EQP-POL-01', N'Máy xát bóng IPJ', 'Ready'),
('EQP-WGH-01', N'Cân điện tử PMA-5000', 'Ready'),
('EQP-WGH-02', N'Cân phân tích IW2-60', 'Ready');

-- ============================================================================
-- 5. DANH MỤC VẬT TƯ (Materials)
-- ============================================================================
PRINT 'Dang tao danh muc Vat tu...';

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

-- ============================================================================
-- 6. TỒN KHO LÔ HÀNG (Inventory Lots)
-- ============================================================================
PRINT 'Dang tao ton kho dau ky...';
INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus)
SELECT MaterialId, 'LOT-' + MaterialCode + '-2026', 1000.0, GETDATE(), DATEADD(YEAR, 2, GETDATE()), 'Released'
FROM Materials WHERE Type = 'RawMaterial';

INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus)
SELECT MaterialId, 'LOT-CAPS-2026', 1000000, GETDATE(), DATEADD(YEAR, 5, GETDATE()), 'Released'
FROM Materials WHERE MaterialCode = 'MAT-NLP6';

-- ============================================================================
-- 7. CÔNG THỨC SẢN XUẤT & ĐỊNH MỨC (Recipe & BOM)
-- ============================================================================
PRINT 'Dang tao cong thuc san xuat...';

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

-- ============================================================================
-- 8. QUY TRÌNH CÔNG ĐOẠN (Routing)
-- ============================================================================
DECLARE @Eqp_Dry INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-DRY-02');
DECLARE @Eqp_Mix INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-MIX-02');

INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentID, EstimatedTimeMinutes, Description) VALUES
(@RecipeID, 1, N'Cân Nguyên Liệu', NULL, 60, N'Cân nguyên liệu theo lệnh'),
(@RecipeID, 2, N'Sấy Nguyên Liệu', @Eqp_Dry, 120, N'Sấy đạt ẩm quy định'),
(@RecipeID, 3, N'Trộn Khô', @Eqp_Mix, 30, N'Trộn đều hỗn hợp bột');

PRINT '---------------------------------------------------------';
PRINT '✅ KHOI TAO DU LIEU THANH CONG!';
PRINT '---------------------------------------------------------';
GO
