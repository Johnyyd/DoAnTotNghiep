# Báo Cáo Đánh Giá Tổng Quan Codebase (Codebase Review)

**Dự án:** Hệ Thống Quản Lý Quy Trình Chế Biến Thuốc - GMP-WHO (Pharmaceutical Processing Management System)
**Ngày đánh giá:** 29/03/2026

---

## 1. Tổng Quan Về Kiến Trúc & Cấu Trúc (Architecture & Structure)

Dự án được thiết kế theo mô hình Microservices/Component-based với sự phân tách rõ ràng giữa các phân hệ: Frontend, Backend, Mobile App và Cơ sở dữ liệu. Kiến trúc hệ thống áp dụng các nguyên tắc của **Domain-Driven Design (DDD)** và **Clean Architecture** (đối với Backend).

### 1.1. Hệ Thống Các Thành Phần

- **Backend (`/GMP_System`):** Xây dựng bằng C# .NET 8. Đảm nhận toàn bộ nghiệp vụ lõi (Master Data, Planning, Execution, Traceability). Cấu trúc tuân theo Clean Architecture với các lớp Entities, Interfaces, Repositories, Application/Services và Controllers.
- **Frontend (`/PharmaceuticalProcessingManagementSystem`):** Xây dựng bằng React + TypeScript, sử dụng Vite làm module bundler. Đóng vai trò là Web Admin để quản lý danh mục (Material, Recipe), kế hoạch sản xuất và theo dõi hệ thống.
- **Mobile App (`/MobileApp`):** Xây dựng bằng Flutter (hiện tại gen ra Flutter Web, cấu hình build chạy nginx). Ứng dụng này hướng tới môi trường Tablet cho công nhân xưởng để ghi nhận quá trình sản xuất thực tế (eBMR - electronic Batch Manufacturing Record).
- **Database (`/DATABASE`):** Microsoft SQL Server 2022. Quản lý toàn bộ thông tin hệ thống. Được định nghĩa qua hàng loạt các script SQL chuyên biệt giúp đảm bảo tính toàn vẹn và nghiệp vụ phức tạp ở tầng DB (Triggers, Stored Procedures).

### 1.2. Môi Trường & Triển Khai (Deployment)

- Áp dụng hệ sinh thái **Docker** qua `docker-compose.yml` và `docker-compose.override.yml` nhằm hỗ trợ song song cho môi trường Production (nhẹ nhàng, độc lập) và Development (có Hot Reloading).
- Có đầy đủ các shell scripts tự động hóa khởi chạy: `makeall.sh`, `start-gmp-backend.sh`, `start-gmp-frontend.sh`. Điều này giúp chuẩn hóa quá trình onboarding cho developer.

---

## 2. Trọng Tâm Chuyên Ngành (Đảm Bảo Chuẩn GMP-WHO)

Phần mềm đã được thiết kế sát với các yêu cầu cốt lõi của tiêu chuẩn **GMP-WHO** trong ngành dược:

- **Audit Trail & Immutability:** Áp dụng `AuditLogInterceptor` ở tằng EF Core (C#) và cấu trúc Soft-delete cho mọi master data. Database cũng đi kèm `AuditTrail.sql` và `Immutability.sql` để thiết lập các constraint chống can thiệp trực tiếp (Hard Delete).
- **Truy xuất nguồn gốc (Traceability):** Quản lý nghiêm ngặt lô nguyên liệu nhập (`MaterialBatches`) cho tới mảng sản xuất (`ProductionBatches`), hỗ trợ thuật toán truy vấn cấu trúc cây định mức đệ quy (Recursive BOM).
- **Kiểm soát vòng đời (State Machine):** Vòng đời các đối tượng, đặc biệt là `ProductionOrder` và `Recipe`, tuân thủ nghiêm ngặt quy trình: *Draft → Approved → InProcess → Hold → Completed*.
- **Data Locking / Snapshot Pattern:** Khi một Lệnh Sản Xuất (Production Order) được "Approved", các thành phần liên quan (Recipe, BOM) sẽ tự động bị "đóng băng" dưới dạng bản sao.

---

## 3. Cấu trúc Thực thi Sản xuất (Production Execution)

Cốt lõi của hệ thống thực thi sản xuất (MES/eBMR) quy định quá trình từ khi có số liệu kế hoạch đến khi đóng mẻ thực tiễn. Dữ liệu được ánh xạ trực tiếp trong Hệ thống qua các thực thể:

- **Lệnh Sản Xuất (`ProductionOrder`)**: Đại diện cho một kế hoạch sản xuất tổng thể (gồm `OrderId`, `OrderCode`, `PlannedQuantity`, `ActualQuantity`). Nó tham chiếu thẳng tới một Công thức (`Recipe`) và có vòng đời theo dõi trạng thái (`Status`, `StartDate`, `EndDate`).
- **Mẻ Sản Xuất (`ProductionBatch`)**: Một Lệnh Sản Xuất có thể được chia tách thành một hoặc nhiều Mẻ độc lập. Mỗi mẻ có mã số riêng (`BatchNumber`), có Ngày sản xuất (`ManufactureDate`), Hạn sử dụng (`ExpiryDate`), và lưu vết bước thực thi hiện tại của riêng mẻ đó (`CurrentStep`).
- **Công Đoạn / Tuyến Việc (`RecipeRouting`)**: Các công đoạn tiêu chuẩn của quá trình tạo ra sản phẩm (Ví dụ: 1. Cân, 2. Trộn, 3. Sấy) được định nghĩa sẵn theo công thức, mô tả tên công đoạn (`StepName`), thời gian ước tính, thiết bị mặc định.
- **Nhật Ký Thực Thi Bước Của Mẻ (`BatchProcessLog`)**: Mỗi khi công nhân xử lý một công đoạn (thuộc tuyến việc), ứng dụng sẽ lưu log vào đây với đầy đủ Dữ kiện của GMP: `StartTime`, `EndTime`, `OperatorId` (người làm), `EquipmentId` (máy nào làm), và đặc biệt là `ParametersData` cùng kết quả kiểm tra định mức (`ResultStatus`).

---

## 4. Đánh Giá Khách Quan Về Các Phân Hệ

### Ưu điểm

- **Tổ chức thư mục (Folder Structure):** Rất khoa học, tách bạch công nghệ Frontend/Backend rõ ràng. Tài liệu cung cấp cũng vô cùng chi tiết (`README.md`, `PROJECT_STRUCTURE.md`, `DOCKER_DEPLOYMENT.md`).
- **Lớp Database cực kỳ mạnh mẽ:** Việc tách Database initialization ra thành các domain scripts: `MasterData.sql`, `InventoryTraceability.sql`, `ProcessDefinition.sql`, v.v. chứng tỏ khả năng tổ chức schema theo Domain Model rất tốt.
- **Khởi tạo dữ liệu (Seeding) thông minh:** Đã chuyển đổi từ Script SQL rời rạc sang logic **EF Core Seeding (C#)**. Điều này đảm bảo tính toàn vẹn dữ liệu tuyệt đối khi khởi chạy trong môi trường Docker, tự động nạp 5 kịch bản lệnh sản xuất (Draft, Approved, InProcess, Hold, Completed) để kiểm thử Mobile UI ngay lập tức.
- **Thiết kế Backend chuẩn chỉ:** Sự hiện diện của thư mục `Interceptors` và `Repositories` cho thấy code rất dễ maintain và testing sau này.
- **Stack công nghệ phù hợp:** Phù hợp xu thế (.NET 8 xử lý concurrency cực tốt, React UI tương tác mượt, Flutter có thể build Tablet).

### Khuyến nghị & Cải thiện

1. **Kiểm thử (Testing):** Đã có bộ kịch bản 5 PO (Scenarios) nạp sẵn trong `Program.cs`. Cần mở rộng thêm các Edge Cases về định mức tiêu hao nguyên liệu (Waste Calculation) và kiểm soát dấu thời gian (Audit Timestamps).
2. **Quản lý biến môi trường (Environment Variables):** Cần đảm bảo các thông tin nhạy cảm (như JWT Secret...) không trực tiếp lưu trong `docker-compose` khi lên Production.
3. **Flutter Web Optimization:** Tablet chạy App cho công nhân cần độ ổn định. Nên cấu hình PWA (Progressive Web App) có tính năng Offline First.

## 5. Kết Luận

Hệ thống hiện tại đã đạt trạng thái **Stable (Ổn định)**. Toàn bộ lỗi 502/Connectivity đã được xử lý triệt để thông qua việc đồng bộ hóa Database Unification. Với 5 kịch bản mẫu đã nạp sẵn, hệ thống đã sẵn sàng cho việc kiểm thử các luồng nghiệp vụ MES/eBMR từ Mobile cho tới Web Admin.
