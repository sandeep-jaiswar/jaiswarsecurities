# Stock Screening Database Schema

This directory contains the complete database schema for a comprehensive stock screening and analysis system similar to Bloomberg Terminal. The schema is designed to capture all aspects of financial markets, company information, and trading analysis.

## Schema Overview

The database is organized into 9 main schema files:

### 1. Core Tables (`01-core-tables.sql`)
- **Companies**: Master company information with detailed business data
- **Securities**: Individual securities (stocks, bonds, ETFs) with trading information
- **Exchanges**: Global stock exchanges with trading hours and metadata
- **Countries/Currencies**: Geographic and currency reference data
- **Sectors/Industries**: Comprehensive industry classification

### 2. Market Data (`02-market-data.sql`)
- **OHLCV Data**: Daily and intraday price/volume data with quality metrics
- **Price Adjustments**: Stock splits, dividends, and other corporate actions
- **Trading Statistics**: Daily trading metrics and market activity
- **Market Depth**: Order book and bid/ask data
- **Volume Profile**: Volume distribution by price levels

### 3. Technical Analysis (`03-technical-indicators.sql`)
- **Technical Indicators**: 30+ technical indicators (SMA, EMA, RSI, MACD, etc.)
- **Chart Patterns**: Automated pattern detection with confidence scores
- **Support/Resistance**: Key price levels with strength analysis
- **Custom Indicators**: User-defined technical indicators

### 4. Financial Data (`04-financial-data.sql`)
- **Financial Statements**: Income statements, balance sheets, cash flow
- **Financial Ratios**: 50+ calculated financial ratios
- **Analyst Estimates**: Consensus estimates and revisions
- **Company Guidance**: Management guidance and forecasts
- **Financial Periods**: Flexible reporting period management

### 5. News and Events (`05-news-events.sql`)
- **News Articles**: Comprehensive news with sentiment analysis
- **Corporate Events**: Earnings, dividends, M&A, regulatory events
- **Economic Events**: Economic indicators and market-moving events
- **Earnings Calls**: Transcripts and analysis of earnings calls
- **News Sentiment**: AI-powered sentiment analysis

### 6. Stakeholders and Ownership (`06-stakeholders-ownership.sql`)
- **Stakeholders**: Institutional and individual investors
- **Ownership Records**: Detailed ownership positions and changes
- **Insider Transactions**: Executive and insider trading activity
- **Management**: Executive and board member information
- **Compensation**: Executive compensation analysis

### 7. Screening and Backtesting (`07-screening-backtesting.sql`)
- **Screens**: Flexible screening system with custom criteria
- **Backtesting**: Comprehensive strategy backtesting framework
- **Alerts**: Price and indicator alerts with history
- **Watchlists**: User portfolio tracking and management
- **Performance Analytics**: Screen and strategy performance tracking

### 8. User System (`08-user-system.sql`)
- **Users**: Complete user management with authentication
- **Roles/Permissions**: Granular permission system
- **User Preferences**: Customizable user settings
- **Audit Logs**: Complete audit trail for compliance
- **API Keys**: Programmatic access management

### 9. Seed Data (`09-seed-data.sql`)
- Reference data for countries, currencies, exchanges
- Sample companies and securities
- Default roles, permissions, and system configuration
- Technical indicator and pattern definitions

## Key Features

### Bloomberg-Level Functionality
- **Real-time and Historical Data**: Complete market data infrastructure
- **Financial Analysis**: Comprehensive fundamental and technical analysis
- **News Integration**: Multi-source news with sentiment analysis
- **Ownership Tracking**: Detailed stakeholder and insider tracking
- **Custom Screening**: Flexible screening with 50+ criteria
- **Backtesting**: Professional-grade strategy testing
- **Risk Management**: Portfolio and position risk analysis

### Scalability and Performance
- **Partitioning**: Large tables partitioned by date for performance
- **Indexing**: Comprehensive indexing strategy for fast queries
- **Data Quality**: Built-in data quality scoring and validation
- **Caching**: Redis integration for high-performance data access
- **API Rate Limiting**: Built-in rate limiting for external data sources

### Data Sources Integration
- **Multiple Providers**: Support for Alpha Vantage, Yahoo Finance, Polygon, etc.
- **Data Quality Tracking**: Source reliability and accuracy scoring
- **Fallback Systems**: Multiple data source redundancy
- **Real-time Updates**: Streaming data integration capabilities

### Compliance and Security
- **Audit Trail**: Complete audit logging for regulatory compliance
- **User Permissions**: Granular role-based access control
- **Data Privacy**: GDPR-compliant user data management
- **API Security**: Secure API key management and rate limiting

## Usage Examples

### Running a Stock Screen
```sql
-- Find undervalued tech stocks with strong momentum
SELECT s.symbol, c.name, sr.score
FROM screen_results sr
JOIN securities s ON sr.security_id = s.id
JOIN companies c ON s.company_id = c.id
WHERE sr.screen_id = (SELECT id FROM screens WHERE name = 'Value + Momentum')
AND sr.scan_date = CURRENT_DATE
ORDER BY sr.score DESC
LIMIT 20;
```

### Analyzing Financial Performance
```sql
-- Get latest financial ratios for a company
SELECT fr.*, fp.fiscal_year, fp.fiscal_quarter
FROM financial_ratios fr
JOIN financial_periods fp ON fr.financial_period_id = fp.id
WHERE fp.company_id = (SELECT id FROM companies WHERE name = 'Apple Inc.')
ORDER BY fp.period_end_date DESC
LIMIT 1;
```

### Tracking Insider Activity
```sql
-- Recent insider transactions for a stock
SELECT s.name, it.transaction_date, it.transaction_type, 
       it.shares_transacted, it.price_per_share, it.total_value
FROM insider_transactions it
JOIN stakeholders s ON it.stakeholder_id = s.id
WHERE it.company_id = (SELECT id FROM companies WHERE name = 'Tesla Inc.')
AND it.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY it.transaction_date DESC;
```

### News Sentiment Analysis
```sql
-- Recent news sentiment for a company
SELECT na.title, ns.overall_sentiment, ns.sentiment_label, na.published_at
FROM news_sentiment ns
JOIN news_articles na ON ns.news_article_id = na.id
WHERE ns.company_id = (SELECT id FROM companies WHERE name = 'Microsoft Corporation')
AND na.published_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY na.published_at DESC;
```

## Installation

1. **Create Database**: Create a PostgreSQL database
2. **Run Schema Files**: Execute schema files in order (01-09)
3. **Load Seed Data**: Run the seed data script
4. **Configure Indexes**: Ensure all indexes are created
5. **Set Permissions**: Configure user roles and permissions

## Maintenance

### Regular Tasks
- **Update Statistics**: Run ANALYZE on large tables weekly
- **Partition Management**: Create new partitions for time-series data
- **Index Maintenance**: Monitor and rebuild indexes as needed
- **Data Cleanup**: Archive old data based on retention policies

### Monitoring
- **Query Performance**: Monitor slow queries and optimize
- **Storage Usage**: Track table and index sizes
- **Data Quality**: Monitor data source reliability scores
- **User Activity**: Track system usage and performance

## Extensions

The schema is designed to be extensible:

- **New Data Sources**: Add new market data providers
- **Custom Indicators**: Create user-defined technical indicators
- **Additional Markets**: Support for forex, crypto, commodities
- **Advanced Analytics**: Machine learning model integration
- **Real-time Streaming**: WebSocket data integration

This schema provides a solid foundation for building a professional-grade financial analysis platform with Bloomberg-level capabilities.