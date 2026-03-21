# Hệ Thống Quản Lý Quy Trình Chế Biến Thuốc - GMP-WHO

[![GitHub stars](https://img.shields.io/github/stars/Johnyyd/DoAnTotNghiep?style=social)](https://github.com/Johnyyd/DoAnTotNghiep)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![SQL Server](https://img.shields.io/badge/Database-Microsoft%20SQL%20Server-0078F6?logo=microsoft-sql-server)](https://www.microsoft.com/en-us/sql-server)
[![.NET](https://img.shields.io/badge/Backend-ASP.NET%20Core-512BD4?logo=dotnet)](https://dotnet.microsoft.com)

**Đề tài:** Xây dựng hệ thống quản lý quy trình chế biến thuốc theo tiêu chuẩn GMP-WHO

## 📋 Tổng Quan Dự Án

Hệ thống **Pharmaceutical Processing Management System (PPMS)** là một nền tảng toàn diện để quản lý quy trình sản xuất dược phẩm tuân thủ tiêu chuẩn **GMP-WHO** (Good Manufacturing Practice - Tổ chức Y tế Thế giới). Hệ thống tích hợp quản lý sản xuất, kiểm soát chất lượng, truy xuất nguồn gốc và đảm bảo tính toàn vẹn dữ liệu trong môi trường sản xuất dược phẩm khép kín.

---

## 🎯 Yêu Cầu Chức Năng Cốt Lõi

### 1. Quản Lý Dữ Liệu Nguồn (Master Data)
- **BOM (Bill of Materials):** Định mức nguyên vật liệu cho từng sản phẩm, hỗ trợ cấu trúc đệ quy nhiều cấp (thành phẩm → bán thành phẩm → nguyên liệu thô)
- **Recipe (Công thức):** Công thức sản xuất chi tiết với các thành phần, hàm lượng, và điều kiện xử lý
- **Routing (Quy trình sản xuất):** Lộ trình sản xuất với các công đoạn tuần tự: Trộn → Dập viên → Bao phim → Đóng vỉ → ...

### 2. Quản Lý Sản Xuất & Mobile App
- **Production Order (Lệnh sản xuất):** Tạo lệnh sản xuất dựa trên nhu cầu, tự động tính toán nguyên liệu cần thiết từ BOM
- **Batch (Mẻ sản xuất):** Một lệnh sản xuất có thể chia thành nhiều mẻ nhỏ để thực hiện linh hoạt
- **Mobile App (Tablet):** Ứng dụng Flutter cho công nhân ghi chép điều kiện môi trường, cân nguyên liệu và log từng bước sản xuất ngay tại xưởng.

### 3. Kiểm Soát Vật Tư
- Cấp phát nguyên liệu tự động theo định mức đã tính toán
- Kiểm tra nghiêm ngặt: Đúng loại, đúng lô, đủ lượng, chất lượng đạt chuẩn (QC Passed)
- Cảnh báo khi sai lệch ±5% so với định mức

### 4. Theo Dõi Tiến Độ (State Management)
Hệ thống trạng thái máy chặt chẽ:
```
Draft → Approved → In-Process → Hold → Completed
```
- Không cho phép nhảy cóc trạng thái
- Validation nghiêm ngặt ở Backend trước khi chuyển trạng thái
- Ghi nhận đầy đủ ai, khi nào, tại sao thay đổi trạng thái

### 5. Truy Xuất Nguồn Gốc (Traceability)
- Từ lô thành phẩm → truy ngược lại toàn bộ chuỗi nguyên liệu đầu vào
- Hiển thị cây phả hệ chi tiết: Lô nào, nhập từ đâu, ngày nào, chất lượng thế nào
- Đảm bảo tuân thủ yêu cầu GMP: mọi thứ phải được ghi chép lại

---

## 🔧 Yêu Cầu Kỹ Thuật

### Ngôn Ngữ & Nền Tảng
- **Frontend:** React, TypeScript
- **Backend:** C# (.NET Core / .NET 8)
- **Mobile:** Flutter (Dart) - Hỗ trợ Web Tablet và App Android/iOS

### Cơ Sở Dữ Liệu
- **SQL Server:** Cho dữ liệu quan hệ chặt chẽ (Master Data, Orders, Batches)

### Kiến Trúc Hệ Thống
```
┌─────────────────────────────────────────────────────────────┐
│                     WEB ADMIN (Quản lý)                     │
│              React / TS + Vite (Port: 8080)                 │
├─────────────────────────────────────────────────────────────┤
│                     MOBILE APP (Công nhân)                  │
│              Flutter (Dart) (Port: 8081)                    │
├─────────────────────────────────────────────────────────────┤
│                 BACKEND API (C# .NET)                       │
│         Domain-Driven Design (DDD) + Clean Architecture     │
├─────────────────────────────────────────────────────────────┤
│                     SQL Server (Port: 1434)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Tiêu Chuẩn GMP-WHO & Ảnh Hưởng Đến Code

### GMP-WHO Là Gì?
**Good Manufacturing Practice (GMP)** theo khuyến cáo WHO là bộ quy tắc đảm bảo sản phẩm dược phẩm được sản xuất nhất quán, có chất lượng, và an toàn. Trong ngành dược, một sai sót nhỏ có thể gây nguy hiểm tính mạng, do đó mọi bước phải được kiểm soát và **ghi chép lại đầy đủ**.

### Yếu Tố Cốt Lõi Ảnh Hưởng Thiết Kế Phần Mềm

#### 1. Audit Trail (Vết Kiểm Toán)
- **Yêu cầu:** Mọi hành động UPDATE/DELETE phải được ghi nhận: ai làm? khi nào? giá trị cũ là gì? lý do sửa?
- **Implementation:**
  - Không dùng hard delete → dùng Soft Delete (isDeleted flag)
  - Lưu lịch sử thay đổi vào bảng `AuditLogs`
  - Middleware/Interceptor ghi log tự động cho mọi thay đổi

#### 2. State Machine Chặt Chẽ
- **Yêu cầu:** Không cho phép chuyển trạng thái tùy tiện (ví dụ: Draft → In-Process là BẮT BUỘC phải qua Approved)
- **Implementation:**
  - Enum trạng thái với thứ tự cố định
  - Service/Validator kiểm tra transition hợp lệ trước khi lưu
  - Ghi lại người Approved + timestamp + chữ ký điện tử

#### 3. Quản Lý BOM & Đệ Quy
- **Yêu cầu:** BOM có thể nhiều cấp, cần tính toán tổng nguyên liệu từ cấu trúc cây
- **Implementation:**
  - Bảng `BOMItems` với `ParentItemId` (self-referencing)
  - Recursive CTE (SQL Server) hoặc Graph Lookup (MongoDB)
  - Snapshot BOM vào Production Order khi Approved (không cho phép thay đổi sau đó)

#### 4. Khóa Dữ Liệu (Data Locking)
- **Yêu cầu:** Khi Production Order đã Approved, Recipe và BOM gắn liền không được sửa dù công thức gốc có thay đổi
- **Implementation:**
  - Lưu snapshot của Recipe/BOM vào bảng `ProductionOrderDetails`
  - Chỉ cho phép edit Recipe ở trạng thái Draft
  - Versioning cho Master Data

---

## 🔄 Quy Trình Sản Xuất Dược Phẩm Khép Kín

### Các Bước Logic:

1. **Thiết Lập Công Thức (R&D)**
   - Tạo Recipe + BOM + Routing
   - Phê duyệt công thức gốc

2. **Lập Kế Hoạch & Lệnh Sản Xuất (Planning)**
   - Tạo Production Order từ nhu cầu
   - Hệ thống tự động tính toán nguyên liệu cần thiết dựa trên BOM

3. **Cấp Phát Nguyên Liệu (Dispensing)**
   - Kho xuất nguyên liệu theo định lượng đã tính
   - Kiểm tra: Đúng loại, đúng lô, đủ lượng, QC Passed
   - Ghi nhận lô xuất đi (batch/lot tracking)

4. **Thực Hiện Sản Xuất (Execution)**
   - Công nhân thao tác trên Tablet App
   - Bấm nút "Bắt đầu/Kết thúc" cho từng công đoạn trong Routing
   - Nhập số liệu thực tế (thời gian, quantity, notes)

5. **Kiểm Soát Chất Lượng (QC In-Process)**
   - Kiểm tra QC ở mỗi bước quan trọng
   - Nếu đạt mới được phép qua bước tiếp
   - Ghi nhận kết quả QC + chữ ký

6. **Hoàn Thành & Nhập Kho**
   - Production Order chuyển sang Completed
   - Đóng gói thành lô thành phẩm (Finished Goods Batch)
   - Nhập kho tồn

---

## 📦 Cấu Trúc Dự Án

```
DoAnTotNghiep/
├── GMP_System/              # Backend C# .NET API
│   ├── src/
│   │   ├── Domain/         # Entities, Value Objects, Enums
│   │   ├── Application/    # Use Cases, Services, Validators
│   │   ├── Infrastructure/ # Repositories, DB Context, External APIs
│   │   └── WebAPI/         # Controllers, Middleware, Filters
│   ├── tests/
│   └── Dockerfile
│
├── PharmaceuticalProcessingManagementSystem/  # Frontend Web Admin
│   ├── src/
│   │   ├── components/     # React/Vue components
│   │   ├── pages/         # Admin pages
│   │   ├── services/      # API clients
│   │   └── store/         # State management (Redux/Vuex)
│   ├── public/
│   └── package.json
│
├── MobileApp/              # Tablet App (React Native/Flutter)
│   ├── src/
│   │   ├── screens/       # Worker screens
│   │   ├── components/
│   │   └── services/
│   └── android/ios/
│
├── database/
│   ├── scripts/
│   │   ├── 01_init.sql
│   │   ├── 02_tables.sql
│   │   ├── 03_seeds.sql
│   │   └── 04_constraints.sql
│   └── ERD/
│       └── diagram.md
│
├── docs/
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── GMP_COMPLIANCE.md
│
├── tests/
│   ├── integration/
│   ├── e2e/
│   └── fixtures/
│
└── README.md
```

---

## 🗄️ Thiết Kế Cơ Sở Dữ liệu (SQL Server)

### Bảng Chính:

1. **Materials** - Nguyên liệu (quản lý theo lô/batch)
   - MaterialId, Code, Name, Unit, Specification
   - ShelfLife, StorageCondition, MinStock, MaxStock

2. **MaterialBatches** - Lô nhập nguyên liệu
   - BatchNumber, MaterialId, Quantity, ManufactureDate, ExpiryDate
   - QcStatus (Pending/Passed/Failed), QcDate, QcBy

3. **Recipes** - Công thức
   - RecipeId, Code, Name, Version, Status (Draft/Approved)
   - ApprovedBy, ApprovedDate

4. **RecipeDetails (BOM)** - Định mức chi tiết
   - RecipeId, MaterialId, Quantity, Unit, TolerancePercent, ParentItemId (đệ quy)

5. **ProductionOrders** - Lệnh sản xuất
   - OrderId, OrderNumber, ProductId, Quantity, PlannedDate
   - Status (Draft/Approved/InProcess/Hold/Completed), SnapshotRecipe

6. **ProductionBatches** - Mẻ sản xuất
   - BatchId, OrderId, BatchNumber, Quantity, StartDate, EndDate
   - OperatorId, QcStatus

7. **ProcessLogs** - Nhật ký sản xuất & Audit Trail
   - LogId, EntityType, EntityId, Action (Create/Update/Delete)
   - ChangedBy, ChangedAt, OldValue, NewValue, Reason

8. **RoutingSteps** - Bước trong quy trình
   - StepId, RoutingId, StepOrder, StepName, Duration, QcRequired

9. **StepExecutions** - Thực thi công đoạn
   - ExecutionId, BatchId, StepId, StartTime, EndTime, OperatorId
   - ActualQuantity, Notes, QcResult

10. **Users** - Người dùng với role (Admin, QC, Operator, Manager)

---

## 🚀 Phương Pháp Tiếp Cận Triển Khai

### Bước 1: Thiết Kế Database
- Tạo ERD chi tiết với tất cả quan hệ
- Viết SQL scripts: init, tables, constraints, indexes
- Seed data mẫu cho testing

### Bước 2: Xây Dựng Backend (C# .NET)
- **Domain Layer:** Entities, Enums, Domain Events (OrderApproved, BatchCompleted)
- **Application Layer:** Commands/Queries với MediatR, Validators với FluentValidation
- **Infrastructure:** Entity Framework Core với Repository Pattern
- **WebAPI:** RESTful endpoints, JWT authentication, middleware cho audit logging

**Key Services:**
- `ProductionOrderService`: Tạo order, tính toán BOM, chuyển trạng thái
- `MaterialDispensingService`: Cấp phát nguyên liệu, check QC status
- `BatchTrackingService`: Theo dõi mẻ, log quá trình
- `TraceabilityService:** Truy xuất ngược từ finished goods → raw materials

### Bước 3: Xây Dựng Frontend Web Admin (React/Vue)
**Modules:**
- Master Data Management (Materials, Recipes, Routings)
- Planning & Production Orders (tạo, duyệt, theo dõi)
- Dashboard theo dõi tổng quan
- Reports & Traceability (tìm kiếm lô thành phẩm)

### Bước 4: Xây Dựng Mobile App (Tablet)
**Worker-centric:**
- Scan barcode lệnh sản xuất
- Xem công thức và định mức
- Bắt đầu/kết thúc từng công đoạn
- Nhập số liệu thực tế (đổ vào, cân, temperature,...)
- Ghi nhận QC tại chỗ

### Bước 5: Tính Năng Điểm Nhấn (GMP)
1. **Digital Signature**
   - Khi Approve order, yêu cầu nhập lại mật khẩu hoặc OTP
   - Lưu cryptographic signature vào AuditLog

2. **Deviation Alert**
   - So sánh Actual vs Planned với tolerance ±5%
   - Nếu vượt quá → popup cảnh báo + bắt buộc nhập Reason Code
   - Lock batch cho đến khi Manager approve

3. **Full Traceability Report**
   - Input: Finished Goods Batch Number
   - Output: Tree view với tất cả Material Batches đã dùng
   - Export PDF cho FDA/WHO audit

4. **State Machine Validation**
   - Tất cả transition phải qua validator
   - Log mọi thay đổi trạng thái

5. **Immutable Audit Trail**
   - Không cho phép sửa/xóa log
   - Read-only view cho auditor

---

## ✅ Ghi Chú Triển Khai

### Lưu Ý Quan Trọng
- **Backend là nơi thực thi nghiệp vụ phức tạp:** Không dễ dãi tin frontend, validation nghiêm ngặt
- **Snapshot pattern:** Khi Approved, lưu frozen copy của Recipe/BOM vào ProductionOrder
- **Performance:** BOM đệ quy có thể lớn, cache calculation results
- **Security:** RBAC (Role-Based Access Control) chi tiết, JWT tokens, HTTPS everywhere
- **Compliance:** Tất cả các exception phải được log, không bao giờ swallow errors

### Testing
- Unit tests cho Domain Services, Validators
- Integration tests cho Repository layer
- E2E tests cho critical paths: Create Order → Approve → Dispense → Produce → Complete

### Deployment
- Dockerize tất cả services
- CI/CD pipeline (GitHub Actions / Azure DevOps)
- SQL Server migrations với DbUp hoặc EF Migrations

---

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

**Phát triển bởi:** Tri Nguyen Minh  
**Đề tài:** Xây dựng hệ thống quản lý quy trình chế biến thuốc theo tiêu chuẩn GMP-WHO  
**Ngày:** 2026-03-09  
**Trạng thái:** Đang phát triển
