-- ============================================================================
-- 📝 MODULE: ĐỊNH NGHĨA QUY TRÌNH & CÔNG THỨC (RECIPES & BOM)
-- 
-- Theo GMP, mọi sản phẩm phải có công thức chính (Master Recipe) 
-- và định mức vật tư (BOM) được phê duyệt bởi bộ phận QA.
-- ============================================================================

-- 1. CÔNG THỨC CHÍNH (Recipes)
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

-- 2. ĐỊNH MỨC NGUYÊN VẬT LIỆU (Recipe BOM)
-- Chi tiết từng thành phần để tạo ra sản phẩm.
CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    MaterialId INT REFERENCES Materials(MaterialId), -- Nguyên vật liệu thành phần
    Quantity DECIMAL(18, 4) NOT NULL,               -- Lượng yêu cầu
    UomId INT REFERENCES UnitOfMeasure(UomId),       -- Đơn vị tính của nguyên liệu
    WastePercentage DECIMAL(5, 2) DEFAULT 0,         -- Tỷ lệ hao hụt cho phép (%)
    Note NVARCHAR(200)
);

-- 3. CÁC BƯỚC CÔNG ĐOẠN (Recipe Routing)
-- Quy trình sản xuất từng bước (vd: Cân, Trộn, Sấy...).
CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    StepNumber INT NOT NULL,                        -- Số thứ tự bước (1, 2, 3...)
    StepName NVARCHAR(100) NOT NULL,                -- Tên bước (vd: Trộn khô)
    DefaultEquipmentId INT REFERENCES Equipments(EquipmentId), -- Thiết bị mặc định
    EstimatedTimeMinutes INT,                      -- Thời gian dự kiến (phút)
    Description NVARCHAR(500)                       -- Chi tiết nội dung công việc
);
GO
