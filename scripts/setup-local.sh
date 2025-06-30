#!/bin/bash

set -e

echo "🚀 Setting up Stock Screening System locally..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Copy environment file
print_status "Setting up environment configuration..."
if [ ! -f .env ]; then
    cp .env.local .env
    print_success "Environment file created from .env.local"
else
    print_warning ".env file already exists. Using existing configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p n8n/workflows
mkdir -p database/init
mkdir -p services/data-ingestion/logs
mkdir -p services/backtesting/logs
mkdir -p services/api-gateway/logs

# Build Docker images
print_status "Building Docker images..."
docker-compose -f docker-compose.local.yml build

# Start the system
print_status "Starting the stock screening system..."
docker-compose -f docker-compose.local.yml up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service health
print_status "Checking service health..."

# Check PostgreSQL
if docker-compose -f docker-compose.local.yml exec -T postgres pg_isready -U stockuser -d stockdb > /dev/null 2>&1; then
    print_success "PostgreSQL is ready"
else
    print_error "PostgreSQL is not ready"
fi

# Check Redis
if docker-compose -f docker-compose.local.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_error "Redis is not ready"
fi

# Check API Gateway
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    print_success "API Gateway is ready"
else
    print_warning "API Gateway is not ready yet (may take a few more seconds)"
fi

# Initialize LocalStack resources
print_status "Initializing LocalStack resources..."
sleep 10
./scripts/deploy-localstack.sh || print_warning "LocalStack initialization failed (this is optional)"

print_success "🎉 Stock Screening System is now running!"
echo ""
echo "📋 Access Points:"
echo "  🌐 API Gateway:        http://localhost:3000"
echo "  📚 API Documentation:  http://localhost:3000/api-docs"
echo "  🔧 n8n Workflows:      http://localhost:5678 (admin/admin123)"
echo "  💾 PostgreSQL:         localhost:5432 (stockuser/stockpass123)"
echo "  🔴 Redis:              localhost:6379"
echo "  📨 Kafka:              localhost:9092"
echo "  ☁️  LocalStack:         http://localhost:4566"
echo ""
echo "🔍 Health Checks:"
echo "  curl http://localhost:3000/health"
echo "  curl http://localhost:3001/health"
echo "  curl http://localhost:3002/health"
echo ""
echo "📊 Sample API Calls:"
echo "  curl http://localhost:3000/api/symbols"
echo "  curl http://localhost:3000/api/symbols/AAPL"
echo "  curl http://localhost:3000/api/symbols/AAPL/ohlcv"
echo ""
echo "🛑 To stop the system:"
echo "  docker-compose -f docker-compose.local.yml down"
echo ""
echo "🧹 To clean up everything:"
echo "  docker-compose -f docker-compose.local.yml down -v"
echo "  docker system prune -f"