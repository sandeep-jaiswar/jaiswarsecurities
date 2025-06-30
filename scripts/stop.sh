#!/bin/bash

set -e

echo "🛑 Stopping Bloomberg-style Stock Terminal..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Stop all services
print_status "Stopping all services..."
docker-compose down

print_success "✅ All services stopped successfully!"

# Ask if user wants to remove volumes
echo ""
read -p "Do you want to remove all data volumes? This will delete all data! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing data volumes..."
    docker-compose down -v
    print_success "✅ Data volumes removed!"
fi

# Ask if user wants to clean up Docker system
echo ""
read -p "Do you want to clean up Docker system (remove unused images, containers, networks)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up Docker system..."
    docker system prune -f
    print_success "✅ Docker system cleaned up!"
fi

echo ""
echo "🎉 Bloomberg-style Stock Terminal has been stopped!"