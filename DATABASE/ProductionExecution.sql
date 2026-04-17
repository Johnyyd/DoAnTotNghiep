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
    PlannedQuantity DECIMAL(18, 4) NOT NULL, -- Số lượng dự kiến sản xuất
    ActualQuantity DECIMAL(18, 4),           -- Số lượng thực tế thu hồi
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(50) DEFAULT 'Draft',    -- Trạng thái (Draft, Approved, InProcess, Completed, Hold, Cancelled)
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
    Status NVARCHAR(50) DEFAULT 'Scheduled', -- Trạng thái lô (Scheduled, InProcess, Completed, OnHold)
    ManufactureDate DATETIME2,
    EndTime DATETIME2,                       -- Thời điểm kết thúc mẻ
    ExpiryDate DATETIME2,
    CurrentStep INT DEFAULT 1,              -- Bước hiện tại trong quy trình
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- 3. NHẬT KÝ CÔNG ĐOẠN (Batch Process Logs)
-- Ghi lại mọi hoạt động thực tế diễn ra trong quá trình sản xuất.
CREATE TABLE BatchProcessLogs (
    LogId BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    RoutingId INT REFERENCES RecipeRouting(RoutingId), -- Liên kết cứng với công đoạn quy trình
    EquipmentId INT REFERENCES Equipments(EquipmentId),
    OperatorId INT REFERENCES AppUsers(UserId),
    StartTime DATETIME2,
    EndTime DATETIME2,
    ResultStatus NVARCHAR(50),               -- Trạng thái kết quả (Passed, Failed, PendingQC)
    ParametersData NVARCHAR(MAX),            -- Dữ liệu JSON thông số vận hành máy
    Notes NVARCHAR(MAX),
    IsDeviation BIT DEFAULT 0,               -- Đánh dấu nếu có sai lệch thông số
    VerifiedById INT REFERENCES AppUsers(UserId), -- Người thẩm định (QA/QC)
    VerifiedDate DATETIME2,                  -- Ngày thẩm định
    NumberOfRouting INT DEFAULT 1,           -- Số lần thực thi thực tế của cùng 1 routing
    CONSTRAINT CK_BatchProcessLogs_NumberOfRouting CHECK (NumberOfRouting >= 1)
);
GO  

-- 4. GIÁ TRỊ THỰC TẾ CỦA THÔNG SỐ (Batch Process Parameter Values)
-- Lưu trữ chi tiết từng giá trị thông số đã tách từ JSON để phục vụ báo cáo/truy vấn.
CREATE TABLE BatchProcessParameterValues (
    ValueId BIGINT PRIMARY KEY IDENTITY(1,1),
    LogId BIGINT REFERENCES BatchProcessLogs(LogId), -- Tham chiếu tới nhật ký công đoạn
    ParameterId INT REFERENCES StepParameters(ParameterId), -- Tham chiếu tới định nghĩa thông số
    ActualValue DECIMAL(18, 4),                     -- Giá trị đo được thực tế
    RecordedDate DATETIME2 DEFAULT GETDATE(),       -- Thời điểm ghi nhận
    Note NVARCHAR(500)                              -- Ghi chú riêng cho từng thông số (nếu có)
);
GO
