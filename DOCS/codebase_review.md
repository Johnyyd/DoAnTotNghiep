**Project Review – Pharmaceutical Processing Management System (PPMS)**
*Location: `/media/tringuyen/DuLieu/GitHub/DoAnTotNghiep`*

---

## 1️⃣ High‑level Architecture (✅ What’s solid)

| Layer | Tech | Comments |
|------|------|----------|
| **Database** | SQL Server 2022 (container `gmp‑sqlserver`, port 1435) | Strong relational engine; scripts for schema, seed data, constraints and audit triggers are already in `DATABASE/`. |
| **Backend API** | C# .NET 8 (`GMP_System/GMP_System`) | Clean‑architecture layout (Domain → Application → Infrastructure). Uses EF Core, generic repos, Unit‑of‑Work, and an `AuditLogInterceptor` for immutable audit trails – exactly what GMP compliance demands. |
| **Web Admin UI** | React + TypeScript (`PharmaceuticalProcessingManagementSystem/`) | SPA built with Vite, packaged into an Nginx container (`gmp‑frontend`). |
| **Mobile Worker App** | Flutter (Web target) (`MobileApp/`) | Tablet‑friendly UI for floor‑staff, using the same API. |
| **Orchestration** | Docker‑Compose (`docker‑compose.yml`) | All services (SQL, API, frontend, mobile) wired via `gmp‑network`. Hot‑reload available via `docker‑compose.override.yml`. |
| **Documentation** | README, PROJECT_STRUCTURE, DOCKER_DEPLOYMENT, API Swagger (`/swagger`) | Provides a clear onboarding path. |

*Sources:* directory tree (`ls -R`), `README.md` overview, `PROJECT_STRUCTURE.md` diagram, `DOCKER_DEPLOYMENT.md` service table.

---

## 2️⃣ Strengths

| Area | Why it matters for a GMP‑compliant system |
|------|-------------------------------------------|
| **Audit Trail** – Interceptor automatically logs every INSERT/UPDATE/DELETE (see `GMP_System/Interceptors/AuditLogInterceptor.cs`). Guarantees traceability. |
| **State‑machine enforcement** – Production order lifecycle (`Draft → Approved → InProcess → Hold → Completed`) is coded in the domain layer, preventing illegal transitions. |
| **Snapshot pattern** – Recipes/BOM are frozen into a `ProductionOrder` when approved, ensuring data immutability after the fact. |
| **Recursive BOM** – Self‑referencing `RecipeBom` tables allow multi‑level material breakdown, a core GMP requirement. |
| **Soft‑delete + immutability** – Master data is never physically removed; audit logs are read‑only, satisfying regulatory retention. |
| **Dockerized dev & prod** – Separate dev (`override.yml`) and prod (`docker‑compose.yml`) configs keep hot‑reload for developers while producing lean images for deployment. |
| **Health endpoint** – `HealthController.cs` exposed at `/api/health` for monitoring. |
| **Swagger UI** – Auto‑generated API docs (`/swagger`) help auditors and external tools understand the contract. |

---

## 3️⃣ Areas for Improvement / Risks

| Category | Issue | Suggested Fix |
|----------|-------|---------------|
| **Secret Management** (✅ Đã giải quyết) | SA password and JWT secret are hard‑coded in `docker‑compose.yml` (`GMP_Strong@Passw0rd123`). | Move them to Docker **secrets** or `.env` files (excluded via `.dockerignore`). Use `env_file:` and reference `${SA_PASSWORD}`. |
| **Database Migrations** (✅ Đã giải quyết) | Schema is applied via raw `.sql` scripts (`DATABASE/init.sql`). Manual script ordering can cause drift. | Adopt **EF Core migrations** (`dotnet ef migrations add …`) and run them on container start (`dotnet ef database update`). Keeps schema in sync with model code. |
| **CI/CD** | No pipeline shown for building, testing, and deploying images. | Add a GitHub Actions workflow: <br>• Build & push Docker images (backend, frontend, mobile). <br>• Run unit‑test suites (C# + Flutter). <br>• Deploy to a staging environment for integration tests. |
| **Testing Coverage** | Project contains `tests/` folders but no indication of automated unit/integration tests. | Implement: <br>• **Backend**: xUnit + Moq for services, integration tests with Testcontainers SQL Server.<br>• **Frontend**: Jest + React Testing Library.<br>• **Mobile**: Flutter widget and integration tests. |
| **API Security** | Only a generic JWT is mentioned; no role‑based policy examples. | Define **RBAC** (Admin, QC, Operator, Manager) in `AppUser` + claim‑based policies (`[Authorize(Roles="QC")]`). Document token issuance in `README`. |
| **Observability** | Logging is present (audit), but no structured logging, metrics, or tracing. | Integrate **Serilog** with JSON output, expose Prometheus metrics (`/metrics`), and add OpenTelemetry tracing for end‑to‑end visibility. |
| **Container Size** (✅ Đã giải quyết) | Backend Dockerfile likely copies the full SDK (`dotnet/sdk`) into the final image. | Use a **multi‑stage build** that outputs a runtime‑only image (`mcr.microsoft.com/dotnet/aspnet:8.0`). Same for frontend (build stage → `nginx:alpine`). |
| **Front‑end Build Caching** (✅ Đã giải quyết) | No `.dockerignore` shown for `node_modules`/`build` artifacts. | Add a `.dockerignore` that excludes `node_modules`, `dist`, `*.log`, and IDE files to keep images lean and build faster. |
| **Mobile Offline** | Tablet workers may lose connectivity on the floor. | Implement **offline sync** (SQLite + background sync) in the Flutter app, and expose an endpoint for batch uploads. |
| **Documentation Gaps** | `DOCKER_DEPLOYMENT.md` mentions scripts like `makeall.sh` but they are not version‑controlled in the repo root. | Move helper scripts under `scripts/` and document usage in README. |
| **Internationalisation** | UI appears to be Vietnamese only. | Add i18n support (React i18next, Flutter `intl`) for future multilingual rollout. |

---

## 4️⃣ Quick Wins & Completed Improvements

✅ **COMPLETED:**
- **Secret Management**: Di chuyển mật khẩu và cấu hình nhạy cảm sang `.env` và thiết lập `env_file:` trong `docker-compose.yml`.
- **Docker Image Size**: Đã áp dụng Multi-stage build cho `GMP_System/Dockerfile` giúp tách biệt build SDK và runtime siêu nhẹ.
- **Build Caching**: Đã bổ sung `.dockerignore` để tránh tải `bin/`, `obj/`, `node_modules/` vào Docker Context.
- **Database Migrations**: Thiết lập script tự động chạy migrations qua `entrypoint-api.sh` mỗi khi khởi động container API.

⚠️ **TBD (Cần thực hiện):**
1. **Expose Prometheus metrics** qua `app.UseMetricServer()` và `app.MapMetrics()`.
2. **Add a basic role-based policy** trong `Startup.cs` (`services.AddAuthorization…`).
3. **Create a GitHub Action** xây dựng quy trình CI/CD build và push image.

---

## 5️⃣ Mid‑term Roadmap (1–4 weeks)

| Sprint | Goal | Deliverable |
|--------|------|-------------|
| **Sprint 1** | **CI/CD + Migration** | GitHub Actions workflow, EF Core migrations executed on container start. |
| **Sprint 2** | **Security Harden** | Secrets handling, RBAC implementation, JWT refresh flow. |
| **Sprint 3** | **Observability** | Structured logging (Serilog), Swagger UI with OAuth2, Prometheus + Grafana dashboards. |
| **Sprint 4** | **Testing & Offline** | ≥ 80 % unit test coverage for backend, Flutter offline sync module, integration tests via Testcontainers. |

---

## 6️⃣ Final Thoughts

The project already embodies the **core GMP principles** (auditability, immutable data, strict state flow) and is packaged cleanly with Docker. By tightening security (secrets, RBAC), automating schema evolution (EF migrations), and adding observability & CI pipelines, the system will move from a solid prototype to a **production‑grade, audit‑ready platform** ready for regulatory review.

Feel free to let me know which of the above items you’d like to start with, or if you need a deeper dive into any specific code area (e.g., `ProductionOrderService`, Dockerfile optimizations, or Flutter offline strategy).








### 🌟 Đề xuất tối ưu dự án PPMS dựa trên review

#### 1️⃣ Cải thiện **Docker & CI/CD**

| Hạng mục | Nội dung cụ thể | Mẫu tệp mẫu |
|----------|-----------------|-------------|
| **Docker‑file** (backend) | - Sử dụng multi‑stage build: <br> 1️⃣ stage **build** dùng `mcr.microsoft.com/dotnet/sdk:8.0` <br> 2️⃣ stage **runtime** dùng `mcr.microsoft.com/dotnet/aspnet:8.0` <br> - Chỉ sao chép `bin/Release/net8.0/publish` sang stage runtime. | ```Dockerfile\n# ---- Build stage ----\nFROM mcr.microsoft.com/dotnet/sdk:8.0 AS build\nWORKDIR /src\nCOPY GMP_System/GMP_System/*.csproj ./\nRUN dotnet restore\nCOPY GMP_System/GMP_System/. ./\nRUN dotnet publish -c Release -o /app/publish\n\n# ---- Runtime stage ----\nFROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime\nWORKDIR /app\nCOPY --from=build /app/publish .\nENTRYPOINT [\"dotnet\", \"GMP_System.dll\"]\n``` |
| **Docker‑file** (frontend) | - Multi‑stage: build với Node 18, chạy Nginx. <br>- Đặt `VITE_API_URL` qua `ARG`. | ```Dockerfile\n# ---- Build ----\nFROM node:18-alpine AS build\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci\nCOPY . .\nARG VITE_API_URL\nENV VITE_API_URL=${VITE_API_URL}\nRUN npm run build\n\n# ---- Runtime ----\nFROM nginx:alpine\nCOPY --from=build /app/dist /usr/share/nginx/html\nEXPOSE 80\n``` |
| **.dockerignore** (backend & frontend) | Loại bỏ các thư mục không cần thiết để ảnh nhỏ hơn. | ```text\n# Backend\nbin/\nobj/\n*.csproj.user\n# Frontend\nnode_modules/\ndist/\n*.log\n*.md\n.git\n``` |
| **Quản lý secrets** | - Tạo `.env.example` với các biến môi trường (SA_PASSWORD, JWT_KEY, DB_CONNECTION). <br>- Trong `docker‑compose.yml` dùng `env_file: .env`. <br>- Khi triển khai production, sử dụng Docker secrets hoặc Vault. | ```env\n# .env.example\nSA_PASSWORD=YourStrongPassword123!\nJWT_KEY=ReplaceWithRandom256BitKey\nDB_CONNECTION=Server=gmp-sqlserver;Database=GMP_WHO_DB;User Id=sa;Password=${SA_PASSWORD};\n``` |
| **docker‑compose.yml** | - Thêm `environment:` cho các service, tham chiếu tới biến trong `.env`. <br>- Đặt `restart: unless‑stopped`. | ```yaml\nversion: '3.9'\nservices:\n  gmp-sqlserver:\n    image: mcr.microsoft.com/mssql/server:2022-latest\n    container_name: gmp-sqlserver\n    environment:\n      - SA_PASSWORD=${SA_PASSWORD}\n      - ACCEPT_EULA=Y\n    ports:\n      - \"1435:1433\"\n    restart: unless-stopped\n  gmp-api:\n    build: ./GMP_System/GMP_System\n    container_name: gmp-api\n    env_file: .env\n    depends_on:\n      - gmp-sqlserver\n    ports:\n      - \"5001:80\"\n    restart: unless-stopped\n  gmp-frontend:\n    build:\n      context: ./PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem\n      dockerfile: Dockerfile\n      args:\n        VITE_API_URL: http://gmp-api:80\n    container_name: gmp-frontend\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - gmp-api\n    restart: unless-stopped\n``` |
| **CI/CD (GitHub Actions)** | - Build và push image cho `api`, `frontend`, `mobile`. <br>- Chạy unit‑test (xUnit + Moq, Jest, Flutter). <br>- Deploy tới môi trường staging (Docker‑Compose) sau khi test thành công. | ```yaml\nname: CI/CD\non:\n  push:\n    branches: [main]\n  pull_request:\n    branches: [main]\njobs:\n  build-test:\n    runs-on: ubuntu-latest\n    services:\n      sqlserver:\n        image: mcr.microsoft.com/mssql/server:2022-latest\n        env:\n          SA_PASSWORD: ${{ secrets.SA_PASSWORD }}\n          ACCEPT_EULA: Y\n        ports: [\"1433:1433\"]\n        options: >-\n          --health-cmd \"/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $SA_PASSWORD -Q \\\"SELECT 1\\\"\"\n          --health-interval 10s\n          --health-timeout 5s\n          --health-retries 5\n    steps:\n      - uses: actions/checkout@v3\n      # ---------- Backend ----------\n      - name: Setup .NET\n        uses: actions/setup-dotnet@v3\n        with:\n          dotnet-version: '8.0.x'\n      - name: Restore & Test (API)\n        run: |\n          dotnet restore GMP_System/GMP_System/GMP_System.csproj\n          dotnet test GMP_System/GMP_System.Tests --no-build --verbosity normal\n      - name: Build Docker image (API)\n        run: |\n          docker build -t ghcr.io/${{ github.repository }}/gmp-api:latest ./GMP_System/GMP_System\n      # ---------- Frontend ----------\n      - name: Setup Node\n        uses: actions/setup-node@v3\n        with:\n          node-version: '18'\n      - name: Install & Test (Frontend)\n        working-directory: PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem\n        run: |\n          npm ci\n          npm run test --if-present\n      - name: Build Docker image (Frontend)\n        run: |\n          docker build -t ghcr.io/${{ github.repository }}/gmp-frontend:latest ./PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem\n      # ---------- Push images ----------\n      - name: Login to GHCR\n        uses: docker/login-action@v2\n        with:\n          registry: ghcr.io\n          username: ${{ github.actor }}\n          password: ${{ secrets.GITHUB_TOKEN }}\n      - name: Push images\n        run: |\n          docker push ghcr.io/${{ github.repository }}/gmp-api:latest\n          docker push ghcr.io/${{ github.repository }}/gmp-frontend:latest\n``` |

#### 2️⃣ **Quản lý Migration & Schema**

* **EF Core migrations**  
  ```bash
  cd GMP_System/GMP_System
  dotnet ef migrations add InitialCreate
  dotnet ef migrations add AddAuditTables
  dotnet ef database update   # sẽ chạy khi container khởi động (script entrypoint)
  ```
* **Docker‑entrypoint** cho API  
  ```bash
  #!/bin/bash
  set -e
  dotnet ef database update
  exec dotnet GMP_System.dll
  ```
  Đặt `ENTRYPOINT ["./entrypoint.sh"]` trong Dockerfile.

#### 3️⃣ **Bảo mật & RBAC**

* **Thêm enum `UserRole { Admin, Manager, QC, Operator }`** trong `AppUser`.  
* **Policy** trong `Startup.cs`:
  ```csharp
  services.AddAuthorization(options =>
  {
      options.AddPolicy("RequireQC", policy => policy.RequireRole("QC"));
      options.AddPolicy("RequireManager", policy => policy.RequireRole("Manager"));
  });
  ```
* **Controller** ví dụ:
  ```csharp
  [Authorize(Policy = "RequireQC")]
  [HttpPost("batch/{id}/qc")]
  public async Task<IActionResult> SubmitQc(int id, QcDto dto) { … }
  ```

#### 4️⃣ **Giải pháp Observability**

| Công cụ | Mục đích |
|--------|----------|
| **Serilog** + `Serilog.Sinks.Console` + `Serilog.Sinks.File` | Log JSON, dễ gửi tới Elastic/Seq. |
| **Prometheus** (`App.Metrics`) + `prometheus-net.AspNetCore` | Export `/metrics` cho dashboard Grafana. |
| **OpenTelemetry** (`OpenTelemetry.Extensions.Hosting`) | Trace toàn bộ request‑to‑DB → giúp audit/diagnostic. |
| **Health checks**: đã có `/api/health`; mở rộng để kiểm tra DB, Redis (nếu thêm cache). |

#### 5️⃣ **Kiểm thử tự động**

* **Backend**: xUnit + Moq cho services, Testcontainers để khởi tạo SQL Server tạm thời.  
* **Frontend**: Jest + React Testing Library, kiểm tra API client (`axios`) qua `msw`.  
* **Mobile**: `flutter test` + `integration_test` (đóng gói thành APK/AAB để CI chạy trên Firebase Test Lab).  

#### 6️⃣ **Offline cho Mobile**

1. **SQLite** (sqflite) lưu trữ tạm thời các `ProductionBatch` và `MaterialUsage`.  
2. **Sync service** chạy ở background (Workmanager) gửi dữ liệu tới `/api/sync` khi mạng ổn.  
3. **API `/sync`** nhận batch JSON, validate, và ghi vào DB trong transaction.

#### 7️⃣ **Cải thiện cấu trúc dự án**

```
DoAnTotNghiep/
├── docker-compose.yml
├── .env.example
├── .dockerignore
├── scripts/
│ ├── entrypoint-api.sh
│ ├── start-dev.sh
│ └── reset-db.sh
├── docs/
│ ├── ARCHITECTURE.md # sơ đồ, giải thích các layer
│ ├── SECURITY.md # secret handling, RBAC
│ └── DEPLOYMENT.md # hướng dẫn docker‑compose, CI
├── DATABASE/
│ ├── migrations/ # EF migration scripts (generated)
│ └── init.sql (legacy, keep for reference)
├── GMP_System/
│ └── GMP_System/
│ ├── Dockerfile
│ └── src/
├── PharmaceuticalProcessingManagementSystem/
│ └── PharmaceuticalProcessingManagementSystem/
│ ├── Dockerfile
│ └── src/
└── MobileApp/
    └── Dockerfile (flutter web)
```

#### 8️⃣ **Kế hoạch triển khai nhanh (3‑4 ngày)**

| Ngày | Công việc |
|------|------------|
| **Day 1** | Thêm `.dockerignore`, viết lại Dockerfile (backend + frontend), tạo `.env.example`. |
| **Day 2** | Thiết lập entrypoint cho API, chạy EF migrations tự động, kiểm tra chạy `docker‑compose up`. |
| **Day 3** | Thêm RBAC vào `AppUser`, cập nhật một vài controller để dùng policy, test bằng Postman. |
| **Day 4** | Đưa CI workflow lên GitHub Actions, chạy unit test, push image tới GHCR, triển khai staging. |

---

### 📦 Kết luận

- **Bảo mật**: secret, RBAC, JWT refresh.
- **Quản lý DB**: EF migrations → giảm rủi ro drift.
- **Docker**: multi‑stage, .dockerignore, size tối ưu, health‑restart.
- **CI/CD**: tự động build, test, push, deploy.
- **Observability**: structured log, metrics, tracing.
- **Kiểm thử**: coverage >80 % cho backend, basic front & mobile.
- **Mobile offline**: SQLite + sync service.

Với những thay đổi này dự án sẽ **nhỏ hơn, an toàn hơn, có thể CI/CD, dễ bảo trì** và đáp ứng đầy đủ yêu cầu GMP‑WHO cũng như chuẩn DevOps hiện đại. Nếu muốn tôi thực hiện một phần nào đó (ví dụ viết Dockerfile mới, thêm .env, hoặc tạo workflow CI), cứ chỉ định nhé!