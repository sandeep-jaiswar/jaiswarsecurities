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
 * /api/research/news:
 *   get:
 *     summary: Get financial news with sentiment analysis
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         description: Filter by symbol
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by news category
 *       - in: query
 *         name: sentiment
 *         schema:
 *           type: string
 *           enum: [positive, negative, neutral]
 *         description: Filter by sentiment
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Number of articles to return
 *     responses:
 *       200:
 *         description: News articles with sentiment
 */
router.get('/news', async (req, res) => {
  try {
    const { symbol, category, sentiment, limit = 50 } = req.query;

    let whereClause = 'WHERE na.published_at >= today() - INTERVAL 7 DAY';
    const queryParams = { limit: parseInt(limit) };

    if (symbol) {
      whereClause += ' AND s.symbol = {symbol:String}';
      queryParams.symbol = symbol.toUpperCase();
    }

    if (category) {
      whereClause += ' AND nc.code = {category:String}';
      queryParams.category = category;
    }

    if (sentiment) {
      whereClause += ' AND ns.sentiment_label = {sentiment:String}';
      queryParams.sentiment = sentiment;
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          na.id,
          na.title,
          na.summary,
          na.url,
          na.published_at,
          na.author,
          nso.name as source_name,
          nc.name as category_name,
          ns.overall_sentiment,
          ns.sentiment_label,
          ns.confidence_score,
          s.symbol,
          c.name as company_name
        FROM news_articles na
        LEFT JOIN news_sources nso ON na.news_source_id = nso.id
        LEFT JOIN news_categories nc ON na.news_category_id = nc.id
        LEFT JOIN company_news cn ON na.id = cn.news_article_id
        LEFT JOIN companies c ON cn.company_id = c.id
        LEFT JOIN securities s ON c.id = s.company_id
        LEFT JOIN news_sentiment ns ON na.id = ns.news_article_id AND c.id = ns.company_id
        ${whereClause}
        ORDER BY na.published_at DESC
        LIMIT {limit:UInt32}
      `,
      query_params: queryParams,
    });

    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching news:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/earnings:
 *   get:
 *     summary: Get earnings calendar
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *         description: Specific date (YYYY-MM-DD)
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [today, week, month]
 *           default: week
 *         description: Time period
 *     responses:
 *       200:
 *         description: Earnings calendar
 */
router.get('/earnings', async (req, res) => {
  try {
    const { date, period = 'week' } = req.query;

    let dateFilter = '';
    const queryParams = {};

    if (date) {
      dateFilter = 'AND ce.event_date = {date:Date}';
      queryParams.date = date;
    } else {
      switch (period) {
        case 'today':
          dateFilter = 'AND ce.event_date = today()';
          break;
        case 'week':
          dateFilter = 'AND ce.event_date BETWEEN today() AND today() + INTERVAL 7 DAY';
          break;
        case 'month':
          dateFilter = 'AND ce.event_date BETWEEN today() AND today() + INTERVAL 30 DAY';
          break;
      }
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          c.name as company_name,
          ce.event_date,
          ce.event_name,
          ce.description,
          fp.fiscal_year,
          fp.fiscal_quarter,
          ae.mean_estimate as eps_estimate,
          ae.high_estimate as eps_high,
          ae.low_estimate as eps_low
        FROM corporate_events ce
        JOIN companies c ON ce.company_id = c.id
        JOIN securities s ON c.id = s.company_id
        LEFT JOIN financial_periods fp ON c.id = fp.company_id
        LEFT JOIN analyst_estimates ae ON c.id = ae.company_id 
          AND ae.estimate_type = 'EPS' 
          AND ae.fiscal_year = fp.fiscal_year 
          AND ae.fiscal_quarter = fp.fiscal_quarter
        WHERE ce.event_name ILIKE '%earnings%'
          AND s.is_active = 1
          ${dateFilter}
        ORDER BY ce.event_date ASC, s.symbol
      `,
      query_params: queryParams,
    });

    const data = await result.json();
    res.json({
      period,
      date,
      earnings: data.data,
    });
  } catch (error) {
    logger.error('Error fetching earnings calendar:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/estimates:
 *   get:
 *     summary: Get analyst estimates
 *     tags: [Research]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *         description: Stock symbol
 *     responses:
 *       200:
 *         description: Analyst estimates
 */
router.get('/estimates/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    const result = await clickhouse.query({
      query: `
        SELECT 
          ae.estimate_type,
          ae.period_type,
          ae.fiscal_year,
          ae.fiscal_quarter,
          ae.mean_estimate,
          ae.median_estimate,
          ae.high_estimate,
          ae.low_estimate,
          ae.standard_deviation,
          ae.number_of_estimates,
          ae.number_of_revisions_up,
          ae.number_of_revisions_down,
          ae.estimate_date
        FROM analyst_estimates ae
        JOIN companies c ON ae.company_id = c.id
        JOIN securities s ON c.id = s.company_id
        WHERE s.symbol = {symbol:String}
          AND ae.estimate_date >= today() - INTERVAL 90 DAY
        ORDER BY ae.fiscal_year DESC, ae.fiscal_quarter DESC, ae.estimate_type
      `,
      query_params: { symbol: symbol.toUpperCase() },
    });

    const data = await result.json();
    res.json({
      symbol: symbol.toUpperCase(),
      estimates: data.data,
    });
  } catch (error) {
    logger.error('Error fetching analyst estimates:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/insider-trading:
 *   get:
 *     summary: Get insider trading activity
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         description: Filter by symbol
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to look back
 *     responses:
 *       200:
 *         description: Insider trading data
 */
router.get('/insider-trading', async (req, res) => {
  try {
    const { symbol, days = 30 } = req.query;

    let whereClause = `WHERE it.transaction_date >= today() - INTERVAL {days:UInt32} DAY`;
    const queryParams = { days: parseInt(days) };

    if (symbol) {
      whereClause += ' AND s.symbol = {symbol:String}';
      queryParams.symbol = symbol.toUpperCase();
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          c.name as company_name,
          st.name as insider_name,
          st.title,
          it.transaction_date,
          it.transaction_type,
          it.shares_transacted,
          it.price_per_share,
          it.total_value,
          it.shares_owned_after,
          it.form_type
        FROM insider_transactions it
        JOIN companies c ON it.company_id = c.id
        JOIN securities s ON c.id = s.company_id
        JOIN stakeholders st ON it.stakeholder_id = st.id
        ${whereClause}
        ORDER BY it.transaction_date DESC, it.total_value DESC
        LIMIT 100
      `,
      query_params: queryParams,
    });

    const data = await result.json();
    res.json({
      period_days: parseInt(days),
      transactions: data.data,
    });
  } catch (error) {
    logger.error('Error fetching insider trading:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/institutional-holdings:
 *   get:
 *     summary: Get institutional holdings
 *     tags: [Research]
 *     parameters:
 *       - in: path
 *         name: symbol
 *         required: true
 *         schema:
 *           type: string
 *         description: Stock symbol
 *     responses:
 *       200:
 *         description: Institutional holdings data
 */
router.get('/institutional-holdings/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;

    const result = await clickhouse.query({
      query: `
        SELECT 
          st.name as institution_name,
          or.shares_owned,
          or.ownership_percentage,
          or.market_value,
          or.as_of_date,
          or.change_in_shares,
          or.change_percentage,
          st.aum
        FROM ownership_records or
        JOIN companies c ON or.company_id = c.id
        JOIN securities s ON c.id = s.company_id
        JOIN stakeholders st ON or.stakeholder_id = st.id
        WHERE s.symbol = {symbol:String}
          AND st.is_institutional = 1
          AND or.as_of_date >= today() - INTERVAL 90 DAY
        ORDER BY or.ownership_percentage DESC
        LIMIT 50
      `,
      query_params: { symbol: symbol.toUpperCase() },
    });

    const data = await result.json();
    res.json({
      symbol: symbol.toUpperCase(),
      holdings: data.data,
    });
  } catch (error) {
    logger.error('Error fetching institutional holdings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/research/events:
 *   get:
 *     summary: Get corporate events
 *     tags: [Research]
 *     parameters:
 *       - in: query
 *         name: symbol
 *         schema:
 *           type: string
 *         description: Filter by symbol
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: Filter by event type
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to look ahead
 *     responses:
 *       200:
 *         description: Corporate events
 */
router.get('/events', async (req, res) => {
  try {
    const { symbol, type, days = 30 } = req.query;

    let whereClause = `WHERE ce.event_date BETWEEN today() AND today() + INTERVAL {days:UInt32} DAY`;
    const queryParams = { days: parseInt(days) };

    if (symbol) {
      whereClause += ' AND s.symbol = {symbol:String}';
      queryParams.symbol = symbol.toUpperCase();
    }

    if (type) {
      whereClause += ' AND et.code = {type:String}';
      queryParams.type = type;
    }

    const result = await clickhouse.query({
      query: `
        SELECT 
          s.symbol,
          c.name as company_name,
          ce.event_name,
          ce.description,
          ce.event_date,
          ce.announcement_date,
          et.name as event_type,
          ce.expected_impact,
          ce.status
        FROM corporate_events ce
        JOIN companies c ON ce.company_id = c.id
        JOIN securities s ON c.id = s.company_id
        LEFT JOIN event_types et ON ce.event_type_id = et.id
        ${whereClause}
        ORDER BY ce.event_date ASC
        LIMIT 100
      `,
      query_params: queryParams,
    });

    const data = await result.json();
    res.json({
      period_days: parseInt(days),
      events: data.data,
    });
  } catch (error) {
    logger.error('Error fetching corporate events:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;