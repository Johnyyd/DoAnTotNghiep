#!/bin/bash
# GMP-WHO System - All-in-One Setup Script

set -e

echo "================================================"
echo "GMP-WHO Pharmaceutical Processing Management"
echo "Docker Setup Script"
echo "================================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker first!"
    exit 1
fi

# Check if DATABASE folder exists and has SQL files
if [ ! -d "DATABASE" ] || [ -z "$(ls -A DATABASE/*.sql 2>/dev/null)" ]; then
    echo "Preparing database scripts..."
    cp PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem/*.sql DATABASE/ 2>/dev/null || true
    if [ -z "$(ls -A DATABASE/*.sql 2>/dev/null)" ]; then
        echo "WARNING: No SQL scripts found. Database initialization may fail."
    fi
fi

# Ask user for action
echo "Choose an option:"
echo "  1) Start all services (docker-compose up)"
echo "  2) Stop all services (docker-compose down)"
echo "  3) Rebuild and restart all"
echo "  4) View logs"
echo "  5) Exit"
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo "Starting all services..."
        docker compose up -d
        echo ""
        echo "Services starting..."
        echo "  Backend API: http://localhost:5001"
        echo "  Frontend:    http://localhost:8080"
        echo "  Mobile App:  http://localhost:8081"
        echo "  Database:    localhost,1434 (SA password: GMP_Strong@Passw0rd123)"
        echo ""
        echo "To view logs: docker-compose logs -f"
        echo "To stop:     docker-compose down"
        ;;
    2)
        echo "Stopping all services..."
        docker compose down
        echo "All services stopped."
        ;;
    3)
        echo "Stopping and removing existing containers..."
        docker compose down
        echo "Rebuilding images..."
        docker compose build --no-cache
        echo "Starting services..."
        docker compose up -d
        echo ""
        echo "All services rebuilt and started!"
        echo "  Backend API: http://localhost:5001"
        echo "  Frontend:    http://localhost:8080"
        echo "  Mobile App:  http://localhost:8081"
        ;;
    4)
        echo "Which service logs to view?"
        echo "  1) All services"
        echo "  2) Backend API only"
        echo "  3) Frontend only"
        echo "  4) Database only"
        echo "  5) Mobile App only"
        read -p "Enter choice [1-5]: " log_choice
        case $log_choice in
            1) docker compose logs -f ;;
            2) docker compose logs -f gmp-api ;;
            3) docker compose logs -f gmp-frontend ;;
            4) docker compose logs -f gmp-sqlserver ;;
            5) docker compose logs -f gmp-mobile ;;
            *) echo "Invalid choice" ;;
        esac
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
