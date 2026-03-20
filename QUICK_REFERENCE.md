# 🎯 GMP-WHO System - Quick Reference

## ✅ Current Status: ALL SERVICES RUNNING

| Service | Status | Port | Tailscale Access |
|---------|--------|------|------------------|
| Frontend (Nginx) | ✅ Up | 80 | `http://100.89.137.3` |
| Mobile App (Flutter) | ✅ Up | 8081 | `http://100.89.137.3:8081` |
| Backend API (.NET) | ✅ Up | 5001 → 5000 | `http://100.89.137.3:5001` |
| SQL Server | ✅ Up | 1434 → 1433 | `100.89.137.3,1434` |

## 🚀 Quick Start Commands

```bash
# Navigate to project
cd ~/openclaw-app/workspace/DoAnTotNghiep

# Option 1: Start manually (recommended for now)
./start-gmp-backend.sh    # Starts SQL Server + Backend
./start-gmp-frontend.sh   # Starts Frontend

# Option 2: Using docker-compose (future)
docker-compose up -d

# Verify
curl http://localhost:5001/api/health
curl http://localhost  # Should show HTML
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `README.md` | Full project documentation (Vietnamese) |
| `TAILSCALE_SETUP.md` | Tailscale access guide (this file) |
| `PROJECT_STRUCTURE.md` | Codebase structure |
| `DOCKER_DEPLOYMENT.md` | Docker deployment basics |
| `docker-compose.yml` | Full orchestration config |
| `start-gmp-backend.sh` | Backend startup script |
| `start-gmp-frontend.sh` | Frontend startup script |
| `DATABASE/init.sql` | Database schema init |
| `DATABASE/seed.sql` | Sample data |

## 🔗 URLs

| Environment | Frontend | Mobile App | Backend API | Health Check |
|-------------|----------|------------|-------------|--------------|
| **Localhost** | http://localhost | http://localhost:8081 | http://localhost:5001 | `http://localhost:5001/api/health` |
| **Tailscale** | http://100.89.137.3 | http://100.89.137.3:8081 | http://100.89.137.3:5001 | `http://100.89.137.3:5001/api/health` |

## 🏗️ Architecture

```
Frontend (React + Nginx) -> port 80
Mobile App (Flutter Web) -> port 8081
    ↓ (proxy /api/ hoặc truy vấn trực tiếp)
Backend (.NET API) -> port 5000 (container), 5001 (host)
    ↓ (SQL Server)
Database (SQL Server 2022) -> port 1433 (container), 1434 (host)
```

## 📊 API Endpoints (Implemented)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/materials` | List materials |
| GET | `/api/materials/{id}` | Get material by ID |
| POST | `/api/materials` | Create material |
| PUT | `/api/materials/{id}` | Update material |
| DELETE | `/api/materials/{id}` | Delete material |
| GET | `/api/recipes` | List recipes |
| GET | `/api/production-orders` | List production orders |
| ... | more endpoints | See `src/services/api.ts` |

## 🧪 Testing

```bash
# Test backend health
curl http://100.89.137.3:5001/api/health

# Test materials API
curl http://100.89.137.3:5001/api/materials

# Test from frontend (through nginx proxy)
curl http://100.89.137.3/api/health
```

## 🐛 Troubleshooting

### Services not running?
```bash
docker ps  # Check containers
docker logs gmp-api      # Backend logs
docker logs gmp-frontend # Frontend logs
docker logs gmp-sqlserver # Database logs
```

### Port conflicts?
- If port 80 is busy, change frontend mapping to `-p 8080:80`
- If port 5001 is busy, change backend mapping to `-p 5002:5000`
- Update `VITE_API_URL` accordingly

### Database not initializing?
```bash
# Check if DB exists
docker exec gmp-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U SA -P 'GMP_Strong@Passw0rd123' \
  -Q "SELECT name FROM sys.databases"
```

### Frontend shows blank?
- Check browser console (F12)
- Verify API connectivity: `curl http://localhost/api/health`
- Rebuild frontend: `cd .../PharmaceuticalProcessingManagementSystem && docker build -t gmp-who-frontend .`

## 🔐 Default Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| SQL Server | sa | GMP_Strong@Passw0rd123 | Development only |
| JWT | N/A | GMP_WHO_Default_Secret_Key_Minimum_32_Characters_Long_123456789 | Change in production |

## 📱 Next Steps

- [ ] Implement full CRUD for Recipes (BOM + Routing)
- [ ] Implement Production Orders with state machine
- [ ] Implement Batch execution (mobile/tablet UI)
- [ ] Implement Traceability reports
- [ ] Add authentication (JWT)
- [ ] Add digital signature feature
- [ ] Implement QC deviation alerts
- [ ] Add audit log viewing

## 🎨 Frontend Development

```bash
cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
npm install
npm run dev    # Development server on http://localhost:5173
npm run build  # Production build
```

Tech: React 18, TypeScript, Vite, Tailwind CSS, React Router v6, TanStack Query.

## 🖥️ Backend Development

```bash
cd GMP_System/GMP_System
dotnet restore
dotnet run
```

Tech: .NET 8, EF Core, SQL Server, Repository + Unit of Work pattern.

---

**Status**: ✅ All services running and accessible via Tailscale
**Last Updated**: 2025-03-09 17:20 GMT+7
**Tailscale IP**: 100.89.137.3
