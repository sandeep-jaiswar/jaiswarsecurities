-- Stock Screening System Database Schema
-- Comprehensive schema for Bloomberg-like financial platform

-- =====================================================
-- REFERENCE DATA TABLES
-- =====================================================

-- Countries
CREATE TABLE IF NOT EXISTS countries (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    alpha_2 VARCHAR(2) NOT NULL,
    region VARCHAR(50),
    sub_region VARCHAR(50),
    currency_code VARCHAR(3),
    phone_code VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Currencies
CREATE TABLE IF NOT EXISTS currencies (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimal_places INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exchanges
CREATE TABLE IF NOT EXISTS exchanges (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    country_id INTEGER REFERENCES countries(id),
    currency_id INTEGER REFERENCES currencies(id),
    timezone VARCHAR(50),
    trading_hours JSONB,
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sectors
CREATE TABLE IF NOT EXISTS sectors (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Industries
CREATE TABLE IF NOT EXISTS industries (
    id SERIAL PRIMARY KEY,
    sector_id INTEGER REFERENCES sectors(id),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Security Types
CREATE TABLE IF NOT EXISTS security_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- COMPANY AND SECURITY TABLES
-- =====================================================

-- Companies
CREATE TABLE IF NOT EXISTS companies (
    id SERIAL PRIMARY KEY,
    cik VARCHAR(20) UNIQUE,
    lei VARCHAR(20) UNIQUE,
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(300),
    short_name VARCHAR(100),
    former_names TEXT[],
    sector_id INTEGER REFERENCES sectors(id),
    industry_id INTEGER REFERENCES industries(id),
    sub_industry VARCHAR(100),
    headquarters_country_id INTEGER REFERENCES countries(id),
    headquarters_address JSONB,
    incorporation_country_id INTEGER REFERENCES countries(id),
    incorporation_date DATE,
    business_description TEXT,
    website VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(100),
    employee_count INTEGER,
    fiscal_year_end VARCHAR(5),
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    delisting_date DATE,
    delisting_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Securities
CREATE TABLE IF NOT EXISTS securities (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    security_type_id INTEGER REFERENCES security_types(id),
    symbol VARCHAR(20) NOT NULL,
    isin VARCHAR(12) UNIQUE,
    cusip VARCHAR(9),
    sedol VARCHAR(7),
    exchange_id INTEGER REFERENCES exchanges(id),
    currency_id INTEGER REFERENCES currencies(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    shares_outstanding BIGINT,
    shares_float BIGINT,
    par_value NUMERIC(15,4),
    is_active BOOLEAN DEFAULT TRUE,
    listing_date DATE,
    delisting_date DATE,
    trading_status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol, exchange_id)
);

-- =====================================================
-- MARKET DATA TABLES
-- =====================================================

-- OHLCV Daily Data
CREATE TABLE IF NOT EXISTS ohlcv_daily (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    open_price NUMERIC(15,4) NOT NULL,
    high_price NUMERIC(15,4) NOT NULL,
    low_price NUMERIC(15,4) NOT NULL,
    close_price NUMERIC(15,4) NOT NULL,
    adjusted_close NUMERIC(15,4),
    volume BIGINT DEFAULT 0,
    volume_weighted_price NUMERIC(15,4),
    trade_count INTEGER,
    turnover NUMERIC(20,4),
    data_source VARCHAR(50),
    data_quality_score NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, trade_date)
);

-- OHLCV Intraday Data
CREATE TABLE IF NOT EXISTS ohlcv_intraday (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    open_price NUMERIC(15,4) NOT NULL,
    high_price NUMERIC(15,4) NOT NULL,
    low_price NUMERIC(15,4) NOT NULL,
    close_price NUMERIC(15,4) NOT NULL,
    volume BIGINT DEFAULT 0,
    volume_weighted_price NUMERIC(15,4),
    trade_count INTEGER,
    bid_price NUMERIC(15,4),
    ask_price NUMERIC(15,4),
    bid_size INTEGER,
    ask_size INTEGER,
    spread NUMERIC(15,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, timestamp)
);

-- Price Adjustments (Splits, Dividends)
CREATE TABLE IF NOT EXISTS price_adjustments (
    id SERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    adjustment_date DATE NOT NULL,
    ex_date DATE NOT NULL,
    record_date DATE,
    payment_date DATE,
    adjustment_type VARCHAR(20) NOT NULL, -- 'SPLIT', 'DIVIDEND', 'SPINOFF'
    split_ratio_from INTEGER,
    split_ratio_to INTEGER,
    dividend_amount NUMERIC(15,4),
    dividend_type VARCHAR(20), -- 'CASH', 'STOCK', 'SPECIAL'
    price_adjustment_factor NUMERIC(10,6) DEFAULT 1.0,
    volume_adjustment_factor NUMERIC(10,6) DEFAULT 1.0,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trading Statistics
CREATE TABLE IF NOT EXISTS trading_statistics (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    previous_close NUMERIC(15,4),
    price_change NUMERIC(15,4),
    price_change_percent NUMERIC(8,4),
    true_range NUMERIC(15,4),
    intraday_return NUMERIC(8,4),
    volume_ratio NUMERIC(8,4),
    avg_volume_10d BIGINT,
    avg_volume_30d BIGINT,
    up_ticks INTEGER,
    down_ticks INTEGER,
    unchanged_ticks INTEGER,
    market_cap NUMERIC(20,2),
    shares_traded BIGINT,
    turnover_ratio NUMERIC(8,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, trade_date)
);

-- Market Depth (Order Book)
CREATE TABLE IF NOT EXISTS market_depth (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    bid_prices NUMERIC(15,4)[] NOT NULL,
    bid_sizes INTEGER[] NOT NULL,
    ask_prices NUMERIC(15,4)[] NOT NULL,
    ask_sizes INTEGER[] NOT NULL,
    total_bid_volume BIGINT,
    total_ask_volume BIGINT,
    spread NUMERIC(15,4),
    mid_price NUMERIC(15,4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Volume Profile
CREATE TABLE IF NOT EXISTS volume_profile (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    price_level NUMERIC(15,4) NOT NULL,
    volume BIGINT NOT NULL,
    trade_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, trade_date, price_level)
);

-- =====================================================
-- TECHNICAL ANALYSIS TABLES
-- =====================================================

-- Technical Indicators
CREATE TABLE IF NOT EXISTS technical_indicators (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    -- Moving Averages
    sma_5 NUMERIC(15,4),
    sma_10 NUMERIC(15,4),
    sma_20 NUMERIC(15,4),
    sma_50 NUMERIC(15,4),
    sma_100 NUMERIC(15,4),
    sma_200 NUMERIC(15,4),
    ema_5 NUMERIC(15,4),
    ema_10 NUMERIC(15,4),
    ema_12 NUMERIC(15,4),
    ema_20 NUMERIC(15,4),
    ema_26 NUMERIC(15,4),
    ema_50 NUMERIC(15,4),
    ema_100 NUMERIC(15,4),
    ema_200 NUMERIC(15,4),
    -- Momentum Indicators
    rsi_14 NUMERIC(8,4),
    rsi_21 NUMERIC(8,4),
    stoch_k NUMERIC(8,4),
    stoch_d NUMERIC(8,4),
    williams_r NUMERIC(8,4),
    -- MACD
    macd NUMERIC(15,4),
    macd_signal NUMERIC(15,4),
    macd_histogram NUMERIC(15,4),
    -- Bollinger Bands
    bb_upper NUMERIC(15,4),
    bb_middle NUMERIC(15,4),
    bb_lower NUMERIC(15,4),
    bb_width NUMERIC(8,4),
    bb_percent NUMERIC(8,4),
    -- Volume Indicators
    volume_sma_20 BIGINT,
    volume_ratio NUMERIC(8,4),
    on_balance_volume BIGINT,
    accumulation_distribution NUMERIC(20,4),
    chaikin_money_flow NUMERIC(8,4),
    volume_price_trend NUMERIC(20,4),
    -- Volatility Indicators
    atr_14 NUMERIC(15,4),
    atr_21 NUMERIC(15,4),
    true_range NUMERIC(15,4),
    volatility_10d NUMERIC(8,4),
    volatility_30d NUMERIC(8,4),
    -- Trend Indicators
    adx_14 NUMERIC(8,4),
    di_plus NUMERIC(8,4),
    di_minus NUMERIC(8,4),
    aroon_up NUMERIC(8,4),
    aroon_down NUMERIC(8,4),
    aroon_oscillator NUMERIC(8,4),
    -- Support/Resistance
    pivot_point NUMERIC(15,4),
    resistance_1 NUMERIC(15,4),
    resistance_2 NUMERIC(15,4),
    resistance_3 NUMERIC(15,4),
    support_1 NUMERIC(15,4),
    support_2 NUMERIC(15,4),
    support_3 NUMERIC(15,4),
    -- Price Comparisons
    price_vs_sma20 NUMERIC(8,4),
    price_vs_sma50 NUMERIC(8,4),
    price_vs_sma200 NUMERIC(8,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, trade_date)
);

-- Pattern Types
CREATE TABLE IF NOT EXISTS pattern_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- 'REVERSAL', 'CONTINUATION', 'BILATERAL'
    description TEXT,
    bullish_probability NUMERIC(5,2),
    bearish_probability NUMERIC(5,2),
    min_periods INTEGER,
    max_periods INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chart Patterns
CREATE TABLE IF NOT EXISTS chart_patterns (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    pattern_type_id INTEGER REFERENCES pattern_types(id),
    start_date DATE NOT NULL,
    end_date DATE,
    detection_date DATE NOT NULL,
    pattern_name VARCHAR(100) NOT NULL,
    confidence_score NUMERIC(5,2),
    strength VARCHAR(20), -- 'WEAK', 'MODERATE', 'STRONG'
    direction VARCHAR(20), -- 'BULLISH', 'BEARISH', 'NEUTRAL'
    breakout_price NUMERIC(15,4),
    target_price NUMERIC(15,4),
    stop_loss_price NUMERIC(15,4),
    key_points JSONB,
    volume_confirmation BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'ACTIVE', -- 'ACTIVE', 'COMPLETED', 'FAILED'
    completion_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support/Resistance Levels
CREATE TABLE IF NOT EXISTS support_resistance_levels (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    price_level NUMERIC(15,4) NOT NULL,
    level_type VARCHAR(20) NOT NULL, -- 'SUPPORT', 'RESISTANCE'
    strength INTEGER NOT NULL, -- 1-10 scale
    first_touch_date DATE NOT NULL,
    last_touch_date DATE NOT NULL,
    touch_count INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    break_date DATE,
    break_volume BIGINT,
    time_frame VARCHAR(20), -- 'DAILY', 'WEEKLY', 'MONTHLY'
    formation_method VARCHAR(50), -- 'PIVOT_POINTS', 'TREND_LINES', 'FIBONACCI'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- SCREENING AND BACKTESTING TABLES
-- =====================================================

-- Screens
CREATE TABLE IF NOT EXISTS screens (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    criteria JSONB NOT NULL,
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Screen Results
CREATE TABLE IF NOT EXISTS screen_results (
    id SERIAL PRIMARY KEY,
    screen_id INTEGER REFERENCES screens(id) ON DELETE CASCADE,
    security_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    scan_date DATE NOT NULL,
    score NUMERIC(8,4),
    criteria_met JSONB,
    market_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(screen_id, security_id, scan_date)
);

-- Strategies
CREATE TABLE IF NOT EXISTS strategies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parameters JSONB,
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backtests
CREATE TABLE IF NOT EXISTS backtests (
    id SERIAL PRIMARY KEY,
    strategy_id INTEGER REFERENCES strategies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    initial_capital NUMERIC(15,2) NOT NULL,
    commission NUMERIC(8,6) DEFAULT 0.001,
    slippage NUMERIC(8,6) DEFAULT 0.001,
    status VARCHAR(20) DEFAULT 'pending',
    total_return NUMERIC(10,4),
    annual_return NUMERIC(10,4),
    max_drawdown NUMERIC(10,4),
    sharpe_ratio NUMERIC(8,4),
    sortino_ratio NUMERIC(8,4),
    win_rate NUMERIC(8,4),
    profit_factor NUMERIC(8,4),
    total_trades INTEGER,
    winning_trades INTEGER,
    losing_trades INTEGER,
    avg_win NUMERIC(12,4),
    avg_loss NUMERIC(12,4),
    largest_win NUMERIC(12,4),
    largest_loss NUMERIC(12,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Backtest Trades
CREATE TABLE IF NOT EXISTS backtest_trades (
    id SERIAL PRIMARY KEY,
    backtest_id INTEGER REFERENCES backtests(id) ON DELETE CASCADE,
    security_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    exit_date DATE,
    side VARCHAR(10) NOT NULL CHECK (side IN ('long', 'short')),
    entry_price NUMERIC(12,4) NOT NULL,
    exit_price NUMERIC(12,4),
    quantity INTEGER NOT NULL,
    commission NUMERIC(12,4) DEFAULT 0,
    pnl NUMERIC(12,4),
    pnl_percent NUMERIC(8,4),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    entry_signal JSONB,
    exit_signal JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backtest Equity Curve
CREATE TABLE IF NOT EXISTS backtest_equity_curve (
    id SERIAL PRIMARY KEY,
    backtest_id INTEGER REFERENCES backtests(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    portfolio_value NUMERIC(15,2) NOT NULL,
    cash NUMERIC(15,2) NOT NULL,
    positions_value NUMERIC(15,2) NOT NULL,
    daily_return NUMERIC(10,6),
    cumulative_return NUMERIC(10,6),
    drawdown NUMERIC(10,6),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(backtest_id, trade_date)
);

-- Watchlists
CREATE TABLE IF NOT EXISTS watchlists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchlist Symbols
CREATE TABLE IF NOT EXISTS watchlist_symbols (
    id SERIAL PRIMARY KEY,
    watchlist_id INTEGER REFERENCES watchlists(id) ON DELETE CASCADE,
    security_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    added_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    target_price NUMERIC(12,4),
    stop_loss NUMERIC(12,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(watchlist_id, security_id)
);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    security_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL, -- 'PRICE', 'VOLUME', 'INDICATOR'
    condition_type VARCHAR(20) NOT NULL CHECK (condition_type IN ('above', 'below', 'crosses_above', 'crosses_below')),
    target_value NUMERIC(12,4) NOT NULL,
    current_value NUMERIC(12,4),
    is_triggered BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- USER MANAGEMENT TABLES
-- =====================================================

-- Users
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    display_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ DEFAULT NOW(),
    email_verification_token VARCHAR(255),
    email_verified_at TIMESTAMPTZ,
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Permissions
CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(50),
    action VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Role Permissions
CREATE TABLE IF NOT EXISTS role_permissions (
    id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

-- User Roles
CREATE TABLE IF NOT EXISTS user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_by BIGINT REFERENCES users(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    UNIQUE(user_id, role_id)
);

-- User Sessions
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(50),
    browser VARCHAR(100),
    os VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    logout_at TIMESTAMPTZ
);

-- User Preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'light',
    chart_type VARCHAR(20) DEFAULT 'candlestick',
    default_time_frame VARCHAR(20) DEFAULT '1D',
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    alert_frequency VARCHAR(20) DEFAULT 'IMMEDIATE',
    max_alerts_per_day INTEGER DEFAULT 50,
    default_currency VARCHAR(3) DEFAULT 'USD',
    price_display_format VARCHAR(20) DEFAULT 'DECIMAL',
    profile_visibility VARCHAR(20) DEFAULT 'PRIVATE',
    share_watchlists BOOLEAN DEFAULT FALSE,
    share_performance BOOLEAN DEFAULT FALSE,
    custom_settings JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    user_id BIGINT REFERENCES users(id),
    username VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    request_method VARCHAR(10),
    request_url VARCHAR(500),
    old_values JSONB,
    new_values JSONB,
    additional_data JSONB,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- LEGACY COMPATIBILITY TABLES
-- =====================================================

-- Keep the original symbols table for backward compatibility
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Keep the original ohlcv table for backward compatibility
CREATE TABLE IF NOT EXISTS ohlcv (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    open_price NUMERIC(12,4) NOT NULL,
    high_price NUMERIC(12,4) NOT NULL,
    low_price NUMERIC(12,4) NOT NULL,
    close_price NUMERIC(12,4) NOT NULL,
    adjusted_close NUMERIC(12,4),
    volume BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol_id, trade_date)
);

-- Keep the original indicators table for backward compatibility
CREATE TABLE IF NOT EXISTS indicators (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    sma_20 NUMERIC(12,4),
    sma_50 NUMERIC(12,4),
    sma_200 NUMERIC(12,4),
    ema_12 NUMERIC(12,4),
    ema_26 NUMERIC(12,4),
    rsi_14 NUMERIC(8,4),
    macd NUMERIC(12,4),
    macd_signal NUMERIC(12,4),
    macd_histogram NUMERIC(12,4),
    bb_upper NUMERIC(12,4),
    bb_middle NUMERIC(12,4),
    bb_lower NUMERIC(12,4),
    stoch_k NUMERIC(8,4),
    stoch_d NUMERIC(8,4),
    williams_r NUMERIC(8,4),
    atr_14 NUMERIC(12,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol_id, trade_date)
);