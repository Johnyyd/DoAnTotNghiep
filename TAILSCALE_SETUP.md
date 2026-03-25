# 🐙 Tailscale Access Configuration - GMP-WHO System

## 📋 Tổng quan

Hệ thống GMP-WHO đã được cấu hình để truy cập từ xa thông qua Tailscale VPN mesh. Các services chạy trong Docker containers và được expose qua ports cục bộ.

## 🌐 Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host Machine                           │
│  Tailscale IP: 100.89.137.3                                    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Docker Bridge Network: gmp-network                       │ │
│  │                                                                     │ │
│  │  ┌─────────────┐   ┌─────────────┐      ┌─────────────┐ ┌─────────┐ │ │
│  │  │  Frontend   │   │  Mobile App │─────▶│   Backend   │ │ Database│ │ │
│  │  │  :80        │   │  :80 (8081) │      │  :5000      │ │ :1433   │ │ │
│  │  └─────────────┘   └─────────────┘      └─────────────┘ └─────────┘ │ │
│  │      (nginx)        (flutter-web)            (API)      (SQL Server)│ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

## 🔌 Ports Mapped to Host (Tailscale Accessible)

| Service | Container Port | Host Port | Access via Tailscale |
|---------|---------------|-----------|---------------------|
| **Frontend (Nginx)** | 80 | 80 | `http://100.89.137.3` |
| **Mobile App (Flutter)** | 80 | 8081 | `http://100.89.137.3:8081` |
| **Backend API** | 5000 | 5001 | `http://100.89.137.3:5001` |
| **SQL Server** | 1433 | 1434 | `100.89.137.3,1434` |

## 🚀 Cách Truy Cập

### 1. Web Frontend (Admin Interface)
```
URL: http://100.89.137.3
```
- Giao diện quản trị React
- Tự động proxy API requests qua `/api/` đến backend
- Single Page Application với routing phía client

### 2. Mobile App (eBMR - Tablet/Android)
```
URL: http://100.89.137.3:8081
```
- Giao diện thao tác cho công nhân dưới xưởng
- Tích hợp Flutter Web để dễ dùng trên thiết bị di động với browser

### 3. Backend API Direct
```
URL: http://100.89.137.3:5001
```
- REST API endpoints
- Health check: `http://100.89.137.3:5001/api/health`
- Không có Swagger UI (đã tắt để đơn giản)
- API documentation xem trong code hoặc `README.md`

### 3. Database Connection (from other Tailscale nodes)
```
Server: 100.89.137.3,1434
Database: GMP_WHO_DB
Username: sa
Password: GMP_Strong@Passw0rd123
```
- Dùng SQL Server Management Studio, Azure Data Studio, hoặc connection string:
```
Server=100.89.137.3,1434;Database=GMP_WHO_DB;User Id=sa;Password=GMP_Strong@Passw0rd123;TrustServerCertificate=true
```

## 📦 Docker Setup Commands

### Quick Start (All-in-One)
```bash
cd /home/tringuyen/openclaw-app/workspace/DoAnTotNghiep
docker-compose up -d
```

### Or Manual Start
```bash
# 1. Ensure network exists
docker network create gmp-network 2>/dev/null || true

# 2. Start SQL Server
docker run -d --name gmp-sqlserver \
  --network gmp-network \
  -e ACCEPT_EULA=Y \
  -e SA_PASSWORD=GMP_Strong@Passw0rd123 \
  -p 1434:1433 \
  -v $(pwd)/DATABASE:/var/opt/mssql/backup:ro \
  mcr.microsoft.com/mssql/server:2022-latest

# 3. Build and start Backend
cd GMP_System/GMP_System
docker build -t gmp-who-api .
cd ../..
docker run -d --name gmp-api \
  --network gmp-network \
  -p 5001:5000 \
  -e "ConnectionStrings__DefaultConnection=Server=gmp-sqlserver;Database=GMP_WHO_DB;User Id=sa;Password=GMP_Strong@Passw0rd123;TrustServerCertificate=true" \
  gmp-who-api

# 4. Build and start Frontend
cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
docker build -t gmp-who-frontend .
cd ../..
docker run -d --name gmp-frontend \
  --network gmp-network \
  -p 80:80 \
  -e VITE_API_URL=/ \
  gmp-who-frontend
```

## 🔍 Verify Services

```bash
# Check all containers
docker ps

# Check logs
docker logs gmp-api
docker logs gmp-frontend
docker logs gmp-sqlserver

# Test health endpoint
curl http://localhost:5001/api/health

# Test frontend
curl -I http://localhost
```

## ⚙️ Configuration Details

### Backend (C# .NET 8)
- **Image:** `gmp-who-api`
- **Port:** 5000 (internal), 5001 (host mapping)
- **Environment:**
  - `ConnectionStrings__DefaultConnection`: SQL Server connection
  - `Jwt__Key`: JWT secret for authentication
  - `ASPNETCORE_ENVIRONMENT=Development`
- **Features:**
  - Audit Log Interceptor (EF Core)
  - State Machine validation
  - Health check endpoint at `/api/health`
  - Repositories + Unit of Work pattern

### Frontend (React + TypeScript + Vite)
- **Image:** `gmp-who-frontend`
- **Port:** 80 (nginx)
- **Build args:**
  - `VITE_API_URL=/` (uses nginx proxy)
- **Tech Stack:**
  - React 18 + TypeScript
  - React Router v6
  - TanStack Query
  - Tailwind CSS
  - Axios
- **Pages:**
  - Dashboard
  - Materials (CRUD)
  - Recipes (placeholder)
  - Production Orders (placeholder)
  - Batches (placeholder)
  - Traceability (placeholder)

### Database (SQL Server 2022)
- **Image:** `mcr.microsoft.com/mssql/server:2022-latest`
- **Port:** 1433 (internal), 1434 (host)
- **Authentication:** SA account
- **Initialization:**
  - Auto-run `init.sql` from backend container
  - Seed data from `seed.sql`

## 🌍 Tailscale Notes

- **All services are bound to 0.0.0.0** via Docker port mappings
- Tailscale assigns IP `100.89.137.3` to this host
- Any device in your Tailscale network can access:
- Frontend: `http://100.89.137.3`
  - Mobile App: `http://100.89.137.3:8081`
  - Backend API: `http://100.89.137.3:5001`
  - Database: `100.89.137.3,1434` (需要 SQL Server client)
- **Firewall:** Ensure your host firewall allows inbound on ports 80, 5001, 1434 from Tailscale subnet (100.89.0.0/16 typically)

## 🔐 Security Considerations

⚠️ **DEVELOPMENT ONLY** - For production:

1. Change default SA password
2. Use environment variables for secrets (not hardcoded)
3. Enable HTTPS (nginx SSL termination or Traefik)
4. Implement proper authentication (JWT + refresh tokens)
5. Restrict database access (firewall rules)
6. Use Docker secrets or HashiCorp Vault
7. Enable audit logging properly
8. Implement RBAC in application

## 🐛 Troubleshooting

### Frontend shows blank page
- Check browser console for errors
- Verify API connectivity: `curl http://localhost/api/health` (should proxy to backend)
- Check nginx logs: `docker logs gmp-frontend`

### Backend API not accessible
- Check if container running: `docker ps | grep gmp-api`
- Check logs: `docker logs gmp-api`
- Test health: `curl http://localhost:5001/api/health`
- Verify port mapping: `docker port gmp-api`

### Database connection fails
- Ensure SQL Server is healthy: `docker logs gmp-sqlserver`
- Test connection from backend container:
  ```bash
  docker exec gmp-api /opt/mssql-tools/bin/sqlcmd -S gmp-sqlserver -U SA -P 'GMP_Strong@Passw0rd123' -Q 'SELECT @@SERVERNAME'
  ```
- Check if database exists: `SELECT name FROM sys.databases WHERE name = 'GMP_WHO_DB'`

### Cannot access from other Tailscale nodes
- Verify Tailscale is running on host: `tailscale status`
- Check firewall: `sudo ufw status` or `iptables -L`
- Test from another node: `curl http://100.89.137.3/api/health`

## 📚 Additional Documentation

- `README.md` - Full project documentation
- `PROJECT_STRUCTURE.md` - Codebase structure
- `DOCKER_DEPLOYMENT.md` - Docker deployment basics
- `FRONTEND_DEV.md` - Frontend development guide

---

**Last Updated:** 2025-03-09
**Version:** 1.0.0
**Tailscale Host IP:** 100.89.137.3
