# TASKS.md – Action Items for PPMS Project

## 🎯 High‑Priority (Complete within 2 days)

1. [x] **Add RBAC Skeleton**
   - Create `UserRole` enum and basic policies (`RequireAdmin`, `RequireQC`, `RequireOperator`).
   - Apply one example policy to a controller (e.g., `ProductionBatchesController`).

2. [x] **CI/CD Workflow**
   - Add a GitHub Actions workflow (`.github/workflows/ci-cd.yml`) that:
     * Restores, builds, runs unit tests for the backend (xUnit).
     * Installs, builds, runs Jest tests for the frontend.
     * Runs Flutter tests.
     * Builds Docker images for API, frontend and mobile.
     * Pushes images to GitHub Container Registry.
   - Verify the workflow passes on a fresh commit.

3. [x] **EF Core Migrations & Schema Management**
   - Transition from raw `.sql` scripts (`DATABASE/init.sql`) to EF Core migrations (`dotnet ef migrations add`).
   - Create an `entrypoint-api.sh` script and update the backend Dockerfile `ENTRYPOINT` to execute `dotnet ef database update` automatically when the container starts.

4. **Observability & Health Checks**
   - Integrate Serilog (with JSON output to console/file) for structured logging to replace default loggers.
   - Expose Prometheus metrics via `/metrics` using `prometheus-net.AspNetCore` for future Grafana dashboards.
   - Expand the existing `/api/health` endpoint to include SQL Server connection verification.

5. **Automated Testing Foundation**
   - **Backend**: Set up xUnit + Moq for services and configure Testcontainers to spin up a temporary SQL Server for integration tests.
   - **Frontend**: Initialize Jest + React Testing Library, and configure API client mocking (e.g., `msw`).
   - **Mobile**: Set up `flutter test` and basic `integration_test` configurations.

6. **Mobile Offline Sync Module**
   - Implement SQLite (`sqflite`) in the Flutter app to temporarily store `ProductionBatch` and `MaterialUsage` data during network drops.
   - Create a background sync service (e.g., using Workmanager) to push locally saved data to a new `/api/sync` endpoint when connectivity is restored.

## 📅 Mid‑Term (1‑2 weeks)

- **Security Hardening**: Implement JWT refresh flow and document token issuance in the README.
- **Documentation Standardization**: Create `docs/ARCHITECTURE.md`, `docs/SECURITY.md`, and `docs/DEPLOYMENT.md` describing the architecture, secret handling, and deployment steps.
- **Testing Coverage**: Increase backend unit-test coverage to >80% and flesh out frontend/mobile test cases.

## 📦 Long‑Term (3‑4 weeks)

- **Full RBAC & Claims**: Flesh out role‑based access throughout all controllers and UI routes.
- **OpenTelemetry**: Add tracing for end‑to‑end request flow.
- **Internationalisation**: Integrate i18n for React (i18next) and Flutter (`intl`).
- **Production‑Ready Deploy**: Separate `docker‑compose.prod.yml` with production‑grade settings (no hot‑reload, secure secrets, health checks).

---

*All tasks are ordered by impact and effort. Feel free to adjust priorities or ask for a specific task to be implemented first.*