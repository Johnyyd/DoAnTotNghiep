# 🐳 Docker Deployment Guide - GMP-WHO System

Hướng dẫn nhanh để chạy toàn bộ hệ thống GMP-WHO bằng Docker.

## 📦 Các Services

| Service | Port | Image | Mô tả |
|---------|------|-------|-------|
| **gmp-sqlserver** | 1434 | mcr.microsoft.com/mssql/server:2022-latest | Database SQL Server |
| **gmp-api** | 5001 | gmp-who-api (custom) | Backend .NET API |
| **gmp-frontend** | 8080 | gmp-who-frontend (custom) | Web Admin Interface |
| **gmp-mobile** | 8081 | gmp-who-mobile (custom) | Mobile Tablet Interface (Flutter Web) |

## 🚀 Cách 1: Docker Compose (Khuyến nghị)

Dự án thiết lập song song 2 cấu trúc: `docker-compose.yml` (Chuẩn Production) và `docker-compose.override.yml` (Bật tính năng Hot Reloading cho môi trường Dev).

### Chạy môi trường Development (Có Hot Reload)
Mặc định Docker sẽ tự động gộp 2 file lại, ánh xạ mã nguồn từ máy bạn vào Container:

```bash
# Build và start tất cả (Bắt buộc thêm --build mỗi khi gỡ file override ra/vào)
docker-compose up -d --build

# Ghi chú Hot Reload: 
# - Bạn sửa code React/Flutter/C#, ứng dụng sẽ tự động cập nhật ngay trên trình duyệt máy ảo.
```

### Chạy môi trường Production (Không có Hot Reload)
Chạy kịch bản thực tế (Mã React/Flutter được đóng gói Nginx), tiêu thụ RAM thấp nhất:

```bash
# Chỉ định rõ chỉ chạy file gốc, phớt lờ file override
docker-compose -f docker-compose.yml up -d --build

# Xem logs
docker-compose logs -f

# Dừng tất cả
docker-compose down
```

## 🚀 Cách 2: Scripts riêng lẻ

### 1. Start Backend (Database + API)
```bash
./start-gmp-backend.sh
```

Script này sẽ:
- Tạo network `gmp-network`
- Start SQL Server container (port 1434)
- Khởi tạo database với script SQL trong thư mục `DATABASE/`
- Build và chạy backend API container (port 5001)

### 2. Start Frontend
```bash
./start-gmp-frontend.sh
```

Script này sẽ:
- Build frontend image từ React/Vue project
- Start frontend container (port 80)
- Connect vào network `gmp-network` với backend

Hoặc dùng `makeall.sh` để có menu tương tác:

```bash
./makeall.sh
```

## 🔗 Truy Cập Ứng Dụng

| URL | Mô tả |
|-----|-------|
| http://localhost:8080 | Web Admin (Frontend) |
| http://localhost:8081 | Mobile App (Tablet Interface) |
| http://localhost:5001/swagger | Swagger UI (Backend API docs) |
| http://localhost:5001/scalar | Scalar API Reference |
| http://localhost:5001/api/health | Health check endpoint |

## 💾 Database

- **Server:** `localhost,1434` (từ host) hoặc `gmp-sqlserver,1433` (từ container)
- **Database:** `GMP_WHO_DB`
- **Username:** `sa`
- **Password:** `GMP_Strong@Passw0rd123`

## 📁 Cấu Trúc Volume Mounts

```
DoAnTotNghiep/
├── DATABASE/                    # SQL scripts mounted vào SQL Server container
│   ├── init.sql                 # Main initialize script (includes all modules)
│   ├── seed.sql                 # Sample data
│   ├── MasterData.sql           # Master data tables
│   ├── ProcessDefinition.sql    # Recipes & Routing
│   ├── ProductionExecution.sql  # Production orders & batches
│   └── ... (other SQL files)
├── GMP_System/GMP_System/       # Backend source code
├── PharmaceuticalProcessingManagementSystem/  # Frontend source code
```

## 🛠️ Xây Dựng Lại Docker Images

Khi source code thay đổi:

```bash
# Backend
cd GMP_System/GMP_System
docker build -t gmp-who-api .

# Frontend
cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
docker build --build-arg VITE_API_URL=/api -t gmp-who-frontend .

# Mobile
cd MobileApp
docker build -t gmp-who-mobile .
```

Hoặc dùng docker-compose:

```bash
docker-compose build
```

## 🔍 Troubleshooting

### SQL Server không start được
- Kiểm tra port 1434 đã free chưa: `netstat -tlnp | grep 1434`
- Xem logs: `docker logs gmp-sqlserver`

### API không kết nối được database
- Kiểm tra SQL Server đã sẵn sàng: `docker exec gmp-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'GMP_Strong@Passw0rd123' -Q "SELECT @@SERVERNAME"`
- Kiểm tra connection string trong environment variables

### Frontend không load API
- Kiểm tra `VITE_API_URL` environment variable trong frontend container
- Trong môi trường dev, frontend gọi direct `http://localhost:5001`
- Trong production (Docker), frontend gọi `http://gmp-api:5000`

## 📋 Clean Up

```bash
# Dừng và xóa containers
docker-compose down

# Xóa cả volumes (dữ liệu database)
docker-compose down -v

# Xóa images
docker rmi gmp-who-api gmp-who-frontend

# Xóa network
docker network rm gmp-network
```

## 🔐 Security Notes

- Đây là môi trường development. Thay đổi passwords trong production:
  - SA_PASSWORD trong `docker-compose.yml`
  - Jwt__Key trong backend environment
  - Dùng HTTPS trong production
- Database không exposed trực tiếp ra internet (chỉ port 1434 trên localhost)
- SQL Server authentication dùng SA account (không dùng Windows Auth trong container)

## 📊 Ports Summary

| Port | Service | Description |
|------|---------|-------------|
| 8080 | gmp-frontend | HTTP (Web Admin) |
| 8081 | gmp-mobile | HTTP (Mobile Tablet Interface) |
| 1434 | gmp-sqlserver | SQL Server TCP |
| 5001 | gmp-api | Backend REST API |

## 🏗️ Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────────┐
│                     HOST MACHINE                           │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐   ┌─────────────┐   │
│  │   Browser   │───▶│  Frontend   │──▶│   Backend   │   │
│  │ (localhost:80) │  │ (gmp-frontend)│  │ (gmp-api:5001)│   │
│  └─────────────┘    └─────────────┘   └─────────────┘   │
│                                                   │       │
│                                                   │       │
│                                          ┌─────────────┐ │
│                                          │   SQL       │ │
│                                          │  Server     │ │
│                                          │ (gmp-sqlserver)│
│                                          └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                   Docker Network: gmp-network
```

**Happy Coding!** 🎯
