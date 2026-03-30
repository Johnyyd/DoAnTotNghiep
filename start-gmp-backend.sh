#!/bin/bash
# Startup script for GMP-WHO Pharmaceutical Processing Management System

set -e

echo "=== GMP-WHO Backend Setup ==="

# 1. Create Docker network (nếu chưa tồn tại)
if ! docker network ls | grep -q '^gmp-network'; then
    echo "Creating Docker network: gmp-network..."
    docker network create gmp-network
else
    echo "Network gmp-network already exists"
fi

# 2. Start SQL Server (nếu chưa chạy)
if ! docker ps --format '{{.Names}}' | grep -q '^gmp-sqlserver$'; then
    echo "Starting SQL Server for GMP..."
    docker run -d --name gmp-sqlserver \
        --network gmp-network \
        -e 'ACCEPT_EULA=Y' \
        -e 'SA_PASSWORD=GMP_Strong@Passw0rd123' \
        -p 1434:1433 \
        -v "$(pwd)/DATABASE:/var/opt/mssql/backup:ro" \
        -v "gmp-sqlserver-data:/var/opt/mssql" \
        mcr.microsoft.com/mssql/server:2022-latest
else
    echo "SQL Server already running"
fi

# 3. Wait for SQL Server to accept connections
echo "Waiting for SQL Server to accept connections on port 1434..."
attempt=0
max_attempts=60
while ! docker exec gmp-sqlserver /bin/bash -c "timeout 1 bash -c '</dev/tcp/localhost/1433'" 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "SQL Server did not become ready in time"
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""
echo "SQL Server is accepting connections"

# 4. Initialize database (only if not already initialized)
echo "Checking if GMP database exists..."
DB_EXISTS=$(docker exec gmp-sqlserver /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U SA -P 'GMP_Strong@Passw0rd123' \
    -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GMP_WHO_DB') SELECT 1 ELSE SELECT 0" \
    2>/dev/null | tail -n 1 | tr -d ' ' || echo 0)

if [ "$DB_EXISTS" = "0" ]; then
    echo "Initializing GMP database..."
    docker exec gmp-sqlserver /opt/mssql-tools/bin/sqlcmd \
        -S localhost -U SA -P 'GMP_Strong@Passw0rd123' \
        -i /var/opt/mssql/backup/init.sql
    docker exec gmp-sqlserver /opt/mssql-tools/bin/sqlcmd \
        -S localhost -U SA -P 'GMP_Strong@Passw0rd123' \
        -i /var/opt/mssql/backup/seed.sql
    echo "Database initialized"
else
    echo "Database already exists"
fi

# 5. Build backend API Docker image
echo "Building GMP backend API image..."
cd GMP_System/GMP_System
docker build -t gmp-who-api .

# 6. Start backend API (nếu chưa chạy)
if ! docker ps --format '{{.Names}}' | grep -q '^gmp-api$'; then
    echo "Running GMP backend API..."
    cd ../..
    docker run -d --name gmp-api \
        --network gmp-network \
        -p 5001:5000 \
        -v "$(pwd)/DATABASE:/app/DATABASE:ro" \
        -e "ConnectionStrings__DefaultConnection=Server=gmp-sqlserver;Database=PharmaceuticalProcessingManagementSystem;User Id=sa;Password=GMP_Strong@Passw0rd123;TrustServerCertificate=true" \
        -e "Jwt__Key=GMP_WHO_Default_Secret_Key_Minimum_32_Characters_Long_123456789" \
        -e "ASPNETCORE_ENVIRONMENT=Development" \
        gmp-who-api
    cd GMP_System/GMP_System
else
    echo "Backend API already running"
    cd ../..
fi

echo ""
echo "=== GMP-WHO System Started! ==="
echo "Backend API: http://localhost:5001"
echo "Swagger UI: http://localhost:5001/swagger"
echo "Scalar API: http://localhost:5001/scalar"
echo ""
echo "Database:"
echo "  Server: localhost,1434"
echo "  Database: GMP_WHO_DB"
echo "  User: sa"
echo ""
echo "To view logs:"
echo "  docker logs -f gmp-api"
echo "  docker logs -f gmp-sqlserver"
echo ""
echo "To stop all services:"
echo "  docker stop gmp-api gmp-sqlserver"
echo "  docker network rm gmp-network"
echo ""
echo "To rebuild API image after code changes:"
echo "  cd GMP_System/GMP_System && docker build -t gmp-who-api ."
