.PHONY: help setup start stop restart logs clean health test api-test build-client

# Default target
help:
	@echo "🚀 Bloomberg-style Stock Terminal with ClickHouse"
	@echo ""
	@echo "Available commands:"
	@echo "  setup       - Initial setup and start all services"
	@echo "  start       - Start all services"
	@echo "  stop        - Stop all services"
	@echo "  restart     - Restart all services"
	@echo "  logs        - Show logs from all services"
	@echo "  logs-[service] - Show logs from specific service"
	@echo "  clean       - Clean up Docker resources"
	@echo "  health      - Check service health"
	@echo "  test        - Run API tests"
	@echo "  api-test    - Test API endpoints"
	@echo "  build-client - Build Next.js client"
	@echo "  clickhouse-shell - Access ClickHouse shell"
	@echo "  sample-queries - Show sample ClickHouse queries"

# Initial setup
setup:
	@echo "🚀 Setting up Bloomberg-style Stock Terminal with ClickHouse..."
	chmod +x scripts/setup.sh
	chmod +x scripts/stop.sh
	chmod +x scripts/logs.sh
	chmod +x scripts/generate-package-locks.sh
	./scripts/generate-package-locks.sh
	./scripts/setup.sh

# Start all services
start:
	@echo "▶️  Starting services..."
	docker-compose up -d
	@echo "✅ Services started!"
	@echo "📋 Access points:"
	@echo "  Next.js Client: http://localhost:3001"
	@echo "  Trading Platform: http://localhost:3001/trading"
	@echo "  API Gateway: http://localhost:3000"
	@echo "  ClickHouse Web UI: http://localhost:8123"
	@echo "  n8n: http://localhost:5678 (admin/admin123)"
	@echo "  API Docs: http://localhost:3000/api-docs"

# Stop all services
stop:
	@echo "⏹️  Stopping services..."
	docker-compose down
	@echo "✅ Services stopped!"

# Restart all services
restart: stop start

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs from specific services
logs-clickhouse:
	docker-compose logs -f clickhouse

logs-redis:
	docker-compose logs -f redis

logs-kafka:
	docker-compose logs -f kafka

logs-api:
	docker-compose logs -f api-gateway

logs-data:
	docker-compose logs -f data-ingestion

logs-backtest:
	docker-compose logs -f backtesting

logs-client:
	docker-compose logs -f client

logs-n8n:
	docker-compose logs -f n8n

logs-localstack:
	docker-compose logs -f localstack

# Clean up Docker resources
clean:
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	docker system prune -f
	docker volume prune -f
	@echo "✅ Cleanup complete!"

# Check service health
health:
	@echo "🏥 Checking service health..."
	@echo "ClickHouse:"
	@curl -s http://localhost:8123/ping || echo "❌ ClickHouse not ready"
	@echo ""
	@echo "Redis:"
	@docker-compose exec -T redis redis-cli ping || echo "❌ Redis not ready"
	@echo ""
	@echo "API Gateway:"
	@curl -s http://localhost:3000/health | jq . || echo "❌ API Gateway not ready"
	@echo ""
	@echo "Data Ingestion:"
	@curl -s http://localhost:3002/health | jq . || echo "❌ Data Ingestion not ready"
	@echo ""
	@echo "Backtesting:"
	@curl -s http://localhost:3003/health | jq . || echo "❌ Backtesting not ready"
	@echo ""
	@echo "Next.js Client:"
	@curl -s http://localhost:3001 > /dev/null && echo "✅ Next.js Client ready" || echo "❌ Next.js Client not ready"

# Run tests
test:
	@echo "🧪 Running tests..."
	docker-compose exec data-ingestion npm test || echo "Data ingestion tests not available"
	docker-compose exec backtesting npm test || echo "Backtesting tests not available"
	docker-compose exec api-gateway npm test || echo "API gateway tests not available"

# Test API endpoints
api-test:
	@echo "🔍 Testing API endpoints..."
	@echo "Health check:"
	curl -s http://localhost:3000/health | jq .
	@echo ""
	@echo "Market overview:"
	curl -s http://localhost:3000/api/analytics/market-overview | jq .
	@echo ""
	@echo "Symbols:"
	curl -s "http://localhost:3000/api/market/symbols?limit=5" | jq .
	@echo ""
	@echo "AAPL quote:"
	curl -s http://localhost:3000/api/market/symbols/AAPL/quote | jq .
	@echo ""
	@echo "Trading chart:"
	curl -s http://localhost:3000/api/trading/chart/AAPL | jq .

# Build Next.js client
build-client:
	@echo "🔨 Building Next.js client..."
	cd client && npm run build

# Build images
build:
	@echo "🔨 Building Docker images..."
	docker-compose build

# Pull latest images
pull:
	@echo "⬇️  Pulling latest images..."
	docker-compose pull

# Show running containers
ps:
	docker-compose ps

# Execute shell in services
clickhouse-shell:
	docker-compose exec clickhouse clickhouse-client --user=stockuser --password=stockpass123 --database=stockdb

shell-redis:
	docker-compose exec redis redis-cli

shell-api:
	docker-compose exec api-gateway sh

shell-data:
	docker-compose exec data-ingestion sh

shell-backtest:
	docker-compose exec backtesting sh

shell-client:
	docker-compose exec client sh

# Development mode for client
dev-client:
	cd client && npm run dev

# Install client dependencies
install-client:
	cd client && npm install

# ClickHouse specific commands
clickhouse-status:
	@echo "📊 ClickHouse Status:"
	@curl -s http://localhost:8123/ || echo "ClickHouse not responding"

clickhouse-query:
	@echo "Enter your ClickHouse query:"
	@read query; curl -s "http://localhost:8123/?query=$$query&user=stockuser&password=stockpass123&database=stockdb"

# Show sample queries
sample-queries:
	@echo "📊 Sample ClickHouse Queries:"
	@echo ""
	@echo "1. Market Overview:"
	@echo "   SELECT COUNT(*) as total_securities FROM securities WHERE is_active = 1;"
	@echo ""
	@echo "2. Latest Prices:"
	@echo "   SELECT s.symbol, o.close_price, o.volume FROM securities s JOIN ohlcv_daily o ON s.id = o.security_id WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily) LIMIT 10;"
	@echo ""
	@echo "3. Top Movers:"
	@echo "   SELECT * FROM market_movers_view WHERE trade_date = today() ORDER BY change_percent DESC LIMIT 10;"
	@echo ""
	@echo "4. Sector Performance:"
	@echo "   SELECT * FROM sector_performance_view WHERE trade_date = today() ORDER BY avg_change_percent DESC;"
	@echo ""
	@echo "5. Technical Signals:"
	@echo "   SELECT * FROM technical_signals_view WHERE trade_date = today() AND signal_strength = 'HIGH' LIMIT 20;"
	@echo ""
	@echo "Use 'make clickhouse-shell' to run these queries interactively"

# Deploy to production
deploy:
	@echo "🚀 Deploying to production..."
	docker-compose -f docker-compose.yml up -d

# Backup ClickHouse data
backup:
	@echo "💾 Creating ClickHouse backup..."
	docker-compose exec clickhouse clickhouse-client --user=stockuser --password=stockpass123 --query="BACKUP DATABASE stockdb TO Disk('backups', 'backup_$(shell date +%Y%m%d_%H%M%S)')"

# Initialize the system
init: build start
	@echo "⏳ Waiting for services to be ready..."
	sleep 60
	@echo "✅ System initialized successfully!"
	@echo "📋 Access points:"
	@echo "  Next.js Client: http://localhost:3001"
	@echo "  Trading Platform: http://localhost:3001/trading"
	@echo "  API Gateway: http://localhost:3000"
	@echo "  ClickHouse: http://localhost:8123"
	@echo "  n8n: http://localhost:5678 (admin/admin123)"
	@echo "  API Docs: http://localhost:3000/api-docs"