/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   Schema Cơ sở dữ liệu cơ bản
   Mục đích: Định nghĩa toàn bộ các bảng, khóa chính, khóa ngoại 
   của hệ thống theo quy trình chuẩn của nhà máy Dược.
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -------------------------------------------------------------------------
-- 0. DỌN DẸP DỮ LIỆU CŨ (THEO THỨ TỰ NGƯỢC KHÓA NGOẠI)
-- -------------------------------------------------------------------------
PRINT 'Cleaning up existing tables...';
IF OBJECT_ID('BatchProcessParameterValue', 'U') IS NOT NULL DROP TABLE BatchProcessParameterValue;
IF OBJECT_ID('QualityTests', 'U') IS NOT NULL DROP TABLE QualityTests;
IF OBJECT_ID('MaterialUsage', 'U') IS NOT NULL DROP TABLE MaterialUsage;
IF OBJECT_ID('BatchProcessLogs', 'U') IS NOT NULL DROP TABLE BatchProcessLogs;
IF OBJECT_ID('ProductionBatches', 'U') IS NOT NULL DROP TABLE ProductionBatches;
IF OBJECT_ID('ProductionOrders', 'U') IS NOT NULL DROP TABLE ProductionOrders;
IF OBJECT_ID('InventoryLots', 'U') IS NOT NULL DROP TABLE InventoryLots;
IF OBJECT_ID('RecipeBom', 'U') IS NOT NULL DROP TABLE RecipeBom;
IF OBJECT_ID('StepParameters', 'U') IS NOT NULL DROP TABLE StepParameters;
IF OBJECT_ID('RecipeRouting', 'U') IS NOT NULL DROP TABLE RecipeRouting;
IF OBJECT_ID('Recipes', 'U') IS NOT NULL DROP TABLE Recipes;
IF OBJECT_ID('Materials', 'U') IS NOT NULL DROP TABLE Materials;
IF OBJECT_ID('Equipments', 'U') IS NOT NULL DROP TABLE Equipments;
IF OBJECT_ID('ProductionAreas', 'U') IS NOT NULL DROP TABLE ProductionAreas;
IF OBJECT_ID('UomConversions', 'U') IS NOT NULL DROP TABLE UomConversions;
IF OBJECT_ID('UnitOfMeasure', 'U') IS NOT NULL DROP TABLE UnitOfMeasure;
IF OBJECT_ID('AppUsers', 'U') IS NOT NULL DROP TABLE AppUsers;
GO

-- -------------------------------------------------------------------------
-- 1. Bảng AppUsers: Quản lý người dùng, nhân viên trong nhà máy
-- Lưu trữ thông tin tài khoản đăng nhập, họ tên và vai trò để phân quyền
-- theo từng chức năng và công đoạn (QA, Nhân viên, Quản lý).
-- -------------------------------------------------------------------------
CREATE TABLE AppUsers (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE, -- Định danh người dùng duy nhất
    FullName NVARCHAR(100) NOT NULL,      -- Tên thật của nhân viên để hiển thị lên chữ ký, báo cáo
    Role NVARCHAR(50) NOT NULL,          -- Cấp quyền bảo mật (Admin, QA_QC, Operator, ProductionManager)
    IsActive BIT DEFAULT 1,               -- Soft delete: 1 - Đang làm việc, 0 - Nghỉ việc (Cấm xóa vật lý)
    PasswordHash NVARCHAR(MAX),          -- Mật khẩu đã được mã hóa Hash an toàn
    CreatedAt DATETIME2 DEFAULT GETDATE(),-- Thời gian tạo tài khoản
);

-- -------------------------------------------------------------------------
-- 2. Bảng UnitOfMeasure: Danh mục đơn vị đo lường (UoM)
-- Hệ thống chuẩn hóa đơn vị để dễ dàng kiểm soát hao hụt và tính toán công thức.
-- -------------------------------------------------------------------------
CREATE TABLE UnitOfMeasure (
    UomId INT PRIMARY KEY IDENTITY(1,1),
    UomName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200)
);

-- -------------------------------------------------------------------------
-- 15. Bảng UomConversions: Từ điển Đối soát tỷ lệ Đơn Vị Tính toán
-- Giải quyết bài toán quy chiếu linh hoạt theo cấp số nhân lúc mua vật tư
-- so với khối lượng cân xuất phát tính cấp số lẻ xuống dây chuyền phân xưởng.
-- -------------------------------------------------------------------------
CREATE TABLE UomConversions (
    ConversionId INT PRIMARY KEY IDENTITY(1,1),
    FromUomId INT REFERENCES UnitOfMeasure(UomId),    -- Đơn vị đầu cần quy chuẩn (Lớn)
    ToUomId INT REFERENCES UnitOfMeasure(UomId),      -- Đơn vị tiếp nhận sau phép chia (Nhỏ)
    ConversionFactor DECIMAL(18, 6) NOT NULL,         -- Tỉ lệ số lượng toán học (vd: Nếu quy đổi Kg ra Gram, ghi hệ số 1000)
    Note NVARCHAR(200)                                -- Lời bình để giải phẫu tránh sai sót đơn vị
);

-- -------------------------------------------------------------------------
-- 3. THIẾT BỊ SẢN XUẤT (Equipments)
-- -------------------------------------------------------------------------
CREATE TABLE ProductionAreas (
    AreaId INT PRIMARY KEY IDENTITY(1,1),
    AreaCode VARCHAR(50) NOT NULL UNIQUE,
    AreaName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500)
);
-- Theo tiêu chuẩn GMP, mọi công đoạn phải ghi rõ thực hiện trên máy móc nào.
CREATE TABLE Equipments (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE, -- Mã máy (vd: EQP-DRY-01)
    EquipmentName NVARCHAR(200) NOT NULL,      -- Tên máy (vd: Máy sấy tầng sôi)
    TechnicalSpecification NVARCHAR(300),      -- Đặc tính kỹ thuật/năng suất
    UsagePurpose NVARCHAR(300),                -- Công dụng/sử dụng cho
    AreaId INT REFERENCES ProductionAreas(AreaId), -- Khu vực đặt thiết bị

);

-- -------------------------------------------------------------------------
-- 4. Bảng Materials: Danh mục Vựng tập nguyên vật liệu và Sản phẩm
-- Nắm giữ thông tin danh mục về mọi nguyên liệu thô, tá dược, bao bì 
-- và cả thành phẩm đầu ra chờ xuất kho.
-- -------------------------------------------------------------------------
CREATE TABLE Materials (
    MaterialId INT PRIMARY KEY IDENTITY(1,1),
    MaterialCode VARCHAR(50) NOT NULL UNIQUE, -- Mã SKU vật tư nội bộ nhà máy
    MaterialName NVARCHAR(200) NOT NULL,      -- Tên thương mại / tên danh pháp của vật tư
    Type NVARCHAR(50) CHECK (Type IN ('RawMaterial', 'Packaging', 'FinishedGood', 'Intermediate')), -- Phân loại mục đích sử dụng
    BaseUomId INT REFERENCES UnitOfMeasure(UomId), -- Khóa liên kết tới bảng Đơn vị đo lường gốc của vật tư
    IsActive BIT DEFAULT 1,                   -- Đánh dấu trạng thái kinh doanh/sử dụng của vật tư
    TechnicalSpecification NVARCHAR(500),                -- Tiêu chuẩn kĩ thuật
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2                       -- Lưu thời điểm diễn ra tác động cập nhật thuộc tính
);

-- -------------------------------------------------------------------------
-- 5. Bảng Recipes: Công thức gốc sản xuất (Master Recipe)
-- Tài liệu công thức do bộ phận R&D hoặc Cấp cao ban hành. 
-- Một công thức sẽ chế biến ra một Thành phẩm cụ thể ở mức BatchSize cho trước.
-- -------------------------------------------------------------------------
CREATE TABLE Recipes (
    RecipeId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId),  -- Khóa liên kết tới mã Thành phẩm đầu ra
    VersionNumber INT DEFAULT 1,                      -- Phiên bản công thức (để update lịch sử công thức an toàn)
    BatchSize DECIMAL(18, 2) NOT NULL,               -- Cỡ mẻ làm chuẩn cho công thức (ví dụ: công thức này dành cho 100 kg)
    Status NVARCHAR(50) DEFAULT 'Draft',            -- Phân loại trạng thái phê duyệt (Draft, Approved, Obsolete - hết hạn)
    ApprovedBy INT REFERENCES AppUsers(UserId),       -- Người thẩm định, chịu trách nhiệm ban hành (QA/QC)
    ApprovedDate DATETIME2,                           -- Lịch sử ngày chốt duyệt lệnh công thức
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    EffectiveDate DATETIME2,                          -- Ngày bắt đầu cho phép áp dụng xuống xưởng thực tế
    Note NVARCHAR(500)                                -- Lời dặn dò, lưu ý
);

-- -------------------------------------------------------------------------
-- 6. Bảng RecipeBom: Cấu trúc Định mức vật tư (BOM)
-- Chứa danh sách các loại nguyên liệu thô và tỷ lệ cần thiết 
-- cấu thành nên một công thức (Recipe) ở mức cụ thể.
-- -------------------------------------------------------------------------
CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),       -- Định mức thuộc về Công thức nào?
    MaterialId INT REFERENCES Materials(MaterialId), -- Vật tư cụ thể đóng góp vào BOM
    Quantity DECIMAL(18, 4) NOT NULL,               -- Số lượng lý thuyết cần xuất kho để nấu mẻ chuẩn
    UomId INT REFERENCES UnitOfMeasure(UomId),       -- Đơn vị của con số định mức Quantity
    WastePercentage DECIMAL(5, 2) DEFAULT 0,         -- % Khấu hao được bù phòng hờ rớt vãi lúc làm (Tiêu chuẩn GMP)
    Note NVARCHAR(200)                               -- Chú ý riêng cho việc xử lý nguyên liệu này (vd: tránh sáng, độ ẩm)
);

-- -------------------------------------------------------------------------
-- 7. Bảng RecipeRouting: Lộ trình và các bước công đoạn (Quy trình sản xuất)
-- Định nghĩa 1 công thức phải trải qua các thủ tục, các bước nấu, đánh, sấy liên tiếp.
-- -------------------------------------------------------------------------
CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),      -- Quy trình dùng để diễn giải cho Công thức nào
    StepNumber INT NOT NULL,                        -- Số thứ tự các bước phải làm (1, 2, 3...)
    StepName NVARCHAR(100) NOT NULL,                -- Tên vắn tắt công đoạn thao tác (vd: Trộn tá dược, sấy mẻ)
    DefaultEquipmentId INT REFERENCES Equipments(EquipmentId), -- Khuyến nghị dùng hệ thống loại thiết bị máy nào
    EstimatedTimeMinutes INT,                      -- Dự trù tổng thời gian gian chạy máy (Tính bằng Phút)
    Description NVARCHAR(500),                      -- Mô tả văn bản các thao tác công nhân cần lấy làm chuẩn
    NumberOfRouting INT DEFAULT 1,                   -- Số lần thực thực thi mặc định (Loop support)
    CONSTRAINT CK_RecipeRouting_NumberOfRouting CHECK (NumberOfRouting >= 1)
);

-- -------------------------------------------------------------------------
-- 7b. Bảng StepParameters: Thông số kiểm tra tiêu chuẩn cho từng bước
-- -------------------------------------------------------------------------
CREATE TABLE StepParameters (
    ParameterId INT PRIMARY KEY IDENTITY(1,1),
    RoutingId INT REFERENCES RecipeRouting(RoutingId), -- Tham chiếu tới bước quy trình
    ParameterName NVARCHAR(100) NOT NULL,             -- Tên thông số (vd: Nhiệt độ sấy)
    Unit NVARCHAR(50),                                -- Đơn vị tính (vd: °C, v/p)
    MinValue DECIMAL(18, 4),                          -- Ngưỡng dưới cho phép
    MaxValue DECIMAL(18, 4),                          -- Ngưỡng trên cho phép
    IsCritical BIT DEFAULT 1,                         -- Có phải thông số trọng yếu (CCP) hay không
    Note NVARCHAR(200)                                -- Ghi chú hướng dẫn kiểm tra
);

-- -------------------------------------------------------------------------
-- 8. Bảng ProductionOrders: Lệnh sản xuất do Kế hoạch sản xuất ban ra
-- Văn bản pháp lý số hóa lệnh xưởng phải hoàn thành khối lượng sản phẩm cho trước.
-- -------------------------------------------------------------------------
CREATE TABLE ProductionOrders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE,          -- Mã lệnh cấp xuống xưởng (vd: PO-2026-001)
    RecipeId INT REFERENCES Recipes(RecipeId),      -- Sản xuất dựa trên hồ sơ công thức (Recipe) nào
    PlannedQuantity DECIMAL(18, 4) NOT NULL,        -- Khối lượng yêu cầu trả hàng từ phòng kinh doanh
    ActualQuantity DECIMAL(18, 4),                  -- Khối lượng thực tế thu hồi
    StartDate DATETIME2 NOT NULL,                   -- Hạn lịch bắt đầu nổ máy
    EndDate DATETIME2,                              -- Lịch bàn giao sản phẩm dự kiến
    Status NVARCHAR(50) DEFAULT 'Draft',            -- Luồng giám sát tiến độ (Draft, Approved, InProcess, Completed, Hold, Cancelled)
    CreatedBy INT REFERENCES AppUsers(UserId),      -- Quản lý đã khai sinh lệnh
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(500)                              -- Yêu cầu kèm theo lô này (Nhiệt độ phòng, Ưu tiên gấp...)
);

-- -------------------------------------------------------------------------
-- 9. Bảng ProductionBatches: Quản lý chi tiết Mẻ/Lô thực tế (Batches)
-- Một lệnh sản xuất 1000kg có thể được chia nhỏ làm 10 mẻ Batch nhỏ (100kg/mẻ),
-- hệ thống sẽ theo dõi và bảo chứng dữ liệu của từng mẻ lô nhỏ độc lập này.
-- -------------------------------------------------------------------------
CREATE TABLE ProductionBatches (
    BatchId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT REFERENCES ProductionOrders(OrderId),-- Lô siêu nhỏ nhưng thuộc lệnh tổng nào
    BatchNumber VARCHAR(50) NOT NULL UNIQUE,         -- Số Lô thực tế in nổi lên hộp thuốc (Ví dụ: 112026)
    Status NVARCHAR(50) DEFAULT 'Scheduled',         -- Tình trạng tác nghiệp của phần lô (Scheduled, InProcess, Completed, OnHold)
    ManufactureDate DATETIME2,                       -- Ngày sản xuất thực tế dập trên vỏ chai
    EndTime DATETIME2,                               -- Thời điểm kết thúc mẻ
    ExpiryDate DATETIME2,                            -- Hạn sử dụng của sản phẩm
    CurrentStep INT DEFAULT 1,                       -- Điểm chốt chặn: Lô đang xử lý, hoặc ách tắc ở bước quy trình thứ mấy
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- -------------------------------------------------------------------------
-- 10. Bảng BatchProcessLogs: Nhật ký công đoạn sản xuất (Electronic Batch Record - eBMR)
-- Lưu trữ lại bằng chứng thao tác của người công nhân đối với từng công đoạn của mỗi mẻ.
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessLogs (
    LogId BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),-- Ghi chép này trích xuất từ phần lô sản xuất nào
    RoutingId INT REFERENCES RecipeRouting(RoutingId),-- Liên kết cứng tới công đoạn quy trình
    EquipmentId INT REFERENCES Equipments(EquipmentId),-- Máy thực tế người dùng đã chọn chạy mẻ
    OperatorId INT REFERENCES AppUsers(UserId),       -- Chữ ký điện tử đối chiếu nhân viên chịu trách nhiệm chạy máy
    StartTime DATETIME2,                              -- Ràng buộc thời gian bấm đồng hồ (Start)
    EndTime DATETIME2,                                -- Chốt thời khắc công đoạn kết thúc nghiệp thu
    ResultStatus NVARCHAR(50),                        -- Trạng thái kết quả (Passed, Failed, PendingQC)
    ParametersData NVARCHAR(MAX),                     -- Dữ liệu JSON thông số vận hành máy
    Notes NVARCHAR(MAX),                              -- Phân trần, giải trình sự cố kỹ thuật hoặc hao hụt
    IsDeviation BIT DEFAULT 0,                        -- Đánh dấu nếu có sai lệch thông số
    VerifiedById INT REFERENCES AppUsers(UserId),     -- Người thẩm định (QA/QC)
    VerifiedDate DATETIME2,                           -- Ngày thẩm định
    NumberOfRouting INT DEFAULT 1                     -- Số lần thực thi thực tế (Attempt/Iteration count)
);

-- -------------------------------------------------------------------------
-- 10b. Bảng BatchProcessParameterValue: Giá trị thực tế của thông số
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessParameterValue (
    ValueId BIGINT PRIMARY KEY IDENTITY(1,1),
    LogId BIGINT REFERENCES BatchProcessLogs(LogId), -- Tham chiếu tới nhật ký công đoạn
    ParameterId INT REFERENCES StepParameters(ParameterId), -- Tham chiếu tới định nghĩa thông số
    ActualValue DECIMAL(18, 4),                     -- Giá trị đo được thực tế
    RecordedDate DATETIME2 DEFAULT GETDATE(),       -- Thời điểm ghi nhận
    Note NVARCHAR(500)                              -- Ghi chú riêng cho từng thông số (nếu có)
);

-- -------------------------------------------------------------------------
-- 11. Bảng InventoryLots: Quản lý Bồn chứa / Kho lưu trữ truy vết chất lượng (Traceability)
-- Theo dõi chính xác lượng tồn kho nguyên vật liệu phân mảnh cực kỳ chi tiết 
-- tới từng hộp hóa chất nhập về từ nhà cung cấp riêng biệt.
-- -------------------------------------------------------------------------
CREATE TABLE InventoryLots (
    LotId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId), -- Bồn chứa đang quản lý chủng loại chất gì
    LotNumber VARCHAR(50) NOT NULL UNIQUE,           -- Số kiểm soát mã lô của bên bán/nhà cung cấp cấp
    QuantityCurrent DECIMAL(18, 4) NOT NULL,         -- Lượng đang tồn đọng thực tế ở thời điểm hiện tại (Cập nhật realtime)
    ManufactureDate DATETIME2,                       -- Thời điểm chất được ra lò (Hóa đơn sản xuất)
    ExpiryDate DATETIME2 NOT NULL,                   -- Hạn dùng nghiêm ngặt GMP bắt buộc phải tuân theo vòng đời lô hóa chất
    QCStatus NVARCHAR(50) DEFAULT 'Pending',         -- Trạng thái được phép xuất kho? (Pending: Đang test QA, Released: Đã pass QC, Rejected: Cấm xài)
    SupplierName NVARCHAR(200),                      -- Thông tin thực tế của đại lý buôn thuốc/nguyên liệu
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- -------------------------------------------------------------------------
-- 12. Bảng MaterialUsage: Lịch sử Cấp phát kho và Xử lý hao hụt
-- Ràng buộc lô hóa chất cụ thể trong kho được lấy bao nhiêu kilogam 
-- đổ vào công đoạn của Mẻ thành phẩm cụ thể nào. Dữ liệu quý giá nhất quy trình truy vết (Trace).
-- -------------------------------------------------------------------------
CREATE TABLE MaterialUsage (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    InventoryLotId INT REFERENCES InventoryLots(LotId),
    PlannedAmount DECIMAL(18, 4),                     -- Khối lượng dự tính từ BOM
    ActualAmount DECIMAL(18, 4) NOT NULL,              -- Khối lượng cấp phát thực tế
    UsedDate DATETIME2 DEFAULT GETDATE(),
    DispensedBy INT REFERENCES AppUsers(UserId),
    Timestamp DATETIME2 DEFAULT GETDATE(),            -- Thời điểm ghi nhận hệ thống
    Note NVARCHAR(200)
);

-- -------------------------------------------------------------------------
-- 13. Bảng QualityTests: Nhật ký Thử nghiệm và Kiểm định (Dành riêng cho QA/QC)
-- Lưu lại chỉ số kiểm định đối với từng Lot nguyên liệu lúc đón đầu nhập kho, 
-- hoặc lấy mẫu test trong quá trình luân chuyển đóng gói mẻ sản phẩm.
-- -------------------------------------------------------------------------
CREATE TABLE QualityTests (
    TestId INT PRIMARY KEY IDENTITY(1,1),
    InventoryLotId INT REFERENCES InventoryLots(LotId),-- Cuộc xét nghiệm giành riêng cho thùng nguyên liệu, lô thành phẩm nào
    TestName NVARCHAR(100),         -- Tên khoa học của kỹ thuật xét nghiệm phòng vật lý (Độ ẩm, Phổ quang, Kích thước hạt)
    ResultValue NVARCHAR(200),      -- Trị số kết quả cuối cùng thu về từ phòng Lab trả mộc
    PassStatus BIT DEFAULT 1,       -- Đánh giá QC (1: Vượt tiêu chuẩn, 0: Thi trượt)
    TestedBy INT REFERENCES AppUsers(UserId), -- Người lấy mẫu trắc nghiệm
    TestDate DATETIME2 DEFAULT GETDATE()      -- Ngày bàn trắc nghiệm nghiệm thu
);


PRINT 'Centralized Master Schema Created Successfully.';