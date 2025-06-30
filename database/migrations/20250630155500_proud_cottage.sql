-- ClickHouse Market Data Tables
-- Optimized for time-series financial data with partitioning

USE stockdb;

-- OHLCV Daily data (partitioned by month for optimal performance)
CREATE TABLE IF NOT EXISTS ohlcv_daily (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    open_price Decimal(15, 4),
    high_price Decimal(15, 4),
    low_price Decimal(15, 4),
    close_price Decimal(15, 4),
    adjusted_close Decimal(15, 4),
    volume UInt64 DEFAULT 0,
    volume_weighted_price Decimal(15, 4),
    trade_count UInt32,
    turnover Decimal(20, 4),
    data_source String,
    data_quality_score Decimal(3, 2),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date)
SETTINGS index_granularity = 8192;

-- OHLCV Intraday data (partitioned by day)
CREATE TABLE IF NOT EXISTS ohlcv_intraday (
    id UInt64,
    security_id UInt32,
    timestamp DateTime,
    open_price Decimal(15, 4),
    high_price Decimal(15, 4),
    low_price Decimal(15, 4),
    close_price Decimal(15, 4),
    volume UInt64 DEFAULT 0,
    volume_weighted_price Decimal(15, 4),
    trade_count UInt32,
    bid_price Decimal(15, 4),
    ask_price Decimal(15, 4),
    bid_size UInt32,
    ask_size UInt32,
    spread Decimal(15, 4),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (security_id, timestamp)
SETTINGS index_granularity = 8192;

-- Price Adjustments table
CREATE TABLE IF NOT EXISTS price_adjustments (
    id UInt32,
    security_id UInt32,
    adjustment_date Date,
    ex_date Date,
    record_date Date,
    payment_date Date,
    adjustment_type String,
    split_ratio_from UInt32,
    split_ratio_to UInt32,
    dividend_amount Decimal(15, 4),
    dividend_type String,
    price_adjustment_factor Decimal(10, 6) DEFAULT 1.0,
    volume_adjustment_factor Decimal(10, 6) DEFAULT 1.0,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (security_id, adjustment_date)
SETTINGS index_granularity = 8192;

-- Trading Statistics table
CREATE TABLE IF NOT EXISTS trading_statistics (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    previous_close Decimal(15, 4),
    price_change Decimal(15, 4),
    price_change_percent Decimal(8, 4),
    true_range Decimal(15, 4),
    intraday_return Decimal(8, 4),
    volume_ratio Decimal(8, 4),
    avg_volume_10d UInt64,
    avg_volume_30d UInt64,
    up_ticks UInt32,
    down_ticks UInt32,
    unchanged_ticks UInt32,
    market_cap Decimal(20, 2),
    shares_traded UInt64,
    turnover_ratio Decimal(8, 4),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date)
SETTINGS index_granularity = 8192;

-- Volume Profile table
CREATE TABLE IF NOT EXISTS volume_profile (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    price_level Decimal(15, 4),
    volume UInt64,
    trade_count UInt32,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date, price_level)
SETTINGS index_granularity = 8192;

-- Market Depth table
CREATE TABLE IF NOT EXISTS market_depth (
    id UInt64,
    security_id UInt32,
    timestamp DateTime,
    bid_prices Array(Decimal(15, 4)),
    bid_sizes Array(UInt32),
    ask_prices Array(Decimal(15, 4)),
    ask_sizes Array(UInt32),
    total_bid_volume UInt64,
    total_ask_volume UInt64,
    spread Decimal(15, 4),
    mid_price Decimal(15, 4),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (security_id, timestamp)
SETTINGS index_granularity = 8192;

-- Market Data Sources table
CREATE TABLE IF NOT EXISTS market_data_sources (
    id UInt32,
    name String,
    api_endpoint String,
    api_key_required UInt8 DEFAULT 1,
    rate_limit_per_minute UInt32 DEFAULT 60,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;