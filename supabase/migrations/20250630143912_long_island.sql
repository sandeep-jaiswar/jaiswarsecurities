/*
  # Market Data Tables
  
  1. Price Data
    - ohlcv_daily: Daily OHLCV data
    - ohlcv_intraday: Intraday price data
    - price_adjustments: Stock splits, dividends adjustments
  
  2. Volume and Trading
    - volume_profile: Volume by price levels
    - trading_statistics: Daily trading statistics
    - market_depth: Order book depth data
*/

-- Daily OHLCV data
CREATE TABLE IF NOT EXISTS ohlcv_daily (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    
    -- Price data
    open_price DECIMAL(15,4) NOT NULL,
    high_price DECIMAL(15,4) NOT NULL,
    low_price DECIMAL(15,4) NOT NULL,
    close_price DECIMAL(15,4) NOT NULL,
    adjusted_close DECIMAL(15,4),
    
    -- Volume data
    volume BIGINT NOT NULL DEFAULT 0,
    volume_weighted_price DECIMAL(15,4),
    
    -- Trading statistics
    trade_count INTEGER,
    turnover DECIMAL(20,4), -- Total value traded
    
    -- Market data quality
    data_source VARCHAR(50),
    data_quality_score DECIMAL(3,2), -- 0.00 to 1.00
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, trade_date)
);

-- Intraday OHLCV data (1-minute intervals)
CREATE TABLE IF NOT EXISTS ohlcv_intraday (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Price data
    open_price DECIMAL(15,4) NOT NULL,
    high_price DECIMAL(15,4) NOT NULL,
    low_price DECIMAL(15,4) NOT NULL,
    close_price DECIMAL(15,4) NOT NULL,
    
    -- Volume data
    volume BIGINT NOT NULL DEFAULT 0,
    volume_weighted_price DECIMAL(15,4),
    trade_count INTEGER,
    
    -- Bid/Ask data
    bid_price DECIMAL(15,4),
    ask_price DECIMAL(15,4),
    bid_size INTEGER,
    ask_size INTEGER,
    spread DECIMAL(15,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, timestamp)
);

-- Price adjustments (splits, dividends, etc.)
CREATE TABLE IF NOT EXISTS price_adjustments (
    id SERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    adjustment_date DATE NOT NULL,
    ex_date DATE NOT NULL,
    record_date DATE,
    payment_date DATE,
    
    adjustment_type VARCHAR(20) NOT NULL, -- SPLIT, DIVIDEND, SPINOFF, MERGER
    
    -- Split information
    split_ratio_from INTEGER, -- 2 for 2:1 split
    split_ratio_to INTEGER,   -- 1 for 2:1 split
    
    -- Dividend information
    dividend_amount DECIMAL(15,4),
    dividend_type VARCHAR(20), -- CASH, STOCK, SPECIAL
    
    -- Adjustment factors
    price_adjustment_factor DECIMAL(10,6) DEFAULT 1.0,
    volume_adjustment_factor DECIMAL(10,6) DEFAULT 1.0,
    
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Volume profile data
CREATE TABLE IF NOT EXISTS volume_profile (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    price_level DECIMAL(15,4) NOT NULL,
    volume BIGINT NOT NULL,
    trade_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, trade_date, price_level)
);

-- Daily trading statistics
CREATE TABLE IF NOT EXISTS trading_statistics (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    
    -- Price statistics
    previous_close DECIMAL(15,4),
    price_change DECIMAL(15,4),
    price_change_percent DECIMAL(8,4),
    
    -- Volatility measures
    true_range DECIMAL(15,4),
    intraday_return DECIMAL(8,4),
    
    -- Volume statistics
    volume_ratio DECIMAL(8,4), -- Current volume / Average volume
    avg_volume_10d BIGINT,
    avg_volume_30d BIGINT,
    
    -- Trading activity
    up_ticks INTEGER,
    down_ticks INTEGER,
    unchanged_ticks INTEGER,
    
    -- Market cap and valuation
    market_cap DECIMAL(20,2),
    shares_traded BIGINT,
    turnover_ratio DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, trade_date)
);

-- Market depth / Order book data
CREATE TABLE IF NOT EXISTS market_depth (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Bid side (buyers)
    bid_prices DECIMAL(15,4)[] NOT NULL, -- Array of bid prices
    bid_sizes INTEGER[] NOT NULL,        -- Array of bid sizes
    
    -- Ask side (sellers)
    ask_prices DECIMAL(15,4)[] NOT NULL, -- Array of ask prices
    ask_sizes INTEGER[] NOT NULL,        -- Array of ask sizes
    
    -- Summary statistics
    total_bid_volume BIGINT,
    total_ask_volume BIGINT,
    spread DECIMAL(15,4),
    mid_price DECIMAL(15,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for market data
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_security_date ON ohlcv_daily(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_date ON ohlcv_daily(trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_volume ON ohlcv_daily(volume DESC);

CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_security_time ON ohlcv_intraday(security_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_timestamp ON ohlcv_intraday(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_price_adjustments_security_date ON price_adjustments(security_id, adjustment_date);
CREATE INDEX IF NOT EXISTS idx_price_adjustments_type ON price_adjustments(adjustment_type);

CREATE INDEX IF NOT EXISTS idx_trading_stats_security_date ON trading_statistics(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_trading_stats_market_cap ON trading_statistics(market_cap DESC);

-- Partitioning for large tables (example for daily OHLCV)
-- This would be implemented based on data volume and query patterns
-- CREATE TABLE ohlcv_daily_y2024 PARTITION OF ohlcv_daily FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');