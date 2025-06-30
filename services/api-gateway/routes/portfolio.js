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

// Authentication middleware (simplified)
const authenticateToken = (req, res, next) => {
  // In a real implementation, verify JWT token
  req.user = { id: 1, username: 'demo' }; // Mock user
  next();
};

/**
 * @swagger
 * /api/portfolio/watchlists:
 *   get:
 *     summary: Get user watchlists
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User watchlists
 */
router.get('/watchlists', authenticateToken, async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          w.id,
          w.name,
          w.description,
          w.is_public,
          w.created_at,
          COUNT(ws.symbol_id) as symbol_count
        FROM watchlists w
        LEFT JOIN watchlist_symbols ws ON w.id = ws.watchlist_id
        WHERE w.created_by = {username:String}
        GROUP BY w.id, w.name, w.description, w.is_public, w.created_at
        ORDER BY w.created_at DESC
      `,
      query_params: { username: req.user.username },
    });

    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching watchlists:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/watchlists/{id}/symbols:
 *   get:
 *     summary: Get symbols in a watchlist
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Watchlist ID
 *     responses:
 *       200:
 *         description: Watchlist symbols with current data
 */
router.get('/watchlists/:id/symbols', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          o.close_price,
          o.volume,
          ts.price_change,
          ts.price_change_percent,
          ts.market_cap,
          ws.target_price,
          ws.stop_loss,
          ws.notes,
          ws.added_date
        FROM watchlist_symbols ws
        JOIN securities s ON ws.symbol_id = s.id
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE ws.watchlist_id = {watchlistId:UInt32}
          AND o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
        ORDER BY ws.added_date DESC
      `,
      query_params: { watchlistId: parseInt(id) },
    });

    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching watchlist symbols:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/watchlists:
 *   post:
 *     summary: Create a new watchlist
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
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
 *               is_public:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Watchlist created
 */
router.post('/watchlists', authenticateToken, async (req, res) => {
  try {
    const { name, description, is_public = false } = req.body;
    const watchlistId = Date.now();

    await clickhouse.insert({
      table: 'watchlists',
      values: [
        {
          id: watchlistId,
          name,
          description: description || '',
          created_by: req.user.username,
          is_public: is_public ? 1 : 0,
        },
      ],
    });

    res.status(201).json({
      id: watchlistId,
      name,
      description,
      is_public,
      message: 'Watchlist created successfully',
    });
  } catch (error) {
    logger.error('Error creating watchlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/watchlists/{id}/symbols:
 *   post:
 *     summary: Add symbol to watchlist
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Watchlist ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbol:
 *                 type: string
 *               target_price:
 *                 type: number
 *               stop_loss:
 *                 type: number
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Symbol added to watchlist
 */
router.post('/watchlists/:id/symbols', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { symbol, target_price, stop_loss, notes } = req.body;

    // Get security ID
    const securityResult = await clickhouse.query({
      query: 'SELECT id FROM securities WHERE symbol = {symbol:String}',
      query_params: { symbol: symbol.toUpperCase() },
    });

    const securities = await securityResult.json();
    if (securities.data.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }

    const symbolId = securities.data[0].id;

    await clickhouse.insert({
      table: 'watchlist_symbols',
      values: [
        {
          id: Date.now(),
          watchlist_id: parseInt(id),
          symbol_id: symbolId,
          target_price: target_price || null,
          stop_loss: stop_loss || null,
          notes: notes || '',
        },
      ],
    });

    res.status(201).json({
      message: 'Symbol added to watchlist',
      symbol: symbol.toUpperCase(),
    });
  } catch (error) {
    logger.error('Error adding symbol to watchlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/alerts:
 *   get:
 *     summary: Get user alerts
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User alerts
 */
router.get('/alerts', authenticateToken, async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          a.id,
          s.symbol,
          s.name,
          a.alert_type,
          a.condition_type,
          a.target_value,
          a.current_value,
          a.is_triggered,
          a.is_active,
          a.triggered_at,
          a.created_at
        FROM alerts a
        JOIN securities s ON a.symbol_id = s.id
        WHERE a.created_by = {username:String}
        ORDER BY a.created_at DESC
        LIMIT 100
      `,
      query_params: { username: req.user.username },
    });

    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/alerts:
 *   post:
 *     summary: Create a new alert
 *     tags: [Portfolio]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               symbol:
 *                 type: string
 *               alert_type:
 *                 type: string
 *                 enum: [price, volume, rsi, macd]
 *               condition_type:
 *                 type: string
 *                 enum: [above, below, crosses_above, crosses_below]
 *               target_value:
 *                 type: number
 *     responses:
 *       201:
 *         description: Alert created
 */
router.post('/alerts', authenticateToken, async (req, res) => {
  try {
    const { symbol, alert_type, condition_type, target_value } = req.body;

    // Get security ID
    const securityResult = await clickhouse.query({
      query: 'SELECT id FROM securities WHERE symbol = {symbol:String}',
      query_params: { symbol: symbol.toUpperCase() },
    });

    const securities = await securityResult.json();
    if (securities.data.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }

    const symbolId = securities.data[0].id;
    const alertId = Date.now();

    await clickhouse.insert({
      table: 'alerts',
      values: [
        {
          id: alertId,
          symbol_id: symbolId,
          alert_type,
          condition_type,
          target_value,
          is_triggered: 0,
          is_active: 1,
          created_by: req.user.username,
        },
      ],
    });

    res.status(201).json({
      id: alertId,
      symbol: symbol.toUpperCase(),
      alert_type,
      condition_type,
      target_value,
      message: 'Alert created successfully',
    });
  } catch (error) {
    logger.error('Error creating alert:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;