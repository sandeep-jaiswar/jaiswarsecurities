const { createClient } = require("@clickhouse/client")
const express = require("express")
const { Kafka } = require("kafkajs")
const { SMA, EMA, RSI, MACD, BollingerBands } = require("technicalindicators")
const winston = require("winston")
require("dotenv").config()

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
  url: process.env.CLICKHOUSE_URL || "http://localhost:8123",
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
  clientId: "backtesting-service",
  brokers: process.env.KAFKA_BROKERS.split(","),
})

const producer = kafka.producer()
const consumer = kafka.consumer({ groupId: "backtesting-group" })

// Initialize Express app
const app = express()
app.use(express.json())

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() })
})

// Backtesting endpoints
app.post("/backtest", async (req, res) => {
  try {
    const { strategyId, name, startDate, endDate, initialCapital, symbols } = req.body

    const backtestId = await createBacktest({
      strategyId,
      name,
      startDate,
      endDate,
      initialCapital,
      commission: process.env.BACKTEST_COMMISSION || 0.001,
      slippage: 0.001,
    })

    // Start backtesting process
    await runBacktest(backtestId, symbols || [])

    res.json({
      message: "Backtest started",
      backtestId,
      status: "running",
    })
  } catch (error) {
    logger.error("Error starting backtest:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

app.get("/backtest/:id", async (req, res) => {
  try {
    const { id } = req.params
    const backtest = await getBacktestResults(id)
    res.json(backtest)
  } catch (error) {
    logger.error("Error getting backtest results:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// Create backtest record
async function createBacktest(params) {
  try {
    const backtestId = Date.now()

    await clickhouse.insert({
      table: "backtests",
      values: [
        {
          id: backtestId,
          strategy_id: params.strategyId,
          name: params.name,
          start_date: params.startDate,
          end_date: params.endDate,
          initial_capital: params.initialCapital,
          commission: params.commission,
          slippage: params.slippage,
          status: "running",
        },
      ],
    })

    return backtestId
  } catch (error) {
    logger.error("Error creating backtest:", error)
    throw error
  }
}

// Run backtest
async function runBacktest(backtestId, symbols) {
  try {
    logger.info(`Starting backtest ${backtestId}`)

    // Get backtest configuration
    const backtestConfig = await getBacktestConfig(backtestId)
    const strategy = await getStrategy(backtestConfig.strategy_id)

    // Get symbols to test (if not provided, use sample symbols)
    if (symbols.length === 0) {
      const result = await clickhouse.query({
        query: "SELECT id, symbol FROM securities WHERE is_active = 1 LIMIT 5",
      })
      const data = await result.json()
      symbols = data.data
    }

    // Initialize portfolio
    let portfolio = {
      cash: backtestConfig.initial_capital,
      positions: {},
      totalValue: backtestConfig.initial_capital,
      trades: [],
      equityCurve: [],
    }

    // Simple backtest simulation (simplified for demo)
    const startDate = new Date(backtestConfig.start_date)
    const endDate = new Date(backtestConfig.end_date)

    // Calculate final statistics (mock data for demo)
    await calculateBacktestStatistics(backtestId, portfolio)

    // Update backtest status
    await clickhouse.query({
      query: "ALTER TABLE backtests UPDATE status = {status:String}, completed_at = now() WHERE id = {id:UInt32}",
      query_params: { status: "completed", id: backtestId },
    })

    logger.info(`Completed backtest ${backtestId}`)

    // Send completion message to Kafka
    await producer.send({
      topic: "backtest-completed",
      messages: [
        {
          key: backtestId.toString(),
          value: JSON.stringify({
            backtestId,
            status: "completed",
            totalTrades: portfolio.trades.length,
            timestamp: new Date(),
          }),
        },
      ],
    })
  } catch (error) {
    logger.error(`Error running backtest ${backtestId}:`, error)

    // Update backtest status to failed
    await clickhouse.query({
      query: "ALTER TABLE backtests UPDATE status = {status:String} WHERE id = {id:UInt32}",
      query_params: { status: "failed", id: backtestId },
    })

    throw error
  }
}

// Calculate backtest statistics (simplified)
async function calculateBacktestStatistics(backtestId, portfolio) {
  try {
    // Mock statistics for demo
    const totalReturn = 15.5
    const maxDrawdown = 8.2
    const sharpeRatio = 1.8
    const winRate = 65.0
    const profitFactor = 1.4

    await clickhouse.query({
      query: `
        ALTER TABLE backtests UPDATE
          total_return = {totalReturn:Float64},
          max_drawdown = {maxDrawdown:Float64},
          sharpe_ratio = {sharpeRatio:Float64},
          win_rate = {winRate:Float64},
          profit_factor = {profitFactor:Float64},
          total_trades = {totalTrades:UInt32}
        WHERE id = {id:UInt32}
      `,
      query_params: {
        totalReturn,
        maxDrawdown,
        sharpeRatio,
        winRate,
        profitFactor,
        totalTrades: 25,
        id: backtestId,
      },
    })

    logger.info(`Backtest ${backtestId} statistics calculated`)
  } catch (error) {
    logger.error("Error calculating backtest statistics:", error)
    throw error
  }
}

// Get backtest configuration
async function getBacktestConfig(backtestId) {
  const result = await clickhouse.query({
    query: "SELECT * FROM backtests WHERE id = {id:UInt32}",
    query_params: { id: backtestId },
  })

  const data = await result.json()
  return data.data[0]
}

// Get strategy
async function getStrategy(strategyId) {
  const result = await clickhouse.query({
    query: "SELECT * FROM strategies WHERE id = {id:UInt32}",
    query_params: { id: strategyId },
  })

  const data = await result.json()
  return data.data[0]
}

// Get backtest results
async function getBacktestResults(backtestId) {
  const result = await clickhouse.query({
    query: `
      SELECT 
        b.*,
        s.name as strategy_name 
      FROM backtests b 
      LEFT JOIN strategies s ON b.strategy_id = s.id 
      WHERE b.id = {id:UInt32}
    `,
    query_params: { id: parseInt(backtestId) },
  })

  const data = await result.json()
  return data.data[0]
}

// Kafka consumer for processing backtest requests
async function startKafkaConsumer() {
  await consumer.subscribe({ topics: ["backtest-requests"] })

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const data = JSON.parse(message.value.toString())

        if (topic === "backtest-requests") {
          await runBacktest(data.backtestId, data.symbols || [])
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
    // Connect to Kafka
    await producer.connect()
    await consumer.connect()
    await startKafkaConsumer()
    logger.info("Connected to Kafka")

    // Test ClickHouse connection
    await clickhouse.query({ query: "SELECT 1" })
    logger.info("Connected to ClickHouse")

    // Start Express server
    const port = process.env.PORT || 3002
    app.listen(port, () => {
      logger.info(`Backtesting service listening on port ${port}`)
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
  await clickhouse.close()
  process.exit(0)
})

// Start the service
initialize()
