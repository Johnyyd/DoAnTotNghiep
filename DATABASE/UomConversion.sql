-- ============================================================================
-- ⚖️ MODULE: QUY ĐỔI ĐƠN VỊ (UOM CONVERSIONS)
-- 
-- Quản lý tỉ lệ quy đổi giữa các đơn vị đo lường (vd: 1 kg = 1000 g).
-- Rất quan trọng cho việc trừ tồn kho nguyên liệu lẻ.
-- ============================================================================

CREATE TABLE UomConversions (
    ConversionId INT PRIMARY KEY IDENTITY(1,1),
    FromUomId INT REFERENCES UnitOfMeasure(UomId),
    ToUomId INT REFERENCES UnitOfMeasure(UomId),
    ConversionFactor DECIMAL(18, 6) NOT NULL, -- Tỉ lệ (vd: 1000)
    Note NVARCHAR(200)
);
GO
