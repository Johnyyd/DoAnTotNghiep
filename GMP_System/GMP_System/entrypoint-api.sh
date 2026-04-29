#!/bin/bash
set -e

# Run EF Core migrations before starting the API
if command -v dotnet >/dev/null 2>&1; then
  echo "Applying EF Core migrations..."
  # Assuming the migrations are compiled into the DLL, use dotnet ef if available
  if dotnet ef --help >/dev/null 2>&1; then
    dotnet ef database update --no-build || echo "EF migrations failed, continuing..."
  else
    echo "dotnet ef tool not found; ensure migrations are applied via application startup."
  fi
else
  echo "dotnet runtime not available; cannot run migrations."
fi

# Start the API
if [ -f "/app/GMP_System.dll" ]; then
  cd /app
  exec dotnet GMP_System.dll
elif [ -f "GMP_System.dll" ]; then
  exec dotnet GMP_System.dll
else
  echo "Error: GMP_System.dll not found."
  exit 1
fi