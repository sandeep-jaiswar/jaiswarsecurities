# Stock Screening System with Backtesting

A comprehensive stock screening and backtesting system built with Docker, featuring n8n workflow automation, PostgreSQL database, Kafka message streaming, Liquibase migrations, and LocalStack for AWS services simulation.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │  Data Ingestion │    │   Backtesting   │
│     (3000)      │    │     Service     │    │     Service     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
         │   PostgreSQL    │    │      Kafka      │    │      Redis      │
         │     (5432)      │    │     (9092)      │    │     (6379)      │
         └─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
         ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
         │       n8n       │    │   Liquibase     │    │   LocalStack    │
         │     (5678)      │    │   (Migrations)  │    │     (4566)      │
         └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

### Core Functionality
- **Stock Data Ingestion**: Real-time and batch data ingestion from multiple sources
- **Technical Indicators**: 15+ technical indicators (SMA, EMA, RSI, MACD, Bollinger Bands, etc.)
- **Stock Screening**: Custom screening criteria with real-time results
- **Backtesting Engine**: Strategy backtesting with comprehensive performance metrics
- **Watchlists & Alerts**: Portfolio management and price/indicator alerts
- **RESTful API**: Comprehensive API with Swagger documentation

### Technology Stack
- **Database**: PostgreSQL with Liquibase migrations
- **Message Queue**: Apache Kafka for event streaming
- **Cache**: Redis for high-performance caching
- **Workflow**: n8n for automation and data pipelines
- **Cloud Services**: LocalStack for AWS services simulation
- **Containerization**: Docker and Docker Compose
- **API Documentation**: Swagger/OpenAPI 3.0

### AWS Services (via LocalStack)
- **S3**: Data storage and backups
- **SQS**: Message queuing with DLQ support
- **SNS**: Notifications and alerts
- **CloudWatch**: Logging and monitoring
- **CloudFormation**: Infrastructure as Code

## 📋 Prerequisites

- Docker and Docker Compose
- Make (optional, for convenience commands)
- AWS CLI (for LocalStack interaction)
- 8GB+ RAM recommended

## 🛠️ Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd stock-screening-system
cp .env.example .env
# Edit .env file with your API keys
```

### 2. Initialize System
```bash
# Using Make (recommended)
make init

# Or manually
docker-compose build
docker-compose up -d
make migrate
make seed
```

### 3. Access Services
- **n8n Workflow**: http://localhost:5678 (admin/admin123)
- **API Gateway**: http://localhost:3000
- **API Documentation**: http://localhost:3000/api-docs
- **LocalStack**: http://localhost:4566

## 🔧 Configuration

### Environment Variables
Key configuration options in `.env`:

```bash
# Database
POSTGRES_USER=stockuser
POSTGRES_PASSWORD=stockpass123
POSTGRES_DB=stockdb

# API Keys
ALPHA_VANTAGE_API_KEY=your_key_here
YAHOO_FINANCE_API_KEY=your_key_here
POLYGON_API_KEY=your_key_here

# Backtesting
BACKTEST_INITIAL_CAPITAL=100000
BACKTEST_COMMISSION=0.001
```

### Data Sources
Configure multiple data sources:
- Alpha Vantage (5 calls/minute)
- Yahoo Finance (2000 calls/minute)
- Polygon.io (1000 calls/minute)

## 📊 Database Schema

### Core Tables
- **symbols**: Stock symbols and metadata
- **ohlcv**: Price and volume data
- **indicators**: Technical indicators
- **strategies**: Trading strategies
- **backtests**: Backtest configurations and results
- **screens**: Screening criteria
- **watchlists**: User watchlists
- **alerts**: Price and indicator alerts

### Performance Optimizations
- Comprehensive indexing strategy
- Partitioning for large datasets
- Connection pooling
- Query optimization

## 🔄 API Endpoints

### Market Data
```bash
GET /api/symbols                    # List all symbols
GET /api/symbols/{symbol}           # Symbol details
GET /api/symbols/{symbol}/ohlcv     # Price data
GET /api/symbols/{symbol}/indicators # Technical indicators
```

### Screening
```bash
GET /api/screens                    # List screens
POST /api/screens/{id}/run          # Run screen
GET /api/screens/{id}/results       # Screen results
```

### Backtesting
```bash
GET /api/strategies                 # List strategies
POST /api/backtest                  # Start backtest
GET /api/backtests/{id}            # Backtest results
GET /api/backtests/{id}/trades     # Trade history
GET /api/backtests/{id}/equity-curve # Performance curve
```

### Portfolio Management
```bash
GET /api/watchlists                 # List watchlists
GET /api/watchlists/{id}/symbols    # Watchlist symbols
POST /api/alerts                    # Create alert
GET /api/alerts                     # List alerts
```

## 🧪 Testing

### Run Tests
```bash
make test
# Or individually
docker-compose exec data-ingestion npm test
docker-compose exec backtesting npm test
docker-compose exec api-gateway npm test
```

### Health Checks
```bash
make health
curl http://localhost:3000/health
```

## 📈 Backtesting Strategies

### Built-in Strategies
1. **SMA Crossover**: Moving average crossover signals
2. **RSI Mean Reversion**: Oversold/overbought RSI signals
3. **Bollinger Bands**: Band breakout/breakdown signals

### Custom Strategies
Create custom strategies by:
1. Adding strategy to `strategies` table
2. Implementing logic in backtesting service
3. Configuring parameters via JSON

### Performance Metrics
- Total Return
- Sharpe Ratio
- Maximum Drawdown
- Win Rate
- Profit Factor
- Risk-adjusted returns

## 🔍 Stock Screening

### Pre-built Screens
- High Volume Breakout
- Oversold Value Stocks
- Momentum Stocks
- Technical Pattern Recognition

### Custom Screening
Create screens with criteria:
```json
{
  "rsi": {"min": 30, "max": 70},
  "volume_ratio": {"min": 2.0},
  "price_change": {"min": 0.05},
  "market_cap": {"min": 1000000000}
}
```

## 🚀 Deployment

### LocalStack Deployment
```bash
make deploy
./scripts/deploy-localstack.sh
```

### Production Deployment
```bash
# Update environment for production
cp .env.prod .env

# Deploy with production configuration
make prod
```

### AWS Deployment
Use the CloudFormation templates in `/cloudformation/` for AWS deployment.

## 📊 Monitoring & Logging

### Logging
- Structured JSON logging
- Log levels: error, warn, info, debug
- Centralized logging via CloudWatch

### Monitoring
- Health check endpoints
- Performance metrics
- Error tracking
- Resource utilization

### Alerts
- System health alerts
- Data quality alerts
- Performance degradation alerts

## 🛠️ Development

### Local Development
```bash
# Start in development mode
make dev

# View logs
make logs

# Access specific service logs
make logs-api-gateway
make logs-data-ingestion
```

### Adding New Features
1. Update database schema in Liquibase migrations
2. Implement service logic
3. Add API endpoints
4. Update documentation
5. Add tests

### Code Structure
```
services/
├── data-ingestion/     # Data ingestion service
├── backtesting/        # Backtesting engine
└── api-gateway/        # API gateway and REST endpoints

liquibase/
└── changelog/          # Database migrations

cloudformation/         # AWS infrastructure templates
scripts/               # Deployment and utility scripts
```

## 🔒 Security

### Security Features
- Rate limiting
- CORS protection
- Helmet.js security headers
- Input validation
- SQL injection prevention

### Authentication
- JWT token authentication
- Role-based access control
- API key management

## 📚 Documentation

### API Documentation
- Swagger/OpenAPI 3.0 specification
- Interactive API explorer
- Code examples and schemas

### Database Documentation
- ERD diagrams
- Table relationships
- Index strategies

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues
- **Port conflicts**: Ensure ports 3000, 5432, 5678, 9092, 6379, 4566 are available
- **Memory issues**: Increase Docker memory allocation to 8GB+
- **API rate limits**: Configure API keys and respect rate limits

### Getting Help
- Check logs: `make logs`
- Health checks: `make health`
- Documentation: http://localhost:3000/api-docs
- Issues: Create GitHub issue with logs and configuration

## 🔮 Roadmap

### Upcoming Features
- Machine learning models for price prediction
- Real-time WebSocket data feeds
- Advanced portfolio optimization
- Options and derivatives support
- Mobile application
- Advanced charting and visualization
- Social trading features

### Performance Improvements
- Database sharding
- Microservices architecture
- Kubernetes deployment
- Advanced caching strategies
- Real-time data processing