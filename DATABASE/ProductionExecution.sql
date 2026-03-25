-- ============================================================================
-- 🏭 MODULE: THI CÔNG SẢN XUẤT (PRODUCTION EXECUTION)
-- 
-- Quản lý Lệnh sản xuất (Production Orders) và các Mẻ sản xuất (Batches).
-- Đảm bảo tính chính xác của số lượng và thời gian thực hiện.
-- ============================================================================

-- 1. LỆNH SẢN XUẤT (Production Orders)
CREATE TABLE ProductionOrders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE, -- Mã lệnh (vd: PO-2026-001)
    RecipeId INT REFERENCES Recipes(RecipeId),
    PlannedQuantity DECIMAL(18, 2) NOT NULL, -- Số lượng dự kiến sản xuất
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(50) DEFAULT 'Draft',    -- Trạng thái (Nháp, Đã duyệt, Đang chạy, Hoàn thành, Hủy)
    CreatedBy INT REFERENCES AppUsers(UserId),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(500)
);

-- 2. MẺ SẢN XUẤT (Production Batches)
-- Một Lệnh sản xuất có thể chia thành nhiều Mẻ (Batch).
CREATE TABLE ProductionBatches (
    BatchId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT REFERENCES ProductionOrders(OrderId),
    BatchNumber VARCHAR(50) NOT NULL UNIQUE, -- Số lô (vd: 112026)
    Status NVARCHAR(50) DEFAULT 'Scheduled', -- Trạng thái lô (Lập lịch, Đang làm, QC chờ, Hoàn tất)
    ManufactureDate DATETIME2,
    ExpiryDate DATETIME2,
    CurrentStep INT DEFAULT 1,              -- Bước hiện tại trong quy trình
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- 3. NHẬT KÝ CÔNG ĐOẠN (Batch Process Logs)
-- Ghi lại mọi hoạt động thực tế diễn ra trong quá trình sản xuất.
CREATE TABLE BatchProcessLogs (
    LogId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    StepNumber INT NOT NULL,
    StepName NVARCHAR(100) NOT NULL,
    EquipmentId INT REFERENCES Equipments(EquipmentId),
    OperatorId INT REFERENCES AppUsers(UserId),
    StartTime DATETIME2,
    EndTime DATETIME2,
    Status NVARCHAR(50),                     -- Trạng thái bước (Đang làm, Hoàn tất)
    Notes NVARCHAR(MAX)
);
GO
