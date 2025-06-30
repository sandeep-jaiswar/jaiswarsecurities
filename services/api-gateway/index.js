const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const Redis = require('redis');
const winston = require('winston');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const WebSocket = require('ws');
const http = require('http');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
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
const server = http.createServer(app);

// Initialize WebSocket server
const wss = new WebSocket.Server({ server });

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3001', 'http://localhost:5678'],
  credentials: true
}));

// Rate limiting with different tiers
const createRateLimit = (windowMs, max, message) => rateLimit({
  windowMs,
  max,
  message: { error: message },
  standardHeaders: true,
  legacyHeaders: false,
});

// Different rate limits for different endpoint types
const generalLimit = createRateLimit(15 * 60 * 1000, 1000, 'Too many requests');
const marketDataLimit = createRateLimit(60 * 1000, 100, 'Market data rate limit exceeded');
const authLimit = createRateLimit(15 * 60 * 1000, 5, 'Too many authentication attempts');

app.use('/api/auth', authLimit);
app.use('/api/market', marketDataLimit);
app.use(generalLimit);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// JWT Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Bloomberg-style Stock Terminal API',
      version: '2.0.0',
      description: 'Comprehensive financial data API with Bloomberg Terminal functionality',
    },
    servers: [
      {
        url: `http://localhost:${process.env.API_PORT || 3000}`,
        description: 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./routes/*.js', './index.js'],
};

const specs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Bloomberg-style Stock Terminal API',
    version: '2.0.0',
    features: [
      'Real-time market data',
      'Advanced analytics',
      'Portfolio management',
      'Risk analysis',
      'News & research',
      'Backtesting',
      'Screening',
      'Alerts & notifications'
    ],
    endpoints: {
      health: '/health',
      docs: '/api-docs',
      auth: '/api/auth',
      market: '/api/market',
      analytics: '/api/analytics',
      portfolio: '/api/portfolio',
      research: '/api/research',
      trading: '/api/trading'
    }
  });
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    
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
        redis: redisStatus,
        websocket: wss.clients.size + ' clients connected'
      },
      uptime: process.uptime(),
      memory: process.memoryUsage()
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

// ==================== AUTHENTICATION ENDPOINTS ====================

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *     responses:
 *       201:
 *         description: User registered successfully
 */
app.post('/api/auth/register', async (req, res) => {
  try {
    const schema = Joi.object({
      username: Joi.string().alphanum().min(3).max(30).required(),
      email: Joi.string().email().required(),
      password: Joi.string().min(8).required(),
      firstName: Joi.string().max(100),
      lastName: Joi.string().max(100)
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { username, email, password, firstName, lastName } = value;

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE username = $1 OR email = $2',
      [username, email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'Username or email already exists' });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await pool.query(`
      INSERT INTO users (username, email, password_hash, first_name, last_name)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, username, email, first_name, last_name, created_at
    `, [username, email, passwordHash, firstName, lastName]);

    const user = result.rows[0];

    // Create user profile
    await pool.query(`
      INSERT INTO user_profiles (user_id) VALUES ($1)
    `, [user.id]);

    // Create user preferences
    await pool.query(`
      INSERT INTO user_preferences (user_id) VALUES ($1)
    `, [user.id]);

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: User login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 */
app.post('/api/auth/login', async (req, res) => {
  try {
    const schema = Joi.object({
      username: Joi.string().required(),
      password: Joi.string().required()
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { username, password } = value;

    // Get user
    const result = await pool.query(`
      SELECT id, username, email, password_hash, first_name, last_name, is_active, is_locked
      FROM users 
      WHERE username = $1 OR email = $1
    `, [username]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(401).json({ error: 'Account is deactivated' });
    }

    if (user.is_locked) {
      return res.status(401).json({ error: 'Account is locked' });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        username: user.username,
        email: user.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Update last login
    await pool.query(
      'UPDATE users SET last_login_at = NOW() WHERE id = $1',
      [user.id]
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name
      }
    });

  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== MARKET DATA ENDPOINTS ====================

/**
 * @swagger
 * /api/market/symbols:
 *   get:
 *     summary: Get market symbols with advanced filtering
 *     tags: [Market Data]
 *     parameters:
 *       - in: query
 *         name: exchange
 *         schema:
 *           type: string
 *       - in: query
 *         name: sector
 *         schema:
 *           type: string
 *       - in: query
 *         name: marketCap
 *         schema:
 *           type: string
 *           enum: [micro, small, mid, large, mega]
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of symbols with market data
 */
app.get('/api/market/symbols', async (req, res) => {
  try {
    const { 
      exchange, 
      sector, 
      industry, 
      marketCap, 
      search, 
      limit = 100, 
      offset = 0,
      sortBy = 'symbol',
      sortOrder = 'ASC'
    } = req.query;
    
    let query = `
      SELECT 
        s.id, s.symbol, s.name, s.isin, s.cusip,
        c.name as company_name, c.business_description,
        e.name as exchange_name, e.code as exchange_code,
        curr.code as currency_code, curr.symbol as currency_symbol,
        sec.name as sector_name, sec.code as sector_code,
        ind.name as industry_name, ind.code as industry_code,
        s.shares_outstanding, s.shares_float,
        s.listing_date, s.trading_status,
        COALESCE(latest.close_price, 0) as last_price,
        COALESCE(latest.volume, 0) as last_volume,
        COALESCE(latest.trade_date, CURRENT_DATE) as last_trade_date
      FROM securities s
      LEFT JOIN companies c ON s.company_id = c.id
      LEFT JOIN exchanges e ON s.exchange_id = e.id
      LEFT JOIN currencies curr ON s.currency_id = curr.id
      LEFT JOIN sectors sec ON c.sector_id = sec.id
      LEFT JOIN industries ind ON c.industry_id = ind.id
      LEFT JOIN LATERAL (
        SELECT close_price, volume, trade_date
        FROM ohlcv_daily od
        WHERE od.security_id = s.id
        ORDER BY trade_date DESC
        LIMIT 1
      ) latest ON true
      WHERE s.is_active = true
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (exchange) {
      query += ` AND e.code = $${++paramCount}`;
      params.push(exchange);
    }
    
    if (sector) {
      query += ` AND sec.code = $${++paramCount}`;
      params.push(sector);
    }
    
    if (industry) {
      query += ` AND ind.code = $${++paramCount}`;
      params.push(industry);
    }
    
    if (search) {
      query += ` AND (s.symbol ILIKE $${++paramCount} OR c.name ILIKE $${++paramCount})`;
      params.push(`%${search}%`, `%${search}%`);
      paramCount++;
    }
    
    // Market cap filtering
    if (marketCap) {
      const marketCapRanges = {
        micro: [0, 300000000],
        small: [300000000, 2000000000],
        mid: [2000000000, 10000000000],
        large: [10000000000, 200000000000],
        mega: [200000000000, Number.MAX_SAFE_INTEGER]
      };
      
      if (marketCapRanges[marketCap]) {
        const [min, max] = marketCapRanges[marketCap];
        query += ` AND (s.shares_outstanding * COALESCE(latest.close_price, 0)) BETWEEN $${++paramCount} AND $${++paramCount}`;
        params.push(min, max);
        paramCount++;
      }
    }
    
    // Sorting
    const allowedSortFields = ['symbol', 'company_name', 'last_price', 'last_volume', 'market_cap'];
    const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'symbol';
    const order = sortOrder.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';
    
    if (sortField === 'market_cap') {
      query += ` ORDER BY (s.shares_outstanding * COALESCE(latest.close_price, 0)) ${order}`;
    } else {
      query += ` ORDER BY ${sortField} ${order}`;
    }
    
    query += ` LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    
    // Add calculated fields
    const symbols = result.rows.map(row => ({
      ...row,
      market_cap: row.shares_outstanding * row.last_price,
      float_percentage: row.shares_float ? (row.shares_float / row.shares_outstanding) * 100 : null
    }));
    
    res.json({
      symbols,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: symbols.length
      }
    });
    
  } catch (error) {
    logger.error('Error fetching symbols:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/market/symbols/{symbol}/quote:
 *   get:
 *     summary: Get real-time quote for symbol
 *     tags: [Market Data]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Real-time quote data
 */
app.get('/api/market/symbols/:symbol/quote', async (req, res) => {
  try {
    const { symbol } = req.params;
    
    const cacheKey = `quote:${symbol}`;
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
    
    const result = await pool.query(`
      SELECT 
        s.symbol, s.name, c.name as company_name,
        e.name as exchange_name, curr.code as currency,
        od.open_price, od.high_price, od.low_price, od.close_price,
        od.adjusted_close, od.volume, od.trade_date,
        od.volume_weighted_price, od.trade_count,
        prev.close_price as previous_close,
        (od.close_price - prev.close_price) as price_change,
        ((od.close_price - prev.close_price) / prev.close_price * 100) as price_change_percent,
        s.shares_outstanding,
        (s.shares_outstanding * od.close_price) as market_cap,
        ts.avg_volume_30d, ts.volume_ratio,
        ts.true_range, ts.intraday_return
      FROM securities s
      JOIN companies c ON s.company_id = c.id
      JOIN exchanges e ON s.exchange_id = e.id
      JOIN currencies curr ON s.currency_id = curr.id
      LEFT JOIN ohlcv_daily od ON s.id = od.security_id 
        AND od.trade_date = (
          SELECT MAX(trade_date) FROM ohlcv_daily WHERE security_id = s.id
        )
      LEFT JOIN ohlcv_daily prev ON s.id = prev.security_id 
        AND prev.trade_date = (
          SELECT MAX(trade_date) FROM ohlcv_daily 
          WHERE security_id = s.id AND trade_date < od.trade_date
        )
      LEFT JOIN trading_statistics ts ON s.id = ts.security_id 
        AND ts.trade_date = od.trade_date
      WHERE s.symbol = $1
    `, [symbol.toUpperCase()]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }
    
    const quote = result.rows[0];
    
    // Get latest intraday data if available
    const intradayResult = await pool.query(`
      SELECT * FROM ohlcv_intraday 
      WHERE security_id = (SELECT id FROM securities WHERE symbol = $1)
      ORDER BY timestamp DESC 
      LIMIT 1
    `, [symbol.toUpperCase()]);
    
    if (intradayResult.rows.length > 0) {
      const intraday = intradayResult.rows[0];
      quote.bid_price = intraday.bid_price;
      quote.ask_price = intraday.ask_price;
      quote.bid_size = intraday.bid_size;
      quote.ask_size = intraday.ask_size;
      quote.spread = intraday.spread;
      quote.last_update = intraday.timestamp;
    }
    
    // Cache for 30 seconds
    try {
      if (redis && redis.isOpen) {
        await redis.setEx(cacheKey, 30, JSON.stringify(quote));
      }
    } catch (redisError) {
      logger.warn('Redis cache set failed:', redisError.message);
    }
    
    res.json(quote);
    
  } catch (error) {
    logger.error('Error fetching quote:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/market/symbols/{symbol}/chart:
 *   get:
 *     summary: Get chart data with technical indicators
 *     tags: [Market Data]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [1D, 5D, 1M, 3M, 6M, 1Y, 2Y, 5Y, MAX]
 *       - in: query
 *         name: interval
 *         schema:
 *           type: string
 *           enum: [1m, 5m, 15m, 30m, 1h, 1d]
 *       - in: query
 *         name: indicators
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Chart data with OHLCV and indicators
 */
app.get('/api/market/symbols/:symbol/chart', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { period = '1M', interval = '1d', indicators } = req.query;
    
    // Calculate date range based on period
    const periodMap = {
      '1D': 1,
      '5D': 5,
      '1M': 30,
      '3M': 90,
      '6M': 180,
      '1Y': 365,
      '2Y': 730,
      '5Y': 1825
    };
    
    const days = periodMap[period] || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    let query, params;
    
    if (interval === '1d' || days > 30) {
      // Use daily data
      query = `
        SELECT 
          od.trade_date as timestamp,
          od.open_price as open,
          od.high_price as high,
          od.low_price as low,
          od.close_price as close,
          od.volume,
          ti.sma_20, ti.sma_50, ti.sma_200,
          ti.ema_12, ti.ema_26,
          ti.rsi_14, ti.macd, ti.macd_signal, ti.macd_histogram,
          ti.bb_upper, ti.bb_middle, ti.bb_lower,
          ti.atr_14, ti.volume_sma_20
        FROM ohlcv_daily od
        LEFT JOIN technical_indicators ti ON od.security_id = ti.security_id 
          AND od.trade_date = ti.trade_date
        WHERE od.security_id = (SELECT id FROM securities WHERE symbol = $1)
          AND od.trade_date >= $2
        ORDER BY od.trade_date
      `;
      params = [symbol.toUpperCase(), startDate.toISOString().split('T')[0]];
    } else {
      // Use intraday data for shorter periods
      query = `
        SELECT 
          oi.timestamp,
          oi.open_price as open,
          oi.high_price as high,
          oi.low_price as low,
          oi.close_price as close,
          oi.volume,
          oi.volume_weighted_price as vwap
        FROM ohlcv_intraday oi
        WHERE oi.security_id = (SELECT id FROM securities WHERE symbol = $1)
          AND oi.timestamp >= $2
        ORDER BY oi.timestamp
      `;
      params = [symbol.toUpperCase(), startDate.toISOString()];
    }
    
    const result = await pool.query(query, params);
    
    res.json({
      symbol: symbol.toUpperCase(),
      period,
      interval,
      data: result.rows
    });
    
  } catch (error) {
    logger.error('Error fetching chart data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/market/movers:
 *   get:
 *     summary: Get market movers (gainers, losers, most active)
 *     tags: [Market Data]
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [gainers, losers, active, volume]
 *       - in: query
 *         name: exchange
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Market movers data
 */
app.get('/api/market/movers', async (req, res) => {
  try {
    const { type = 'gainers', exchange, limit = 20 } = req.query;
    
    let orderBy;
    switch (type) {
      case 'gainers':
        orderBy = 'price_change_percent DESC';
        break;
      case 'losers':
        orderBy = 'price_change_percent ASC';
        break;
      case 'active':
      case 'volume':
        orderBy = 'volume DESC';
        break;
      default:
        orderBy = 'price_change_percent DESC';
    }
    
    let query = `
      SELECT 
        s.symbol, c.name as company_name,
        e.name as exchange_name,
        od.close_price as price,
        prev.close_price as previous_close,
        (od.close_price - prev.close_price) as price_change,
        ((od.close_price - prev.close_price) / prev.close_price * 100) as price_change_percent,
        od.volume,
        (s.shares_outstanding * od.close_price) as market_cap,
        ts.volume_ratio
      FROM securities s
      JOIN companies c ON s.company_id = c.id
      JOIN exchanges e ON s.exchange_id = e.id
      JOIN ohlcv_daily od ON s.id = od.security_id 
        AND od.trade_date = CURRENT_DATE
      JOIN ohlcv_daily prev ON s.id = prev.security_id 
        AND prev.trade_date = CURRENT_DATE - INTERVAL '1 day'
      LEFT JOIN trading_statistics ts ON s.id = ts.security_id 
        AND ts.trade_date = CURRENT_DATE
      WHERE s.is_active = true
        AND od.volume > 100000
        AND od.close_price > 1.0
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (exchange) {
      query += ` AND e.code = $${++paramCount}`;
      params.push(exchange);
    }
    
    query += ` ORDER BY ${orderBy} LIMIT $${++paramCount}`;
    params.push(parseInt(limit));
    
    const result = await pool.query(query, params);
    
    res.json({
      type,
      exchange: exchange || 'ALL',
      movers: result.rows
    });
    
  } catch (error) {
    logger.error('Error fetching market movers:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== ANALYTICS ENDPOINTS ====================

/**
 * @swagger
 * /api/analytics/market-overview:
 *   get:
 *     summary: Get comprehensive market overview
 *     tags: [Analytics]
 *     responses:
 *       200:
 *         description: Market overview with indices, sectors, and statistics
 */
app.get('/api/analytics/market-overview', async (req, res) => {
  try {
    const cacheKey = 'market-overview-v2';
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
    
    // Get major indices performance
    const indicesQuery = `
      SELECT 
        s.symbol, c.name,
        od.close_price as price,
        prev.close_price as previous_close,
        (od.close_price - prev.close_price) as change,
        ((od.close_price - prev.close_price) / prev.close_price * 100) as change_percent,
        od.volume
      FROM securities s
      JOIN companies c ON s.company_id = c.id
      JOIN ohlcv_daily od ON s.id = od.security_id AND od.trade_date = CURRENT_DATE
      JOIN ohlcv_daily prev ON s.id = prev.security_id AND prev.trade_date = CURRENT_DATE - INTERVAL '1 day'
      WHERE s.symbol IN ('SPY', 'QQQ', 'DIA', 'IWM', 'VTI')
      ORDER BY s.symbol
    `;
    
    // Get sector performance
    const sectorsQuery = `
      SELECT 
        sec.name as sector,
        COUNT(*) as companies,
        AVG((od.close_price - prev.close_price) / prev.close_price * 100) as avg_change_percent,
        SUM(od.volume) as total_volume,
        SUM(s.shares_outstanding * od.close_price) as total_market_cap
      FROM securities s
      JOIN companies c ON s.company_id = c.id
      JOIN sectors sec ON c.sector_id = sec.id
      JOIN ohlcv_daily od ON s.id = od.security_id AND od.trade_date = CURRENT_DATE
      JOIN ohlcv_daily prev ON s.id = prev.security_id AND prev.trade_date = CURRENT_DATE - INTERVAL '1 day'
      WHERE s.is_active = true
      GROUP BY sec.id, sec.name
      ORDER BY avg_change_percent DESC
    `;
    
    // Get market statistics
    const statsQuery = `
      SELECT 
        COUNT(*) as total_symbols,
        COUNT(CASE WHEN (od.close_price - prev.close_price) > 0 THEN 1 END) as advancing,
        COUNT(CASE WHEN (od.close_price - prev.close_price) < 0 THEN 1 END) as declining,
        COUNT(CASE WHEN (od.close_price - prev.close_price) = 0 THEN 1 END) as unchanged,
        SUM(od.volume) as total_volume,
        AVG(od.volume) as avg_volume,
        SUM(s.shares_outstanding * od.close_price) as total_market_cap
      FROM securities s
      JOIN ohlcv_daily od ON s.id = od.security_id AND od.trade_date = CURRENT_DATE
      JOIN ohlcv_daily prev ON s.id = prev.security_id AND prev.trade_date = CURRENT_DATE - INTERVAL '1 day'
      WHERE s.is_active = true
    `;
    
    const [indicesResult, sectorsResult, statsResult] = await Promise.all([
      pool.query(indicesQuery),
      pool.query(sectorsQuery),
      pool.query(statsQuery)
    ]);
    
    const overview = {
      timestamp: new Date().toISOString(),
      market_status: 'OPEN', // This would be calculated based on trading hours
      indices: indicesResult.rows,
      sectors: sectorsResult.rows,
      statistics: statsResult.rows[0],
      advance_decline_ratio: statsResult.rows[0].advancing / statsResult.rows[0].declining
    };
    
    // Cache for 1 minute
    try {
      if (redis && redis.isOpen) {
        await redis.setEx(cacheKey, 60, JSON.stringify(overview));
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

/**
 * @swagger
 * /api/analytics/heatmap:
 *   get:
 *     summary: Get market heatmap data
 *     tags: [Analytics]
 *     parameters:
 *       - in: query
 *         name: groupBy
 *         schema:
 *           type: string
 *           enum: [sector, industry, exchange, market_cap]
 *       - in: query
 *         name: metric
 *         schema:
 *           type: string
 *           enum: [change_percent, volume, market_cap]
 *     responses:
 *       200:
 *         description: Heatmap data grouped by specified criteria
 */
app.get('/api/analytics/heatmap', async (req, res) => {
  try {
    const { groupBy = 'sector', metric = 'change_percent' } = req.query;
    
    let groupField, groupName;
    switch (groupBy) {
      case 'sector':
        groupField = 'sec.id';
        groupName = 'sec.name';
        break;
      case 'industry':
        groupField = 'ind.id';
        groupName = 'ind.name';
        break;
      case 'exchange':
        groupField = 'e.id';
        groupName = 'e.name';
        break;
      default:
        groupField = 'sec.id';
        groupName = 'sec.name';
    }
    
    let metricField;
    switch (metric) {
      case 'change_percent':
        metricField = '((od.close_price - prev.close_price) / prev.close_price * 100)';
        break;
      case 'volume':
        metricField = 'od.volume';
        break;
      case 'market_cap':
        metricField = '(s.shares_outstanding * od.close_price)';
        break;
      default:
        metricField = '((od.close_price - prev.close_price) / prev.close_price * 100)';
    }
    
    const query = `
      SELECT 
        ${groupName} as group_name,
        COUNT(*) as count,
        AVG(${metricField}) as avg_value,
        SUM(${metricField}) as total_value,
        MIN(${metricField}) as min_value,
        MAX(${metricField}) as max_value,
        STDDEV(${metricField}) as std_dev
      FROM securities s
      JOIN companies c ON s.company_id = c.id
      LEFT JOIN sectors sec ON c.sector_id = sec.id
      LEFT JOIN industries ind ON c.industry_id = ind.id
      JOIN exchanges e ON s.exchange_id = e.id
      JOIN ohlcv_daily od ON s.id = od.security_id AND od.trade_date = CURRENT_DATE
      JOIN ohlcv_daily prev ON s.id = prev.security_id AND prev.trade_date = CURRENT_DATE - INTERVAL '1 day'
      WHERE s.is_active = true
      GROUP BY ${groupField}, ${groupName}
      ORDER BY avg_value DESC
    `;
    
    const result = await pool.query(query);
    
    res.json({
      groupBy,
      metric,
      data: result.rows
    });
    
  } catch (error) {
    logger.error('Error fetching heatmap data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== PORTFOLIO ENDPOINTS ====================

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
app.get('/api/portfolio/watchlists', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT w.*, 
        COUNT(ws.symbol_id) as symbol_count,
        ARRAY_AGG(s.symbol ORDER BY ws.added_date DESC) as symbols
      FROM watchlists w
      LEFT JOIN watchlist_symbols ws ON w.id = ws.watchlist_id
      LEFT JOIN securities s ON ws.symbol_id = s.id
      WHERE w.created_by = $1 OR w.is_public = true
      GROUP BY w.id
      ORDER BY w.created_at DESC
    `, [req.user.username]);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching watchlists:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/watchlists:
 *   post:
 *     summary: Create new watchlist
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
 *               isPublic:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Watchlist created successfully
 */
app.post('/api/portfolio/watchlists', authenticateToken, async (req, res) => {
  try {
    const schema = Joi.object({
      name: Joi.string().max(100).required(),
      description: Joi.string().max(500),
      isPublic: Joi.boolean().default(false)
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { name, description, isPublic } = value;

    const result = await pool.query(`
      INSERT INTO watchlists (name, description, created_by, is_public)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [name, description, req.user.username, isPublic]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    logger.error('Error creating watchlist:', error);
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
 *     parameters:
 *       - in: query
 *         name: active
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: User alerts
 */
app.get('/api/portfolio/alerts', authenticateToken, async (req, res) => {
  try {
    const { active } = req.query;
    
    let query = `
      SELECT a.*, s.symbol, s.name as security_name
      FROM alerts a
      JOIN securities s ON a.symbol_id = s.id
      WHERE a.created_by = $1
    `;
    
    const params = [req.user.username];
    
    if (active !== undefined) {
      query += ` AND a.is_active = $2`;
      params.push(active === 'true');
    }
    
    query += ` ORDER BY a.created_at DESC`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/portfolio/alerts:
 *   post:
 *     summary: Create new alert
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
 *               alertType:
 *                 type: string
 *               conditionType:
 *                 type: string
 *               targetValue:
 *                 type: number
 *     responses:
 *       201:
 *         description: Alert created successfully
 */
app.post('/api/portfolio/alerts', authenticateToken, async (req, res) => {
  try {
    const schema = Joi.object({
      symbol: Joi.string().required(),
      alertType: Joi.string().valid('price', 'volume', 'rsi', 'macd').required(),
      conditionType: Joi.string().valid('above', 'below', 'crosses_above', 'crosses_below').required(),
      targetValue: Joi.number().required()
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { symbol, alertType, conditionType, targetValue } = value;

    // Get symbol ID
    const symbolResult = await pool.query('SELECT id FROM securities WHERE symbol = $1', [symbol.toUpperCase()]);
    if (symbolResult.rows.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }

    const result = await pool.query(`
      INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [symbolResult.rows[0].id, alertType, conditionType, targetValue, req.user.username]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    logger.error('Error creating alert:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== RESEARCH ENDPOINTS ====================

/**
 * @swagger
 * /api/research/news:
 *   get:
 *     summary: Get financial news with sentiment analysis
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *       - in: query
 *         name: sentiment
 *         schema:
 *           type: string
 *           enum: [positive, negative, neutral]
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Financial news articles with sentiment
 */
app.get('/api/research/news', async (req, res) => {
  try {
    const { symbol, category, sentiment, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT 
        na.id, na.title, na.summary, na.url, na.published_at,
        ns_src.name as source_name, ns_src.credibility_score,
        nc.name as category_name,
        COALESCE(ns.overall_sentiment, 0) as sentiment_score,
        ns.sentiment_label,
        ns.confidence_score,
        CASE WHEN cn.company_id IS NOT NULL THEN true ELSE false END as is_company_specific
      FROM news_articles na
      LEFT JOIN news_sources ns_src ON na.news_source_id = ns_src.id
      LEFT JOIN news_categories nc ON na.news_category_id = nc.id
      LEFT JOIN news_sentiment ns ON na.id = ns.news_article_id
      LEFT JOIN company_news cn ON na.id = cn.news_article_id
    `;
    
    const params = [];
    let paramCount = 0;
    const conditions = [];
    
    if (symbol) {
      conditions.push(`cn.company_id = (
        SELECT c.id FROM companies c 
        JOIN securities s ON c.id = s.company_id 
        WHERE s.symbol = $${++paramCount}
      )`);
      params.push(symbol.toUpperCase());
    }
    
    if (category) {
      conditions.push(`nc.code = $${++paramCount}`);
      params.push(category);
    }
    
    if (sentiment) {
      conditions.push(`ns.sentiment_label = $${++paramCount}`);
      params.push(sentiment);
    }
    
    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }
    
    query += ` ORDER BY na.published_at DESC LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching news:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/earnings:
 *   get:
 *     summary: Get earnings calendar and estimates
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Earnings calendar and estimates
 */
app.get('/api/research/earnings', async (req, res) => {
  try {
    const { symbol, startDate, endDate } = req.query;
    
    let query = `
      SELECT 
        c.name as company_name, s.symbol,
        ce.event_date, ce.announcement_date,
        ce.description, ce.expected_impact,
        ae.mean_estimate as eps_estimate,
        ae.high_estimate as eps_high,
        ae.low_estimate as eps_low,
        ae.number_of_estimates as analyst_count,
        fp.fiscal_year, fp.fiscal_quarter
      FROM corporate_events ce
      JOIN companies c ON ce.company_id = c.id
      JOIN securities s ON c.id = s.company_id
      LEFT JOIN financial_periods fp ON c.id = fp.company_id 
        AND fp.period_end_date >= ce.event_date - INTERVAL '90 days'
        AND fp.period_end_date <= ce.event_date + INTERVAL '30 days'
      LEFT JOIN analyst_estimates ae ON c.id = ae.company_id 
        AND ae.period_type = 'QUARTERLY'
        AND ae.estimate_type = 'EPS'
        AND ae.fiscal_year = fp.fiscal_year
        AND ae.fiscal_quarter = fp.fiscal_quarter
      WHERE ce.event_type_id = (SELECT id FROM event_types WHERE code = 'EARNINGS')
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (symbol) {
      query += ` AND s.symbol = $${++paramCount}`;
      params.push(symbol.toUpperCase());
    }
    
    if (startDate) {
      query += ` AND ce.event_date >= $${++paramCount}`;
      params.push(startDate);
    }
    
    if (endDate) {
      query += ` AND ce.event_date <= $${++paramCount}`;
      params.push(endDate);
    }
    
    query += ` ORDER BY ce.event_date ASC`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching earnings data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== TRADING ENDPOINTS ====================

/**
 * @swagger
 * /api/trading/orderbook/{symbol}:
 *   get:
 *     summary: Get order book data
 *     tags: [Trading]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: depth
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: Order book with bids and asks
 */
app.get('/api/trading/orderbook/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { depth = 10 } = req.query;
    
    const result = await pool.query(`
      SELECT 
        bid_prices, bid_sizes, ask_prices, ask_sizes,
        total_bid_volume, total_ask_volume, spread, mid_price,
        timestamp
      FROM market_depth
      WHERE security_id = (SELECT id FROM securities WHERE symbol = $1)
      ORDER BY timestamp DESC
      LIMIT 1
    `, [symbol.toUpperCase()]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order book data not found' });
    }
    
    const orderBook = result.rows[0];
    
    // Format the order book data
    const bids = orderBook.bid_prices.slice(0, depth).map((price, index) => ({
      price: parseFloat(price),
      size: orderBook.bid_sizes[index] || 0,
      total: orderBook.bid_sizes.slice(0, index + 1).reduce((sum, size) => sum + size, 0)
    }));
    
    const asks = orderBook.ask_prices.slice(0, depth).map((price, index) => ({
      price: parseFloat(price),
      size: orderBook.ask_sizes[index] || 0,
      total: orderBook.ask_sizes.slice(0, index + 1).reduce((sum, size) => sum + size, 0)
    }));
    
    res.json({
      symbol: symbol.toUpperCase(),
      timestamp: orderBook.timestamp,
      bids,
      asks,
      spread: orderBook.spread,
      midPrice: orderBook.mid_price,
      totalBidVolume: orderBook.total_bid_volume,
      totalAskVolume: orderBook.total_ask_volume
    });
    
  } catch (error) {
    logger.error('Error fetching order book:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== SCREENING ENDPOINTS ====================

/**
 * @swagger
 * /api/screening/screens:
 *   get:
 *     summary: Get available screens
 *     tags: [Screening]
 *     responses:
 *       200:
 *         description: List of available screens
 */
app.get('/api/screening/screens', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*, 
        COUNT(sr.id) as last_result_count,
        MAX(sr.scan_date) as last_run_date
      FROM screens s
      LEFT JOIN screen_results sr ON s.id = sr.screen_id
      WHERE s.is_active = true
      GROUP BY s.id
      ORDER BY s.name
    `);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching screens:', error);
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
 *         description: List of screening criteria
 */
app.get('/api/screening/criteria', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT * FROM screen_criteria
      ORDER BY category, name
    `);
    
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching screening criteria:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== BACKTESTING ENDPOINTS ====================

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
app.get('/api/backtesting/strategies', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*,
        COUNT(b.id) as backtest_count,
        AVG(b.total_return) as avg_return,
        AVG(b.sharpe_ratio) as avg_sharpe
      FROM strategies s
      LEFT JOIN backtests b ON s.id = b.strategy_id
      WHERE s.is_active = true
      GROUP BY s.id
      ORDER BY s.name
    `);
    
    res.json(result.rows);
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
 *         name: strategyId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of backtest results
 */
app.get('/api/backtesting/backtests', async (req, res) => {
  try {
    const { strategyId, status, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT b.*, s.name as strategy_name
      FROM backtests b
      JOIN strategies s ON b.strategy_id = s.id
    `;
    
    const params = [];
    let paramCount = 0;
    const conditions = [];
    
    if (strategyId) {
      conditions.push(`b.strategy_id = $${++paramCount}`);
      params.push(parseInt(strategyId));
    }
    
    if (status) {
      conditions.push(`b.status = $${++paramCount}`);
      params.push(status);
    }
    
    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`;
    }
    
    query += ` ORDER BY b.created_at DESC LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    logger.error('Error fetching backtests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== WEBSOCKET REAL-TIME DATA ====================

wss.on('connection', (ws, req) => {
  logger.info('New WebSocket connection established');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      switch (data.type) {
        case 'subscribe':
          handleSubscription(ws, data);
          break;
        case 'unsubscribe':
          handleUnsubscription(ws, data);
          break;
        case 'ping':
          ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
          break;
      }
    } catch (error) {
      logger.error('WebSocket message error:', error);
      ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }));
    }
  });
  
  ws.on('close', () => {
    logger.info('WebSocket connection closed');
  });
  
  // Send welcome message
  ws.send(JSON.stringify({
    type: 'welcome',
    message: 'Connected to Bloomberg-style Terminal API',
    timestamp: Date.now()
  }));
});

function handleSubscription(ws, data) {
  const { symbols, dataTypes } = data;
  
  // Store subscription info on the WebSocket
  ws.subscriptions = ws.subscriptions || new Set();
  
  symbols.forEach(symbol => {
    dataTypes.forEach(dataType => {
      const subscription = `${symbol}:${dataType}`;
      ws.subscriptions.add(subscription);
    });
  });
  
  ws.send(JSON.stringify({
    type: 'subscribed',
    symbols,
    dataTypes,
    timestamp: Date.now()
  }));
}

function handleUnsubscription(ws, data) {
  const { symbols, dataTypes } = data;
  
  if (ws.subscriptions) {
    symbols.forEach(symbol => {
      dataTypes.forEach(dataType => {
        const subscription = `${symbol}:${dataType}`;
        ws.subscriptions.delete(subscription);
      });
    });
  }
  
  ws.send(JSON.stringify({
    type: 'unsubscribed',
    symbols,
    dataTypes,
    timestamp: Date.now()
  }));
}

// Broadcast real-time data to subscribed clients
function broadcastMarketData(symbol, dataType, data) {
  const subscription = `${symbol}:${dataType}`;
  
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && 
        client.subscriptions && 
        client.subscriptions.has(subscription)) {
      client.send(JSON.stringify({
        type: 'market_data',
        symbol,
        dataType,
        data,
        timestamp: Date.now()
      }));
    }
  });
}

// Simulate real-time data updates (in production, this would come from market data feeds)
setInterval(() => {
  const symbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA'];
  const symbol = symbols[Math.floor(Math.random() * symbols.length)];
  
  const mockQuote = {
    price: 150 + Math.random() * 100,
    change: (Math.random() - 0.5) * 10,
    volume: Math.floor(Math.random() * 1000000),
    bid: 149.95,
    ask: 150.05,
    timestamp: Date.now()
  };
  
  broadcastMarketData(symbol, 'quote', mockQuote);
}, 5000);

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
    
    // Start Express server with WebSocket support
    const port = process.env.API_PORT || 3000;
    server.listen(port, () => {
      logger.info(`Bloomberg-style API Gateway listening on port ${port}`);
      logger.info(`API Documentation available at http://localhost:${port}/api-docs`);
      logger.info(`WebSocket server running on ws://localhost:${port}`);
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
  server.close();
  process.exit(0);
});

// Start the service
initialize();