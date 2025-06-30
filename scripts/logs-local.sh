#!/bin/bash

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to show logs for a specific service
show_service_logs() {
    local service=$1
    print_status "Showing logs for $service..."
    docker-compose -f docker-compose.local.yml logs -f --tail=100 $service
}

# Function to show all logs
show_all_logs() {
    print_status "Showing logs for all services..."
    docker-compose -f docker-compose.local.yml logs -f --tail=50
}

# Main script
if [ $# -eq 0 ]; then
    echo "📋 Available services:"
    echo "  postgres"
    echo "  redis"
    echo "  kafka"
    echo "  zookeeper"
    echo "  localstack"
    echo "  n8n"
    echo "  data-ingestion"
    echo "  backtesting"
    echo "  api-gateway"
    echo ""
    echo "Usage:"
    echo "  $0 [service-name]  # Show logs for specific service"
    echo "  $0 all            # Show logs for all services"
    echo ""
    echo "Examples:"
    echo "  $0 api-gateway"
    echo "  $0 data-ingestion"
    echo "  $0 all"
    exit 1
fi

if [ "$1" = "all" ]; then
    show_all_logs
else
    show_service_logs $1
fi