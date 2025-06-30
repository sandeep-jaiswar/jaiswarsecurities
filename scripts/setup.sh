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

# Check if .env file exists, if not create from template
if [ ! -f .env ]; then
    print_status "Creating .env file from template..."
    cat > .env << 'EOF'
# Environment
NODE_ENV=development

# ClickHouse Configuration
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=stockuser
CLICKHOUSE_PASSWORD=stockpass123
CLICKHOUSE_DB=stockdb

# Redis Configuration
REDIS_URL=redis://redis:6379

# Kafka Configuration
KAFKA_BROKERS=kafka:9092
ZOOKEEPER_CLIENT_PORT=2181
ZOOKEEPER_TICK_TIME=2000

# API Configuration
API_PORT=3000
DATA_INGESTION_PORT=3002
BACKTESTING_PORT=3003
ALLOWED_ORIGINS=http://localhost:3001,http://localhost:5678
LOG_LEVEL=info

# Next.js Configuration
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:3000

# Authentication
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
BCRYPT_ROUNDS=10

# External API Keys (Optional)
ALPHA_VANTAGE_API_KEY=your-alpha-vantage-key
YAHOO_FINANCE_API_KEY=your-yahoo-finance-key
POLYGON_API_KEY=your-polygon-key
FINNHUB_API_KEY=your-finnhub-key
QUANDL_API_KEY=your-quandl-key

# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin123
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# LocalStack Configuration
LOCALSTACK_SERVICES=s3,sqs,sns,logs,cloudformation
LOCALSTACK_DEBUG=1
LOCALSTACK_DATA_DIR=/tmp/localstack

# Backtesting Configuration
BACKTEST_START_DATE=2020-01-01
BACKTEST_END_DATE=2024-12-31
BACKTEST_INITIAL_CAPITAL=100000
BACKTEST_COMMISSION=0.001
EOF
    print_success "Environment file created"
else
    print_warning ".env file already exists. Using existing configuration."
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

print_success "🎉 Bloomberg-style Stock Terminal is now running!"
echo ""
echo "📋 Access Points:"
echo "  🌐 Next.js Client:      http://localhost:3001"
echo "  📈 Trading Platform:    http://localhost:3001/trading"
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
echo "  curl http://localhost:3000/api/trading/chart/AAPL"
echo ""
echo "🗄️  ClickHouse Access:"
echo "  make clickhouse-shell"
echo "  curl 'http://localhost:8123/?query=SELECT * FROM securities LIMIT 5&user=stockuser&password=stockpass123&database=stockdb'"
echo ""
echo "📊 View Logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "🛑 To stop the system:"
echo "  make stop"
echo ""
echo "🧹 To clean up everything:"
echo "  make clean"
echo ""
echo "📖 For more commands, see the Makefile"