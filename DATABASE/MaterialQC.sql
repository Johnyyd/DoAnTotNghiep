-- ============================================================================
-- 🔬 MODULE: KIỂM TRA CHẤT LƯỢNG (QUALITY CONTROL - QC)
-- 
-- Lưu các bản ghi về việc xét duyệt chất lượng cho Lô ngueyên liệu và Thành phẩm.
-- ============================================================================

CREATE TABLE QualityTests (
    TestId INT PRIMARY KEY IDENTITY(1,1),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    TestName NVARCHAR(100),         -- Tên chỉ tiêu kiểm tra
    ResultValue NVARCHAR(200),      -- Kết quả thực tế
    PassStatus BIT DEFAULT 1,       -- Đạt hay không đạt
    TestedBy INT REFERENCES AppUsers(UserId),
    TestDate DATETIME2 DEFAULT GETDATE()
);
GO
