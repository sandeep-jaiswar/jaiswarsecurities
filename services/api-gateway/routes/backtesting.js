const express = require('express');
const router = express.Router();
const { createClient } = require('@clickhouse/client');
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [new winston.transports.Console()]
});

// Initialize ClickHouse connection
const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || 'http://localhost:8123',
  username: process.env.CLICKHOUSE_USER || 'stockuser',
  password: process.env.CLICKHOUSE_PASSWORD || 'stockpass123',
  database: process.env.CLICKHOUSE_DATABASE || 'stockdb',
});

/**
 * @swagger
 * /api/backtesting/strategies:
 *   get:
 *     summary: Get available trading strategies
 *     tags: [Backtesting]
 *     responses:
 *       200:
 *         description: List of trading strategies
 */
router.get('/strategies', async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          id,
          name,
          description,
          parameters,
          created_by,
          is_active,
          created_at
        FROM strategies
        WHERE is_active = 1
        ORDER BY name
      `
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching strategies:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/backtests:
 *   get:
 *     summary: Get backtest results
 *     tags: [Backtesting]
 *     parameters:
 *       - in: query
 *         name: strategy_id
 *         schema:
 *           type: integer
 *         description: Filter by strategy ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, running, completed, failed]
 *         description: Filter by status
 *     responses:
 *       200:
 *         description: List of backtests
 */
router.get('/backtests', async (req, res) => {
  try {
    const { strategy_id, status } = req.query;
    
    let whereClause = 'WHERE 1=1';
    const queryParams = {};
    
    if (strategy_id) {
      whereClause += ' AND b.strategy_id = {strategyId:UInt32}';
      queryParams.strategyId = parseInt(strategy_id);
    }
    
    if (status) {
      whereClause += ' AND b.status = {status:String}';
      queryParams.status = status;
    }
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          b.id,
          b.name,
          b.start_date,
          b.end_date,
          b.initial_capital,
          b.status,
          b.total_return,
          b.annual_return,
          b.max_drawdown,
          b.sharpe_ratio,
          b.win_rate,
          b.total_trades,
          b.created_at,
          b.completed_at,
          s.name as strategy_name
        FROM backtests b
        LEFT JOIN strategies s ON b.strategy_id = s.id
        ${whereClause}
        ORDER BY b.created_at DESC
        LIMIT 100
      `,
      query_params: queryParams
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching backtests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/backtests:
 *   post:
 *     summary: Start a new backtest
 *     tags: [Backtesting]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               strategy_id:
 *                 type: integer
 *               name:
 *                 type: string
 *               start_date:
 *                 type: string
 *                 format: date
 *               end_date:
 *                 type: string
 *                 format: date
 *               initial_capital:
 *                 type: number
 *               symbols:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Backtest started
 */
router.post('/backtests', async (req, res) => {
  try {
    const { 
      strategy_id, 
      name, 
      start_date, 
      end_date, 
      initial_capital, 
      symbols = [] 
    } = req.body;
    
    const backtestId = Date.now();
    
    await clickhouse.insert({
      table: 'backtests',
      values: [{
        id: backtestId,
        strategy_id: strategy_id || null,
        name,
        start_date,
        end_date,
        initial_capital,
        commission: 0.001,
        slippage: 0.001,
        status: 'pending'
      }]
    });
    
    // In a real implementation, this would trigger the backtesting service
    // For now, we'll simulate immediate completion with mock results
    setTimeout(async () => {
      try {
        await clickhouse.query({
          query: `
            ALTER TABLE backtests UPDATE
              status = 'completed',
              total_return = {totalReturn:Float64},
              annual_return = {annualReturn:Float64},
              max_drawdown = {maxDrawdown:Float64},
              sharpe_ratio = {sharpeRatio:Float64},
              win_rate = {winRate:Float64},
              total_trades = {totalTrades:UInt32},
              completed_at = now()
            WHERE id = {id:UInt32}
          `,
          query_params: {
            totalReturn: 15.5 + Math.random() * 20,
            annualReturn: 12.3 + Math.random() * 15,
            maxDrawdown: -(5 + Math.random() * 10),
            sharpeRatio: 1.2 + Math.random() * 0.8,
            winRate: 55 + Math.random() * 20,
            totalTrades: Math.floor(20 + Math.random() * 50),
            id: backtestId
          }
        });
      } catch (error) {
        logger.error('Error updating backtest results:', error);
      }
    }, 5000);
    
    res.status(201).json({
      id: backtestId,
      name,
      status: 'pending',
      message: 'Backtest started successfully'
    });
  } catch (error) {
    logger.error('Error starting backtest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/backtests/{id}:
 *   get:
 *     summary: Get detailed backtest results
 *     tags: [Backtesting]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Backtest ID
 *     responses:
 *       200:
 *         description: Detailed backtest results
 */
router.get('/backtests/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          b.*,
          s.name as strategy_name,
          s.description as strategy_description,
          s.parameters as strategy_parameters
        FROM backtests b
        LEFT JOIN strategies s ON b.strategy_id = s.id
        WHERE b.id = {id:UInt32}
      `,
      query_params: { id: parseInt(id) }
    });
    
    const data = await result.json();
    if (data.data.length === 0) {
      return res.status(404).json({ error: 'Backtest not found' });
    }
    
    res.json(data.data[0]);
  } catch (error) {
    logger.error('Error fetching backtest details:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/backtests/{id}/trades:
 *   get:
 *     summary: Get backtest trade history
 *     tags: [Backtesting]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Backtest ID
 *     responses:
 *       200:
 *         description: Trade history
 */
router.get('/backtests/:id/trades', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          bt.id,
          s.symbol,
          bt.entry_date,
          bt.exit_date,
          bt.side,
          bt.entry_price,
          bt.exit_price,
          bt.quantity,
          bt.pnl,
          bt.pnl_percent,
          bt.status
        FROM backtest_trades bt
        JOIN securities s ON bt.symbol_id = s.id
        WHERE bt.backtest_id = {backtestId:UInt32}
        ORDER BY bt.entry_date DESC
      `,
      query_params: { backtestId: parseInt(id) }
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching backtest trades:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/backtests/{id}/equity-curve:
 *   get:
 *     summary: Get backtest equity curve
 *     tags: [Backtesting]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Backtest ID
 *     responses:
 *       200:
 *         description: Equity curve data
 */
router.get('/backtests/:id/equity-curve', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          trade_date,
          portfolio_value,
          cash,
          positions_value,
          daily_return,
          cumulative_return,
          drawdown
        FROM backtest_equity_curve
        WHERE backtest_id = {backtestId:UInt32}
        ORDER BY trade_date ASC
      `,
      query_params: { backtestId: parseInt(id) }
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching equity curve:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/backtesting/strategies:
 *   post:
 *     summary: Create a new trading strategy
 *     tags: [Backtesting]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               parameters:
 *                 type: object
 *     responses:
 *       201:
 *         description: Strategy created
 */
router.post('/strategies', async (req, res) => {
  try {
    const { name, description, parameters } = req.body;
    const strategyId = Date.now();
    
    await clickhouse.insert({
      table: 'strategies',
      values: [{
        id: strategyId,
        name,
        description: description || '',
        parameters: JSON.stringify(parameters || {}),
        created_by: 'system',
        is_active: 1
      }]
    });
    
    res.status(201).json({
      id: strategyId,
      name,
      description,
      parameters,
      message: 'Strategy created successfully'
    });
  } catch (error) {
    logger.error('Error creating strategy:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;