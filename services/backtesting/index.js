const express = require('express');
const { Pool } = require('pg');
const { Kafka } = require('kafkajs');
const winston = require('winston');
const { SMA, EMA, RSI, MACD, BollingerBands } = require('technicalindicators');
require('dotenv').config();

// Initialize logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});

// Initialize database connection
const pool = new Pool({
  connectionString: process.env.POSTGRES_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Initialize Kafka
const kafka = new Kafka({
  clientId: 'backtesting-service',
  brokers: process.env.KAFKA_BROKERS.split(','),
});

const producer = kafka.producer();
const consumer = kafka.consumer({ groupId: 'backtesting-group' });

// Initialize Express app
const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Backtesting endpoints
app.post('/backtest', async (req, res) => {
  try {
    const { strategyId, name, startDate, endDate, initialCapital, symbols } = req.body;
    
    const backtestId = await createBacktest({
      strategyId,
      name,
      startDate,
      endDate,
      initialCapital,
      commission: process.env.BACKTEST_COMMISSION || 0.001,
      slippage: 0.001
    });
    
    // Start backtesting process
    await runBacktest(backtestId, symbols || []);
    
    res.json({ 
      message: 'Backtest started', 
      backtestId,
      status: 'running'
    });
  } catch (error) {
    logger.error('Error starting backtest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/backtest/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const backtest = await getBacktestResults(id);
    res.json(backtest);
  } catch (error) {
    logger.error('Error getting backtest results:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/backtest/:id/trades', async (req, res) => {
  try {
    const { id } = req.params;
    const trades = await getBacktestTrades(id);
    res.json(trades);
  } catch (error) {
    logger.error('Error getting backtest trades:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/backtest/:id/equity-curve', async (req, res) => {
  try {
    const { id } = req.params;
    const equityCurve = await getEquityCurve(id);
    res.json(equityCurve);
  } catch (error) {
    logger.error('Error getting equity curve:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create backtest record
async function createBacktest(params) {
  const client = await pool.connect();
  try {
    const query = `
      INSERT INTO backtests (strategy_id, name, start_date, end_date, initial_capital, commission, slippage, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'running')
      RETURNING id
    `;
    
    const result = await client.query(query, [
      params.strategyId,
      params.name,
      params.startDate,
      params.endDate,
      params.initialCapital,
      params.commission,
      params.slippage
    ]);
    
    return result.rows[0].id;
  } finally {
    client.release();
  }
}

// Run backtest
async function runBacktest(backtestId, symbols) {
  try {
    logger.info(`Starting backtest ${backtestId}`);
    
    // Get backtest configuration
    const backtestConfig = await getBacktestConfig(backtestId);
    const strategy = await getStrategy(backtestConfig.strategy_id);
    
    // Get symbols to test (if not provided, use all active symbols)
    if (symbols.length === 0) {
      const result = await pool.query('SELECT id, symbol FROM symbols WHERE is_active = true LIMIT 10');
      symbols = result.rows;
    }
    
    // Initialize portfolio
    let portfolio = {
      cash: backtestConfig.initial_capital,
      positions: {},
      totalValue: backtestConfig.initial_capital,
      trades: [],
      equityCurve: []
    };
    
    // Get date range
    const startDate = new Date(backtestConfig.start_date);
    const endDate = new Date(backtestConfig.end_date);
    
    // Run backtest for each trading day
    for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + 1)) {
      // Skip weekends
      if (date.getDay() === 0 || date.getDay() === 6) continue;
      
      const dateStr = date.toISOString().split('T')[0];
      
      // Process each symbol
      for (const symbol of symbols) {
        await processSymbolForDate(backtestId, symbol, dateStr, strategy, portfolio);
      }
      
      // Update portfolio value and equity curve
      await updatePortfolioValue(backtestId, dateStr, portfolio, symbols);
    }
    
    // Calculate final statistics
    await calculateBacktestStatistics(backtestId, portfolio);
    
    // Update backtest status
    await pool.query(
      'UPDATE backtests SET status = $1, completed_at = NOW() WHERE id = $2',
      ['completed', backtestId]
    );
    
    logger.info(`Completed backtest ${backtestId}`);
    
    // Send completion message to Kafka
    await producer.send({
      topic: 'backtest-completed',
      messages: [{
        key: backtestId.toString(),
        value: JSON.stringify({ 
          backtestId, 
          status: 'completed',
          totalTrades: portfolio.trades.length,
          timestamp: new Date() 
        })
      }]
    });
    
  } catch (error) {
    logger.error(`Error running backtest ${backtestId}:`, error);
    
    // Update backtest status to failed
    await pool.query(
      'UPDATE backtests SET status = $1 WHERE id = $2',
      ['failed', backtestId]
    );
    
    throw error;
  }
}

// Process symbol for specific date
async function processSymbolForDate(backtestId, symbol, date, strategy, portfolio) {
  try {
    // Get market data and indicators for the date
    const marketData = await getMarketDataForDate(symbol.id, date);
    if (!marketData) return;
    
    const indicators = await getIndicatorsForDate(symbol.id, date);
    if (!indicators) return;
    
    // Apply strategy logic
    const signal = applyStrategy(strategy, marketData, indicators, portfolio.positions[symbol.symbol]);
    
    if (signal.action === 'buy' && !portfolio.positions[symbol.symbol]) {
      await executeBuyOrder(backtestId, symbol, date, marketData, signal, portfolio);
    } else if (signal.action === 'sell' && portfolio.positions[symbol.symbol]) {
      await executeSellOrder(backtestId, symbol, date, marketData, signal, portfolio);
    }
    
  } catch (error) {
    logger.error(`Error processing ${symbol.symbol} for ${date}:`, error);
  }
}

// Apply strategy logic
function applyStrategy(strategy, marketData, indicators, currentPosition) {
  const params = strategy.parameters;
  
  switch (strategy.name) {
    case 'Simple Moving Average Crossover':
      return applySMACrossoverStrategy(marketData, indicators, params, currentPosition);
    
    case 'RSI Mean Reversion':
      return applyRSIMeanReversionStrategy(marketData, indicators, params, currentPosition);
    
    case 'Bollinger Bands Breakout':
      return applyBollingerBandsStrategy(marketData, indicators, params, currentPosition);
    
    default:
      return { action: 'hold' };
  }
}

// SMA Crossover Strategy
function applySMACrossoverStrategy(marketData, indicators, params, currentPosition) {
  const shortMA = indicators.sma_20;
  const longMA = indicators.sma_50;
  
  if (!shortMA || !longMA) return { action: 'hold' };
  
  if (!currentPosition && shortMA > longMA) {
    return {
      action: 'buy',
      reason: 'SMA crossover - short MA above long MA',
      stopLoss: marketData.close_price * (1 - params.stop_loss),
      takeProfit: marketData.close_price * (1 + params.take_profit)
    };
  }
  
  if (currentPosition && shortMA < longMA) {
    return {
      action: 'sell',
      reason: 'SMA crossover - short MA below long MA'
    };
  }
  
  // Check stop loss and take profit
  if (currentPosition) {
    if (marketData.close_price <= currentPosition.stopLoss) {
      return { action: 'sell', reason: 'Stop loss triggered' };
    }
    if (marketData.close_price >= currentPosition.takeProfit) {
      return { action: 'sell', reason: 'Take profit triggered' };
    }
  }
  
  return { action: 'hold' };
}

// RSI Mean Reversion Strategy
function applyRSIMeanReversionStrategy(marketData, indicators, params, currentPosition) {
  const rsi = indicators.rsi_14;
  
  if (!rsi) return { action: 'hold' };
  
  if (!currentPosition && rsi < params.oversold) {
    return {
      action: 'buy',
      reason: `RSI oversold at ${rsi}`,
      stopLoss: marketData.close_price * (1 - params.stop_loss)
    };
  }
  
  if (currentPosition && rsi > params.overbought) {
    return {
      action: 'sell',
      reason: `RSI overbought at ${rsi}`
    };
  }
  
  // Check stop loss
  if (currentPosition && marketData.close_price <= currentPosition.stopLoss) {
    return { action: 'sell', reason: 'Stop loss triggered' };
  }
  
  return { action: 'hold' };
}

// Bollinger Bands Strategy
function applyBollingerBandsStrategy(marketData, indicators, params, currentPosition) {
  const upperBand = indicators.bb_upper;
  const lowerBand = indicators.bb_lower;
  
  if (!upperBand || !lowerBand) return { action: 'hold' };
  
  if (!currentPosition && marketData.close_price > upperBand) {
    return {
      action: 'buy',
      reason: 'Bollinger Bands upper breakout',
      stopLoss: marketData.close_price * (1 - params.stop_loss),
      takeProfit: marketData.close_price * (1 + params.take_profit)
    };
  }
  
  if (currentPosition && marketData.close_price < lowerBand) {
    return {
      action: 'sell',
      reason: 'Bollinger Bands lower breakdown'
    };
  }
  
  // Check stop loss and take profit
  if (currentPosition) {
    if (marketData.close_price <= currentPosition.stopLoss) {
      return { action: 'sell', reason: 'Stop loss triggered' };
    }
    if (marketData.close_price >= currentPosition.takeProfit) {
      return { action: 'sell', reason: 'Take profit triggered' };
    }
  }
  
  return { action: 'hold' };
}

// Execute buy order
async function executeBuyOrder(backtestId, symbol, date, marketData, signal, portfolio) {
  const price = marketData.close_price;
  const commission = price * 0.001; // 0.1% commission
  const maxPositionSize = portfolio.cash * 0.1; // Max 10% per position
  const quantity = Math.floor(maxPositionSize / (price + commission));
  
  if (quantity <= 0 || portfolio.cash < (quantity * price + commission)) {
    return; // Not enough cash
  }
  
  const totalCost = quantity * price + commission;
  
  // Update portfolio
  portfolio.cash -= totalCost;
  portfolio.positions[symbol.symbol] = {
    quantity,
    entryPrice: price,
    entryDate: date,
    stopLoss: signal.stopLoss,
    takeProfit: signal.takeProfit
  };
  
  // Record trade
  const trade = {
    backtestId,
    symbolId: symbol.id,
    entryDate: date,
    side: 'long',
    entryPrice: price,
    quantity,
    commission,
    status: 'open',
    entrySignal: signal
  };
  
  portfolio.trades.push(trade);
  
  // Save to database
  await saveTradeToDatabase(trade);
  
  logger.info(`BUY: ${symbol.symbol} x${quantity} @ ${price} on ${date}`);
}

// Execute sell order
async function executeSellOrder(backtestId, symbol, date, marketData, signal, portfolio) {
  const position = portfolio.positions[symbol.symbol];
  if (!position) return;
  
  const price = marketData.close_price;
  const commission = price * position.quantity * 0.001;
  const totalProceeds = position.quantity * price - commission;
  
  // Calculate P&L
  const pnl = totalProceeds - (position.quantity * position.entryPrice);
  const pnlPercent = (pnl / (position.quantity * position.entryPrice)) * 100;
  
  // Update portfolio
  portfolio.cash += totalProceeds;
  delete portfolio.positions[symbol.symbol];
  
  // Update trade record
  const trade = portfolio.trades.find(t => 
    t.symbolId === symbol.id && 
    t.entryDate === position.entryDate && 
    t.status === 'open'
  );
  
  if (trade) {
    trade.exitDate = date;
    trade.exitPrice = price;
    trade.pnl = pnl;
    trade.pnlPercent = pnlPercent;
    trade.status = 'closed';
    trade.exitSignal = signal;
    
    // Update in database
    await updateTradeInDatabase(trade);
  }
  
  logger.info(`SELL: ${symbol.symbol} x${position.quantity} @ ${price} on ${date}, P&L: ${pnl.toFixed(2)}`);
}

// Get market data for date
async function getMarketDataForDate(symbolId, date) {
  const result = await pool.query(
    'SELECT * FROM ohlcv WHERE symbol_id = $1 AND trade_date = $2',
    [symbolId, date]
  );
  return result.rows[0];
}

// Get indicators for date
async function getIndicatorsForDate(symbolId, date) {
  const result = await pool.query(
    'SELECT * FROM indicators WHERE symbol_id = $1 AND trade_date = $2',
    [symbolId, date]
  );
  return result.rows[0];
}

// Save trade to database
async function saveTradeToDatabase(trade) {
  const query = `
    INSERT INTO backtest_trades (
      backtest_id, symbol_id, entry_date, side, entry_price, quantity, 
      commission, status, entry_signal
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
  `;
  
  await pool.query(query, [
    trade.backtestId,
    trade.symbolId,
    trade.entryDate,
    trade.side,
    trade.entryPrice,
    trade.quantity,
    trade.commission,
    trade.status,
    JSON.stringify(trade.entrySignal)
  ]);
}

// Update trade in database
async function updateTradeInDatabase(trade) {
  const query = `
    UPDATE backtest_trades 
    SET exit_date = $1, exit_price = $2, pnl = $3, pnl_percent = $4, 
        status = $5, exit_signal = $6
    WHERE backtest_id = $7 AND symbol_id = $8 AND entry_date = $9 AND status = 'open'
  `;
  
  await pool.query(query, [
    trade.exitDate,
    trade.exitPrice,
    trade.pnl,
    trade.pnlPercent,
    trade.status,
    JSON.stringify(trade.exitSignal),
    trade.backtestId,
    trade.symbolId,
    trade.entryDate
  ]);
}

// Update portfolio value and equity curve
async function updatePortfolioValue(backtestId, date, portfolio, symbols) {
  let positionsValue = 0;
  
  // Calculate current value of all positions
  for (const [symbolName, position] of Object.entries(portfolio.positions)) {
    const symbol = symbols.find(s => s.symbol === symbolName);
    if (symbol) {
      const marketData = await getMarketDataForDate(symbol.id, date);
      if (marketData) {
        positionsValue += position.quantity * marketData.close_price;
      }
    }
  }
  
  const totalValue = portfolio.cash + positionsValue;
  const dailyReturn = portfolio.equityCurve.length > 0 
    ? (totalValue - portfolio.totalValue) / portfolio.totalValue 
    : 0;
  
  portfolio.totalValue = totalValue;
  
  // Save equity curve point
  const equityPoint = {
    backtestId,
    date,
    portfolioValue: totalValue,
    cash: portfolio.cash,
    positionsValue,
    dailyReturn
  };
  
  portfolio.equityCurve.push(equityPoint);
  
  // Save to database
  await saveEquityCurvePoint(equityPoint);
}

// Save equity curve point to database
async function saveEquityCurvePoint(point) {
  const query = `
    INSERT INTO backtest_equity_curve (
      backtest_id, trade_date, portfolio_value, cash, positions_value, daily_return
    ) VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (backtest_id, trade_date) DO UPDATE SET
      portfolio_value = EXCLUDED.portfolio_value,
      cash = EXCLUDED.cash,
      positions_value = EXCLUDED.positions_value,
      daily_return = EXCLUDED.daily_return
  `;
  
  await pool.query(query, [
    point.backtestId,
    point.date,
    point.portfolioValue,
    point.cash,
    point.positionsValue,
    point.dailyReturn
  ]);
}

// Calculate backtest statistics
async function calculateBacktestStatistics(backtestId, portfolio) {
  const trades = portfolio.trades.filter(t => t.status === 'closed');
  const equityCurve = portfolio.equityCurve;
  
  if (trades.length === 0 || equityCurve.length === 0) return;
  
  // Basic statistics
  const totalReturn = ((portfolio.totalValue - equityCurve[0].portfolioValue) / equityCurve[0].portfolioValue) * 100;
  const winningTrades = trades.filter(t => t.pnl > 0);
  const losingTrades = trades.filter(t => t.pnl < 0);
  const winRate = (winningTrades.length / trades.length) * 100;
  
  const avgWin = winningTrades.length > 0 
    ? winningTrades.reduce((sum, t) => sum + t.pnl, 0) / winningTrades.length 
    : 0;
  const avgLoss = losingTrades.length > 0 
    ? losingTrades.reduce((sum, t) => sum + Math.abs(t.pnl), 0) / losingTrades.length 
    : 0;
  
  const largestWin = winningTrades.length > 0 ? Math.max(...winningTrades.map(t => t.pnl)) : 0;
  const largestLoss = losingTrades.length > 0 ? Math.min(...losingTrades.map(t => t.pnl)) : 0;
  
  const profitFactor = avgLoss > 0 ? avgWin / avgLoss : 0;
  
  // Calculate max drawdown
  let maxDrawdown = 0;
  let peak = equityCurve[0].portfolioValue;
  
  for (const point of equityCurve) {
    if (point.portfolioValue > peak) {
      peak = point.portfolioValue;
    }
    const drawdown = ((peak - point.portfolioValue) / peak) * 100;
    if (drawdown > maxDrawdown) {
      maxDrawdown = drawdown;
    }
  }
  
  // Calculate Sharpe ratio (simplified)
  const returns = equityCurve.map(p => p.dailyReturn || 0);
  const avgReturn = returns.reduce((sum, r) => sum + r, 0) / returns.length;
  const returnStd = Math.sqrt(returns.reduce((sum, r) => sum + Math.pow(r - avgReturn, 2), 0) / returns.length);
  const sharpeRatio = returnStd > 0 ? (avgReturn / returnStd) * Math.sqrt(252) : 0; // Annualized
  
  // Update backtest record
  const query = `
    UPDATE backtests SET
      total_return = $1,
      max_drawdown = $2,
      sharpe_ratio = $3,
      win_rate = $4,
      profit_factor = $5,
      total_trades = $6,
      winning_trades = $7,
      losing_trades = $8,
      avg_win = $9,
      avg_loss = $10,
      largest_win = $11,
      largest_loss = $12
    WHERE id = $13
  `;
  
  await pool.query(query, [
    totalReturn,
    maxDrawdown,
    sharpeRatio,
    winRate,
    profitFactor,
    trades.length,
    winningTrades.length,
    losingTrades.length,
    avgWin,
    avgLoss,
    largestWin,
    largestLoss,
    backtestId
  ]);
  
  logger.info(`Backtest ${backtestId} statistics calculated: Total Return: ${totalReturn.toFixed(2)}%, Win Rate: ${winRate.toFixed(2)}%`);
}

// Get backtest configuration
async function getBacktestConfig(backtestId) {
  const result = await pool.query('SELECT * FROM backtests WHERE id = $1', [backtestId]);
  return result.rows[0];
}

// Get strategy
async function getStrategy(strategyId) {
  const result = await pool.query('SELECT * FROM strategies WHERE id = $1', [strategyId]);
  return result.rows[0];
}

// Get backtest results
async function getBacktestResults(backtestId) {
  const result = await pool.query(`
    SELECT b.*, s.name as strategy_name 
    FROM backtests b 
    JOIN strategies s ON b.strategy_id = s.id 
    WHERE b.id = $1
  `, [backtestId]);
  return result.rows[0];
}

// Get backtest trades
async function getBacktestTrades(backtestId) {
  const result = await pool.query(`
    SELECT bt.*, s.symbol 
    FROM backtest_trades bt 
    JOIN symbols s ON bt.symbol_id = s.id 
    WHERE bt.backtest_id = $1 
    ORDER BY bt.entry_date
  `, [backtestId]);
  return result.rows;
}

// Get equity curve
async function getEquityCurve(backtestId) {
  const result = await pool.query(`
    SELECT * FROM backtest_equity_curve 
    WHERE backtest_id = $1 
    ORDER BY trade_date
  `, [backtestId]);
  return result.rows;
}

// Kafka consumer for processing backtest requests
async function startKafkaConsumer() {
  await consumer.subscribe({ topics: ['backtest-requests'] });
  
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const data = JSON.parse(message.value.toString());
        
        if (topic === 'backtest-requests') {
          await runBacktest(data.backtestId, data.symbols || []);
        }
        
      } catch (error) {
        logger.error('Error processing Kafka message:', error);
      }
    },
  });
}

// Initialize services
async function initialize() {
  try {
    // Connect to Kafka
    await producer.connect();
    await consumer.connect();
    await startKafkaConsumer();
    logger.info('Connected to Kafka');
    
    // Test database connection
    await pool.query('SELECT NOW()');
    logger.info('Connected to PostgreSQL');
    
    // Start Express server
    const port = process.env.PORT || 3002;
    app.listen(port, () => {
      logger.info(`Backtesting service listening on port ${port}`);
    });
    
  } catch (error) {
    logger.error('Failed to initialize service:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  await producer.disconnect();
  await consumer.disconnect();
  await pool.end();
  process.exit(0);
});

// Start the service
initialize();