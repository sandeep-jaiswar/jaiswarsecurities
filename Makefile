.PHONY: help build up down logs clean test deploy

# Default target
help:
	@echo "Available commands:"
	@echo "  build     - Build all Docker images"
	@echo "  up        - Start all services"
	@echo "  down      - Stop all services"
	@echo "  logs      - Show logs from all services"
	@echo "  clean     - Clean up Docker resources"
	@echo "  test      - Run tests"
	@echo "  deploy    - Deploy to LocalStack"
	@echo "  migrate   - Run database migrations"
	@echo "  seed      - Seed database with sample data"

# Build all Docker images
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d
	@echo "Services are starting up..."
	@echo "n8n will be available at http://localhost:5678"
	@echo "API Gateway will be available at http://localhost:3000"
	@echo "API Documentation will be available at http://localhost:3000/api-docs"

# Stop all services
down:
	docker-compose down

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs from specific service
logs-%:
	docker-compose logs -f $*

# Clean up Docker resources
clean:
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

# Run database migrations
migrate:
	docker-compose run --rm liquibase liquibase update

# Seed database with sample data
seed:
	docker-compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f /docker-entrypoint-initdb.d/seed.sql

# Run tests
test:
	docker-compose exec data-ingestion npm test
	docker-compose exec backtesting npm test
	docker-compose exec api-gateway npm test

# Deploy infrastructure to LocalStack
deploy:
	@echo "Deploying infrastructure to LocalStack..."
	./scripts/deploy-localstack.sh

# Check service health
health:
	@echo "Checking service health..."
	curl -s http://localhost:3000/health | jq .
	curl -s http://localhost:5678 > /dev/null && echo "n8n: healthy" || echo "n8n: unhealthy"

# Initialize the system
init: build up migrate seed
	@echo "System initialized successfully!"
	@echo "Access points:"
	@echo "  - n8n: http://localhost:5678 (admin/admin123)"
	@echo "  - API: http://localhost:3000"
	@echo "  - API Docs: http://localhost:3000/api-docs"

# Development mode (with file watching)
dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production deployment
prod:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Backup database
backup:
	docker-compose exec postgres pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) > backup_$(shell date +%Y%m%d_%H%M%S).sql

# Restore database
restore:
	@read -p "Enter backup file path: \" backup_file; \
	docker-compose exec -T postgres psql -U $(POSTGRES_USER) $(POSTGRES_DB) < $$backup_file