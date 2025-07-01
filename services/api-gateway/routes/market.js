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
 * /api/market/symbols:
 *   get:
 *     summary: Get list of securities with filtering
 *     tags: [Market Data]
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
 *         name: exchange
 *         schema:
 *           type: string
 *         description: Filter by exchange
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *         description: Number of results to return
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *         description: Number of results to skip
 *     responses:
 *       200:
 *         description: List of securities
 */
router.get("/symbols", async (req, res) => {
  try {
    const { search, sector, exchange, limit = 100, offset = 0 } = req.query

    let query = `
      SELECT 
        s.id,
        s.symbol,
        s.name,
        c.name as company_name,
        sec.name as sector_name,
        ind.name as industry_name,
        e.name as exchange_name,
        s.is_active,
        s.listing_date,
        s.shares_outstanding
      FROM securities s
      LEFT JOIN companies c ON s.company_id = c.id
      LEFT JOIN sectors sec ON c.sector_id = sec.id
      LEFT JOIN industries ind ON c.industry_id = ind.id
      LEFT JOIN exchanges e ON s.exchange_id = e.id
      WHERE s.is_active = 1
    `

    const queryParams = {}

    if (search) {
      query += ` AND (s.symbol ILIKE {search:String} OR s.name ILIKE {search:String} OR c.name ILIKE {search:String})`
      queryParams.search = `%${search}%`
    }

    if (sector) {
      query += ` AND sec.code = {sector:String}`
      queryParams.sector = sector
    }

    if (exchange) {
      query += ` AND e.code = {exchange:String}`
      queryParams.exchange = exchange
    }

    query += ` ORDER BY s.symbol LIMIT {limit:UInt32} OFFSET {offset:UInt32}`
    queryParams.limit = parseInt(limit)
    queryParams.offset = parseInt(offset)

    const result = await clickhouse.query({
      query,
      query_params: queryParams,
    })

    const data = await result.json()
    res.json({
      data: data.data,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: data.data.length,
      },
    })
  } catch (error) {
    logger.error("Error fetching symbols:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/market/symbols/{symbol}/quote:
 *   get:
 *     summary: Get real-time quote for a symbol
 *     tags: [Market Data]
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
router.get("/symbols/:symbol/quote", async (req, res) => {
  try {
    const { symbol } = req.params

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          o.open_price,
          o.high_price,
          o.low_price,
          o.close_price,
          o.adjusted_close,
          o.volume,
          o.trade_date,
          ts.previous_close,
          ts.price_change,
          ts.price_change_percent,
          ts.volume_ratio,
          ts.market_cap
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE s.symbol = {symbol:String}
        ORDER BY o.trade_date DESC
        LIMIT 1
      `,
      query_params: { symbol: symbol.toUpperCase() },
    })

    const data = await result.json()
    if (data.data.length === 0) {
      return res.status(404).json({ error: "Symbol not found" })
    }

    res.json(data.data[0])
  } catch (error) {
    logger.error("Error fetching quote:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

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
 *         description: Stock symbol
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [1D, 5D, 1M, 3M, 6M, 1Y, 2Y, 5Y]
 *           default: 1M
 *         description: Time period
 *       - in: query
 *         name: interval
 *         schema:
 *           type: string
 *           enum: [1m, 5m, 15m, 30m, 1h, 1d]
 *           default: 1d
 *         description: Data interval
 *     responses:
 *       200:
 *         description: Chart data with indicators
 */
router.get("/symbols/:symbol/chart", async (req, res) => {
  try {
    const { symbol } = req.params
    const { period = "1M", interval = "1d" } = req.query

    // Calculate date range based on period
    const endDate = new Date()
    const startDate = new Date()

    switch (period) {
      case "1D":
        startDate.setDate(endDate.getDate() - 1)
        break
      case "5D":
        startDate.setDate(endDate.getDate() - 5)
        break
      case "1M":
        startDate.setMonth(endDate.getMonth() - 1)
        break
      case "3M":
        startDate.setMonth(endDate.getMonth() - 3)
        break
      case "6M":
        startDate.setMonth(endDate.getMonth() - 6)
        break
      case "1Y":
        startDate.setFullYear(endDate.getFullYear() - 1)
        break
      case "2Y":
        startDate.setFullYear(endDate.getFullYear() - 2)
        break
      case "5Y":
        startDate.setFullYear(endDate.getFullYear() - 5)
        break
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
          ti.sma_200,
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
          AND o.trade_date >= {startDate:Date}
          AND o.trade_date <= {endDate:Date}
        ORDER BY o.trade_date ASC
      `,
      query_params: {
        symbol: symbol.toUpperCase(),
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
    })

    const data = await result.json()
    res.json({
      symbol: symbol.toUpperCase(),
      period,
      interval,
      data: data.data,
    })
  } catch (error) {
    logger.error("Error fetching chart data:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

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
 *           enum: [gainers, losers, active]
 *           default: gainers
 *         description: Type of movers
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of results
 *     responses:
 *       200:
 *         description: Market movers data
 */
router.get("/movers", async (req, res) => {
  try {
    const { type = "gainers", limit = 20 } = req.query

    let orderBy = ""
    switch (type) {
      case "gainers":
        orderBy = "ts.price_change_percent DESC"
        break
      case "losers":
        orderBy = "ts.price_change_percent ASC"
        break
      case "active":
        orderBy = "o.volume DESC"
        break
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          s.name,
          o.close_price,
          o.volume,
          ts.price_change,
          ts.price_change_percent,
          ts.market_cap
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
          AND ts.price_change_percent IS NOT NULL
        ORDER BY ${orderBy}
        LIMIT {limit:UInt32}
      `,
      query_params: { limit: parseInt(limit) },
    })

    const data = await result.json()
    res.json({
      type,
      data: data.data,
    })
  } catch (error) {
    logger.error("Error fetching movers:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/market/sectors:
 *   get:
 *     summary: Get sector performance
 *     tags: [Market Data]
 *     responses:
 *       200:
 *         description: Sector performance data
 */
router.get("/sectors", async (req, res) => {
  try {
    const result = await clickhouse.query({
      query: `
        SELECT 
          sec.name as sector_name,
          sec.code as sector_code,
          COUNT(DISTINCT s.id) as stock_count,
          AVG(ts.price_change_percent) as avg_change_percent,
          SUM(o.volume) as total_volume,
          SUM(ts.market_cap) as total_market_cap
        FROM sectors sec
        JOIN companies c ON sec.id = c.sector_id
        JOIN securities s ON c.id = s.company_id
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
        GROUP BY sec.name, sec.code
        ORDER BY avg_change_percent DESC
      `,
    })

    const data = await result.json()
    res.json(data.data)
  } catch (error) {
    logger.error("Error fetching sector performance:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/market/indices:
 *   get:
 *     summary: Get major market indices
 *     tags: [Market Data]
 *     responses:
 *       200:
 *         description: Market indices data
 */
router.get("/indices", async (req, res) => {
  try {
    // Mock data for major indices
    const indices = [
      {
        symbol: "SPY",
        name: "SPDR S&P 500 ETF",
        price: 450.25,
        change: 2.15,
        changePercent: 0.48,
        volume: 45000000,
      },
      {
        symbol: "QQQ",
        name: "Invesco QQQ Trust",
        price: 385.5,
        change: 3.2,
        changePercent: 0.84,
        volume: 32000000,
      },
      {
        symbol: "DIA",
        name: "SPDR Dow Jones Industrial Average ETF",
        price: 340.75,
        change: 1.85,
        changePercent: 0.55,
        volume: 15000000,
      },
      {
        symbol: "IWM",
        name: "iShares Russell 2000 ETF",
        price: 195.3,
        change: -0.85,
        changePercent: -0.43,
        volume: 28000000,
      },
    ]

    res.json(indices)
  } catch (error) {
    logger.error("Error fetching indices:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

/**
 * @swagger
 * /api/market/symbols/{symbol}/fundamentals:
 *   get:
 *     summary: Get fundamental data for a symbol
 *     tags: [Market Data]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *         description: Stock symbol
 *     responses:
 *       200:
 *         description: Fundamental data
 */
router.get("/symbols/:symbol/fundamentals", async (req, res) => {
  try {
    const { symbol } = req.params

    const result = await clickhouse.query({
      query: `
        SELECT 
          c.name as company_name,
          c.business_description,
          c.employee_count,
          c.website,
          sec.name as sector_name,
          ind.name as industry_name,
          s.shares_outstanding,
          s.shares_float,
          fr.price_to_earnings,
          fr.price_to_book,
          fr.price_to_sales,
          fr.return_on_equity,
          fr.return_on_assets,
          fr.debt_to_equity,
          fr.current_ratio,
          fr.gross_margin,
          fr.operating_margin,
          fr.net_margin
        FROM securities s
        JOIN companies c ON s.company_id = c.id
        LEFT JOIN sectors sec ON c.sector_id = sec.id
        LEFT JOIN industries ind ON c.industry_id = ind.id
        LEFT JOIN financial_periods fp ON c.id = fp.company_id
        LEFT JOIN financial_ratios fr ON fp.id = fr.financial_period_id
        WHERE s.symbol = {symbol:String}
          AND fp.period_type = 'annual'
        ORDER BY fp.fiscal_year DESC
        LIMIT 1
      `,
      query_params: { symbol: symbol.toUpperCase() },
    })

    const data = await result.json()
    if (data.data.length === 0) {
      return res.status(404).json({ error: "Symbol not found" })
    }

    res.json(data.data[0])
  } catch (error) {
    logger.error("Error fetching fundamentals:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

module.exports = router
