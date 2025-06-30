const express = require('express');
const router = express.Router();

// Trading chart data
router.get('/chart/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { timeframe = 'Daily' } = req.query;

    // Mock chart data with candlestick patterns
    const chartData = {
      symbol,
      timeframe,
      data: Array.from({ length: 100 }, (_, i) => ({
        timestamp: new Date(Date.now() - (100 - i) * 24 * 60 * 60 * 1000).toISOString(),
        open: 150 + Math.random() * 10,
        high: 155 + Math.random() * 10,
        low: 145 + Math.random() * 10,
        close: 150 + Math.random() * 10,
        volume: Math.floor(Math.random() * 1000000),
        patterns: i % 10 === 0 ? ['doji', 'hammer'] : [],
      })),
      indicators: {
        sma20: Array.from({ length: 100 }, () => 150 + Math.random() * 5),
        sma50: Array.from({ length: 100 }, () => 148 + Math.random() * 5),
        rsi: Array.from({ length: 100 }, () => 30 + Math.random() * 40),
        macd: Array.from({ length: 100 }, () => -2 + Math.random() * 4),
      },
      annotations: [
        {
          type: 'trendline',
          points: [
            [0, 150],
            [50, 155],
          ],
          color: 'blue',
        },
        { type: 'support', level: 148, color: 'green' },
        { type: 'resistance', level: 158, color: 'red' },
      ],
    };

    res.json(chartData);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Trading news
router.get('/news/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    const news = [
      {
        id: 1,
        title: `${symbol} Reaches New Highs Amid Strong Earnings`,
        summary: 'Company reports better than expected quarterly results...',
        source: 'Reuters',
        publishedAt: new Date().toISOString(),
        sentiment: 'positive',
        impact: 'high',
      },
      {
        id: 2,
        title: 'Federal Reserve Signals Potential Rate Changes',
        summary: 'Central bank officials hint at policy adjustments...',
        source: 'Bloomberg',
        publishedAt: new Date(Date.now() - 3600000).toISOString(),
        sentiment: 'neutral',
        impact: 'medium',
      },
      {
        id: 3,
        title: `Analyst Upgrades ${symbol} to Strong Buy`,
        summary: 'Major investment bank raises price target...',
        source: 'CNBC',
        publishedAt: new Date(Date.now() - 7200000).toISOString(),
        sentiment: 'positive',
        impact: 'high',
      },
    ];

    res.json(news);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Analyst estimates
router.get('/analyst-estimates/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    const estimates = {
      symbol,
      consensus: {
        rating: 'Buy',
        priceTarget: 175.5,
        eps: {
          current: 6.15,
          next: 6.85,
          growth: 11.4,
        },
      },
      ratings: {
        buy: 12,
        hold: 5,
        sell: 1,
      },
      revisions: {
        up: 8,
        down: 2,
        unchanged: 8,
      },
      analysts: [
        { firm: 'Goldman Sachs', rating: 'Buy', target: 180, date: '2024-01-15' },
        { firm: 'Morgan Stanley', rating: 'Buy', target: 175, date: '2024-01-12' },
        { firm: 'JP Morgan', rating: 'Hold', target: 165, date: '2024-01-10' },
      ],
    };

    res.json(estimates);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Market scanner
router.get('/market-scanner', async (req, res) => {
  try {
    const scanResults = [
      {
        symbol: 'AAPL',
        name: 'Apple Inc.',
        price: 185.52,
        change: 2.45,
        changePercent: 1.34,
        volume: 45200000,
        signal: 'BUY',
        strength: 'Strong',
      },
      {
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        price: 285.3,
        change: 3.21,
        changePercent: 1.14,
        volume: 32100000,
        signal: 'BUY',
        strength: 'Medium',
      },
      {
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        price: 125.75,
        change: -1.25,
        changePercent: -0.98,
        volume: 28500000,
        signal: 'HOLD',
        strength: 'Weak',
      },
    ];

    res.json(scanResults);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Backtesting performance
router.get('/backtest-performance', async (req, res) => {
  try {
    const performance = {
      strategy: 'Keltner Channel Buy X Up, Sell Y Down',
      period: '2020-2024',
      metrics: {
        totalReturn: 44.49,
        annualReturn: 104.2,
        maxDrawdown: -41.5,
        sharpeRatio: 1.39,
        sortinoRatio: 1.85,
        winRate: 75.0,
        profitFactor: 2.02,
        totalTrades: 43,
        winningTrades: 32,
        losingTrades: 11,
        avgWin: 8.5,
        avgLoss: -4.2,
        largestWin: 25.3,
        largestLoss: -12.8,
      },
      equityCurve: Array.from({ length: 100 }, (_, i) => ({
        date: new Date(Date.now() - (100 - i) * 24 * 60 * 60 * 1000).toISOString(),
        equity: 10000 * (1 + i * 0.005 + (Math.random() - 0.5) * 0.02),
        drawdown: Math.random() * -0.1,
      })),
      trades: [
        {
          entryDate: '2024-01-15',
          exitDate: '2024-01-20',
          symbol: 'AAPL',
          side: 'long',
          entryPrice: 150.25,
          exitPrice: 155.8,
          quantity: 100,
          pnl: 555,
          pnlPercent: 3.7,
        },
      ],
    };

    res.json(performance);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Pattern recognition
router.get('/patterns/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    const patterns = [
      {
        type: 'Hammer',
        date: '2024-01-15',
        confidence: 85,
        signal: 'Bullish',
        description: 'Strong reversal pattern detected',
      },
      {
        type: 'Doji',
        date: '2024-01-12',
        confidence: 72,
        signal: 'Neutral',
        description: 'Indecision in the market',
      },
      {
        type: 'Engulfing',
        date: '2024-01-10',
        confidence: 91,
        signal: 'Bullish',
        description: 'Strong bullish engulfing pattern',
      },
    ];

    res.json(patterns);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Options chain
router.get('/options/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { expiration } = req.query;

    // Mock options chain data
    const expirations = [
      '2024-02-16',
      '2024-02-23',
      '2024-03-01',
      '2024-03-15',
      '2024-04-19',
      '2024-06-21',
    ];

    const selectedExpiration = expiration || expirations[0];

    // Generate mock options data
    const currentPrice = 150.25; // Mock current price
    const strikes = [];
    for (let i = -10; i <= 10; i++) {
      strikes.push(Math.round((currentPrice + i * 5) * 100) / 100);
    }

    const options = {
      symbol,
      currentPrice,
      expirations,
      selectedExpiration,
      calls: strikes.map((strike) => ({
        strike,
        lastPrice: Math.max(0.01, (currentPrice - strike + Math.random() * 5).toFixed(2)),
        bid: Math.max(0.01, (currentPrice - strike + Math.random() * 4).toFixed(2)),
        ask: Math.max(0.01, (currentPrice - strike + Math.random() * 6).toFixed(2)),
        change: (Math.random() * 2 - 1).toFixed(2),
        volume: Math.floor(Math.random() * 1000),
        openInterest: Math.floor(Math.random() * 5000),
        impliedVolatility: (0.2 + Math.random() * 0.3).toFixed(2),
        delta: Math.min(1, Math.max(0, (0.5 + (currentPrice - strike) / 20).toFixed(2))),
        gamma: (0.02 + Math.random() * 0.03).toFixed(3),
        theta: (-0.05 - Math.random() * 0.1).toFixed(3),
        vega: (0.1 + Math.random() * 0.1).toFixed(3),
        rho: (0.05 + Math.random() * 0.05).toFixed(3),
      })),
      puts: strikes.map((strike) => ({
        strike,
        lastPrice: Math.max(0.01, (strike - currentPrice + Math.random() * 5).toFixed(2)),
        bid: Math.max(0.01, (strike - currentPrice + Math.random() * 4).toFixed(2)),
        ask: Math.max(0.01, (strike - currentPrice + Math.random() * 6).toFixed(2)),
        change: (Math.random() * 2 - 1).toFixed(2),
        volume: Math.floor(Math.random() * 1000),
        openInterest: Math.floor(Math.random() * 5000),
        impliedVolatility: (0.2 + Math.random() * 0.3).toFixed(2),
        delta: Math.min(0, Math.max(-1, (-0.5 - (currentPrice - strike) / 20).toFixed(2))),
        gamma: (0.02 + Math.random() * 0.03).toFixed(3),
        theta: (-0.05 - Math.random() * 0.1).toFixed(3),
        vega: (0.1 + Math.random() * 0.1).toFixed(3),
        rho: (-0.05 - Math.random() * 0.05).toFixed(3),
      })),
    };

    res.json(options);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Order book data
router.get('/orderbook/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { depth = 10 } = req.query;

    // Generate mock order book data
    const currentPrice = 150.25; // Mock current price
    const bids = [];
    const asks = [];

    for (let i = 0; i < parseInt(depth); i++) {
      bids.push({
        price: (currentPrice - 0.01 * (i + 1)).toFixed(2),
        size: Math.floor(100 + Math.random() * 1000),
        orders: Math.floor(1 + Math.random() * 20),
      });

      asks.push({
        price: (currentPrice + 0.01 * (i + 1)).toFixed(2),
        size: Math.floor(100 + Math.random() * 1000),
        orders: Math.floor(1 + Math.random() * 20),
      });
    }

    const orderBook = {
      symbol,
      timestamp: new Date().toISOString(),
      bids,
      asks,
      spread: (asks[0].price - bids[0].price).toFixed(2),
      depth: parseInt(depth),
    };

    res.json(orderBook);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Recent trades
router.get('/trades/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { limit = 20 } = req.query;

    // Generate mock recent trades
    const currentPrice = 150.25; // Mock current price
    const trades = [];

    for (let i = 0; i < parseInt(limit); i++) {
      const price = (currentPrice + (Math.random() - 0.5) * 0.5).toFixed(2);
      const size = Math.floor(10 + Math.random() * 500);
      const timestamp = new Date(Date.now() - i * 1000 * 10).toISOString();
      const side = Math.random() > 0.5 ? 'buy' : 'sell';

      trades.push({
        id: Date.now() - i,
        symbol,
        price,
        size,
        timestamp,
        side,
        exchange: 'NASDAQ',
      });
    }

    res.json({
      symbol,
      trades,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Level 2 market data
router.get('/level2/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { depth = 20 } = req.query;

    // Generate mock level 2 data with multiple exchanges
    const currentPrice = 150.25; // Mock current price
    const exchanges = ['NASDAQ', 'NYSE', 'ARCA', 'BATS', 'EDGX'];
    const bids = [];
    const asks = [];

    for (let i = 0; i < parseInt(depth); i++) {
      const exchange = exchanges[Math.floor(Math.random() * exchanges.length)];
      const bidPrice = (currentPrice - 0.01 * (i + 1)).toFixed(2);
      const askPrice = (currentPrice + 0.01 * (i + 1)).toFixed(2);
      const bidSize = Math.floor(100 + Math.random() * 1000);
      const askSize = Math.floor(100 + Math.random() * 1000);

      bids.push({
        price: bidPrice,
        size: bidSize,
        exchange,
        time: new Date(Date.now() - Math.random() * 60000).toISOString(),
      });

      asks.push({
        price: askPrice,
        size: askSize,
        exchange,
        time: new Date(Date.now() - Math.random() * 60000).toISOString(),
      });
    }

    // Sort bids (descending) and asks (ascending)
    bids.sort((a, b) => parseFloat(b.price) - parseFloat(a.price));
    asks.sort((a, b) => parseFloat(a.price) - parseFloat(b.price));

    const level2Data = {
      symbol,
      timestamp: new Date().toISOString(),
      bids,
      asks,
      spread: (parseFloat(asks[0].price) - parseFloat(bids[0].price)).toFixed(2),
      depth: parseInt(depth),
    };

    res.json(level2Data);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Historical volatility
router.get('/volatility/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { period = '1Y' } = req.query;

    // Generate mock volatility data
    const periods = {
      '1M': 30,
      '3M': 90,
      '6M': 180,
      '1Y': 252,
      '2Y': 504,
    };

    const days = periods[period] || 252;
    const volatilityData = {
      symbol,
      period,
      historicalVolatility: (15 + Math.random() * 10).toFixed(2),
      impliedVolatility: (20 + Math.random() * 15).toFixed(2),
      volatilityRatio: (0.8 + Math.random() * 0.4).toFixed(2),
      volatilityPercentile: (Math.random() * 100).toFixed(2),
      data: Array.from({ length: days }, (_, i) => ({
        date: new Date(Date.now() - (days - i) * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        historicalVolatility: (15 + Math.random() * 10).toFixed(2),
        impliedVolatility: (20 + Math.random() * 15).toFixed(2),
      })),
    };

    res.json(volatilityData);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Risk metrics
router.get('/risk/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    // Generate mock risk metrics
    const riskMetrics = {
      symbol,
      beta: (0.8 + Math.random() * 0.8).toFixed(2),
      alpha: (-2 + Math.random() * 4).toFixed(2),
      sharpeRatio: (0.5 + Math.random() * 1.5).toFixed(2),
      sortinoRatio: (0.7 + Math.random() * 1.8).toFixed(2),
      maxDrawdown: (-5 - Math.random() * 20).toFixed(2),
      valueAtRisk: {
        daily95: (-1 - Math.random() * 3).toFixed(2),
        daily99: (-2 - Math.random() * 4).toFixed(2),
        weekly95: (-2 - Math.random() * 5).toFixed(2),
        weekly99: (-3 - Math.random() * 7).toFixed(2),
      },
      correlations: {
        SPY: (0.5 + Math.random() * 0.5).toFixed(2),
        QQQ: (0.4 + Math.random() * 0.6).toFixed(2),
        DIA: (0.3 + Math.random() * 0.5).toFixed(2),
      },
      volatility: {
        daily: (1 + Math.random() * 2).toFixed(2),
        weekly: (2 + Math.random() * 3).toFixed(2),
        monthly: (4 + Math.random() * 5).toFixed(2),
        annualized: (15 + Math.random() * 10).toFixed(2),
      },
    };

    res.json(riskMetrics);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;