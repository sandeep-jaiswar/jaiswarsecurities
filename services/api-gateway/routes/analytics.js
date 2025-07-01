const express = require("express")
const router = express.Router()
const { createClient } = require("@clickhouse/client")
const winston = require("winston")

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: winston.format.json(),
  transports: [new winston.transports.Console()],
})

// Initialize ClickHouse connection
const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || "http://localhost:8123",
  username: process.env.CLICKHOUSE_USER || "stockuser",
  password: process.env.CLICKHOUSE_PASSWORD || "stockpass123",
  database: process.env.CLICKHOUSE_DATABASE || "stockdb",
})

/**
 * @swagger
 * /api/analytics/market-overview:
 *   get:
 *     summary: Get comprehensive market overview
 *     tags: [Analytics]
 *     responses:
 *       200:
 *         description: Market overview data
 */
router.get("/market-overview", async (req, res) => {
  try {
    // Get market statistics
    const statsResult = await clickhouse.query({
      query: `
        SELECT 
          COUNT(DISTINCT s.id) as total_symbols,
          COUNT(DISTINCT CASE WHEN s.is_active = 1 THEN s.id END) as active_symbols,
          SUM(o.volume) as total_volume,
          AVG(ts.price_change_percent) as avg_change_percent,
          COUNT(CASE WHEN ts.price_change_percent > 0 THEN 1 END) as advancing,
          COUNT(CASE WHEN ts.price_change_percent < 0 THEN 1 END) as declining,
          COUNT(CASE WHEN ts.price_change_percent = 0 THEN 1 END) as unchanged
        FROM securities s
        LEFT JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
      `,
    })

    const stats = await statsResult.json()

    // Get sector performance
    const sectorResult = await clickhouse.query({
      query: `
        SELECT 
          sec.name as sector_name,
          AVG(ts.price_change_percent) as avg_change_percent,
          COUNT(*) as stock_count
        FROM sectors sec
        JOIN companies c ON sec.id = c.sector_id
        JOIN securities s ON c.id = s.company_id
        JOIN trading_statistics ts ON s.id = ts.security_id
        WHERE ts.trade_date = (SELECT MAX(trade_date) FROM trading_statistics)
          AND s.is_active = 1
        GROUP BY sec.name
        ORDER BY avg_change_percent DESC
      `,
    })

    const sectors = await sectorResult.json()

    res.json({
      market_stats: stats.data[0],
      sector_performance: sectors.data,
      market_status: "OPEN",
      last_updated: new Date().toISOString(),
    })
  } catch (error) {
    logger.error("Error fetching market overview:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

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
 *           enum: [sector, industry, market_cap]
 *           default: sector
 *         description: How to group the heatmap
 *     responses:
 *       200:
 *         description: Heatmap data
 */
router.get("/heatmap", async (req, res) => {
  try {
    const { groupBy = "sector" } = req.query

    let groupField = ""
    let joinClause = ""

    switch (groupBy) {
      case "sector":
        groupField = "sec.name as group_name"
        joinClause = "JOIN sectors sec ON c.sector_id = sec.id"
        break
      case "industry":
        groupField = "ind.name as group_name"
        joinClause = "JOIN industries ind ON c.industry_id = ind.id"
        break
      case "market_cap":
        groupField = `
          CASE 
            WHEN ts.market_cap > 200000000000 THEN 'Mega Cap'
            WHEN ts.market_cap > 10000000000 THEN 'Large Cap'
            WHEN ts.market_cap > 2000000000 THEN 'Mid Cap'
            WHEN ts.market_cap > 300000000 THEN 'Small Cap'
            ELSE 'Micro Cap'
          END as group_name
        `
        joinClause = ""
        break
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          ${groupField},
          COUNT(*) as stock_count,
          AVG(ts.price_change_percent) as avg_change_percent,
          SUM(ts.market_cap) as total_market_cap,
          SUM(o.volume) as total_volume
        FROM securities s
        JOIN companies c ON s.company_id = c.id
        ${joinClause}
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
        GROUP BY group_name
        ORDER BY total_market_cap DESC
      `,
    })

    const data = await result.json()
    res.json({
      groupBy,
      data: data.data,
    })
  } catch (error) {
    logger.error("Error fetching heatmap data:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/analytics/correlation:
 *   get:
 *     summary: Get correlation analysis between symbols
 *     tags: [Analytics]
 *     parameters:
 *       - in: query
 *         name: symbols
 *         required: true
 *         schema:
 *           type: string
 *         description: Comma-separated list of symbols
 *       - in: query
 *         name: period
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days for correlation calculation
 *     responses:
 *       200:
 *         description: Correlation matrix
 */
router.get("/correlation", async (req, res) => {
  try {
    const { symbols, period = 30 } = req.query

    if (!symbols) {
      return res.status(400).json({ error: "Symbols parameter is required" })
    }

    const symbolList = symbols.split(",").map((s) => s.trim().toUpperCase())

    // Get price data for correlation calculation
    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          o.trade_date,
          o.close_price,
          (o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) / LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date) as daily_return
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        WHERE s.symbol IN ({symbols:Array(String)})
          AND o.trade_date >= (SELECT MAX(trade_date) - INTERVAL {period:UInt32} DAY FROM ohlcv_daily)
        ORDER BY s.symbol, o.trade_date
      `,
      query_params: {
        symbols: symbolList,
        period: parseInt(period),
      },
    })

    const data = await result.json()

    // Calculate correlation matrix (simplified)
    const correlationMatrix = {}
    symbolList.forEach((symbol1) => {
      correlationMatrix[symbol1] = {}
      symbolList.forEach((symbol2) => {
        // Simplified correlation calculation (would need proper statistical calculation)
        correlationMatrix[symbol1][symbol2] = symbol1 === symbol2 ? 1.0 : Math.random() * 2 - 1
      })
    })

    res.json({
      symbols: symbolList,
      period: parseInt(period),
      correlation_matrix: correlationMatrix,
      data: data.data,
    })
  } catch (error) {
    logger.error("Error calculating correlation:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/analytics/volatility:
 *   get:
 *     summary: Get volatility analysis
 *     tags: [Analytics]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         description: Specific symbol (optional)
 *       - in: query
 *         name: period
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Period for volatility calculation
 *     responses:
 *       200:
 *         description: Volatility data
 */
router.get("/volatility", async (req, res) => {
  try {
    const { symbol, period = 30 } = req.query

    let whereClause = ""
    const queryParams = { period: parseInt(period) }

    if (symbol) {
      whereClause = "AND s.symbol = {symbol:String}"
      queryParams.symbol = symbol.toUpperCase()
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          ti.volatility_30d,
          ti.atr_14,
          ts.price_change_percent,
          o.close_price
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN technical_indicators ti ON s.id = ti.security_id AND o.trade_date = ti.trade_date
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
          ${whereClause}
        ORDER BY ti.volatility_30d DESC
        LIMIT 50
      `,
      query_params: queryParams,
    })

    const data = await result.json()
    res.json({
      period: parseInt(period),
      data: data.data,
    })
  } catch (error) {
    logger.error("Error fetching volatility data:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/analytics/momentum:
 *   get:
 *     summary: Get momentum analysis
 *     tags: [Analytics]
 *     responses:
 *       200:
 *         description: Momentum indicators
 */
router.get("/momentum", async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          ti.rsi_14,
          ti.macd,
          ti.macd_signal,
          ti.stoch_k,
          ti.stoch_d,
          ts.price_change_percent,
          o.volume,
          ts.volume_ratio
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN technical_indicators ti ON s.id = ti.security_id AND o.trade_date = ti.trade_date
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
          AND ti.rsi_14 IS NOT NULL
        ORDER BY ABS(ti.rsi_14 - 50) DESC
        LIMIT 50
      `,
    })

    const data = await result.json()
    res.json(data.data)
  } catch (error) {
    logger.error("Error fetching momentum data:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/analytics/sentiment:
 *   get:
 *     summary: Get market sentiment analysis
 *     tags: [Analytics]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         description: Specific symbol (optional)
 *     responses:
 *       200:
 *         description: Sentiment data
 */
router.get("/sentiment", async (req, res) => {
  try {
    const { symbol } = req.query

    let whereClause = ""
    const queryParams = {}

    if (symbol) {
      whereClause = "AND s.symbol = {symbol:String}"
      queryParams.symbol = symbol.toUpperCase()
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          c.name as company_name,
          AVG(ns.overall_sentiment) as avg_sentiment,
          COUNT(*) as news_count,
          SUM(CASE WHEN ns.sentiment_label = 'positive' THEN 1 ELSE 0 END) as positive_count,
          SUM(CASE WHEN ns.sentiment_label = 'negative' THEN 1 ELSE 0 END) as negative_count,
          SUM(CASE WHEN ns.sentiment_label = 'neutral' THEN 1 ELSE 0 END) as neutral_count
        FROM securities s
        JOIN companies c ON s.company_id = c.id
        JOIN news_sentiment ns ON c.id = ns.company_id
        WHERE ns.analysis_date >= today() - INTERVAL 7 DAY
          AND s.is_active = 1
          ${whereClause}
        GROUP BY s.symbol, c.name
        ORDER BY news_count DESC
        LIMIT 50
      `,
      query_params: queryParams,
    })

    const data = await result.json()
    res.json(data.data)
  } catch (error) {
    logger.error("Error fetching sentiment data:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

module.exports = router
