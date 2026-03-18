-- =====================================================
-- Seed Data: Capsule NLC 3 Production (from PDF)
-- =====================================================
USE [GMP_WHO_DB];
GO

PRINT 'Seeding NLC 3 Capsule Production Data...';

-- 1. Unit of Measure (Ensure they exist)
-- Assuming IDs: 3=kg, 6=Tablet/Capsule, 10=Box, 11=Batch (from pharmacy_seed.sql)

-- 2. Materials
-- Material(MaterialCode, MaterialName, Type, BaseUomID, Description)
INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomID, Description) VALUES
('MAT-NLC3', 'NLC 3 (Active Ingredient)', 'RawMaterial', 3, 'Medicinal powder (High concentration)'),
('MAT-TD1', 'Tá dược TD 1', 'RawMaterial', 3, 'Binder/Excipient'),
('MAT-TD3', 'Tá dược TD 3', 'RawMaterial', 3, 'Filler/Excipient'),
('MAT-TD4', 'Tá dược TD 4', 'RawMaterial', 3, 'Glidant/Excipient'),
('MAT-TD5', 'Tá dược TD 5', 'RawMaterial', 3, 'Disintegrant/Excipient'),
('MAT-TD8', 'Tá dược TD 8', 'RawMaterial', 3, 'Lubricant/Excipient'),
('MAT-NLP6', 'Vỏ nang số 0 (NLP 6)', 'Packaging', 6, 'Hard capsule shells size 0'),
('FG-NLC3-CAP', 'Viên nang NLC 3 (Thành phẩm)', 'FinishedGood', 6, 'Finished capsules in case of 3200');

-- 3. Equipments
-- Equipment(EquipmentCode, EquipmentName, Status)
INSERT INTO Equipments (EquipmentCode, EquipmentName, Status) VALUES
('EQP-DRY-02', 'Máy sấy tầng sôi KBC-TS-50', 'Ready'),
('EQP-MIX-02', 'Máy trộn lập phương AD-LP-200', 'Ready'),
('EQP-FIL-01', 'Máy đóng nang tự động NJP-1200 D', 'Ready'),
('EQP-POL-01', 'Máy xát bóng IPJ', 'Ready');

-- 4. Recipe
-- Get IDs dynamically to avoid hardcoding if possible, but for a seed script we often use known IDs or subqueries.
DECLARE @Mat_FG_NLC3 INT = (SELECT TOP 1 MaterialID FROM Materials WHERE MaterialCode = 'FG-NLC3-CAP');
DECLARE @UserID_Admin INT = (SELECT TOP 1 UserID FROM AppUsers WHERE Username = 'admin');

-- Recipe(MaterialId, VersionNumber, Status, ApprovedBy, BatchSize)
INSERT INTO Recipes (MaterialId, VersionNumber, Status, ApprovedBy, ApprovedDate, BatchSize) VALUES
(@Mat_FG_NLC3, 1, 'Approved', @UserID_Admin, GETDATE(), 100000);

DECLARE @RecipeID INT = SCOPE_IDENTITY();

-- 5. Recipe BOM
-- RecipeBOM(RecipeId, MaterialId, Quantity, UomId)
INSERT INTO RecipeBOM (RecipeId, MaterialId, Quantity, UomId, Note) 
SELECT @RecipeID, MaterialID, 50.0, 3, 'Hoạt chất' FROM Materials WHERE MaterialCode = 'MAT-NLC3' UNION ALL
SELECT @RecipeID, MaterialID, 10.0, 3, 'Tá dược 1' FROM Materials WHERE MaterialCode = 'MAT-TD1' UNION ALL
SELECT @RecipeID, MaterialID, 20.0, 3, 'Tá dược 3' FROM Materials WHERE MaterialCode = 'MAT-TD3' UNION ALL
SELECT @RecipeID, MaterialID, 5.0, 3, 'Tá dược 4' FROM Materials WHERE MaterialCode = 'MAT-TD4' UNION ALL
SELECT @RecipeID, MaterialID, 100000.0, 6, 'Vỏ nang' FROM Materials WHERE MaterialCode = 'MAT-NLP6';

-- 6. Recipe Routing
-- Routing(RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description)
DECLARE @Eqp_Dry INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-DRY-02');
DECLARE @Eqp_Mix INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-MIX-02');
DECLARE @Eqp_Fil INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-FIL-01');
DECLARE @Eqp_Pol INT = (SELECT TOP 1 EquipmentID FROM Equipments WHERE EquipmentCode = 'EQP-POL-01');

INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description) VALUES
(@RecipeID, 10, 'Chuẩn bị nhân sự và vệ sinh', NULL, 30, 'Kiểm tra vệ sinh phòng máy và thiết bị'),
(@RecipeID, 20, 'Sấy nguyên liệu (NLC 3 & TD 8)', @Eqp_Dry, 120, 'Sấy tại 75 độ C đến khi đạt độ ẩm quy định'),
(@RecipeID, 30, 'Trộn bột thuốc', @Eqp_Mix, 30, 'Trộn tại 15 RPM trong 15-30 phút'),
(@RecipeID, 40, 'Đóng nang tự động', @Eqp_Fil, 240, 'Đóng nang số 0, công suất 72.000 nang/giờ'),
(@RecipeID, 50, 'Xát bóng nang', @Eqp_Pol, 60, 'Xát bóng sạch bụi bột, công suất 100.000 nang/giờ'),
(@RecipeID, 60, 'Kiểm tra và Đóng gói', NULL, 120, 'Kiểm tra khối lượng, độ rã và đóng thùng 3200 viên/case');

PRINT 'Seeding of NLC 3 Capsule Production Data completed successfully!';
GO
