const { createClient } = require("@clickhouse/client")
const axios = require("axios")
const express = require("express")
const { Kafka } = require("kafkajs")
const cron = require("node-cron")
const Redis = require("redis")
const winston = require("winston")
const path = require("path")
require("dotenv").config({ path: path.resolve(__dirname, "../../../.env") })

// Initialize logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
})

// Initialize ClickHouse connection
const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL,
  username: process.env.CLICKHOUSE_USER || "stockuser",
  password: process.env.CLICKHOUSE_PASSWORD || "stockpass123",
  database: process.env.CLICKHOUSE_DATABASE || "stockdb",
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 1,
  },
})

// Initialize Kafka
const kafka = new Kafka({
  clientId: "data-ingestion-service",
  brokers: process.env.KAFKA_BROKERS.split(","),
})

const producer = kafka.producer()
const consumer = kafka.consumer({ groupId: "data-ingestion-group" })

// Initialize Redis
const redis = Redis.createClient({
  url: process.env.REDIS_URL,
})

// Initialize Express app
const app = express()
app.use(express.json())

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() })
})

// Data ingestion endpoints
app.post("/ingest/symbols", async (req, res) => {
  try {
    const { symbols } = req.body
    await ingestSymbols(symbols)
    res.json({ message: "Symbols ingestion started", count: symbols.length })
  } catch (error) {
    logger.error("Error ingesting symbols:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

app.post("/ingest/ohlcv", async (req, res) => {
  try {
    const { symbol, startDate, endDate } = req.body
    await ingestOHLCV(symbol, startDate, endDate)
    res.json({
      message: "OHLCV ingestion started",
      symbol,
      startDate,
      endDate,
    })
  } catch (error) {
    logger.error("Error ingesting OHLCV:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Symbol ingestion function
async function ingestSymbols(symbols) {
  try {
    const values = symbols.map((symbol) => ({
      id: Date.now() + Math.random(), // Simple ID generation
      company_id: symbol.company_id || 0,
      symbol: symbol.symbol,
      name: symbol.name,
      is_active: 1,
    }))

    await clickhouse.insert({
      table: "securities",
      values: values,
    })

    logger.info(`Ingested ${symbols.length} symbols`)

    // Send message to Kafka
    await producer.send({
      topic: "symbols-ingested",
      messages: [
        {
          key: "symbols",
          value: JSON.stringify({
            count: symbols.length,
            timestamp: new Date(),
          }),
        },
      ],
    })
  } catch (error) {
    logger.error("Error in ingestSymbols:", error)
    throw error
  }
}

// OHLCV ingestion function
async function ingestOHLCV(symbol, startDate, endDate) {
  try {
    // Get security ID
    const securityResult = await clickhouse.query({
      query: "SELECT id FROM securities WHERE symbol = {symbol:String}",
      query_params: { symbol },
    })

    const securities = await securityResult.json()
    if (securities.data.length === 0) {
      throw new Error(`Symbol ${symbol} not found`)
    }
    const securityId = securities.data[0].id

    // Fetch data from external API
    const data = await fetchOHLCVData(symbol, startDate, endDate)

    const values = data.map((record) => ({
      id: Date.now() + Math.random(),
      security_id: securityId,
      trade_date: record.date,
      open_price: record.open,
      high_price: record.high,
      low_price: record.low,
      close_price: record.close,
      adjusted_close: record.adjusted_close,
      volume: record.volume,
    }))

    await clickhouse.insert({
      table: "ohlcv_daily",
      values: values,
    })

    logger.info(`Ingested ${data.length} OHLCV records for ${symbol}`)

    // Send message to Kafka for indicator calculation
    await producer.send({
      topic: "ohlcv-ingested",
      messages: [
        {
          key: symbol,
          value: JSON.stringify({
            symbol,
            securityId,
            recordCount: data.length,
            startDate,
            endDate,
            timestamp: new Date(),
          }),
        },
      ],
    })
  } catch (error) {
    logger.error(`Error ingesting OHLCV for ${symbol}:`, error)
    throw error
  }
}

// External API data fetching
async function fetchOHLCVData(symbol, startDate, endDate) {
  // Check cache first
  const cacheKey = `ohlcv:${symbol}:${startDate}:${endDate}`
  const cachedData = await redis.get(cacheKey)

  if (cachedData) {
    logger.info(`Using cached data for ${symbol}`)
    return JSON.parse(cachedData)
  }

  try {
    // Alpha Vantage API call
    const response = await axios.get("https://www.alphavantage.co/query", {
      params: {
        function: "TIME_SERIES_DAILY_ADJUSTED",
        symbol: symbol,
        apikey: process.env.ALPHA_VANTAGE_API_KEY,
        outputsize: "full",
      },
      timeout: 30000,
    })

    const timeSeries = response.data["Time Series (Daily)"]
    if (!timeSeries) {
      throw new Error(`No data received for ${symbol}`)
    }

    const data = Object.entries(timeSeries)
      .filter(([date]) => date >= startDate && date <= endDate)
      .map(([date, values]) => ({
        date,
        open: parseFloat(values["1. open"]),
        high: parseFloat(values["2. high"]),
        low: parseFloat(values["3. low"]),
        close: parseFloat(values["4. close"]),
        adjusted_close: parseFloat(values["5. adjusted close"]),
        volume: parseInt(values["6. volume"]),
      }))
      .sort((a, b) => new Date(a.date) - new Date(b.date))

    // Cache the data for 1 hour
    await redis.setEx(cacheKey, 3600, JSON.stringify(data))

    return data
  } catch (error) {
    logger.error(`Error fetching data for ${symbol}:`, error)
    throw error
  }
}

// Scheduled jobs
cron.schedule("0 18 * * 1-5", async () => {
  logger.info("Starting daily data ingestion job")
  try {
    // Get all active symbols
    const result = await clickhouse.query({
      query: "SELECT symbol FROM securities WHERE is_active = 1",
    })

    const securities = await result.json()
    const symbols = securities.data.map((row) => row.symbol)

    // Ingest data for each symbol
    for (const symbol of symbols) {
      const today = new Date().toISOString().split("T")[0]
      await ingestOHLCV(symbol, today, today)

      // Rate limiting
      await new Promise((resolve) => setTimeout(resolve, 12000)) // 12 seconds between calls
    }

    logger.info("Daily data ingestion job completed")
  } catch (error) {
    logger.error("Error in daily data ingestion job:", error)
  }
})

// Kafka consumer for processing messages
async function startKafkaConsumer() {
  await consumer.subscribe({ topics: ["symbol-requests", "ohlcv-requests"] })

  await consumer.run({
    eachMessage: async ({ topic, message }) => {
      try {
        const data = JSON.parse(message.value.toString())

        switch (topic) {
          case "symbol-requests":
            await ingestSymbols(data.symbols)
            break
          case "ohlcv-requests":
            await ingestOHLCV(data.symbol, data.startDate, data.endDate)
            break
        }
      } catch (error) {
        logger.error("Error processing Kafka message:", error)
      }
    },
  })
}

// Initialize services
async function initialize() {
  try {
    // Connect to Redis
    await redis.connect()
    logger.info("Connected to Redis")

    // Connect to Kafka
    await producer.connect()
    await consumer.connect()
    await startKafkaConsumer()
    logger.info("Connected to Kafka")

    // Test ClickHouse connection
    await clickhouse.query({ query: "SELECT 1" })
    logger.info("Connected to ClickHouse")

    // Start Express server
    const port = process.env.PORT || 3001
    app.listen(port, () => {
      logger.info(`Data ingestion service listening on port ${port}`)
    })
  } catch (error) {
    logger.error("Failed to initialize service:", error)
    process.exit(1)
  }
}

// Graceful shutdown
process.on("SIGTERM", async () => {
  logger.info("Received SIGTERM, shutting down gracefully")
  await producer.disconnect()
  await consumer.disconnect()
  await redis.disconnect()
  await clickhouse.close()
  process.exit(0)
})

// Start the service
initialize()
