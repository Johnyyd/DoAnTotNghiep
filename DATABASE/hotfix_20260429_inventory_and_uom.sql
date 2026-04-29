USE [PharmaceuticalProcessingManagementSystem];
GO

SET NOCOUNT ON;

-- 1) Ensure UOM "Cái" exists
IF NOT EXISTS (SELECT 1 FROM UnitOfMeasure WHERE UomName = N'Cái')
BEGIN
    INSERT INTO UnitOfMeasure (UomName, Description) VALUES (N'Cái', N'Đơn vị cái');
END
GO

-- 2) Force AMP (Ống thủy tinh 2ml) to use UOM "Cái"
DECLARE @UomCaiId INT = (SELECT TOP 1 UomId FROM UnitOfMeasure WHERE UomName = N'Cái');
UPDATE Materials
SET BaseUomId = @UomCaiId
WHERE MaterialCode = 'AMP' AND @UomCaiId IS NOT NULL;
GO

-- 3) Ensure ALU/PVC materials exist (packaging)
IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialCode = 'ALU')
BEGIN
    INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification, CreatedAt)
    VALUES ('ALU', N'Màng nhôm ép vỉ', 'Packaging', 1, 1, N'ĐĐVN V', GETDATE());
END

IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialCode = 'PVC')
BEGIN
    INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification, CreatedAt)
    VALUES ('PVC', N'Màng PVC trong suốt', 'Packaging', 1, 1, N'ĐĐVN V', GETDATE());
END
GO

-- 4) Ensure ALU/PVC have at least one inventory lot each
DECLARE @MatAluId INT = (SELECT TOP 1 MaterialId FROM Materials WHERE MaterialCode = 'ALU');
DECLARE @MatPvcId INT = (SELECT TOP 1 MaterialId FROM Materials WHERE MaterialCode = 'PVC');

IF @MatAluId IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM InventoryLots WHERE MaterialId = @MatAluId)
BEGIN
    INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierName, CreatedAt)
    VALUES (@MatAluId, 'L-ALU-01', 20.00, DATEADD(DAY, -20, GETDATE()), DATEADD(YEAR, 3, GETDATE()), 'Released', N'Nhà cung cấp H', GETDATE());
END

IF @MatPvcId IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM InventoryLots WHERE MaterialId = @MatPvcId)
BEGIN
    INSERT INTO InventoryLots (MaterialId, LotNumber, QuantityCurrent, ManufactureDate, ExpiryDate, QCStatus, SupplierName, CreatedAt)
    VALUES (@MatPvcId, 'L-PVC-01', 20.00, DATEADD(DAY, -15, GETDATE()), DATEADD(YEAR, 3, GETDATE()), 'Released', N'Nhà cung cấp I', GETDATE());
END
GO

-- 5) Quick check output
SELECT MaterialId, MaterialCode, MaterialName, Type, BaseUomId
FROM Materials
WHERE MaterialCode IN ('AMP', 'ALU', 'PVC');

SELECT m.MaterialCode, COUNT(*) AS LotCount, SUM(l.QuantityCurrent) AS TotalQty
FROM InventoryLots l
JOIN Materials m ON m.MaterialId = l.MaterialId
WHERE m.MaterialCode IN ('AMP', 'ALU', 'PVC')
GROUP BY m.MaterialCode;
GO
