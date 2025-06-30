-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Countries indexes
CREATE INDEX IF NOT EXISTS idx_countries_code ON countries(code);
CREATE INDEX IF NOT EXISTS idx_countries_region ON countries(region);

-- Currencies indexes
CREATE INDEX IF NOT EXISTS idx_currencies_code ON currencies(code);
CREATE INDEX IF NOT EXISTS idx_currencies_active ON currencies(is_active);

-- Exchanges indexes
CREATE INDEX IF NOT EXISTS idx_exchanges_code ON exchanges(code);
CREATE INDEX IF NOT EXISTS idx_exchanges_country ON exchanges(country_id);
CREATE INDEX IF NOT EXISTS idx_exchanges_active ON exchanges(is_active);

-- Sectors indexes
CREATE INDEX IF NOT EXISTS idx_sectors_code ON sectors(code);

-- Industries indexes
CREATE INDEX IF NOT EXISTS idx_industries_code ON industries(code);
CREATE INDEX IF NOT EXISTS idx_industries_sector ON industries(sector_id);

-- Companies indexes
CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(name);
CREATE INDEX IF NOT EXISTS idx_companies_sector ON companies(sector_id);
CREATE INDEX IF NOT EXISTS idx_companies_industry ON companies(industry_id);
CREATE INDEX IF NOT EXISTS idx_companies_country ON companies(headquarters_country_id);
CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(is_active);
CREATE INDEX IF NOT EXISTS idx_companies_public ON companies(is_public);

-- Securities indexes
CREATE INDEX IF NOT EXISTS idx_securities_symbol ON securities(symbol);
CREATE INDEX IF NOT EXISTS idx_securities_company ON securities(company_id);
CREATE INDEX IF NOT EXISTS idx_securities_exchange ON securities(exchange_id);
CREATE INDEX IF NOT EXISTS idx_securities_type ON securities(security_type_id);
CREATE INDEX IF NOT EXISTS idx_securities_active ON securities(is_active);

-- OHLCV Daily indexes
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_security_date ON ohlcv_daily(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_date ON ohlcv_daily(trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_volume ON ohlcv_daily(volume DESC);

-- OHLCV Intraday indexes
CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_security_time ON ohlcv_intraday(security_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_timestamp ON ohlcv_intraday(timestamp DESC);

-- Price Adjustments indexes
CREATE INDEX IF NOT EXISTS idx_price_adjustments_security_date ON price_adjustments(security_id, adjustment_date);
CREATE INDEX IF NOT EXISTS idx_price_adjustments_type ON price_adjustments(adjustment_type);

-- Trading Statistics indexes
CREATE INDEX IF NOT EXISTS idx_trading_stats_security_date ON trading_statistics(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_trading_stats_market_cap ON trading_statistics(market_cap DESC);

-- Technical Indicators indexes
CREATE INDEX IF NOT EXISTS idx_technical_indicators_security_date ON technical_indicators(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_rsi ON technical_indicators(rsi_14);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_macd ON technical_indicators(macd);

-- Chart Patterns indexes
CREATE INDEX IF NOT EXISTS idx_chart_patterns_security ON chart_patterns(security_id);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_type ON chart_patterns(pattern_type_id);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_detection_date ON chart_patterns(detection_date DESC);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_status ON chart_patterns(status);

-- Support/Resistance indexes
CREATE INDEX IF NOT EXISTS idx_support_resistance_security ON support_resistance_levels(security_id);
CREATE INDEX IF NOT EXISTS idx_support_resistance_price ON support_resistance_levels(price_level);
CREATE INDEX IF NOT EXISTS idx_support_resistance_active ON support_resistance_levels(is_active);

-- Screens indexes
CREATE INDEX IF NOT EXISTS idx_screens_active ON screens(is_active);

-- Screen Results indexes
CREATE INDEX IF NOT EXISTS idx_screen_results_screen_date ON screen_results(screen_id, scan_date);
CREATE INDEX IF NOT EXISTS idx_screen_results_security ON screen_results(security_id);
CREATE INDEX IF NOT EXISTS idx_screen_results_score ON screen_results(score);

-- Backtests indexes
CREATE INDEX IF NOT EXISTS idx_backtests_strategy ON backtests(strategy_id);
CREATE INDEX IF NOT EXISTS idx_backtests_status ON backtests(status);
CREATE INDEX IF NOT EXISTS idx_backtests_dates ON backtests(start_date, end_date);

-- Backtest Trades indexes
CREATE INDEX IF NOT EXISTS idx_backtest_trades_backtest ON backtest_trades(backtest_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_security ON backtest_trades(security_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_dates ON backtest_trades(entry_date, exit_date);

-- Backtest Equity Curve indexes
CREATE INDEX IF NOT EXISTS idx_backtest_equity_backtest_date ON backtest_equity_curve(backtest_id, trade_date);

-- Watchlists indexes
CREATE INDEX IF NOT EXISTS idx_watchlists_created_by ON watchlists(created_by);

-- Watchlist Symbols indexes
CREATE INDEX IF NOT EXISTS idx_watchlist_symbols_watchlist ON watchlist_symbols(watchlist_id);

-- Alerts indexes
CREATE INDEX IF NOT EXISTS idx_alerts_security ON alerts(security_id);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered ON alerts(is_triggered);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_verified ON users(is_verified);

-- User Roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);

-- User Sessions indexes
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

-- Audit Logs indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);

-- Legacy table indexes for backward compatibility
CREATE INDEX IF NOT EXISTS idx_symbols_symbol ON symbols(symbol);
CREATE INDEX IF NOT EXISTS idx_symbols_exchange ON symbols(exchange);
CREATE INDEX IF NOT EXISTS idx_symbols_sector ON symbols(sector);
CREATE INDEX IF NOT EXISTS idx_symbols_industry ON symbols(industry);
CREATE INDEX IF NOT EXISTS idx_symbols_active ON symbols(is_active);

CREATE INDEX IF NOT EXISTS idx_ohlcv_symbol_date ON ohlcv(symbol_id, trade_date);
CREATE INDEX IF NOT EXISTS idx_ohlcv_date ON ohlcv(trade_date);
CREATE INDEX IF NOT EXISTS idx_ohlcv_symbol_date_close ON ohlcv(symbol_id, trade_date, close_price);
CREATE INDEX IF NOT EXISTS idx_ohlcv_close_price ON ohlcv(close_price);
CREATE INDEX IF NOT EXISTS idx_ohlcv_volume ON ohlcv(volume);

CREATE INDEX IF NOT EXISTS idx_indicators_symbol_date ON indicators(symbol_id, trade_date);
CREATE INDEX IF NOT EXISTS idx_indicators_date ON indicators(trade_date);
CREATE INDEX IF NOT EXISTS idx_indicators_symbol_date_rsi ON indicators(symbol_id, trade_date, rsi_14);
CREATE INDEX IF NOT EXISTS idx_indicators_rsi ON indicators(rsi_14);
CREATE INDEX IF NOT EXISTS idx_indicators_sma_20 ON indicators(sma_20);
CREATE INDEX IF NOT EXISTS idx_indicators_macd ON indicators(macd);