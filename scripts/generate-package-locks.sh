#!/bin/bash

set -e

echo "🔧 Generating package-lock.json files for all services..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Generate package-lock.json for client
if [ ! -f client/package-lock.json ]; then
    print_status "Generating package-lock.json for Next.js Client..."
    cd client
    npm install --package-lock-only
    cd ..
    print_success "Client package-lock.json generated"
else
    print_status "Client package-lock.json already exists"
fi

# Generate package-lock.json for API Gateway
if [ ! -f services/api-gateway/package-lock.json ]; then
    print_status "Generating package-lock.json for API Gateway..."
    cd services/api-gateway
    npm install --package-lock-only
    cd ../..
    print_success "API Gateway package-lock.json generated"
else
    print_status "API Gateway package-lock.json already exists"
fi

# Generate package-lock.json for Data Ingestion
if [ ! -f services/data-ingestion/package-lock.json ]; then
    print_status "Generating package-lock.json for Data Ingestion..."
    cd services/data-ingestion
    npm install --package-lock-only
    cd ../..
    print_success "Data Ingestion package-lock.json generated"
else
    print_status "Data Ingestion package-lock.json already exists"
fi

# Generate package-lock.json for Backtesting
if [ ! -f services/backtesting/package-lock.json ]; then
    print_status "Generating package-lock.json for Backtesting..."
    cd services/backtesting
    npm install --package-lock-only
    cd ../..
    print_success "Backtesting package-lock.json generated"
else
    print_status "Backtesting package-lock.json already exists"
fi

print_success "✅ All package-lock.json files are ready!"