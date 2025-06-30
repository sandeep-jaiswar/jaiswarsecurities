-- Core Tables Schema for Stock Screening System
-- This creates a comprehensive database schema similar to Bloomberg Terminal

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================
-- 1. REFERENCE DATA TABLES
-- =============================================

-- Countries table
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

-- Currencies table
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

-- Exchanges table
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

-- Sectors table
CREATE TABLE IF NOT EXISTS sectors (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Industries table
CREATE TABLE IF NOT EXISTS industries (
    id SERIAL PRIMARY KEY,
    sector_id INTEGER REFERENCES sectors(id),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Security types table
CREATE TABLE IF NOT EXISTS security_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 2. COMPANY AND SECURITIES TABLES
-- =============================================

-- Companies table
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

-- Securities table
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

-- =============================================
-- 3. MARKET DATA TABLES
-- =============================================

-- OHLCV Daily data
CREATE TABLE IF NOT EXISTS ohlcv_daily (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    open_price NUMERIC(15,4) NOT NULL,
    high_price NUMERIC(15,4) NOT NULL,
    low_price NUMERIC(15,4) NOT NULL,
    close_price NUMERIC(15,4) NOT NULL,
    adjusted_close NUMERIC(15,4),
    volume BIGINT NOT NULL DEFAULT 0,
    volume_weighted_price NUMERIC(15,4),
    trade_count INTEGER,
    turnover NUMERIC(20,4),
    data_source VARCHAR(50),
    data_quality_score NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(security_id, trade_date)
);

-- OHLCV Intraday data
CREATE TABLE IF NOT EXISTS ohlcv_intraday (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    open_price NUMERIC(15,4) NOT NULL,
    high_price NUMERIC(15,4) NOT NULL,
    low_price NUMERIC(15,4) NOT NULL,
    close_price NUMERIC(15,4) NOT NULL,
    volume BIGINT NOT NULL DEFAULT 0,
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

-- Price adjustments (splits, dividends)
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
    dividend_type VARCHAR(20), -- 'CASH', 'STOCK'
    price_adjustment_factor NUMERIC(10,6) DEFAULT 1.0,
    volume_adjustment_factor NUMERIC(10,6) DEFAULT 1.0,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 4. TECHNICAL INDICATORS TABLES
-- =============================================

-- Technical indicators
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

-- =============================================
-- 5. FINANCIAL DATA TABLES
-- =============================================

-- Financial periods
CREATE TABLE IF NOT EXISTS financial_periods (
    id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    period_type VARCHAR(20) NOT NULL, -- 'ANNUAL', 'QUARTERLY'
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER, -- 1,2,3,4 for quarterly
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    report_date DATE,
    filing_type VARCHAR(20), -- '10-K', '10-Q', '8-K'
    filing_url VARCHAR(500),
    is_restated BOOLEAN DEFAULT FALSE,
    restatement_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, period_type, fiscal_year, fiscal_quarter)
);

-- Income statements
CREATE TABLE IF NOT EXISTS income_statements (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER UNIQUE NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    total_revenue NUMERIC(20,2),
    cost_of_revenue NUMERIC(20,2),
    gross_profit NUMERIC(20,2),
    research_development NUMERIC(20,2),
    sales_marketing NUMERIC(20,2),
    general_administrative NUMERIC(20,2),
    total_operating_expenses NUMERIC(20,2),
    operating_income NUMERIC(20,2),
    operating_margin NUMERIC(8,4),
    interest_income NUMERIC(20,2),
    interest_expense NUMERIC(20,2),
    other_income NUMERIC(20,2),
    income_before_tax NUMERIC(20,2),
    income_tax_expense NUMERIC(20,2),
    net_income NUMERIC(20,2),
    net_income_margin NUMERIC(8,4),
    basic_shares_outstanding BIGINT,
    diluted_shares_outstanding BIGINT,
    basic_eps NUMERIC(10,4),
    diluted_eps NUMERIC(10,4),
    ebitda NUMERIC(20,2),
    depreciation_amortization NUMERIC(20,2),
    stock_compensation NUMERIC(20,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Balance sheets
CREATE TABLE IF NOT EXISTS balance_sheets (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER UNIQUE NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    -- Assets
    cash_and_equivalents NUMERIC(20,2),
    short_term_investments NUMERIC(20,2),
    accounts_receivable NUMERIC(20,2),
    inventory NUMERIC(20,2),
    prepaid_expenses NUMERIC(20,2),
    other_current_assets NUMERIC(20,2),
    total_current_assets NUMERIC(20,2),
    property_plant_equipment NUMERIC(20,2),
    goodwill NUMERIC(20,2),
    intangible_assets NUMERIC(20,2),
    long_term_investments NUMERIC(20,2),
    other_non_current_assets NUMERIC(20,2),
    total_non_current_assets NUMERIC(20,2),
    total_assets NUMERIC(20,2),
    -- Liabilities
    accounts_payable NUMERIC(20,2),
    short_term_debt NUMERIC(20,2),
    accrued_liabilities NUMERIC(20,2),
    deferred_revenue NUMERIC(20,2),
    other_current_liabilities NUMERIC(20,2),
    total_current_liabilities NUMERIC(20,2),
    long_term_debt NUMERIC(20,2),
    deferred_tax_liabilities NUMERIC(20,2),
    other_non_current_liabilities NUMERIC(20,2),
    total_non_current_liabilities NUMERIC(20,2),
    total_liabilities NUMERIC(20,2),
    -- Equity
    common_stock NUMERIC(20,2),
    retained_earnings NUMERIC(20,2),
    accumulated_other_income NUMERIC(20,2),
    treasury_stock NUMERIC(20,2),
    total_shareholders_equity NUMERIC(20,2),
    total_liabilities_equity NUMERIC(20,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cash flow statements
CREATE TABLE IF NOT EXISTS cash_flow_statements (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER UNIQUE NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    -- Operating Activities
    net_income NUMERIC(20,2),
    depreciation_amortization NUMERIC(20,2),
    stock_compensation NUMERIC(20,2),
    deferred_tax NUMERIC(20,2),
    working_capital_changes NUMERIC(20,2),
    other_operating_activities NUMERIC(20,2),
    net_cash_from_operations NUMERIC(20,2),
    -- Investing Activities
    capital_expenditures NUMERIC(20,2),
    acquisitions NUMERIC(20,2),
    investments_purchased NUMERIC(20,2),
    investments_sold NUMERIC(20,2),
    other_investing_activities NUMERIC(20,2),
    net_cash_from_investing NUMERIC(20,2),
    -- Financing Activities
    debt_issued NUMERIC(20,2),
    debt_repaid NUMERIC(20,2),
    equity_issued NUMERIC(20,2),
    equity_repurchased NUMERIC(20,2),
    dividends_paid NUMERIC(20,2),
    other_financing_activities NUMERIC(20,2),
    net_cash_from_financing NUMERIC(20,2),
    -- Summary
    net_change_in_cash NUMERIC(20,2),
    cash_beginning_period NUMERIC(20,2),
    cash_end_period NUMERIC(20,2),
    free_cash_flow NUMERIC(20,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Financial ratios
CREATE TABLE IF NOT EXISTS financial_ratios (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER UNIQUE NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    -- Profitability Ratios
    gross_margin NUMERIC(8,4),
    operating_margin NUMERIC(8,4),
    net_margin NUMERIC(8,4),
    return_on_assets NUMERIC(8,4),
    return_on_equity NUMERIC(8,4),
    return_on_invested_capital NUMERIC(8,4),
    -- Liquidity Ratios
    current_ratio NUMERIC(8,4),
    quick_ratio NUMERIC(8,4),
    cash_ratio NUMERIC(8,4),
    -- Leverage Ratios
    debt_to_equity NUMERIC(8,4),
    debt_to_assets NUMERIC(8,4),
    interest_coverage NUMERIC(8,4),
    debt_service_coverage NUMERIC(8,4),
    -- Efficiency Ratios
    asset_turnover NUMERIC(8,4),
    inventory_turnover NUMERIC(8,4),
    receivables_turnover NUMERIC(8,4),
    payables_turnover NUMERIC(8,4),
    -- Valuation Ratios
    price_to_earnings NUMERIC(8,4),
    price_to_book NUMERIC(8,4),
    price_to_sales NUMERIC(8,4),
    price_to_cash_flow NUMERIC(8,4),
    enterprise_value_revenue NUMERIC(8,4),
    enterprise_value_ebitda NUMERIC(8,4),
    -- Growth Ratios
    revenue_growth NUMERIC(8,4),
    earnings_growth NUMERIC(8,4),
    book_value_growth NUMERIC(8,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 6. SCREENING AND BACKTESTING TABLES
-- =============================================

-- Strategies table
CREATE TABLE IF NOT EXISTS strategies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parameters JSONB,
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Backtests table
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
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Backtest trades
CREATE TABLE IF NOT EXISTS backtest_trades (
    id SERIAL PRIMARY KEY,
    backtest_id INTEGER REFERENCES backtests(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
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
    created_at TIMESTAMP DEFAULT NOW()
);

-- Backtest equity curve
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
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(backtest_id, trade_date)
);

-- Screens table
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

-- Screen results
CREATE TABLE IF NOT EXISTS screen_results (
    id SERIAL PRIMARY KEY,
    screen_id INTEGER REFERENCES screens(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    scan_date DATE NOT NULL,
    score NUMERIC(8,4),
    criteria_met JSONB,
    market_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(screen_id, symbol_id, scan_date)
);

-- Watchlists
CREATE TABLE IF NOT EXISTS watchlists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Watchlist symbols
CREATE TABLE IF NOT EXISTS watchlist_symbols (
    id SERIAL PRIMARY KEY,
    watchlist_id INTEGER REFERENCES watchlists(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    added_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    target_price NUMERIC(12,4),
    stop_loss NUMERIC(12,4),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(watchlist_id, symbol_id)
);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER REFERENCES securities(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,
    condition_type VARCHAR(20) NOT NULL CHECK (condition_type IN ('above', 'below', 'crosses_above', 'crosses_below')),
    target_value NUMERIC(12,4) NOT NULL,
    current_value NUMERIC(12,4),
    is_triggered BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(100),
    triggered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- 7. USER MANAGEMENT TABLES
-- =============================================

-- Users table
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

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(50),
    action VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Role permissions
CREATE TABLE IF NOT EXISTS role_permissions (
    id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

-- User roles
CREATE TABLE IF NOT EXISTS user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_by BIGINT REFERENCES users(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    UNIQUE(user_id, role_id)
);

-- User sessions
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

-- =============================================
-- 8. INDEXES FOR PERFORMANCE
-- =============================================

-- OHLCV indexes
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_security_date ON ohlcv_daily(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_date ON ohlcv_daily(trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_daily_volume ON ohlcv_daily(volume DESC);

CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_security_time ON ohlcv_intraday(security_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ohlcv_intraday_timestamp ON ohlcv_intraday(timestamp DESC);

-- Technical indicators indexes
CREATE INDEX IF NOT EXISTS idx_technical_indicators_security_date ON technical_indicators(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_rsi ON technical_indicators(rsi_14);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_macd ON technical_indicators(macd);

-- Securities indexes
CREATE INDEX IF NOT EXISTS idx_securities_symbol ON securities(symbol);
CREATE INDEX IF NOT EXISTS idx_securities_exchange ON securities(exchange_id);
CREATE INDEX IF NOT EXISTS idx_securities_company ON securities(company_id);
CREATE INDEX IF NOT EXISTS idx_securities_active ON securities(is_active);
CREATE INDEX IF NOT EXISTS idx_securities_type ON securities(security_type_id);

-- Companies indexes
CREATE INDEX IF NOT EXISTS idx_companies_sector ON companies(sector_id);
CREATE INDEX IF NOT EXISTS idx_companies_industry ON companies(industry_id);
CREATE INDEX IF NOT EXISTS idx_companies_country ON companies(headquarters_country_id);
CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(is_active);
CREATE INDEX IF NOT EXISTS idx_companies_public ON companies(is_public);

-- Financial data indexes
CREATE INDEX IF NOT EXISTS idx_financial_periods_company ON financial_periods(company_id);
CREATE INDEX IF NOT EXISTS idx_financial_periods_year_quarter ON financial_periods(fiscal_year, fiscal_quarter);
CREATE INDEX IF NOT EXISTS idx_income_statements_period ON income_statements(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_balance_sheets_period ON balance_sheets(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_cash_flow_statements_period ON cash_flow_statements(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_financial_ratios_period ON financial_ratios(financial_period_id);

-- Backtesting indexes
CREATE INDEX IF NOT EXISTS idx_backtests_strategy ON backtests(strategy_id);
CREATE INDEX IF NOT EXISTS idx_backtests_status ON backtests(status);
CREATE INDEX IF NOT EXISTS idx_backtests_dates ON backtests(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_backtest ON backtest_trades(backtest_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_symbol ON backtest_trades(symbol_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_dates ON backtest_trades(entry_date, exit_date);
CREATE INDEX IF NOT EXISTS idx_backtest_equity_backtest_date ON backtest_equity_curve(backtest_id, trade_date);

-- Screening indexes
CREATE INDEX IF NOT EXISTS idx_screens_active ON screens(is_active);
CREATE INDEX IF NOT EXISTS idx_screen_results_screen_date ON screen_results(screen_id, scan_date);
CREATE INDEX IF NOT EXISTS idx_screen_results_symbol ON screen_results(symbol_id);
CREATE INDEX IF NOT EXISTS idx_screen_results_score ON screen_results(score);

-- Watchlist indexes
CREATE INDEX IF NOT EXISTS idx_watchlists_created_by ON watchlists(created_by);
CREATE INDEX IF NOT EXISTS idx_watchlist_symbols_watchlist ON watchlist_symbols(watchlist_id);

-- Alert indexes
CREATE INDEX IF NOT EXISTS idx_alerts_symbol ON alerts(symbol_id);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered ON alerts(is_triggered);

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_verified ON users(is_verified);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(is_active);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_companies_name_trgm ON companies USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_securities_name_trgm ON securities USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_securities_symbol_trgm ON securities USING gin(symbol gin_trgm_ops);