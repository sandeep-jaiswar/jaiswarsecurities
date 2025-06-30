CREATE TABLE IF NOT EXISTS symbols (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    yticker VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100),
    exchange VARCHAR(50),
    industry VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ohlcv (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    open_price DECIMAL(10, 2) NOT NULL,
    high_price DECIMAL(10, 2) NOT NULL,
    low_price DECIMAL(10, 2) NOT NULL,
    close_price DECIMAL(10, 2) NOT NULL,
    volume BIGINT NOT NULL,
);

CREATE TABLE IF NOT EXISTS indicators (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,      
    date DATE NOT NULL,
    sma_20 NUMERIC,
    ema_12 NUMERIC,
    ema_26 NUMERIC,
    rsi_14 NUMERIC,
    macd NUMERIC,
    macd_signal NUMERIC,
    macd_histogram NUMERIC,
    bb_upper NUMERIC,
    bb_middle NUMERIC,
    bb_lower NUMERIC,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(symbol, date)
);



