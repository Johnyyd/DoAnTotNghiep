#!/bin/bash
# Startup script for GMP-WHO Frontend Admin

set -e

echo "=== GMP-WHO Frontend Setup ==="

# Check if network exists
#if ! docker network ls | grep -q '^gmp-network'; then
#    echo "ERROR: Docker network 'gmp-network' not found. Please start backend first:"
#    echo "  ./start-gmp-backend.sh"
#    exit 1
#fi

# Build frontend image
echo "Building GMP frontend image..."
cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
docker build -t gmp-who-frontend .

# Stop existing container if any
if docker ps -a --format '{{.Names}}' | grep -q '^gmp-frontend$'; then
    echo "Stopping and removing existing frontend container..."
    docker stop gmp-frontend || true
    docker rm gmp-frontend || true
fi

# Run frontend container
echo "Starting GMP frontend..."
docker run -d --name gmp-frontend \
    --network gmp-network \
    -p 80:80 \
    -e "VITE_API_URL=http://gmp-api:5000" \
    gmp-who-frontend

echo ""
echo "=== GMP Frontend Started! ==="
echo "Admin Web Interface: http://localhost"
echo "Backend API: http://localhost:5001 (on host) or http://gmp-api:5000 (within container network)"
echo ""
echo "To view logs:"
echo "  docker logs -f gmp-frontend"
echo ""
echo "To stop frontend:"
echo "  docker stop gmp-frontend"
echo ""
echo "To rebuild frontend after code changes:"
echo "  cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem"
echo "  docker build -t gmp-who-frontend ."
