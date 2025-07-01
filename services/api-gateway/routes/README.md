# API Routes Documentation

This directory contains modular route handlers for the Bloomberg-style Stock Terminal API.

## Route Structure

### Authentication Routes (`/api/auth`)

- `POST /register` - User registration
- `POST /login` - User authentication
- `POST /logout` - User logout
- `GET /profile` - Get user profile
- `PUT /profile` - Update user profile

### Market Data Routes (`/api/market`)

- `GET /symbols` - List symbols with filtering
- `GET /symbols/{symbol}/quote` - Real-time quote
- `GET /symbols/{symbol}/chart` - Chart data with indicators
- `GET /symbols/{symbol}/fundamentals` - Fundamental data
- `GET /movers` - Market movers (gainers/losers/active)
- `GET /indices` - Major market indices
- `GET /sectors` - Sector performance
- `GET /currencies` - Currency rates
- `GET /commodities` - Commodity prices

### Analytics Routes (`/api/analytics`)

- `GET /market-overview` - Comprehensive market overview
- `GET /heatmap` - Market heatmap data
- `GET /correlation` - Correlation analysis
- `GET /volatility` - Volatility analysis
- `GET /momentum` - Momentum indicators
- `GET /sentiment` - Market sentiment analysis

### Portfolio Routes (`/api/portfolio`)

- `GET /watchlists` - User watchlists
- `POST /watchlists` - Create watchlist
- `PUT /watchlists/{id}` - Update watchlist
- `DELETE /watchlists/{id}` - Delete watchlist
- `GET /alerts` - User alerts
- `POST /alerts` - Create alert
- `PUT /alerts/{id}` - Update alert
- `DELETE /alerts/{id}` - Delete alert
- `GET /positions` - Portfolio positions
- `GET /performance` - Portfolio performance

### Research Routes (`/api/research`)

- `GET /news` - Financial news with sentiment
- `GET /earnings` - Earnings calendar
- `GET /estimates` - Analyst estimates
- `GET /insider-trading` - Insider trading activity
- `GET /institutional-holdings` - Institutional holdings
- `GET /sec-filings` - SEC filings
- `GET /events` - Corporate events

### Trading Routes (`/api/trading`)

- `GET /orderbook/{symbol}` - Order book data
- `GET /trades/{symbol}` - Recent trades
- `GET /options/{symbol}` - Options chain
- `GET /futures` - Futures data
- `GET /forex` - Forex rates

### Screening Routes (`/api/screening`)

- `GET /screens` - Available screens
- `POST /screens` - Create custom screen
- `POST /screens/{id}/run` - Run screen
- `GET /screens/{id}/results` - Screen results
- `GET /criteria` - Available criteria

### Backtesting Routes (`/api/backtesting`)

- `GET /strategies` - Available strategies
- `POST /strategies` - Create strategy
- `GET /backtests` - Backtest results
- `POST /backtests` - Start backtest
- `GET /backtests/{id}` - Backtest details
- `GET /backtests/{id}/trades` - Backtest trades
- `GET /backtests/{id}/performance` - Performance metrics

### Risk Management Routes (`/api/risk`)

- `GET /var` - Value at Risk calculations
- `GET /stress-test` - Stress testing
- `GET /correlation` - Risk correlation
- `GET /exposure` - Risk exposure analysis

### Economic Data Routes (`/api/economic`)

- `GET /indicators` - Economic indicators
- `GET /calendar` - Economic calendar
- `GET /fed` - Federal Reserve data
- `GET /treasury` - Treasury rates

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Rate Limiting

Different rate limits apply to different endpoint categories:

- General endpoints: 1000 requests per 15 minutes
- Market data: 100 requests per minute
- Authentication: 5 requests per 15 minutes

## WebSocket Endpoints

Real-time data is available via WebSocket connections:

- Market quotes
- Order book updates
- Trade executions
- News alerts
- Price alerts

## Error Handling

All endpoints return consistent error responses:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## Pagination

List endpoints support pagination:

```
GET /api/endpoint?limit=50&offset=100
```

## Filtering and Sorting

Most list endpoints support filtering and sorting:

```
GET /api/market/symbols?sector=TECH&sortBy=market_cap&sortOrder=DESC
```
