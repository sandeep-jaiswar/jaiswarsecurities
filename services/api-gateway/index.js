const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { createClient } = require('@clickhouse/client');
const Redis = require('redis');
const winston = require('winston');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const WebSocket = require('ws');
const http = require('http');
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

// Initialize ClickHouse connection
const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || 'http://localhost:8123',
  username: process.env.CLICKHOUSE_USER || 'stockuser',
  password: process.env.CLICKHOUSE_PASSWORD || 'stockpass123',
  database: process.env.CLICKHOUSE_DATABASE || 'stockdb',
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 1,
  },
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
      title: 'Bloomberg-style Stock Terminal API',
      version: '2.0.0',
      description: 'Comprehensive API for stock screening, analytics, and trading with ClickHouse backend',
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

// Authentication middleware
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

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Bloomberg-style Stock Terminal API with ClickHouse',
    version: '2.0.0',
    database: 'ClickHouse',
    endpoints: {
      health: '/health',
      docs: '/api-docs',
      auth: '/api/auth',
      market: '/api/market',
      analytics: '/api/analytics',
      portfolio: '/api/portfolio',
      research: '/api/research',
      trading: '/api/trading',
      screening: '/api/screening',
      backtesting: '/api/backtesting'
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
    // Check ClickHouse connection
    await clickhouse.query({ query: 'SELECT 1' });
    
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
        clickhouse: 'connected',
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

// Authentication endpoints
/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
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
 *     responses:
 *       201:
 *         description: User registered successfully
 */
app.post('/api/auth/register', async (req, res) => {
  try {
    const schema = Joi.object({
      username: Joi.string().alphanum().min(3).max(30).required(),
      email: Joi.string().email().required(),
      password: Joi.string().min(6).required(),
      firstName: Joi.string().optional(),
      lastName: Joi.string().optional()
    });

    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { username, email, password, firstName, lastName } = value;

    // Check if user exists
    const existingUser = await clickhouse.query({
      query: 'SELECT id FROM users WHERE username = {username:String} OR email = {email:String}',
      query_params: { username, email }
    });

    if (existingUser.rows > 0) {
      return res.status(409).json({ error: 'Username or email already exists' });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Insert user
    const userId = Date.now(); // Simple ID generation
    await clickhouse.insert({
      table: 'users',
      values: [{
        id: userId,
        username,
        email,
        password_hash: passwordHash,
        first_name: firstName || '',
        last_name: lastName || '',
        is_active: 1,
        is_verified: 0
      }]
    });

    res.status(201).json({ 
      message: 'User registered successfully',
      userId 
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
 *     summary: Login user
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
    const result = await clickhouse.query({
      query: 'SELECT id, username, email, password_hash, is_active FROM users WHERE username = {username:String} OR email = {username:String}',
      query_params: { username }
    });

    const users = await result.json();
    if (users.data.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = users.data[0];
    if (!user.is_active) {
      return res.status(401).json({ error: 'Account is disabled' });
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

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    });

  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Market Data endpoints
/**
 * @swagger
 * /api/market/symbols:
 *   get:
 *     summary: Get all symbols with filtering
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by symbol or name
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
app.get('/api/market/symbols', async (req, res) => {
  try {
    const { search, sector, exchange, limit = 100, offset = 0 } = req.query;
    
    let query = `
      SELECT s.id, s.symbol, s.name, c.name as company_name, s.is_active
      FROM securities s
      LEFT JOIN companies c ON s.company_id = c.id
      WHERE s.is_active = 1
    `;
    
    const queryParams = {};
    
    if (search) {
      query += ` AND (s.symbol ILIKE {search:String} OR s.name ILIKE {search:String})`;
      queryParams.search = `%${search}%`;
    }
    
    if (sector) {
      query += ` AND c.sector_id = {sector:UInt32}`;
      queryParams.sector = parseInt(sector);
    }
    
    query += ` ORDER BY s.symbol LIMIT {limit:UInt32} OFFSET {offset:UInt32}`;
    queryParams.limit = parseInt(limit);
    queryParams.offset = parseInt(offset);
    
    const result = await clickhouse.query({
      query,
      query_params: queryParams
    });
    
    const data = await result.json();
    res.json(data.data);
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
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *         description: Stock symbol
 *     responses:
 *       200:
 *         description: Real-time quote data
 */
app.get('/api/market/symbols/:symbol/quote', async (req, res) => {
  try {
    const { symbol } = req.params;
    
    // Check cache first
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
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          o.open_price,
          o.high_price,
          o.low_price,
          o.close_price,
          o.volume,
          o.trade_date,
          (o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) as price_change,
          ((o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) / LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) * 100 as price_change_percent
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        WHERE s.symbol = {symbol:String}
        ORDER BY o.trade_date DESC
        LIMIT 1
      `,
      query_params: { symbol: symbol.toUpperCase() }
    });
    
    const data = await result.json();
    if (data.data.length === 0) {
      return res.status(404).json({ error: 'Symbol not found' });
    }
    
    const quote = data.data[0];
    
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
 *           enum: [1D, 5D, 1M, 3M, 6M, 1Y, 5Y]
 *       - in: query
 *         name: indicators
 *         schema:
 *           type: string
 *         description: Comma-separated list of indicators
 *     responses:
 *       200:
 *         description: Chart data with indicators
 */
app.get('/api/market/symbols/:symbol/chart', async (req, res) => {
  try {
    const { symbol } = req.params;
    const { period = '1M', indicators } = req.query;
    
    // Calculate date range based on period
    let daysBack = 30;
    switch (period) {
      case '1D': daysBack = 1; break;
      case '5D': daysBack = 5; break;
      case '1M': daysBack = 30; break;
      case '3M': daysBack = 90; break;
      case '6M': daysBack = 180; break;
      case '1Y': daysBack = 365; break;
      case '5Y': daysBack = 1825; break;
    }
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          o.trade_date,
          o.open_price,
          o.high_price,
          o.low_price,
          o.close_price,
          o.volume,
          ti.sma_20,
          ti.sma_50,
          ti.ema_12,
          ti.ema_26,
          ti.rsi_14,
          ti.macd,
          ti.macd_signal,
          ti.bb_upper,
          ti.bb_middle,
          ti.bb_lower
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN technical_indicators ti ON s.id = ti.security_id AND o.trade_date = ti.trade_date
        WHERE s.symbol = {symbol:String}
          AND o.trade_date >= today() - {daysBack:UInt32}
        ORDER BY o.trade_date ASC
      `,
      query_params: { 
        symbol: symbol.toUpperCase(),
        daysBack 
      }
    });
    
    const data = await result.json();
    res.json({
      symbol: symbol.toUpperCase(),
      period,
      data: data.data
    });
  } catch (error) {
    logger.error('Error fetching chart data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Market movers endpoint
app.get('/api/market/movers', async (req, res) => {
  try {
    const { type = 'gainers', limit = 20 } = req.query;
    
    let orderBy = 'price_change_percent DESC';
    if (type === 'losers') {
      orderBy = 'price_change_percent ASC';
    } else if (type === 'active') {
      orderBy = 'volume DESC';
    }
    
    const result = await clickhouse.query({
      query: `
        WITH latest_prices AS (
          SELECT 
            s.symbol,
            s.name,
            o.close_price,
            o.volume,
            o.trade_date,
            (o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) as price_change,
            ((o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) / LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) * 100 as price_change_percent,
            ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY o.trade_date DESC) as rn
          FROM securities s
          JOIN ohlcv_daily o ON s.id = o.security_id
          WHERE s.is_active = 1
            AND o.trade_date >= today() - 5
        )
        SELECT 
          symbol,
          name,
          close_price,
          volume,
          price_change,
          price_change_percent
        FROM latest_prices
        WHERE rn = 1 AND price_change IS NOT NULL
        ORDER BY ${orderBy}
        LIMIT {limit:UInt32}
      `,
      query_params: { limit: parseInt(limit) }
    });
    
    const data = await result.json();
    res.json({
      type,
      data: data.data
    });
  } catch (error) {
    logger.error('Error fetching market movers:', error);
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
    const statsResult = await clickhouse.query({
      query: `
        SELECT 
          COUNT(*) as total_symbols,
          COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_symbols
        FROM securities
      `
    });
    
    const volumeResult = await clickhouse.query({
      query: `
        SELECT 
          COUNT(*) as records_today,
          SUM(volume) as total_volume
        FROM ohlcv_daily 
        WHERE trade_date = today()
      `
    });
    
    const stats = await statsResult.json();
    const volume = await volumeResult.json();
    
    const overview = {
      ...stats.data[0],
      ...volume.data[0],
      last_updated: new Date().toISOString()
    };
    
    // Cache for 10 minutes
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

// Screening endpoints
app.get('/api/screening/screens', async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: 'SELECT * FROM screens WHERE is_active = 1 ORDER BY name'
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching screens:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Backtesting endpoints
app.get('/api/backtesting/strategies', async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: 'SELECT * FROM strategies WHERE is_active = 1 ORDER BY name'
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching strategies:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/backtesting/backtests', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          b.*,
          s.name as strategy_name 
        FROM backtests b 
        LEFT JOIN strategies s ON b.strategy_id = s.id 
        ORDER BY b.created_at DESC 
        LIMIT {limit:UInt32} OFFSET {offset:UInt32}
      `,
      query_params: { 
        limit: parseInt(limit), 
        offset: parseInt(offset) 
      }
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching backtests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// WebSocket handling
wss.on('connection', (ws) => {
  logger.info('New WebSocket connection established');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      switch (data.type) {
        case 'subscribe':
          // Handle subscription to real-time data
          ws.symbol = data.symbol;
          ws.send(JSON.stringify({
            type: 'subscribed',
            symbol: data.symbol,
            message: `Subscribed to ${data.symbol}`
          }));
          break;
          
        case 'unsubscribe':
          // Handle unsubscription
          ws.symbol = null;
          ws.send(JSON.stringify({
            type: 'unsubscribed',
            message: 'Unsubscribed from all symbols'
          }));
          break;
      }
    } catch (error) {
      logger.error('WebSocket message error:', error);
    }
  });
  
  ws.on('close', () => {
    logger.info('WebSocket connection closed');
  });
});

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
    
    // Test ClickHouse connection
    await clickhouse.query({ query: 'SELECT 1' });
    logger.info('Connected to ClickHouse');
    
    // Start server
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
  await clickhouse.close();
  server.close();
  process.exit(0);
});

// Start the service
initialize();