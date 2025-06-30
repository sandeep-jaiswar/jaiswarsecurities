/*
  # Screening and Backtesting Tables
  
  1. Screening System
    - screens: Screen definitions
    - screen_criteria: Individual screening criteria
    - screen_results: Screening results
    - screen_history: Historical screen performance
  
  2. Backtesting System
    - strategies: Trading strategies
    - backtests: Backtest configurations
    - backtest_trades: Individual trades
    - backtest_performance: Performance metrics
  
  3. Alerts and Monitoring
    - alerts: Price and indicator alerts
    - alert_history: Alert trigger history
    - watchlists: User watchlists
*/

-- Screen definitions
CREATE TABLE IF NOT EXISTS screens (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    
    -- Screen configuration
    criteria JSONB NOT NULL, -- Screening criteria in JSON format
    universe VARCHAR(50) DEFAULT 'ALL', -- ALL, SP500, NASDAQ, etc.
    
    -- Metadata
    created_by VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Performance tracking
    hit_rate DECIMAL(5,2), -- Percentage of successful picks
    avg_return DECIMAL(8,4), -- Average return of screened stocks
    last_run_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Screen criteria definitions
CREATE TABLE IF NOT EXISTS screen_criteria (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- FUNDAMENTAL, TECHNICAL, PRICE, VOLUME
    data_type VARCHAR(20), -- NUMERIC, BOOLEAN, STRING
    operator_types TEXT[], -- GREATER_THAN, LESS_THAN, EQUALS, BETWEEN, etc.
    default_value JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Screen results
CREATE TABLE IF NOT EXISTS screen_results (
    id BIGSERIAL PRIMARY KEY,
    screen_id INTEGER NOT NULL REFERENCES screens(id) ON DELETE CASCADE,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    
    -- Result details
    scan_date DATE NOT NULL,
    score DECIMAL(8,4), -- Overall score (0-100)
    rank INTEGER, -- Rank within the screen results
    
    -- Criteria evaluation
    criteria_met JSONB, -- Which criteria were met
    criteria_values JSONB, -- Actual values for each criterion
    
    -- Market data snapshot
    market_data JSONB, -- Price, volume, market cap at scan time
    
    -- Performance tracking
    price_at_scan DECIMAL(15,4),
    return_1d DECIMAL(8,4),
    return_1w DECIMAL(8,4),
    return_1m DECIMAL(8,4),
    return_3m DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(screen_id, security_id, scan_date)
);

-- Screen performance history
CREATE TABLE IF NOT EXISTS screen_history (
    id BIGSERIAL PRIMARY KEY,
    screen_id INTEGER NOT NULL REFERENCES screens(id) ON DELETE CASCADE,
    
    -- Performance period
    evaluation_date DATE NOT NULL,
    period_days INTEGER NOT NULL, -- 1, 7, 30, 90 days
    
    -- Performance metrics
    total_picks INTEGER,
    winning_picks INTEGER,
    losing_picks INTEGER,
    hit_rate DECIMAL(5,2),
    
    -- Return statistics
    avg_return DECIMAL(8,4),
    median_return DECIMAL(8,4),
    best_return DECIMAL(8,4),
    worst_return DECIMAL(8,4),
    
    -- Risk metrics
    volatility DECIMAL(8,4),
    sharpe_ratio DECIMAL(8,4),
    max_drawdown DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(screen_id, evaluation_date, period_days)
);

-- Trading strategies
CREATE TABLE IF NOT EXISTS strategies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    
    -- Strategy configuration
    strategy_type VARCHAR(50), -- TECHNICAL, FUNDAMENTAL, QUANTITATIVE, HYBRID
    parameters JSONB, -- Strategy parameters
    entry_rules JSONB, -- Entry conditions
    exit_rules JSONB, -- Exit conditions
    risk_management JSONB, -- Risk management rules
    
    -- Metadata
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Performance summary
    total_backtests INTEGER DEFAULT 0,
    avg_return DECIMAL(8,4),
    avg_sharpe_ratio DECIMAL(8,4),
    win_rate DECIMAL(5,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backtest configurations
CREATE TABLE IF NOT EXISTS backtests (
    id SERIAL PRIMARY KEY,
    strategy_id INTEGER REFERENCES strategies(id),
    name VARCHAR(100) NOT NULL,
    
    -- Backtest parameters
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    initial_capital DECIMAL(15,2) NOT NULL,
    commission DECIMAL(8,6) DEFAULT 0.001,
    slippage DECIMAL(8,6) DEFAULT 0.001,
    
    -- Universe and constraints
    universe VARCHAR(50) DEFAULT 'ALL',
    max_positions INTEGER DEFAULT 10,
    position_sizing VARCHAR(20) DEFAULT 'EQUAL', -- EQUAL, MARKET_CAP, VOLATILITY
    
    -- Status and results
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, RUNNING, COMPLETED, FAILED
    
    -- Performance metrics
    total_return DECIMAL(10,4),
    annual_return DECIMAL(10,4),
    max_drawdown DECIMAL(10,4),
    sharpe_ratio DECIMAL(8,4),
    sortino_ratio DECIMAL(8,4),
    calmar_ratio DECIMAL(8,4),
    
    -- Trade statistics
    total_trades INTEGER,
    winning_trades INTEGER,
    losing_trades INTEGER,
    win_rate DECIMAL(8,4),
    profit_factor DECIMAL(8,4),
    
    -- Trade analysis
    avg_win DECIMAL(12,4),
    avg_loss DECIMAL(12,4),
    largest_win DECIMAL(12,4),
    largest_loss DECIMAL(12,4),
    avg_trade_duration DECIMAL(8,2), -- Days
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Backtest trades
CREATE TABLE IF NOT EXISTS backtest_trades (
    id BIGSERIAL PRIMARY KEY,
    backtest_id INTEGER NOT NULL REFERENCES backtests(id) ON DELETE CASCADE,
    security_id INTEGER REFERENCES securities(id),
    
    -- Trade details
    entry_date DATE NOT NULL,
    exit_date DATE,
    side VARCHAR(10) NOT NULL, -- LONG, SHORT
    
    -- Prices and quantities
    entry_price DECIMAL(12,4) NOT NULL,
    exit_price DECIMAL(12,4),
    quantity INTEGER NOT NULL,
    
    -- Costs
    commission DECIMAL(12,4) DEFAULT 0,
    slippage DECIMAL(12,4) DEFAULT 0,
    
    -- P&L
    pnl DECIMAL(12,4),
    pnl_percent DECIMAL(8,4),
    
    -- Trade metadata
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, CLOSED
    entry_signal JSONB, -- Entry signal details
    exit_signal JSONB, -- Exit signal details
    
    -- Risk management
    stop_loss_price DECIMAL(12,4),
    take_profit_price DECIMAL(12,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backtest equity curve
CREATE TABLE IF NOT EXISTS backtest_equity_curve (
    id BIGSERIAL PRIMARY KEY,
    backtest_id INTEGER NOT NULL REFERENCES backtests(id) ON DELETE CASCADE,
    
    -- Daily portfolio values
    trade_date DATE NOT NULL,
    portfolio_value DECIMAL(15,2) NOT NULL,
    cash DECIMAL(15,2) NOT NULL,
    positions_value DECIMAL(15,2) NOT NULL,
    
    -- Returns
    daily_return DECIMAL(10,6),
    cumulative_return DECIMAL(10,6),
    
    -- Risk metrics
    drawdown DECIMAL(10,6),
    rolling_volatility DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(backtest_id, trade_date)
);

-- Market data sources
CREATE TABLE IF NOT EXISTS market_data_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    api_endpoint VARCHAR(255),
    api_key_required BOOLEAN DEFAULT TRUE,
    rate_limit_per_minute INTEGER DEFAULT 60,
    cost_per_request DECIMAL(10,6),
    data_quality_score DECIMAL(3,2), -- 0.00 to 1.00
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    security_id INTEGER REFERENCES securities(id),
    
    -- Alert configuration
    alert_type VARCHAR(50) NOT NULL, -- PRICE, VOLUME, INDICATOR, NEWS
    condition_type VARCHAR(20) NOT NULL, -- ABOVE, BELOW, CROSSES_ABOVE, CROSSES_BELOW
    target_value DECIMAL(12,4) NOT NULL,
    
    -- Current state
    current_value DECIMAL(12,4),
    is_triggered BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_by VARCHAR(100),
    alert_message TEXT,
    
    -- Timing
    triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Alert history
CREATE TABLE IF NOT EXISTS alert_history (
    id BIGSERIAL PRIMARY KEY,
    alert_id INTEGER NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
    
    -- Trigger details
    triggered_at TIMESTAMPTZ NOT NULL,
    trigger_value DECIMAL(12,4) NOT NULL,
    market_data JSONB, -- Market context at trigger time
    
    -- Notification details
    notification_sent BOOLEAN DEFAULT FALSE,
    notification_method VARCHAR(50), -- EMAIL, SMS, PUSH, WEBHOOK
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchlists
CREATE TABLE IF NOT EXISTS watchlists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Metadata
    created_by VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    
    -- Performance tracking
    total_return DECIMAL(8,4),
    avg_return DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchlist securities
CREATE TABLE IF NOT EXISTS watchlist_securities (
    id BIGSERIAL PRIMARY KEY,
    watchlist_id INTEGER NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    
    -- Position details
    added_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    target_price DECIMAL(12,4),
    stop_loss DECIMAL(12,4),
    
    -- Performance tracking
    price_when_added DECIMAL(12,4),
    current_return DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(watchlist_id, security_id)
);

-- Indexes for screening and backtesting
CREATE INDEX IF NOT EXISTS idx_screens_active ON screens(is_active);
CREATE INDEX IF NOT EXISTS idx_screens_public ON screens(is_public);
CREATE INDEX IF NOT EXISTS idx_screens_created_by ON screens(created_by);

CREATE INDEX IF NOT EXISTS idx_screen_results_screen_date ON screen_results(screen_id, scan_date DESC);
CREATE INDEX IF NOT EXISTS idx_screen_results_security ON screen_results(security_id);
CREATE INDEX IF NOT EXISTS idx_screen_results_score ON screen_results(score DESC);

CREATE INDEX IF NOT EXISTS idx_strategies_active ON strategies(is_active);
CREATE INDEX IF NOT EXISTS idx_strategies_type ON strategies(strategy_type);

CREATE INDEX IF NOT EXISTS idx_backtests_strategy ON backtests(strategy_id);
CREATE INDEX IF NOT EXISTS idx_backtests_status ON backtests(status);
CREATE INDEX IF NOT EXISTS idx_backtests_dates ON backtests(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_backtest_trades_backtest ON backtest_trades(backtest_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_security ON backtest_trades(security_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_dates ON backtest_trades(entry_date, exit_date);

CREATE INDEX IF NOT EXISTS idx_backtest_equity_backtest_date ON backtest_equity_curve(backtest_id, trade_date);

CREATE INDEX IF NOT EXISTS idx_alerts_security ON alerts(security_id);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered ON alerts(is_triggered);

CREATE INDEX IF NOT EXISTS idx_watchlists_created_by ON watchlists(created_by);
CREATE INDEX IF NOT EXISTS idx_watchlist_securities_watchlist ON watchlist_securities(watchlist_id);