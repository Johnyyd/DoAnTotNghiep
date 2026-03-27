CREATE TABLE AppUsers (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE, -- Tên đăng nhập
    FullName NVARCHAR(100) NOT NULL,      -- Họ tên đầy đủ nhân viên
    Role NVARCHAR(50) NOT NULL,          -- Vai trò (Admin, QA_QC, Operator, ProductionManager)
    IsActive BIT DEFAULT 1,               -- Trạng thái hoạt động (1: Đang làm, 0: Nghỉ việc)
    PasswordHash NVARCHAR(MAX),          -- Mật khẩu mã hóa (BCrypt)
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    LastLogin DATETIME2
);

CREATE TABLE UnitOfMeasure (
    UomId INT PRIMARY KEY IDENTITY(1,1),
    UomName NVARCHAR(50) NOT NULL, -- Tên hiển thị (vd: kg)
    Description NVARCHAR(200)      -- Mô tả chi tiết (vd: Kilogram)
);

CREATE TABLE Equipments (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE, -- Mã máy (vd: EQP-DRY-01)
    EquipmentName NVARCHAR(200) NOT NULL,      -- Tên máy (vd: Máy sấy tầng sôi)
    Status NVARCHAR(50) DEFAULT 'Ready',      -- Trạng thái (Sẵn sàng, Bảo trì, Đang chạy)
    LastMaintenanceDate DATETIME2            -- Ngày bảo trì gần nhất
);

CREATE TABLE Materials (
    MaterialId INT PRIMARY KEY IDENTITY(1,1),
    MaterialCode VARCHAR(50) NOT NULL UNIQUE, -- Mã SKU duy nhất
    MaterialName NVARCHAR(200) NOT NULL,      -- Tên vật tư
    Type NVARCHAR(50) CHECK (Type IN ('RawMaterial', 'Packaging', 'FinishedGood', 'Intermediate')), -- Loại vật tư
    BaseUomId INT REFERENCES UnitOfMeasure(UomId), -- Đơn vị tính cơ bản
    IsActive BIT DEFAULT 1,                   -- Trạng thái hoạt động
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2
);

CREATE TABLE Recipes (
    RecipeId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId), -- Sản phẩm đầu ra
    VersionNumber INT DEFAULT 1,                      -- Phiên bản công thức
    BatchSize DECIMAL(18, 2) NOT NULL,               -- Cỡ mẻ tiêu chuẩn (vd: 100 kg)
    Status NVARCHAR(50) DEFAULT 'Draft',            -- Trạng thái (Nháp, Đã phê duyệt, Hết hiệu lực)
    ApprovedBy INT REFERENCES AppUsers(UserId),       -- Người phê duyệt (QA/QC)
    ApprovedDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    EffectiveDate DATETIME2,                          -- Ngày có hiệu lực
    Note NVARCHAR(500)
);

CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    MaterialId INT REFERENCES Materials(MaterialId), -- Nguyên vật liệu thành phần
    Quantity DECIMAL(18, 4) NOT NULL,               -- Lượng yêu cầu
    UomId INT REFERENCES UnitOfMeasure(UomId),       -- Đơn vị tính của nguyên liệu
    WastePercentage DECIMAL(5, 2) DEFAULT 0,         -- Tỷ lệ hao hụt cho phép (%)
    Note NVARCHAR(200)
);

CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    StepNumber INT NOT NULL,                        -- Số thứ tự bước (1, 2, 3...)
    StepName NVARCHAR(100) NOT NULL,                -- Tên bước (vd: Trộn khô)
    DefaultEquipmentId INT REFERENCES Equipments(EquipmentId), -- Thiết bị mặc định
    EstimatedTimeMinutes INT,                      -- Thời gian dự kiến (phút)
    Description NVARCHAR(500)                       -- Chi tiết nội dung công việc
);

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

CREATE TABLE MaterialUsage (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    QuantityUsed DECIMAL(18, 4) NOT NULL,     -- Lượng dùng thực tế
    UsedDate DATETIME2 DEFAULT GETDATE(),
    DispensedBy INT REFERENCES AppUsers(UserId), -- Người thực hiện xuất kho
    Note NVARCHAR(200)
);

CREATE TABLE QualityTests (
    TestId INT PRIMARY KEY IDENTITY(1,1),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    TestName NVARCHAR(100),         -- Tên chỉ tiêu kiểm tra
    ResultValue NVARCHAR(200),      -- Kết quả thực tế
    PassStatus BIT DEFAULT 1,       -- Đạt hay không đạt
    TestedBy INT REFERENCES AppUsers(UserId),
    TestDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE SystemAuditLog (
    AuditId BIGINT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100),         -- Tên bảng bị thay đổi
    RecordId NVARCHAR(100),          -- ID của bản ghi bị thay đổi
    Action NVARCHAR(50),             -- Hành động (Thêm, Sửa, Xóa)
    OldValue NVARCHAR(MAX),          -- Giá trị cũ (vd: JSON hoặc text)
    NewValue NVARCHAR(MAX),          -- Giá trị mới
    ChangedBy INT REFERENCES AppUsers(UserId), -- Người thay đổi
    ChangedDate DATETIME2 DEFAULT GETDATE()   -- Ngày giờ thay đổi
);

CREATE TABLE UomConversions (
    ConversionId INT PRIMARY KEY IDENTITY(1,1),
    FromUomId INT REFERENCES UnitOfMeasure(UomId),
    ToUomId INT REFERENCES UnitOfMeasure(UomId),
    ConversionFactor DECIMAL(18, 6) NOT NULL, -- Tỉ lệ (vd: 1000)
    Note NVARCHAR(200)
);
