-- ============================================================================
-- 📦 MODULE: DỮ LIỆU MASTER (MASTER DATA)
-- 
-- File này chứa các bảng danh mục cơ bản dùng chung cho toàn hệ thống.
-- Các bảng này phải được tạo đầu tiên vì chúng là "gốc" của các dữ liệu khác.
-- ============================================================================

-- 1. ĐƠN VỊ TÍNH (Units of Measure - UoM)
-- Lưu các đơn vị như: kg, mg, viên, vỉ, hộp...
CREATE TABLE UnitOfMeasure (
    UomId INT PRIMARY KEY IDENTITY(1,1),
    UomName NVARCHAR(50) NOT NULL, -- Tên hiển thị (vd: kg)
    Description NVARCHAR(200)      -- Mô tả chi tiết (vd: Kilogram)
);

-- 2. DANH MỤC VẬT TƯ (Materials)
-- Quản lý Nguyên liệu (Raw Material), Bao bì (Packaging) và Thành phẩm (Finished Good).
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

-- 3. THIẾT BỊ SẢN XUẤT (Equipments)
-- Theo tiêu chuẩn GMP, mọi công đoạn phải ghi rõ thực hiện trên máy móc nào.
CREATE TABLE Equipments (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE, -- Mã máy (vd: EQP-DRY-01)
    EquipmentName NVARCHAR(200) NOT NULL,      -- Tên máy (vd: Máy sấy tầng sôi)
    Status NVARCHAR(50) DEFAULT 'Ready',      -- Trạng thái (Sẵn sàng, Bảo trì, Đang chạy)
    LastMaintenanceDate DATETIME2            -- Ngày bảo trì gần nhất
);
GO
