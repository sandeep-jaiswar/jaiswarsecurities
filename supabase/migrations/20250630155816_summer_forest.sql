-- ClickHouse Materialized Views for Performance
-- Pre-computed analytics for Bloomberg-level performance

USE stockdb;

-- Market Movers View (refreshed every minute)
CREATE MATERIALIZED VIEW IF NOT EXISTS market_movers_view
ENGINE = MergeTree()
ORDER BY (trade_date, change_percent DESC)
POPULATE
AS SELECT 
    s.symbol,
    s.name,
    o.trade_date,
    o.close_price,
    o.volume,
    (o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) as price_change,
    ((o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) / LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) * 100 as change_percent
FROM securities s
JOIN ohlcv_daily o ON s.id = o.security_id
WHERE s.is_active = 1
  AND o.trade_date >= today() - 5;

-- Sector Performance View
CREATE MATERIALIZED VIEW IF NOT EXISTS sector_performance_view
ENGINE = MergeTree()
ORDER BY (trade_date, avg_change_percent DESC)
POPULATE
AS SELECT 
    sec.name as sector_name,
    o.trade_date,
    COUNT(*) as stock_count,
    AVG(o.close_price) as avg_price,
    SUM(o.volume) as total_volume,
    AVG((o.close_price - LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) / LAG(o.close_price) OVER (PARTITION BY s.id ORDER BY o.trade_date)) * 100 as avg_change_percent
FROM securities s
JOIN companies c ON s.company_id = c.id
JOIN sectors sec ON c.sector_id = sec.id
JOIN ohlcv_daily o ON s.id = o.security_id
WHERE s.is_active = 1
  AND o.trade_date >= today() - 30
GROUP BY sec.name, o.trade_date;

-- Technical Signals View
CREATE MATERIALIZED VIEW IF NOT EXISTS technical_signals_view
ENGINE = MergeTree()
ORDER BY (trade_date, signal_strength DESC)
POPULATE
AS SELECT 
    s.symbol,
    ti.trade_date,
    CASE 
        WHEN ti.rsi_14 < 30 THEN 'OVERSOLD'
        WHEN ti.rsi_14 > 70 THEN 'OVERBOUGHT'
        WHEN ti.macd > ti.macd_signal AND LAG(ti.macd) OVER (PARTITION BY s.id ORDER BY ti.trade_date) <= LAG(ti.macd_signal) OVER (PARTITION BY s.id ORDER BY ti.trade_date) THEN 'MACD_BUY'
        WHEN ti.macd < ti.macd_signal AND LAG(ti.macd) OVER (PARTITION BY s.id ORDER BY ti.trade_date) >= LAG(ti.macd_signal) OVER (PARTITION BY s.id ORDER BY ti.trade_date) THEN 'MACD_SELL'
        WHEN o.close_price > ti.bb_upper THEN 'BB_BREAKOUT'
        WHEN o.close_price < ti.bb_lower THEN 'BB_BREAKDOWN'
        ELSE 'NEUTRAL'
    END as signal_type,
    CASE 
        WHEN ti.rsi_14 < 20 OR ti.rsi_14 > 80 THEN 'HIGH'
        WHEN ti.rsi_14 < 30 OR ti.rsi_14 > 70 THEN 'MEDIUM'
        ELSE 'LOW'
    END as signal_strength,
    ti.rsi_14,
    ti.macd,
    ti.macd_signal,
    o.close_price,
    ti.bb_upper,
    ti.bb_lower
FROM securities s
JOIN technical_indicators ti ON s.id = ti.security_id
JOIN ohlcv_daily o ON s.id = o.security_id AND ti.trade_date = o.trade_date
WHERE s.is_active = 1
  AND ti.trade_date >= today() - 30;

-- Volume Analysis View
CREATE MATERIALIZED VIEW IF NOT EXISTS volume_analysis_view
ENGINE = MergeTree()
ORDER BY (trade_date, volume_ratio DESC)
POPULATE
AS SELECT 
    s.symbol,
    o.trade_date,
    o.volume,
    AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) as avg_volume_20d,
    o.volume / AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) as volume_ratio,
    CASE 
        WHEN o.volume > AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) * 3 THEN 'VERY_HIGH'
        WHEN o.volume > AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) * 2 THEN 'HIGH'
        WHEN o.volume > AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) * 1.5 THEN 'ABOVE_AVERAGE'
        WHEN o.volume < AVG(o.volume) OVER (PARTITION BY s.id ORDER BY o.trade_date ROWS BETWEEN 19 PRECEDING AND 1 PRECEDING) * 0.5 THEN 'LOW'
        ELSE 'NORMAL'
    END as volume_category
FROM securities s
JOIN ohlcv_daily o ON s.id = o.security_id
WHERE s.is_active = 1
  AND o.trade_date >= today() - 60;

-- News Sentiment Summary View
CREATE MATERIALIZED VIEW IF NOT EXISTS news_sentiment_summary_view
ENGINE = MergeTree()
ORDER BY (analysis_date, avg_sentiment DESC)
POPULATE
AS SELECT 
    c.name as company_name,
    s.symbol,
    toDate(ns.analysis_date) as analysis_date,
    COUNT(*) as news_count,
    AVG(ns.overall_sentiment) as avg_sentiment,
    SUM(CASE WHEN ns.sentiment_label = 'positive' THEN 1 ELSE 0 END) as positive_count,
    SUM(CASE WHEN ns.sentiment_label = 'negative' THEN 1 ELSE 0 END) as negative_count,
    SUM(CASE WHEN ns.sentiment_label = 'neutral' THEN 1 ELSE 0 END) as neutral_count
FROM news_sentiment ns
JOIN companies c ON ns.company_id = c.id
JOIN securities s ON c.id = s.company_id
WHERE ns.analysis_date >= today() - 30
GROUP BY c.name, s.symbol, toDate(ns.analysis_date);