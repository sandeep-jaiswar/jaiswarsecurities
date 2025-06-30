const express = require('express');
const { Pool } = require('pg');
const { Kafka } = require('kafkajs');
const axios = require('axios');
const cron = require('node-cron');
const winston = require('winston');
const Redis = require('redis');
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
  clientId: 'data-ingestion-service',
  brokers: process.env.KAFKA_BROKERS.split(','),
});

const producer = kafka.producer();
const consumer = kafka.consumer({ groupId: 'data-ingestion-group' });

// Initialize Redis
const redis = Redis.createClient({
  url: process.env.REDIS_URL
});

// Initialize Express app
const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Data ingestion endpoints
app.post('/ingest/symbols', async (req, res) => {
  try {
    const { symbols } = req.body;
    await ingestSymbols(symbols);
    res.json({ message: 'Symbols ingestion started', count: symbols.length });
  } catch (error) {
    logger.error('Error ingesting symbols:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/ingest/ohlcv', async (req, res) => {
  try {
    const { symbol, startDate, endDate } = req.body;
    await ingestOHLCV(symbol, startDate, endDate);
    res.json({ message: 'OHLCV ingestion started', symbol, startDate, endDate });
  } catch (error) {
    logger.error('Error ingesting OHLCV:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Symbol ingestion function
async function ingestSymbols(symbols) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    for (const symbol of symbols) {
      const query = `
        INSERT INTO symbols (symbol, yticker, name, exchange, industry, sector, market_cap)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (symbol) DO UPDATE SET
          name = EXCLUDED.name,
          exchange = EXCLUDED.exchange,
          industry = EXCLUDED.industry,
          sector = EXCLUDED.sector,
          market_cap = EXCLUDED.market_cap,
          updated_at = NOW()
      `;
      
      await client.query(query, [
        symbol.symbol,
        symbol.yticker || symbol.symbol,
        symbol.name,
        symbol.exchange,
        symbol.industry,
        symbol.sector,
        symbol.market_cap
      ]);
    }
    
    await client.query('COMMIT');
    logger.info(`Ingested ${symbols.length} symbols`);
    
    // Send message to Kafka
    await producer.send({
      topic: 'symbols-ingested',
      messages: [{
        key: 'symbols',
        value: JSON.stringify({ count: symbols.length, timestamp: new Date() })
      }]
    });
    
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// OHLCV ingestion function
async function ingestOHLCV(symbol, startDate, endDate) {
  try {
    // Get symbol ID
    const symbolResult = await pool.query('SELECT id FROM symbols WHERE symbol = $1', [symbol]);
    if (symbolResult.rows.length === 0) {
      throw new Error(`Symbol ${symbol} not found`);
    }
    const symbolId = symbolResult.rows[0].id;
    
    // Fetch data from external API (Alpha Vantage example)
    const data = await fetchOHLCVData(symbol, startDate, endDate);
    
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      for (const record of data) {
        const query = `
          INSERT INTO ohlcv (symbol_id, trade_date, open_price, high_price, low_price, close_price, adjusted_close, volume)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ON CONFLICT (symbol_id, trade_date) DO UPDATE SET
            open_price = EXCLUDED.open_price,
            high_price = EXCLUDED.high_price,
            low_price = EXCLUDED.low_price,
            close_price = EXCLUDED.close_price,
            adjusted_close = EXCLUDED.adjusted_close,
            volume = EXCLUDED.volume
        `;
        
        await client.query(query, [
          symbolId,
          record.date,
          record.open,
          record.high,
          record.low,
          record.close,
          record.adjusted_close,
          record.volume
        ]);
      }
      
      await client.query('COMMIT');
      logger.info(`Ingested ${data.length} OHLCV records for ${symbol}`);
      
      // Send message to Kafka for indicator calculation
      await producer.send({
        topic: 'ohlcv-ingested',
        messages: [{
          key: symbol,
          value: JSON.stringify({ 
            symbol, 
            symbolId, 
            recordCount: data.length, 
            startDate, 
            endDate,
            timestamp: new Date() 
          })
        }]
      });
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    
  } catch (error) {
    logger.error(`Error ingesting OHLCV for ${symbol}:`, error);
    throw error;
  }
}

// External API data fetching
async function fetchOHLCVData(symbol, startDate, endDate) {
  // Check cache first
  const cacheKey = `ohlcv:${symbol}:${startDate}:${endDate}`;
  const cachedData = await redis.get(cacheKey);
  
  if (cachedData) {
    logger.info(`Using cached data for ${symbol}`);
    return JSON.parse(cachedData);
  }
  
  try {
    // Alpha Vantage API call
    const response = await axios.get('https://www.alphavantage.co/query', {
      params: {
        function: 'TIME_SERIES_DAILY_ADJUSTED',
        symbol: symbol,
        apikey: process.env.ALPHA_VANTAGE_API_KEY,
        outputsize: 'full'
      },
      timeout: 30000
    });
    
    const timeSeries = response.data['Time Series (Daily)'];
    if (!timeSeries) {
      throw new Error(`No data received for ${symbol}`);
    }
    
    const data = Object.entries(timeSeries)
      .filter(([date]) => date >= startDate && date <= endDate)
      .map(([date, values]) => ({
        date,
        open: parseFloat(values['1. open']),
        high: parseFloat(values['2. high']),
        low: parseFloat(values['3. low']),
        close: parseFloat(values['4. close']),
        adjusted_close: parseFloat(values['5. adjusted close']),
        volume: parseInt(values['6. volume'])
      }))
      .sort((a, b) => new Date(a.date) - new Date(b.date));
    
    // Cache the data for 1 hour
    await redis.setEx(cacheKey, 3600, JSON.stringify(data));
    
    return data;
    
  } catch (error) {
    logger.error(`Error fetching data for ${symbol}:`, error);
    throw error;
  }
}

// Scheduled jobs
cron.schedule('0 18 * * 1-5', async () => {
  logger.info('Starting daily data ingestion job');
  try {
    // Get all active symbols
    const result = await pool.query('SELECT symbol FROM symbols WHERE is_active = true');
    const symbols = result.rows.map(row => row.symbol);
    
    // Ingest data for each symbol
    for (const symbol of symbols) {
      const today = new Date().toISOString().split('T')[0];
      await ingestOHLCV(symbol, today, today);
      
      // Rate limiting
      await new Promise(resolve => setTimeout(resolve, 12000)); // 12 seconds between calls
    }
    
    logger.info('Daily data ingestion job completed');
  } catch (error) {
    logger.error('Error in daily data ingestion job:', error);
  }
});

// Kafka consumer for processing messages
async function startKafkaConsumer() {
  await consumer.subscribe({ topics: ['symbol-requests', 'ohlcv-requests'] });
  
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const data = JSON.parse(message.value.toString());
        
        switch (topic) {
          case 'symbol-requests':
            await ingestSymbols(data.symbols);
            break;
          case 'ohlcv-requests':
            await ingestOHLCV(data.symbol, data.startDate, data.endDate);
            break;
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
    // Connect to Redis
    await redis.connect();
    logger.info('Connected to Redis');
    
    // Connect to Kafka
    await producer.connect();
    await consumer.connect();
    await startKafkaConsumer();
    logger.info('Connected to Kafka');
    
    // Test database connection
    await pool.query('SELECT NOW()');
    logger.info('Connected to PostgreSQL');
    
    // Start Express server
    const port = process.env.PORT || 3001;
    app.listen(port, () => {
      logger.info(`Data ingestion service listening on port ${port}`);
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
  await redis.disconnect();
  await pool.end();
  process.exit(0);
});

// Start the service
initialize();