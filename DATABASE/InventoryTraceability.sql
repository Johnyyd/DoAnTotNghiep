-- ============================================================================
-- 📦 MODULE: QUẢN LÝ KHO & TRUY XUẤT (INVENTORY & TRACEABILITY)
-- 
-- Quản lý các Lô vật tư (Inventory Lots) và việc sử dụng vật tư (Usage).
-- Đây là phần cốt lõi để biết nguyên liệu nào đã đi vào lô sản phẩm nào.
-- ============================================================================

-- 1. LÔ VẬT TƯ TRONG KHO (Inventory Lots)
CREATE TABLE InventoryLots (
    LotId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId),
    LotNumber VARCHAR(50) NOT NULL UNIQUE, -- Số lô nhà cung cấp hoặc mã nội bộ
    QuantityCurrent DECIMAL(18, 4) NOT NULL, -- Số lượng tồn thực tế
    ManufactureDate DATETIME2,               -- Ngày sản xuất
    ExpiryDate DATETIME2 NOT NULL,           -- Hạn dùng (Bắt buộc theo GMP)
    QCStatus NVARCHAR(50) DEFAULT 'Pending', -- Trạng thái QC (Chờ, Đạt - Released, Không đạt - Rejected)
    SupplierName NVARCHAR(200),
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- 2. SỬ DỤNG VẬT TƯ (Material Usage)
-- Ghi chép mỗi khi lấy hàng từ kho ra để sản xuất.
CREATE TABLE MaterialUsage (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    QuantityUsed DECIMAL(18, 4) NOT NULL,     -- Lượng dùng thực tế
    UsedDate DATETIME2 DEFAULT GETDATE(),
    DispensedBy INT REFERENCES AppUsers(UserId), -- Người thực hiện xuất kho
    Note NVARCHAR(200)
    -- Thêm cột, ai là người yêu cầu xuất kho
    -- RequestedBy INT REFERENCES AppUsers(UserId),
    -- RequestedDate DATETIME2 DEFAULT GETDATE()
);
GO
