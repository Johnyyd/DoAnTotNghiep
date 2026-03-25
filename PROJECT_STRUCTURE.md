# GMP-WHO Pharmaceutical Processing Management System

## 📂 Cấu trúc dự án

```
DoAnTotNghiep/
│
├── 📘 README.md                          # Tài liệu dự án chính (đã cập nhật)
├── 📘 DOCKER_DEPLOYMENT.md              # Hướng dẫn deploy Docker
│
├── 🗄️ DATABASE/                         # SQL scripts cho database
│   ├── init.sql                         # Main initialization (gồm tất cả modules)
│   ├── seed.sql                         # Sample data
│   ├── MasterData.sql                   # Unit of Measure, Materials, Equipments, Users
│   ├── ProcessDefinition.sql           # Recipes & Routing
│   ├── ProductionExecution.sql         # Production Orders & Batches
│   ├── InventoryTraceability.sql       # Inventory lots, material usage
│   ├── MaterialQC.sql                  # Quality control data
│   ├── SystemAudit.sql                 # Audit logging system
│   ├── AuditTrail.sql                  # Audit trail triggers
│   ├── AdvancedLogic.sql               # Triggers, SPs, Functions
│   ├── Immutability.sql                # Data immutability constraints
│   ├── UomConversion.sql               # Unit conversion tables
│   └── UserManagement.sql              # User roles & permissions
│
├── 🔧 GMP_System/                       # Backend C# .NET 8
│   └── GMP_System/
│       ├── Controllers/                # API Controllers
│       │   ├── ProductionOrdersController.cs
│       │   ├── ProductionBatchesController.cs
│       │   ├── MaterialsController.cs
│       │   ├── RecipesController.cs
│       │   ├── BatchProcessLogsController.cs
│       │   ├── InventoryLotsController.cs
│       │   ├── MaterialUsagesController.cs
│       │   ├── SystemAuditLogsController.cs
│       │   └── HealthController.cs     # Health check endpoint
│       │
│       ├── Entities/                   # Entity Framework entities
│       │   ├── ProductionOrder.cs
│       │   ├── ProductionBatch.cs
│       │   ├── Material.cs
│       │   ├── Recipe.cs & RecipeBom.cs & RecipeRouting.cs
│       │   ├── MaterialBatch.cs
│       │   ├── InventoryLot.cs
│       │   ├── BatchProcessLog.cs
│       │   ├── SystemAuditLog.cs
│       │   ├── AppUser.cs
│       │   ├── UnitOfMeasure.cs
│       │   ├── Equipment.cs
│       │   ├── UomConversion.cs
│       │   ├── MaterialUsage.cs
│       │   ├── GmpContext.cs           # DbContext
│       │   └── ...
│       │
│       ├── Interfaces/                 # Repository & Unit of Work interfaces
│       │   ├── IGenericRepository.cs
│       │   ├── IUnitOfWork.cs
│       │   └── ...
│       │
│       ├── Repositories/               # EF Core repositories implementation
│       │   ├── GenericRepository.cs
│       │   ├── UnitOfWork.cs
│       │   └── ...
│       │
│       ├── Interceptors/               # EF Core interceptors (Audit Log)
│       │   └── AuditLogInterceptor.cs
│       │
│       ├── GMP_System.csproj          # .NET 8 project file
│       ├── Program.cs                 # Application startup
│       └── Dockerfile                 # Multi-stage Docker build
│
├── 🌐 PharmaceuticalProcessingManagementSystem/  # Frontend React + TypeScript
│   └── PharmaceuticalProcessingManagementSystem/
│       ├── src/
│       │   ├── components/            # Reusable UI components
│       │   ├── pages/                 # Admin pages (Material, Recipe, Production, etc.)
│       │   ├── services/              # API clients
│       │   └── store/                 # State management (Redux/Zustand)
│       ├── public/                    # Static assets
│       ├── package.json
│       ├── Dockerfile                 # Multi-stage build + nginx
│       └── nginx.conf                 # Nginx configuration for SPA
│
├── 📱 MobileApp/                       # Mobile App (Flutter Web) cho công nhân thao tác eBMR
│
├── 🚀 start-gmp-backend.sh            # Script KHỞI ĐỘNG backend (DB + API)
├── 🚀 start-gmp-frontend.sh           # Script KHỞI ĐỘNG frontend
├── 🚀 makeall.sh                      # Menu script tổng hợp
│
├── 🐳 docker-compose.yml              # Orchesrate tất cả services (KHÔNG DÙNG start- scripts)
├── 🐳 .dockerignore
│
└── 📄 LICENSE                         # Giấy phép dự án

```

## 🔧 Yêu cầu hệ thống

- Docker 20.10+
- Docker Compose v2.20+
- Node.js 18+ (để build frontend locally)
- .NET 8 SDK (để build backend locally)

## 🚀 Khởi động nhanh với Docker Compose

```bash
# 1. Build và start tất cả services
docker-compose up -d

# 2. Kiểm tra logs
docker-compose logs -f

# 3. Truy cập
# - Frontend: http://localhost:8080
# - Mobile App: http://localhost:8081
# - Backend API: http://localhost:5001
# - Swagger: http://localhost:5001/swagger
```

Hoặc dùng menu script:

```bash
./makeall.sh
```

## 🏗️ Kiến trúc tổng quan

```
┌─────────────────────────────────────────────────────────────┐
│   FRONTEND (React)     │      MOBILE APP (Flutter)  │
│   Port: 8080           │      Port: 8081            │
├────────────────────────┴────────────────────────────┤
│                     BACKEND (.NET 8 API)                  │
│  Port: 5000 (container) → 5001 (host)                     │
│  Controllers → Services → Repositories → SQL Server       │
├─────────────────────────────────────────────────────────────┤
│                     DATABASE (SQL Server)                 │
│  Port: 1433 (container) → 1434 (host)                     │
│  GMP_WHO_DB                                                │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Tính năng chính theo GMP-WHO

- ✅ Audit Trail (tự động ghi log mọi thay đổi qua EF Core Interceptor)
- ✅ State Machine nghiêm ngặt (Draft → Approved → InProcess → Hold → Completed)
- ✅ BOM đệ quy (cấu trúc phân cấp với self-referencing RecipeBOM)
- ✅ Data Locking (Recipe snapshot vào ProductionOrder khi Approved)
- ✅ Traceability (truy xuất lô thành phẩm → nguyên liệu đầu vào)
- ✅ QC in-process với cảnh báo deviation ±5%
- ✅ Digital Signature (mô phỏng chữ ký điện tử khi Approve)
- ✅ Immutability constraints (không cho phép hard delete logs)

## 📝 Ghi chú triển khai

- **Backend** sử dụng Domain-Driven Design (DDD) với Clean Architecture
- **Database** dùng SQL Server 2022 với constraints mạnh để đảm bảo GMP compliance
- **AuditLogInterceptor** ghi tự động mọi INSERT/UPDATE/DELETE
- **Soft Delete** được áp dụng cho tất cả master data
- **Health Check** endpoint tại `/api/health` cho monitoring

## 📚 Documentation

- Xem `README.md` cho đầy đủ thông tin nghiệp vụ và yêu cầu GMP
- Xem `DOCKER_DEPLOYMENT.md` cho hướng dẫn chi tiết về Docker

---

**Phát triển bởi:** Tri Nguyen Minh  
**Đề tài:** Xây dựng hệ thống quản lý quy trình chế biến thuốc theo tiêu chuẩn GMP-WHO  
**Ngày:** 2026-03-09
