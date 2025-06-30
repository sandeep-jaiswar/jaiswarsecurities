const express = require('express');
const router = express.Router();
const { createClient } = require('@clickhouse/client');
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [new winston.transports.Console()]
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
 * /api/economic/indicators:
 *   get:
 *     summary: Get economic indicators
 *     tags: [Economic Data]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category
 *       - in: query
 *         name: country
 *         schema:
 *           type: string
 *         description: Filter by country code
 *     responses:
 *       200:
 *         description: Economic indicators
 */
router.get('/indicators', async (req, res) => {
  try {
    const { category, country } = req.query;
    
    let whereClause = 'WHERE ei.is_active = 1';
    const queryParams = {};
    
    if (category) {
      whereClause += ' AND ei.category = {category:String}';
      queryParams.category = category;
    }
    
    if (country) {
      whereClause += ' AND c.code = {country:String}';
      queryParams.country = country;
    }
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          ei.id,
          ei.code,
          ei.name,
          ei.description,
          ei.category,
          ei.frequency,
          ei.unit,
          ei.source,
          c.name as country_name,
          c.code as country_code
        FROM economic_indicators ei
        LEFT JOIN countries c ON ei.country_id = c.id
        ${whereClause}
        ORDER BY ei.category, ei.name
      `,
      query_params: queryParams
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching economic indicators:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/economic/calendar:
 *   get:
 *     summary: Get economic calendar
 *     tags: [Economic Data]
 *     parameters:
 *       - in: query
 *         name: start_date
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date (YYYY-MM-DD)
 *       - in: query
 *         name: end_date
 *         schema:
 *           type: string
 *           format: date
 *         description: End date (YYYY-MM-DD)
 *       - in: query
 *         name: importance
 *         schema:
 *           type: string
 *           enum: [low, medium, high]
 *         description: Filter by importance level
 *     responses:
 *       200:
 *         description: Economic calendar events
 */
router.get('/calendar', async (req, res) => {
  try {
    const { start_date, end_date, importance } = req.query;
    
    let whereClause = 'WHERE 1=1';
    const queryParams = {};
    
    if (start_date) {
      whereClause += ' AND ee.release_date >= {startDate:Date}';
      queryParams.startDate = start_date;
    } else {
      whereClause += ' AND ee.release_date >= today()';
    }
    
    if (end_date) {
      whereClause += ' AND ee.release_date <= {endDate:Date}';
      queryParams.endDate = end_date;
    } else {
      whereClause += ' AND ee.release_date <= today() + INTERVAL 30 DAY';
    }
    
    if (importance) {
      whereClause += ' AND ee.importance_level = {importance:String}';
      queryParams.importance = importance;
    }
    
    const result = await clickhouse.query({
      query: `
        SELECT 
          ee.id,
          ee.event_name,
          ee.release_date,
          ee.period_start,
          ee.period_end,
          ee.actual_value,
          ee.forecast_value,
          ee.previous_value,
          ee.importance_level,
          ee.market_impact,
          ee.surprise_factor,
          ei.name as indicator_name,
          ei.unit,
          c.name as country_name
        FROM economic_events ee
        LEFT JOIN economic_indicators ei ON ee.economic_indicator_id = ei.id
        LEFT JOIN countries c ON ei.country_id = c.id
        ${whereClause}
        ORDER BY ee.release_date ASC, ee.importance_level DESC
      `,
      query_params: queryParams
    });
    
    const data = await result.json();
    res.json(data.data);
  } catch (error) {
    logger.error('Error fetching economic calendar:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/economic/fed:
 *   get:
 *     summary: Get Federal Reserve data
 *     tags: [Economic Data]
 *     responses:
 *       200:
 *         description: Federal Reserve data
 */
router.get('/fed', async (req, res) => {
  try {
    // Mock Federal Reserve data
    const fedData = {
      federal_funds_rate: {
        current: 5.25,
        previous: 5.00,
        change: 0.25,
        last_meeting: '2024-01-31',
        next_meeting: '2024-03-20'
      },
      fomc_members: [
        { name: 'Jerome Powell', title: 'Chair', voting: true },
        { name: 'Philip Jefferson', title: 'Vice Chair', voting: true },
        { name: 'Michael Barr', title: 'Vice Chair for Supervision', voting: true }
      ],
      recent_statements: [
        {
          date: '2024-01-31',
          title: 'Federal Reserve maintains target range for federal funds rate',
          summary: 'The Federal Open Market Committee decided to maintain the target range...'
        }
      ],
      economic_projections: {
        gdp_growth: { 2024: 2.1, 2025: 1.9, 2026: 2.0 },
        unemployment: { 2024: 4.0, 2025: 4.1, 2026: 4.0 },
        inflation: { 2024: 2.4, 2025: 2.1, 2026: 2.0 }
      }
    };
    
    res.json(fedData);
  } catch (error) {
    logger.error('Error fetching Fed data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /api/economic/treasury:
 *   get:
 *     summary: Get Treasury rates
 *     tags: [Economic Data]
 *     responses:
 *       200:
 *         description: Treasury yield curve data
 */
router.get('/treasury', async (req, res) => {
  try {
    // Mock Treasury rates data
    const treasuryRates = {
      yield_curve: [
        { maturity: '1M', rate: 5.45, change: 0.02 },
        { maturity: '3M', rate: 5.42, change: 0.01 },
        { maturity: '6M', rate: 5.35, change: -0.01 },
        { maturity: '1Y', rate: 5.20, change: -0.03 },
        { maturity: '2Y', rate: 4.85, change: -0.05 },
        { maturity: '5Y', rate: 4.55, change: -0.04 },
        { maturity: '10Y', rate: 4.35, change: -0.02 },
        { maturity: '30Y', rate: 4.45, change: 0.01 }
      ],
      spreads: {
        '10Y_2Y': -0.50,
        '10Y_3M': -1.07,
        '30Y_10Y': 0.10
      },
      historical: {
        '10Y': [
          { date: '2024-01-01', rate: 4.02 },
          { date: '2024-01-02', rate: 4.05 },
          { date: '2024-01-03', rate: 4.08 }
        ]
      },
      last_updated: new Date().toISOString()
    };
    
    res.json(treasuryRates);
  } catch (error) {
    logger.error('Error fetching Treasury rates:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;