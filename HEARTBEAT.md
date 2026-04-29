- Completed RBAC skeleton (UserRole enum, policies, applied to ProductionBatchesController).

**2024-04-29 04:20 GMT+7**
- Added EF Core migration `Init` via Docker container with dotnet-ef tool.
- Created `entrypoint-api.sh` to run migrations before launching API.
- Updated Dockerfile to use new entrypoint.
- Verified build succeeds.
