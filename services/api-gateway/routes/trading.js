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
        patterns: i % 10 === 0 ? ['doji', 'hammer'] : []
      })),
      indicators: {
        sma20: Array.from({ length: 100 }, () => 150 + Math.random() * 5),
        sma50: Array.from({ length: 100 }, () => 148 + Math.random() * 5),
        rsi: Array.from({ length: 100 }, () => 30 + Math.random() * 40),
        macd: Array.from({ length: 100 }, () => -2 + Math.random() * 4)
      },
      annotations: [
        { type: 'trendline', points: [[0, 150], [50, 155]], color: 'blue' },
        { type: 'support', level: 148, color: 'green' },
        { type: 'resistance', level: 158, color: 'red' }
      ]
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
        impact: 'high'
      },
      {
        id: 2,
        title: 'Federal Reserve Signals Potential Rate Changes',
        summary: 'Central bank officials hint at policy adjustments...',
        source: 'Bloomberg',
        publishedAt: new Date(Date.now() - 3600000).toISOString(),
        sentiment: 'neutral',
        impact: 'medium'
      },
      {
        id: 3,
        title: `Analyst Upgrades ${symbol} to Strong Buy`,
        summary: 'Major investment bank raises price target...',
        source: 'CNBC',
        publishedAt: new Date(Date.now() - 7200000).toISOString(),
        sentiment: 'positive',
        impact: 'high'
      }
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
        priceTarget: 175.50,
        eps: {
          current: 6.15,
          next: 6.85,
          growth: 11.4
        }
      },
      ratings: {
        buy: 12,
        hold: 5,
        sell: 1
      },
      revisions: {
        up: 8,
        down: 2,
        unchanged: 8
      },
      analysts: [
        { firm: 'Goldman Sachs', rating: 'Buy', target: 180, date: '2024-01-15' },
        { firm: 'Morgan Stanley', rating: 'Buy', target: 175, date: '2024-01-12' },
        { firm: 'JP Morgan', rating: 'Hold', target: 165, date: '2024-01-10' }
      ]
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
        strength: 'Strong'
      },
      {
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        price: 285.30,
        change: 3.21,
        changePercent: 1.14,
        volume: 32100000,
        signal: 'BUY',
        strength: 'Medium'
      },
      {
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        price: 125.75,
        change: -1.25,
        changePercent: -0.98,
        volume: 28500000,
        signal: 'HOLD',
        strength: 'Weak'
      }
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
        largestLoss: -12.8
      },
      equityCurve: Array.from({ length: 100 }, (_, i) => ({
        date: new Date(Date.now() - (100 - i) * 24 * 60 * 60 * 1000).toISOString(),
        equity: 10000 * (1 + (i * 0.005) + (Math.random() - 0.5) * 0.02),
        drawdown: Math.random() * -0.1
      })),
      trades: [
        {
          entryDate: '2024-01-15',
          exitDate: '2024-01-20',
          symbol: 'AAPL',
          side: 'long',
          entryPrice: 150.25,
          exitPrice: 155.80,
          quantity: 100,
          pnl: 555,
          pnlPercent: 3.7
        }
      ]
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
        description: 'Strong reversal pattern detected'
      },
      {
        type: 'Doji',
        date: '2024-01-12',
        confidence: 72,
        signal: 'Neutral',
        description: 'Indecision in the market'
      },
      {
        type: 'Engulfing',
        date: '2024-01-10',
        confidence: 91,
        signal: 'Bullish',
        description: 'Strong bullish engulfing pattern'
      }
    ];
    
    res.json(patterns);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;