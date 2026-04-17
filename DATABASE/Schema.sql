/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO SYSTEM)
   TÀI LIỆU CHI TIẾT CƠ SỞ DỮ LIỆU (DATABASE SCHEMA SPECIFICATION)
   
   Hệ thống thiết kế theo mô hình 3 lớp chính:
   1. MASTER DATA (Dữ liệu gốc): Người dùng, Vật tư, Máy móc, Công thức.
   2. PRODUCTION FLOW (Luồng sản xuất): Lệnh sản xuất, Mẻ sản xuất.
   3. COMPLIANCE & TRACEABILITY (Tuân thủ & Truy vết): eBMR, Inventory, Audit Trail.
========================================================================= */

-- -------------------------------------------------------------------------
-- 1. Bảng AppUsers: QUẢN LÝ NHÂN SỰ & PHÂN QUYỀN (Auth & Authorization)
-- Mục đích: Lưu trữ toàn bộ danh sách nhân viên tham gia vào hệ thống.
-- Ứng dụng GMP: Đóng vai trò là "Chữ ký điện tử" (Electronic Signature) 
-- cho mọi thao tác phê duyệt hoặc thực hiện công đoạn.
-- -------------------------------------------------------------------------
CREATE TABLE AppUsers (
    UserId INT PRIMARY KEY IDENTITY (1, 1),
    Username VARCHAR(50) NOT NULL UNIQUE, -- Tên đăng nhập dùng để xác thực.
    FullName NVARCHAR (100) NOT NULL, -- Họ và tên đầy đủ để in lên Hồ sơ lô và Báo cáo.
    Role NVARCHAR (50) NOT NULL, -- Vai trò: QA_QC (Kiểm soát chất lượng), Operator (Công nhân), Admin (Quản trị).
    IsActive BIT DEFAULT 1, -- Trạng thái: 1-Đang làm việc, 0-Nghỉ việc/Vô hiệu hóa (Tuyệt đối không xóa vật lý).
    PasswordHash NVARCHAR (MAX), -- Mật khẩu mã hóa để bảo mật thông tin.
    CreatedAt DATETIME2 DEFAULT GETDATE (), -- Ngày khởi tạo tài khoản.
    LastLogin DATETIME2 -- Vết đăng nhập cuối để kiểm soát bảo mật truy cập.
);

-- -------------------------------------------------------------------------
-- 2. Bảng UnitOfMeasure (UoM): ĐƠN VỊ ĐO LƯỜNG
-- Mục đích: Chuẩn hóa đơn vị tính toán trong toàn nhà máy để tránh nhầm lẫn 
-- giữa các bộ phận (Kho dùng Kg, Sản xuất dùng Gram, Kinh doanh dùng Thùng).
-- -------------------------------------------------------------------------
CREATE TABLE UnitOfMeasure (
    UomId INT PRIMARY KEY IDENTITY (1, 1),
    UomName NVARCHAR (50) NOT NULL, -- Tên đơn vị (kg, g, viên, vỉ, chai).
    Description NVARCHAR (200) -- Giải thích rõ đơn vị (Ví dụ: Kilogram, Gram).
);

-- -------------------------------------------------------------------------
-- 3. Bảng Equipments: DANH MỤC THIẾT BỊ SẢN XUẤT
-- Mục đích: Quản lý danh sách máy móc được phép sử dụng trong sản xuất.
-- Ứng dụng GMP: Máy móc phải được thẩm định (Qualification) và vệ sinh trước khi dùng.
-- -------------------------------------------------------------------------
CREATE TABLE Equipments (
    EquipmentId INT PRIMARY KEY IDENTITY (1, 1),
    EquipmentCode VARCHAR(50) NOT NULL UNIQUE, -- Mã máy (Ví dụ: DRY-01 cho máy sấy số 1).
    EquipmentName NVARCHAR (200) NOT NULL, -- Tên máy (Ví dụ: Máy sấy tầng sôi).
    Status NVARCHAR (50) DEFAULT 'Ready', -- Trạng thái: Ready, InUse, Maintenance, Cleaning.
    LastMaintenanceDate DATETIME2 -- Ngày bảo trì/vệ sinh gần nhất để QA kiểm soát.
);

-- -------------------------------------------------------------------------
-- 4. Bảng Materials: DANH MỤC VẬT TƯ & SẢN PHẨM (SKU Master)
-- Mục đích: Quản lý mọi thứ từ nguyên liệu thô đến thành phẩm.
-- MQH: Liên kết với UnitOfMeasure qua BaseUomId.
-- -------------------------------------------------------------------------
CREATE TABLE Materials (
    MaterialId INT PRIMARY KEY IDENTITY (1, 1),
    MaterialCode VARCHAR(50) NOT NULL UNIQUE, -- Mã vật tư (Mã số quản lý hàng hóa).
    MaterialName NVARCHAR (200) NOT NULL, -- Tên vật tư (Tên hóa học hoặc tên thương mại).
    Type NVARCHAR (50) CHECK (
        Type IN ('RawMaterial', 'Packaging', 'FinishedGood', 'Intermediate')
    ), -- Phân loại: Nguyên liệu thô, Bao bì, Thành phẩm, Bán thành phẩm.
    BaseUomId INT REFERENCES UnitOfMeasure (UomId), -- Đơn vị tính cơ bản (Gốc).
    IsActive BIT DEFAULT 1, -- Trạng thái kinh doanh của mặt hàng.
    Description NVARCHAR (500), -- Thông tin thêm về đặc tính (Ví dụ: Bảo quản < 25 độ C).
    CreatedAt DATETIME2 DEFAULT GETDATE (),
    UpdatedAt DATETIME2
);

-- -------------------------------------------------------------------------
-- 5. Bảng Recipes: CÔNG THỨC GỐC (Master Formula)
-- Mục đích: Lưu trữ bí quyết sản xuất của một loại thuốc.
-- MQH: Liên kết với Materials (Sản phẩm đầu ra) và AppUsers (Người phê duyệt).
-- Ứng dụng GMP: Quản lý phiên bản (Version Control) để tránh dùng nhầm công thức cũ.
-- -------------------------------------------------------------------------
CREATE TABLE Recipes (
    RecipeId INT PRIMARY KEY IDENTITY (1, 1),
    MaterialId INT REFERENCES Materials (MaterialId), -- Liên kết tới Thành phẩm sẽ sản xuất.
    VersionNumber INT DEFAULT 1, -- Số phiên bản (Tăng dần khi có thay đổi công thức).
    BatchSize DECIMAL(18, 2) NOT NULL, -- Quy mô mẻ chuẩn (Ví dụ: Công thức này dùng cho 100,000 viên).
    Status NVARCHAR (50) DEFAULT 'Draft', -- Trạng thái: Draft (Dự thảo), Approved (Đã duyệt), Obsolete (Hết hạn).
    ApprovedBy INT REFERENCES AppUsers (UserId), -- Chữ ký QA/QC phê duyệt công thức này.
    ApprovedDate DATETIME2, -- Thời điểm chốt duyệt để cho phép áp dụng.
    CreatedAt DATETIME2 DEFAULT GETDATE (),
    EffectiveDate DATETIME2, -- Ngày bắt đầu có hiệu lực sản xuất.
    Note NVARCHAR (500)
);

-- -------------------------------------------------------------------------
-- 6. Bảng RecipeBom: ĐỊNH MỨC NGUYÊN LIỆU (BOM)
-- Mục đích: Chi tiết danh sách thành phần nguyên liệu cho một công thức.
-- MQH: Liên kết với Recipes và Materials (Nguyên liệu thô).
-- -------------------------------------------------------------------------
CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY (1, 1),
    RecipeId INT REFERENCES Recipes (RecipeId), -- Thuộc về công thức nào?
    MaterialId INT REFERENCES Materials (MaterialId), -- Nguyên liệu gì?
    Quantity DECIMAL(18, 4) NOT NULL, -- Số lượng lý thuyết cần dùng.
    UomId INT REFERENCES UnitOfMeasure (UomId), -- Đơn vị tính của số lượng trên.
    WastePercentage DECIMAL(5, 2) DEFAULT 0, -- Tỷ lệ hao hụt cho phép (GMP Standard).
    Note NVARCHAR (200)
);

-- -------------------------------------------------------------------------
-- 7. Bảng RecipeRouting: QUY TRÌNH QUÁ TRÌNH (Process Flow)
-- Mục đích: Định nghĩa các bước sản xuất tiếp diễn (Ví dụ: Bước 1: Sấy, Bước 2: Cân).
-- MQH: Liên kết với Recipes và Equipments (Máy móc mặc định).
-- -------------------------------------------------------------------------
CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY (1, 1),
    RecipeId INT REFERENCES Recipes (RecipeId), -- Thuộc về công thức nào?
    StepNumber INT NOT NULL, -- Thứ tự thực hiện (1, 2, 3...).
    StepName NVARCHAR (100) NOT NULL, -- Tên công đoạn (Ví dụ: Pha chế, Sấy tầng sôi, Dập viên).
    DefaultEquipmentId INT REFERENCES Equipments (EquipmentId), -- Thiết bị chuẩn được dùng cho công đoạn này.
    EstimatedTimeMinutes INT, -- Thời gian ước tính thực hiện bước này.
    Description NVARCHAR (500), -- Hướng dẫn thao tác chi tiết cho công nhân.
    NumberOfRouting INT DEFAULT 1 -- Số lần thực hiện lặp lại (Nếu có).
);

-- -------------------------------------------------------------------------
-- 8. Bảng StepParameters: THÔNG SỐ KIỂM SOÁT CÔNG ĐOẠN (CPP - Critical Process Parameters)
-- Mục đích: Quy định các chỉ số kỹ thuật phải đạt được trong mỗi bước.
-- MQH: Liên kết với RecipeRouting.
-- -------------------------------------------------------------------------
CREATE TABLE StepParameters (
    ParameterId INT PRIMARY KEY IDENTITY (1, 1),
    RoutingId INT REFERENCES RecipeRouting (RoutingId), -- Tham chiếu tới bước quy trình cụ thể.
    ParameterName NVARCHAR (100) NOT NULL, -- Tên thông số (Ví dụ: Nhiệt độ sấy, Tốc độ cánh khuấy).
    Unit NVARCHAR (50), -- Đơn vị đo của thông số (Ví dụ: độ C, vòng/phút).
    MinValue DECIMAL(18, 4), -- Giá trị tối thiểu cho phép.
    MaxValue DECIMAL(18, 4), -- Giá trị tối đa cho phép.
    IsCritical BIT DEFAULT 1, -- Đánh dấu nếu là Thông số trọng yếu (Ảnh hưởng trực tiếp chất lượng).
    Note NVARCHAR (200) -- Lưu ý cách đo hoặc dụng cụ đo.
);

-- -------------------------------------------------------------------------
-- 9. Bảng ProductionOrders: LỆNH SẢN XUẤT
-- Mục đích: Lệnh từ phòng kế hoạch yêu cầu sản xuất số lượng hàng cụ thể.
-- MQH: Liên kết với Recipes và AppUsers.
-- -------------------------------------------------------------------------
CREATE TABLE ProductionOrders (
    OrderId INT PRIMARY KEY IDENTITY (1, 1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE, -- Mã số lệnh (Ví dụ: PO-2026-001).
    RecipeId INT REFERENCES Recipes (RecipeId), -- Sản xuất theo công thức nào.
    PlannedQuantity DECIMAL(18, 4) NOT NULL, -- Tổng số lượng hàng cần sản xuất.
    ActualQuantity DECIMAL(18, 4), -- Số lượng thực tế thu hồi sau khi xong. (Dùng để tính hiệu suất/hao hụt).
    StartDate DATETIME2 NOT NULL, -- Ngày bắt đầu dự kiến.
    EndDate DATETIME2, -- Ngày kết thúc dự kiến.
    Status NVARCHAR (50) DEFAULT 'Draft', -- Trạng thái: Draft, Approved, InProcess, Completed, Hold, Cancelled.
    CreatedBy INT REFERENCES AppUsers (UserId), -- Người tạo lệnh.
    CreatedAt DATETIME2 DEFAULT GETDATE (),
    Note NVARCHAR (500)
);

-- -------------------------------------------------------------------------
-- 10. Bảng ProductionBatches: MẺ SẢN XUẤT (Batches)
-- Mục đích: Chia nhỏ Lệnh sản xuất thành các mẻ thực tế (Để quản lý rủi ro và truy vết).
-- MQH: Liên kết với ProductionOrders.
-- Ứng dụng GMP: Mỗi mẻ/lô thuốc phải có một mã số lô duy nhất (Batch Number).
-- -------------------------------------------------------------------------
CREATE TABLE ProductionBatches (
    BatchId INT PRIMARY KEY IDENTITY (1, 1),
    OrderId INT REFERENCES ProductionOrders (OrderId), -- Trực thuộc lệnh sản xuất nào.
    BatchNumber VARCHAR(50) NOT NULL UNIQUE, -- SỐ LÔ SẢN XUẤT (In trên bao bì thuốc).
    Status NVARCHAR (50) DEFAULT 'Scheduled', -- Trạng thái: Scheduled, InProcess, Completed, OnHold.
    ManufactureDate DATETIME2, -- Ngày sản xuất thực tế.
    EndTime DATETIME2, -- Ngày kết thúc thực tế.
    ExpiryDate DATETIME2, -- Hạn sử dụng (Tính toán dựa trên Recipe và MfgDate).
    CurrentStep INT DEFAULT 1, -- Bước hiện tại trong quy trình sản xuất.
    CreatedAt DATETIME2 DEFAULT GETDATE ()
);

-- -------------------------------------------------------------------------
-- 11. Bảng BatchProcessLogs: NHẬT KÝ HỒ SƠ LÔ ĐIỆN TỬ (eBMR - Electronic Batch Record)
-- Mục đích: Ghi lại toàn bộ bằng chứng thao tác thực tế tại xưởng.
-- MQH: Liên kết với ProductionBatches, RecipeRouting, Equipments và AppUsers (Operator).
-- Ứng dụng GMP: Là trái tim của hệ thống tuân thủ, ghi lại "Ai làm? Làm gì? Khi nào? Kết quả?".
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessLogs (
    LogId BIGINT PRIMARY KEY IDENTITY (1, 1),
    BatchId INT REFERENCES ProductionBatches (BatchId), -- Thuộc mẻ nào.
    RoutingId INT REFERENCES RecipeRouting (RoutingId), -- Là công đoạn nào.
    EquipmentId INT REFERENCES Equipments (EquipmentId), -- Sử dụng máy nào thực tế.
    OperatorId INT REFERENCES AppUsers (UserId), -- CHỮ KÝ CÔNG NHÂN THỰC HIỆN.
    StartTime DATETIME2, -- Thời điểm bắt đầu bấm đồng hồ chạy.
    EndTime DATETIME2, -- Thời điểm chốt hoàn thành.
    ResultStatus NVARCHAR (50), -- Kết quả: Passed, Failed, PendingQC.
    ParametersData NVARCHAR (MAX), -- Lưu một "bản chụp" JSON của toàn bộ thông số lúc đó.
    Notes NVARCHAR (MAX), -- Ghi chú sự cố hoặc giải trình thao tác.
    IsDeviation BIT DEFAULT 0, -- Đánh dấu nếu có sai lệch (Cần QA thẩm duyệt sai lệch).
    VerifiedById INT REFERENCES AppUsers (UserId), -- CHỮ KÝ QA/QC THẨM ĐỊNH LẠI CÔNG ĐOẠN.
    VerifiedDate DATETIME2, -- Thời điểm chốt duyệt QC.
    NumberOfRouting INT DEFAULT 1 -- Lần thực hiện thứ mấy (Nếu phải làm lại bước này).
);

-- -------------------------------------------------------------------------
-- 12. Bảng BatchProcessParameterValue: GIÁ TRỊ THÔNG SỐ THỰC TẾ
-- Mục đích: Lưu trữ dữ liệu thô của từng thông số kỹ thuật đơn lẻ để vẽ biểu đồ và phân tích.
-- MQH: Liên kết với BatchProcessLogs và StepParameters.
-- -------------------------------------------------------------------------
CREATE TABLE BatchProcessParameterValue (
    ValueId BIGINT PRIMARY KEY IDENTITY (1, 1),
    LogId BIGINT REFERENCES BatchProcessLogs (LogId), -- Tham chiếu tới hồ sơ bước.
    ParameterId INT REFERENCES StepParameters (ParameterId), -- Là thông số nào (Nhiệt độ, tốc độ...).
    ActualValue DECIMAL(18, 4), -- CON SỐ ĐO ĐƯỢC THỰC TẾ.
    RecordedDate DATETIME2 DEFAULT GETDATE (),
    Note NVARCHAR (500)
);

-- -------------------------------------------------------------------------
-- 13. Bảng InventoryLots: QUẢN LÝ TỒN KHO THEO LÔ (Traceability)
-- Mục tiêu: Quản lý nguyên liệu trong kho theo từng "Lô nhập" (Lot) để truy xuất nguồn gốc.
-- MQH: Liên kết với Materials.
-- Ứng dụng GMP: Chỉ các lô có QCStatus = 'Released' mới được phép dùng cho sản xuất.
-- -------------------------------------------------------------------------
CREATE TABLE InventoryLots (
    LotId INT PRIMARY KEY IDENTITY (1, 1),
    MaterialId INT REFERENCES Materials (MaterialId), -- Loại nguyên liệu gì.
    LotNumber VARCHAR(50) NOT NULL UNIQUE, -- Số lô của nhà cung cấp.
    QuantityCurrent DECIMAL(18, 4) NOT NULL, -- Số lượng đang còn lại trong kho.
    ManufactureDate DATETIME2, -- Ngày sản xuất của nguyên liệu.
    ExpiryDate DATETIME2 NOT NULL, -- Hạn dùng nguyên liệu.
    QCStatus NVARCHAR (50) DEFAULT 'Pending', -- Trạng thái: Pending (Chờ kiểm), Released (Cho phép dùng), Rejected (Loại bỏ).
    SupplierName NVARCHAR (200), -- Tên nhà cung cấp.
    CreatedAt DATETIME2 DEFAULT GETDATE ()
);

-- -------------------------------------------------------------------------
-- 14. Bảng MaterialUsage: CẤP PHÁT & SỬ DỤNG NGUYÊN LIỆU (Reconciliation)
-- Mục đích: Ghi lại việc lấy bao nhiêu nguyên liệu từ Lô kho nào để đổ vào Mẻ nào.
-- MQH: Liên kết với ProductionBatches và InventoryLots.
-- Ứng dụng GMP: Đây là xương sống để thực hiện "Truy xuất ngược" (Trace back) khi có sự cố.
-- -------------------------------------------------------------------------
CREATE TABLE MaterialUsage (
    UsageId INT PRIMARY KEY IDENTITY (1, 1),
    BatchId INT REFERENCES ProductionBatches (BatchId), -- Mẻ thuốc nào tiêu thụ.
    InventoryLotId INT REFERENCES InventoryLots (LotId), -- Thùng nguyên liệu nào bị xuất đi.
    QuantityUsed DECIMAL(18, 4) NOT NULL, -- Số lượng thực tế đã múc đi.
    UsedDate DATETIME2 DEFAULT GETDATE (),
    DispensedBy INT REFERENCES AppUsers (UserId), -- Chữ ký nhân viên thủ kho/người cân.
    Note NVARCHAR (200)
);

-- -------------------------------------------------------------------------
-- 15. Bảng QualityTests: KIỂM TRA CHẤT LƯỢNG (QC Tests)
-- Mục đích: Kết quả xét nghiệm của phòng Lab đối với một lô hàng.
-- MQH: Liên kết với InventoryLots.
-- -------------------------------------------------------------------------
CREATE TABLE QualityTests (
    TestId INT PRIMARY KEY IDENTITY (1, 1),
    InventoryLotId INT REFERENCES InventoryLots (LotId), -- Xét nghiệm lô nào.
    TestName NVARCHAR (100), -- Tên phép thử (Ví dụ: Độ hòa tan, Định lượng hoạt chất).
    ResultValue NVARCHAR (200), -- Giá trị kết quả Lab trả về.
    PassStatus BIT DEFAULT 1, -- 1: Đạt, 0: Không đạt.
    TestedBy INT REFERENCES AppUsers (UserId), -- Nhân viên kiểm nghiệm.
    TestDate DATETIME2 DEFAULT GETDATE ()
);

-- -------------------------------------------------------------------------
-- 16. Bảng SystemAuditLog: DẤU VẾT KIỂM TOÁN (Compliance Audit Trail)
-- Mục đích: Ghi lại lịch sử chỉnh sửa dữ liệu (Ai sửa? Sửa gì? Giá trị cũ/mới?).
-- Ứng dụng GMP: Đáp ứng quy tắc ALCOA+ của FDA/WHO (Tính toàn vẹn dữ liệu). Bảng này KHÔNG ĐƯỢC PHÉP SỬA/XÓA.
-- -------------------------------------------------------------------------
CREATE TABLE SystemAuditLog (
    AuditId BIGINT PRIMARY KEY IDENTITY (1, 1),
    TableName NVARCHAR (100), -- Tên bảng bị thay đổi.
    RecordId NVARCHAR (100), -- ID của bản ghi bị thay đổi.
    Action NVARCHAR (50), -- INSERT, UPDATE, DELETE.
    OldValue NVARCHAR (MAX), -- Dữ liệu cũ (Dạng JSON).
    NewValue NVARCHAR (MAX), -- Dữ liệu mới (Dạng JSON).
    ChangedBy INT REFERENCES AppUsers (UserId), -- Người thực hiện thay đổi.
    ChangedDate DATETIME2 DEFAULT GETDATE () -- Thời điểm thay đổi.
);

-- -------------------------------------------------------------------------
-- 17. Bảng UomConversions: ĐỔI ĐƠN VỊ TÍNH
-- Mục đích: Cung cấp tỷ lệ quy đổi (Ví dụ: 1 thùng = 12 hộp, 1 kg = 1000g).
-- MQH: Liên kết với UnitOfMeasure.
-- -------------------------------------------------------------------------
CREATE TABLE UomConversions (
    ConversionId INT PRIMARY KEY IDENTITY (1, 1),
    FromUomId INT REFERENCES UnitOfMeasure (UomId), -- Đơn vị nguồn.
    ToUomId INT REFERENCES UnitOfMeasure (UomId), -- Đơn vị đích.
    ConversionFactor DECIMAL(18, 6) NOT NULL, -- Công thức: ToAmount = FromAmount * ConversionFactor.
    Note NVARCHAR (200)
);