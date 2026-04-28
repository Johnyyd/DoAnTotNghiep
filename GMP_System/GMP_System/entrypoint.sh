#!/bin/bash
set -e

# Support running custom commands (like dotnet watch)
if [ $# -gt 0 ]; then
    echo "Starting with custom command: $@"
    exec "$@"
fi

# Fallback to default production behavior
echo "Starting production API..."
if [ -f "/app/GMP_System.dll" ]; then
    cd /app
    exec dotnet GMP_System.dll
elif [ -f "GMP_System.dll" ]; then
    exec dotnet GMP_System.dll
else
    echo "Error: GMP_System.dll not found."
    exit 1
fi
