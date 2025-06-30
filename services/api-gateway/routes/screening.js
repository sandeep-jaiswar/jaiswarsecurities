const express = require('express');
const router = express.Router();
const { createClient } = require('@clickhouse/client');
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [new winston.transports.Console()],
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
 * /api/screening/screens:
 *   get:
 *     summary: Get available screening templates
 *     tags: [Screening]
 *     responses:
 *       200:
 *         description: List of screening templates
 */
router.get('/screens', async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          id,
          name,
          description,
          criteria,
          created_by,
          is_active,
          created_at
        FROM screens
        WHERE is_active = 1
        ORDER BY name
      `,
    });

    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching screens:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/screening/screens/{id}/run:
 *   post:
 *     summary: Run a screening template
 *     tags: [Screening]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Screen ID
 *     responses:
 *       200:
 *         description: Screening results
 */
router.post('/screens/:id/run', async (req, res) => {
  try {
    const { id } = req.params;

    // Get screen configuration
    const screenResult = await clickhouse.query({
      query: 'SELECT * FROM screens WHERE id = {id:UInt32}',
      query_params: { id: parseInt(id) },
    });

    const screens = await screenResult.json();
    if (screens.data.length === 0) {
      return res.status(404).json({ error: 'Screen not found' });
    }

    const screen = screens.data[0];
    const criteria = JSON.parse(screen.criteria);

    // Build dynamic query based on criteria
    const { query, queryParams } = buildScreeningQuery(criteria);

    const result = await clickhouse.query({
      query,
      query_params: queryParams,
    });

    const data = await result.json();

    // Store results
    const scanDate = new Date().toISOString().split('T')[0];
    const results = data.data.map((row, index) => ({
      id: Date.now() + index,
      screen_id: parseInt(id),
      symbol_id: row.security_id,
      scan_date: scanDate,
      score: row.score || 0,
      criteria_met: JSON.stringify(row),
      market_data: JSON.stringify(row),
    }));

    if (results.length > 0) {
      await clickhouse.insert({
        table: 'screen_results',
        values: results,
      });
    }

    res.json({
      screen_name: screen.name,
      scan_date: scanDate,
      results_count: data.data.length,
      results: data.data,
    });
  } catch (error) {
    logger.error('Error running screen:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/screening/custom:
 *   post:
 *     summary: Run custom screening criteria
 *     tags: [Screening]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               criteria:
 *                 type: object
 *                 description: Screening criteria
 *               limit:
 *                 type: integer
 *                 default: 50
 *     responses:
 *       200:
 *         description: Custom screening results
 */
router.post('/custom', async (req, res) => {
  try {
    const { criteria, limit = 50 } = req.body;

    const { query, queryParams } = buildScreeningQuery(criteria, limit);

    const result = await clickhouse.query({
      query,
      query_params: queryParams,
    });

    const data = await result.json();

    res.json({
      criteria,
      results_count: data.data.length,
      results: data.data,
    });
  } catch (error) {
    logger.error('Error running custom screen:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/screening/criteria:
 *   get:
 *     summary: Get available screening criteria
 *     tags: [Screening]
 *     responses:
 *       200:
 *         description: Available screening criteria
 */
router.get('/criteria', async (req, res) => {
  try {
    const criteria = {
      price: {
        name: 'Price',
        type: 'number',
        operators: ['>', '<', '>=', '<=', '='],
        description: 'Current stock price',
      },
      market_cap: {
        name: 'Market Cap',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Market capitalization',
      },
      volume: {
        name: 'Volume',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Trading volume',
      },
      volume_ratio: {
        name: 'Volume Ratio',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Volume vs average volume',
      },
      price_change_percent: {
        name: 'Price Change %',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Daily price change percentage',
      },
      rsi_14: {
        name: 'RSI (14)',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Relative Strength Index',
      },
      macd: {
        name: 'MACD',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'MACD indicator',
      },
      sma_20: {
        name: 'SMA 20',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: '20-day Simple Moving Average',
      },
      sma_50: {
        name: 'SMA 50',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: '50-day Simple Moving Average',
      },
      price_to_earnings: {
        name: 'P/E Ratio',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Price to Earnings ratio',
      },
      price_to_book: {
        name: 'P/B Ratio',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Price to Book ratio',
      },
      debt_to_equity: {
        name: 'Debt/Equity',
        type: 'number',
        operators: ['>', '<', '>=', '<='],
        description: 'Debt to Equity ratio',
      },
      sector: {
        name: 'Sector',
        type: 'string',
        operators: ['=', '!='],
        description: 'Company sector',
      },
      exchange: {
        name: 'Exchange',
        type: 'string',
        operators: ['=', '!='],
        description: 'Stock exchange',
      },
    };

    res.json(criteria);
  } catch (error) {
    logger.error('Error fetching criteria:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Helper function to build screening query
function buildScreeningQuery(criteria, limit = 50) {
  let query = `
    SELECT 
      s.id as security_id,
      s.symbol,
      s.name,
      o.close_price,
      o.volume,
      ts.price_change_percent,
      ts.market_cap,
      ts.volume_ratio,
      ti.rsi_14,
      ti.macd,
      ti.sma_20,
      ti.sma_50,
      fr.price_to_earnings,
      fr.price_to_book,
      fr.debt_to_equity,
      sec.name as sector_name,
      e.name as exchange_name,
      0 as score
    FROM securities s
    JOIN ohlcv_daily o ON s.id = o.security_id
    LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
    LEFT JOIN technical_indicators ti ON s.id = ti.security_id AND o.trade_date = ti.trade_date
    LEFT JOIN companies c ON s.company_id = c.id
    LEFT JOIN financial_periods fp ON c.id = fp.company_id
    LEFT JOIN financial_ratios fr ON fp.id = fr.financial_period_id
    LEFT JOIN sectors sec ON c.sector_id = sec.id
    LEFT JOIN exchanges e ON s.exchange_id = e.id
    WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
      AND s.is_active = 1
  `;

  const queryParams = { limit: parseInt(limit) };
  let paramCounter = 0;

  // Add criteria filters
  Object.entries(criteria).forEach(([field, condition]) => {
    if (condition.min !== undefined) {
      const paramName = `param_${paramCounter++}`;
      query += ` AND ${getFieldMapping(field)} >= {${paramName}:Float64}`;
      queryParams[paramName] = parseFloat(condition.min);
    }

    if (condition.max !== undefined) {
      const paramName = `param_${paramCounter++}`;
      query += ` AND ${getFieldMapping(field)} <= {${paramName}:Float64}`;
      queryParams[paramName] = parseFloat(condition.max);
    }

    if (condition.equals !== undefined) {
      const paramName = `param_${paramCounter++}`;
      if (typeof condition.equals === 'string') {
        query += ` AND ${getFieldMapping(field)} = {${paramName}:String}`;
        queryParams[paramName] = condition.equals;
      } else {
        query += ` AND ${getFieldMapping(field)} = {${paramName}:Float64}`;
        queryParams[paramName] = parseFloat(condition.equals);
      }
    }
  });

  query += ` ORDER BY o.volume DESC LIMIT {limit:UInt32}`;

  return { query, queryParams };
}

// Helper function to map criteria fields to database columns
function getFieldMapping(field) {
  const mappings = {
    price: 'o.close_price',
    market_cap: 'ts.market_cap',
    volume: 'o.volume',
    volume_ratio: 'ts.volume_ratio',
    price_change_percent: 'ts.price_change_percent',
    rsi_14: 'ti.rsi_14',
    macd: 'ti.macd',
    sma_20: 'ti.sma_20',
    sma_50: 'ti.sma_50',
    price_to_earnings: 'fr.price_to_earnings',
    price_to_book: 'fr.price_to_book',
    debt_to_equity: 'fr.debt_to_equity',
    sector: 'sec.name',
    exchange: 'e.name',
  };

  return mappings[field] || field;
}

module.exports = router;