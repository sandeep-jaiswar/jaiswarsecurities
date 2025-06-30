const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const Redis = require('redis');
const winston = require('winston');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
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

// Initialize Redis (with error handling)
let redis;
try {
  redis = Redis.createClient({
    url: process.env.REDIS_URL
  });
  
  redis.on('error', (err) => {
    logger.error('Redis connection error:', err);
  });
  
  redis.on('connect', () => {
    logger.info('Connected to Redis');
  });
} catch (error) {
  logger.error('Failed to create Redis client:', error);
}

// Initialize Express app
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:5678'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Stock Screening API',
      version: '1.0.0',
      description: 'API for stock screening and backtesting system',
    },
    servers: [
      {
        url: `http://localhost:${process.env.API_PORT || 3000}`,
        description: 'Development server',
      },
    ],
  },
  apis: ['./routes/*.js', './index.js'],
};

const specs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Stock Screening API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      docs: '/api-docs',
      symbols: '/api/symbols',
      analytics: '/api/analytics/market-overview'
    }
  });
});

// Health check endpoint
/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check endpoint
 *     responses:
 *       200:
 *         description: Service is healthy
 */
app.get('/health', async (req, res) => {
  try {
    // Check database connection
    await pool.query('SELECT 1');
    
    // Check Redis connection (optional)
    let redisStatus = 'disconnected';
    try {
      if (redis && redis.isOpen) {
        await redis.ping();
        redisStatus = 'connected';
      }
    } catch (redisError) {
      logger.warn('Redis health check failed:', redisError.message);
    }
    
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: redisStatus
      }
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      error: error.message 
    });
  }
});

// Symbols endpoints
/**
 * @swagger
 * /api/symbols:
 *   get:
 *     summary: Get all symbols
 *     parameters:
 *       - in: query
 *         name: exchange
 *         schema:
 *           type: string
 *         description: Filter by exchange
 *       - in: query
 *         name: sector
 *         schema:
 *           type: string
 *         description: Filter by sector
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Limit number of results
 *     responses:
 *       200:
 *         description: List of symbols
 */
app.get('/api/symbols', async (req, res) => {
  try {
    const { exchange, sector, industry, limit = 100, offset = 0 } = req.query;
    
    let query = 'SELECT * FROM symbols WHERE is_active = true';
    const params = [];
    let paramCount = 0;
    
    if (exchange) {
      query += ` AND exchange = $${++paramCount}`;
      params.push(exchange);
    }
    
    if (sector) {
      query += ` AND sector = $${++paramCount}`;
      params.push(sector);
    }
    
    if (industry) {
      query += ` AND industry = $${++paramCount}`;
      params.push(industry);
    }
    
    query += ` ORDER BY symbol LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching symbols:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/symbols/{symbol}:
 *   get:
 *     summary: Get symbol details
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *         description: Stock symbol
 *     responses:
 *       200:
 *         description: Symbol details
 *       404:
 *         description: Symbol not found
 */
app.get('/api/symbols/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const result = await pool.query('SELECT * FROM symbols WHERE symbol = $1', [symbol.toUpperCase()]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Error fetching symbol:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Market data endpoints
/**
 * @swagger
 * /api/symbols/{symbol}/ohlcv:
 *   get:
 *     summary: Get OHLCV data for symbol
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: OHLCV data
 */
app.get('/api/symbols/:symbol/ohlcv', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { start_date, end_date, limit = 100 } = req.query;
    
    // Check cache first (if Redis is available)
    const cacheKey = `ohlcv:${symbol}:${start_date}:${end_date}:${limit}`;
    let cachedData = null;
    
    try {
      if (redis && redis.isOpen) {
        cachedData = await redis.get(cacheKey);
      }
    } catch (redisError) {
      logger.warn('Redis cache check failed:', redisError.message);
    }
    
    if (cachedData) {
      return res.json(JSON.parse(cachedData));
    }
    
    let query = `
      SELECT o.*, s.symbol 
      FROM ohlcv o 
      JOIN symbols s ON o.symbol_id = s.id 
      WHERE s.symbol = $1
    `;
    const params = [symbol.toUpperCase()];
    let paramCount = 1;
    
    if (start_date) {
      query += ` AND o.trade_date >= $${++paramCount}`;
      params.push(start_date);
    }
    
    if (end_date) {
      query += ` AND o.trade_date <= $${++paramCount}`;
      params.push(end_date);
    }
    
    query += ` ORDER BY o.trade_date DESC LIMIT $${++paramCount}`;
    params.push(parseInt(limit));
    
    const result = await pool.query(query, params);
    
    // Cache for 5 minutes (if Redis is available)
    try {
      if (redis && redis.isOpen) {
        await redis.setEx(cacheKey, 300, JSON.stringify(result.rows));
      }
    } catch (redisError) {
      logger.warn('Redis cache set failed:', redisError.message);
    }
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching OHLCV data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Indicators endpoints
app.get('/api/symbols/:symbol/indicators', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { start_date, end_date, limit = 100 } = req.query;
    
    // Check cache first (if Redis is available)
    const cacheKey = `indicators:${symbol}:${start_date}:${end_date}:${limit}`;
    let cachedData = null;
    
    try {
      if (redis && redis.isOpen) {
        cachedData = await redis.get(cacheKey);
      }
    } catch (redisError) {
      logger.warn('Redis cache check failed:', redisError.message);
    }
    
    if (cachedData) {
      return res.json(JSON.parse(cachedData));
    }
    
    let query = `
      SELECT i.*, s.symbol 
      FROM indicators i 
      JOIN symbols s ON i.symbol_id = s.id 
      WHERE s.symbol = $1
    `;
    const params = [symbol.toUpperCase()];
    let paramCount = 1;
    
    if (start_date) {
      query += ` AND i.trade_date >= $${++paramCount}`;
      params.push(start_date);
    }
    
    if (end_date) {
      query += ` AND i.trade_date <= $${++paramCount}`;
      params.push(end_date);
    }
    
    query += ` ORDER BY i.trade_date DESC LIMIT $${++paramCount}`;
    params.push(parseInt(limit));
    
    const result = await pool.query(query, params);
    
    // Cache for 5 minutes (if Redis is available)
    try {
      if (redis && redis.isOpen) {
        await redis.setEx(cacheKey, 300, JSON.stringify(result.rows));
      }
    } catch (redisError) {
      logger.warn('Redis cache set failed:', redisError.message);
    }
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching indicators:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Screening endpoints
app.get('/api/screens', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM screens WHERE is_active = true ORDER BY name');
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching screens:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/screens/:id/run', async (req, res) => {
  try {
    const { id } = req.params;
    const { date = new Date().toISOString().split('T')[0] } = req.body;
    
    // Get screen configuration
    const screenResult = await pool.query('SELECT * FROM screens WHERE id = $1', [id]);
    if (screenResult.rows.length === 0) {
      return res.status(404).json({ error: 'Screen not found' });
    }
    
    const screen = screenResult.rows[0];
    
    // Run screening logic (simplified)
    const results = await runScreen(screen, date);
    
    res.json({
      screen: screen.name,
      date,
      results: results.length,
      data: results
    });
  } catch (error) {
    logger.error('Error running screen:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Backtesting endpoints
app.get('/api/strategies', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM strategies WHERE is_active = true ORDER BY name');
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching strategies:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/backtests', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await pool.query(`
      SELECT b.*, s.name as strategy_name 
      FROM backtests b 
      JOIN strategies s ON b.strategy_id = s.id 
      ORDER BY b.created_at DESC 
      LIMIT $1 OFFSET $2
    `, [parseInt(limit), parseInt(offset)]);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching backtests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/backtests/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT b.*, s.name as strategy_name, s.description as strategy_description 
      FROM backtests b 
      JOIN strategies s ON b.strategy_id = s.id 
      WHERE b.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Backtest not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Error fetching backtest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/backtests/:id/trades', async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 100, offset = 0 } = req.query;
    
    const result = await pool.query(`
      SELECT bt.*, s.symbol 
      FROM backtest_trades bt 
      JOIN symbols s ON bt.symbol_id = s.id 
      WHERE bt.backtest_id = $1 
      ORDER BY bt.entry_date DESC 
      LIMIT $2 OFFSET $3
    `, [id, parseInt(limit), parseInt(offset)]);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching backtest trades:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/backtests/:id/equity-curve', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT * FROM backtest_equity_curve 
      WHERE backtest_id = $1 
      ORDER BY trade_date
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching equity curve:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Watchlist endpoints
app.get('/api/watchlists', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM watchlists ORDER BY name');
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching watchlists:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/watchlists/:id/symbols', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT ws.*, s.symbol, s.name, s.exchange 
      FROM watchlist_symbols ws 
      JOIN symbols s ON ws.symbol_id = s.id 
      WHERE ws.watchlist_id = $1 
      ORDER BY ws.added_date DESC
    `, [id]);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching watchlist symbols:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Analytics endpoints
app.get('/api/analytics/market-overview', async (req, res) => {
  try {
    const cacheKey = 'market-overview';
    let cachedData = null;
    
    try {
      if (redis && redis.isOpen) {
        cachedData = await redis.get(cacheKey);
      }
    } catch (redisError) {
      logger.warn('Redis cache check failed:', redisError.message);
    }
    
    if (cachedData) {
      return res.json(JSON.parse(cachedData));
    }
    
    // Get market statistics
    const stats = await pool.query(`
      SELECT 
        COUNT(*) as total_symbols,
        COUNT(CASE WHEN is_active THEN 1 END) as active_symbols,
        COUNT(DISTINCT exchange) as exchanges,
        COUNT(DISTINCT sector) as sectors
      FROM symbols
    `);
    
    const recentData = await pool.query(`
      SELECT COUNT(*) as records_today
      FROM ohlcv 
      WHERE trade_date = CURRENT_DATE
    `);
    
    const overview = {
      ...stats.rows[0],
      ...recentData.rows[0],
      last_updated: new Date().toISOString()
    };
    
    // Cache for 10 minutes (if Redis is available)
    try {
      if (redis && redis.isOpen) {
        await redis.setEx(cacheKey, 600, JSON.stringify(overview));
      }
    } catch (redisError) {
      logger.warn('Redis cache set failed:', redisError.message);
    }
    
    res.json(overview);
  } catch (error) {
    logger.error('Error fetching market overview:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Run screening logic
async function runScreen(screen, date) {
  const criteria = screen.criteria;
  let query = `
    SELECT DISTINCT s.symbol, s.name, s.exchange, o.close_price, o.volume, i.*
    FROM symbols s
    JOIN ohlcv o ON s.id = o.symbol_id
    LEFT JOIN indicators i ON s.id = i.symbol_id AND i.trade_date = o.trade_date
    WHERE s.is_active = true AND o.trade_date = $1
  `;
  
  const params = [date];
  const conditions = [];
  
  // Apply screening criteria
  if (criteria.rsi) {
    if (criteria.rsi.min) conditions.push(`i.rsi_14 >= ${criteria.rsi.min}`);
    if (criteria.rsi.max) conditions.push(`i.rsi_14 <= ${criteria.rsi.max}`);
  }
  
  if (criteria.volume_ratio && criteria.volume_ratio.min) {
    // This would require calculating volume ratio vs average
    conditions.push(`o.volume > 1000000`); // Simplified
  }
  
  if (criteria.price_change && criteria.price_change.min) {
    // This would require calculating price change
    conditions.push(`o.close_price > o.open_price * 1.02`); // Simplified
  }
  
  if (conditions.length > 0) {
    query += ' AND ' + conditions.join(' AND ');
  }
  
  query += ' ORDER BY o.volume DESC LIMIT 50';
  
  const result = await pool.query(query, params);
  return result.rows;
}

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Initialize services
async function initialize() {
  try {
    // Connect to Redis (optional)
    if (redis) {
      try {
        await redis.connect();
        logger.info('Connected to Redis');
      } catch (redisError) {
        logger.warn('Failed to connect to Redis (continuing without cache):', redisError.message);
      }
    }
    
    // Test database connection
    await pool.query('SELECT NOW()');
    logger.info('Connected to PostgreSQL');
    
    // Start Express server
    const port = process.env.API_PORT || 3000;
    app.listen(port, () => {
      logger.info(`API Gateway listening on port ${port}`);
      logger.info(`API Documentation available at http://localhost:${port}/api-docs`);
    });
    
  } catch (error) {
    logger.error('Failed to initialize service:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  if (redis && redis.isOpen) {
    await redis.disconnect();
  }
  await pool.end();
  process.exit(0);
});

// Start the service
initialize();