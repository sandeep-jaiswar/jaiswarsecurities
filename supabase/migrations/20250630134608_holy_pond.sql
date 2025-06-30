--liquibase formatted sql

--changeset architect:001-initial-schema
--comment: Create initial database schema for stock screening system

CREATE TABLE IF NOT EXISTS symbols (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    yticker VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    exchange VARCHAR(50),
    industry VARCHAR(100),
    sector VARCHAR(100),
    market_cap BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ohlcv (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    open_price DECIMAL(12, 4) NOT NULL,
    high_price DECIMAL(12, 4) NOT NULL,
    low_price DECIMAL(12, 4) NOT NULL,
    close_price DECIMAL(12, 4) NOT NULL,
    adjusted_close DECIMAL(12, 4),
    volume BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(symbol_id, trade_date)
);

CREATE TABLE IF NOT EXISTS indicators (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    sma_20 DECIMAL(12, 4),
    sma_50 DECIMAL(12, 4),
    sma_200 DECIMAL(12, 4),
    ema_12 DECIMAL(12, 4),
    ema_26 DECIMAL(12, 4),
    rsi_14 DECIMAL(8, 4),
    macd DECIMAL(12, 4),
    macd_signal DECIMAL(12, 4),
    macd_histogram DECIMAL(12, 4),
    bb_upper DECIMAL(12, 4),
    bb_middle DECIMAL(12, 4),
    bb_lower DECIMAL(12, 4),
    stoch_k DECIMAL(8, 4),
    stoch_d DECIMAL(8, 4),
    williams_r DECIMAL(8, 4),
    atr_14 DECIMAL(12, 4),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(symbol_id, trade_date)
);

CREATE TABLE IF NOT EXISTS market_data_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    api_endpoint VARCHAR(255),
    api_key_required BOOLEAN DEFAULT TRUE,
    rate_limit_per_minute INTEGER DEFAULT 60,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default data sources
INSERT INTO market_data_sources (name, api_endpoint, rate_limit_per_minute) VALUES
('Alpha Vantage', 'https://www.alphavantage.co/query', 5),
('Yahoo Finance', 'https://query1.finance.yahoo.com/v8/finance/chart', 2000),
('Polygon', 'https://api.polygon.io', 1000)
ON CONFLICT (name) DO NOTHING;

--rollback DROP TABLE IF EXISTS market_data_sources CASCADE;
--rollback DROP TABLE IF EXISTS indicators CASCADE;
--rollback DROP TABLE IF EXISTS ohlcv CASCADE;
--rollback DROP TABLE IF EXISTS symbols CASCADE;