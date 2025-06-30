--liquibase formatted sql

--changeset architect:004-add-screening-tables
--comment: Create tables for stock screening functionality

CREATE TABLE IF NOT EXISTS screens (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    criteria JSONB NOT NULL,
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS screen_results (
    id SERIAL PRIMARY KEY,
    screen_id INTEGER REFERENCES screens(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    scan_date DATE NOT NULL,
    score DECIMAL(8, 4),
    criteria_met JSONB,
    market_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(screen_id, symbol_id, scan_date)
);

CREATE TABLE IF NOT EXISTS watchlists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS watchlist_symbols (
    id SERIAL PRIMARY KEY,
    watchlist_id INTEGER REFERENCES watchlists(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    added_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    target_price DECIMAL(12, 4),
    stop_loss DECIMAL(12, 4),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(watchlist_id, symbol_id)
);

CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,
    condition_type VARCHAR(20) NOT NULL CHECK (condition_type IN ('above', 'below', 'crosses_above', 'crosses_below')),
    target_value DECIMAL(12, 4) NOT NULL,
    current_value DECIMAL(12, 4),
    is_triggered BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    triggered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample screens
INSERT INTO screens (name, description, criteria) VALUES
('High Volume Breakout', 'Stocks breaking out with high volume',
 '{"volume_ratio": {"min": 2.0}, "price_change": {"min": 0.05}, "rsi": {"max": 80}}'),
('Oversold Value Stocks', 'Undervalued stocks with oversold RSI',
 '{"rsi": {"max": 30}, "pe_ratio": {"max": 15}, "market_cap": {"min": 1000000000}}'),
('Momentum Stocks', 'Stocks with strong momentum indicators',
 '{"rsi": {"min": 60, "max": 80}, "macd": {"condition": "positive"}, "sma_20_slope": {"min": 0.02}}')
ON CONFLICT (name) DO NOTHING;

-- Indexes for screening tables
CREATE INDEX IF NOT EXISTS idx_screens_active ON screens(is_active);
CREATE INDEX IF NOT EXISTS idx_screen_results_screen_date ON screen_results(screen_id, scan_date);
CREATE INDEX IF NOT EXISTS idx_screen_results_symbol ON screen_results(symbol_id);
CREATE INDEX IF NOT EXISTS idx_screen_results_score ON screen_results(score);
CREATE INDEX IF NOT EXISTS idx_watchlists_created_by ON watchlists(created_by);
CREATE INDEX IF NOT EXISTS idx_watchlist_symbols_watchlist ON watchlist_symbols(watchlist_id);
CREATE INDEX IF NOT EXISTS idx_alerts_symbol ON alerts(symbol_id);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered ON alerts(is_triggered);

--rollback DROP INDEX IF EXISTS idx_alerts_triggered;
--rollback DROP INDEX IF EXISTS idx_alerts_active;
--rollback DROP INDEX IF EXISTS idx_alerts_symbol;
--rollback DROP INDEX IF EXISTS idx_watchlist_symbols_watchlist;
--rollback DROP INDEX IF EXISTS idx_watchlists_created_by;
--rollback DROP INDEX IF EXISTS idx_screen_results_score;
--rollback DROP INDEX IF EXISTS idx_screen_results_symbol;
--rollback DROP INDEX IF EXISTS idx_screen_results_screen_date;
--rollback DROP INDEX IF EXISTS idx_screens_active;
--rollback DROP TABLE IF EXISTS alerts CASCADE;
--rollback DROP TABLE IF EXISTS watchlist_symbols CASCADE;
--rollback DROP TABLE IF EXISTS watchlists CASCADE;
--rollback DROP TABLE IF EXISTS screen_results CASCADE;
--rollback DROP TABLE IF EXISTS screens CASCADE;