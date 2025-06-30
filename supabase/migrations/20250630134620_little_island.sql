--liquibase formatted sql

--changeset architect:002-add-indexes
--comment: Add performance indexes for stock data queries

-- Indexes for symbols table
CREATE INDEX IF NOT EXISTS idx_symbols_symbol ON symbols(symbol);
CREATE INDEX IF NOT EXISTS idx_symbols_exchange ON symbols(exchange);
CREATE INDEX IF NOT EXISTS idx_symbols_industry ON symbols(industry);
CREATE INDEX IF NOT EXISTS idx_symbols_sector ON symbols(sector);
CREATE INDEX IF NOT EXISTS idx_symbols_active ON symbols(is_active);

-- Indexes for ohlcv table
CREATE INDEX IF NOT EXISTS idx_ohlcv_symbol_date ON ohlcv(symbol_id, trade_date);
CREATE INDEX IF NOT EXISTS idx_ohlcv_date ON ohlcv(trade_date);
CREATE INDEX IF NOT EXISTS idx_ohlcv_volume ON ohlcv(volume);
CREATE INDEX IF NOT EXISTS idx_ohlcv_close_price ON ohlcv(close_price);

-- Indexes for indicators table
CREATE INDEX IF NOT EXISTS idx_indicators_symbol_date ON indicators(symbol_id, trade_date);
CREATE INDEX IF NOT EXISTS idx_indicators_date ON indicators(trade_date);
CREATE INDEX IF NOT EXISTS idx_indicators_rsi ON indicators(rsi_14);
CREATE INDEX IF NOT EXISTS idx_indicators_macd ON indicators(macd);
CREATE INDEX IF NOT EXISTS idx_indicators_sma_20 ON indicators(sma_20);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_ohlcv_symbol_date_close ON ohlcv(symbol_id, trade_date, close_price);
CREATE INDEX IF NOT EXISTS idx_indicators_symbol_date_rsi ON indicators(symbol_id, trade_date, rsi_14);

--rollback DROP INDEX IF EXISTS idx_indicators_symbol_date_rsi;
--rollback DROP INDEX IF EXISTS idx_ohlcv_symbol_date_close;
--rollback DROP INDEX IF EXISTS idx_indicators_sma_20;
--rollback DROP INDEX IF EXISTS idx_indicators_macd;
--rollback DROP INDEX IF EXISTS idx_indicators_rsi;
--rollback DROP INDEX IF EXISTS idx_indicators_date;
--rollback DROP INDEX IF EXISTS idx_indicators_symbol_date;
--rollback DROP INDEX IF EXISTS idx_ohlcv_close_price;
--rollback DROP INDEX IF EXISTS idx_ohlcv_volume;
--rollback DROP INDEX IF EXISTS idx_ohlcv_date;
--rollback DROP INDEX IF EXISTS idx_ohlcv_symbol_date;
--rollback DROP INDEX IF EXISTS idx_symbols_active;
--rollback DROP INDEX IF EXISTS idx_symbols_sector;
--rollback DROP INDEX IF EXISTS idx_symbols_industry;
--rollback DROP INDEX IF EXISTS idx_symbols_exchange;
--rollback DROP INDEX IF EXISTS idx_symbols_symbol;