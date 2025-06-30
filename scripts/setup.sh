#!/bin/bash

set -e

echo "🚀 Setting up Bloomberg-style Stock Terminal with ClickHouse..."

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

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please create it from the template."
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p n8n/workflows
mkdir -p database/clickhouse/init
mkdir -p database/clickhouse/config
mkdir -p services/data-ingestion/logs
mkdir -p services/backtesting/logs
mkdir -p services/api-gateway/logs
mkdir -p uploads
mkdir -p localstack

# Generate package-lock.json files for services if they don't exist
print_status "Checking service dependencies..."

# API Gateway
if [ ! -f services/api-gateway/package-lock.json ]; then
    print_status "Generating package-lock.json for API Gateway..."
    cd services/api-gateway
    npm install --package-lock-only
    cd ../..
fi

# Data Ingestion
if [ ! -f services/data-ingestion/package-lock.json ]; then
    print_status "Generating package-lock.json for Data Ingestion..."
    cd services/data-ingestion
    npm install --package-lock-only
    cd ../..
fi

# Backtesting
if [ ! -f services/backtesting/package-lock.json ]; then
    print_status "Generating package-lock.json for Backtesting..."
    cd services/backtesting
    npm install --package-lock-only
    cd ../..
fi

# Client
if [ ! -f client/package-lock.json ]; then
    print_status "Generating package-lock.json for Next.js Client..."
    cd client
    npm install --package-lock-only
    cd ..
fi

# Build Docker images
print_status "Building Docker images..."
docker-compose build

# Start the system
print_status "Starting the Bloomberg-style Stock Terminal..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 60

# Check service health
print_status "Checking service health..."

# Check ClickHouse
if curl -s http://localhost:8123/ping > /dev/null 2>&1; then
    print_success "ClickHouse is ready"
else
    print_error "ClickHouse is not ready"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_error "Redis is not ready"
fi

# Check Kafka
print_status "Checking Kafka..."
sleep 10
if docker-compose exec -T kafka kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    print_success "Kafka is ready"
else
    print_warning "Kafka may still be starting up"
fi

# Check API Gateway
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    print_success "API Gateway is ready"
else
    print_warning "API Gateway is not ready yet (may take a few more seconds)"
fi

# Check Data Ingestion
if curl -s http://localhost:3002/health > /dev/null 2>&1; then
    print_success "Data Ingestion service is ready"
else
    print_warning "Data Ingestion service is not ready yet"
fi

# Check Backtesting
if curl -s http://localhost:3003/health > /dev/null 2>&1; then
    print_success "Backtesting service is ready"
else
    print_warning "Backtesting service is not ready yet"
fi

# Check Next.js Client
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    print_success "Next.js Client is ready"
else
    print_warning "Next.js Client is not ready yet"
fi

# Initialize LocalStack resources
print_status "Initializing LocalStack resources..."
sleep 10
if [ -f scripts/deploy-localstack.sh ]; then
    chmod +x scripts/deploy-localstack.sh
    ./scripts/deploy-localstack.sh || print_warning "LocalStack initialization failed (this is optional)"
else
    print_warning "LocalStack deployment script not found"
fi

# Test ClickHouse connection and show sample data
print_status "Testing ClickHouse connection and showing sample data..."
sleep 5

# Show companies in database
print_status "Sample companies in database:"
docker-compose exec -T clickhouse clickhouse-client --user=stockuser --password=stockpass123 --database=stockdb --query="SELECT name, symbol FROM companies c JOIN securities s ON c.id = s.company_id LIMIT 5 FORMAT Pretty" 2>/dev/null || print_warning "Could not fetch sample data"

print_success "🎉 Bloomberg-style Stock Terminal is now running!"
echo ""
echo "📋 Access Points:"
echo "  🌐 Next.js Client:      http://localhost:3001"
echo "  🔗 API Gateway:         http://localhost:3000"
echo "  📚 API Documentation:   http://localhost:3000/api-docs"
echo "  🗄️  ClickHouse Web UI:   http://localhost:8123"
echo "  🔧 n8n Workflows:       http://localhost:5678 (admin/admin123)"
echo "  🔴 Redis:               localhost:6379"
echo "  📨 Kafka:               localhost:9092"
echo "  ☁️  LocalStack:          http://localhost:4566"
echo ""
echo "🔍 Health Checks:"
echo "  curl http://localhost:3000/health"
echo "  curl http://localhost:3002/health"
echo "  curl http://localhost:3003/health"
echo ""
echo "📊 Sample API Calls:"
echo "  curl http://localhost:3000/api/market/symbols"
echo "  curl http://localhost:3000/api/market/symbols/AAPL/quote"
echo "  curl http://localhost:3000/api/analytics/market-overview"
echo ""
echo "🗄️  ClickHouse Access:"
echo "  make clickhouse-shell"
echo "  curl 'http://localhost:8123/?query=SELECT * FROM securities LIMIT 5&user=stockuser&password=stockpass123&database=stockdb'"
echo ""
echo "📊 View Logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "🛑 To stop the system:"
echo "  docker-compose down"
echo ""
echo "🧹 To clean up everything:"
echo "  docker-compose down -v"
echo "  docker system prune -f"
echo ""
echo "📖 For more commands, see the Makefile"