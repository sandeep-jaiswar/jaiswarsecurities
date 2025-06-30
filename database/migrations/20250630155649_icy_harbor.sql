-- ClickHouse Screening and Backtesting Tables
-- Comprehensive screening and strategy testing infrastructure

USE stockdb;

-- Strategies table
CREATE TABLE IF NOT EXISTS strategies (
    id UInt32,
    name String,
    description String,
    parameters String, -- JSON as String
    created_by String,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Backtests table
CREATE TABLE IF NOT EXISTS backtests (
    id UInt32,
    strategy_id UInt32,
    name String,
    start_date Date,
    end_date Date,
    initial_capital Decimal(15, 2),
    commission Decimal(8, 6) DEFAULT 0.001,
    slippage Decimal(8, 6) DEFAULT 0.001,
    status String DEFAULT 'pending',
    total_return Decimal(10, 4),
    annual_return Decimal(10, 4),
    max_drawdown Decimal(10, 4),
    sharpe_ratio Decimal(8, 4),
    sortino_ratio Decimal(8, 4),
    win_rate Decimal(8, 4),
    profit_factor Decimal(8, 4),
    total_trades UInt32,
    winning_trades UInt32,
    losing_trades UInt32,
    avg_win Decimal(12, 4),
    avg_loss Decimal(12, 4),
    largest_win Decimal(12, 4),
    largest_loss Decimal(12, 4),
    created_at DateTime DEFAULT now(),
    completed_at DateTime
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Backtest Trades table
CREATE TABLE IF NOT EXISTS backtest_trades (
    id UInt32,
    backtest_id UInt32,
    symbol_id UInt32,
    entry_date Date,
    exit_date Date,
    side String,
    entry_price Decimal(12, 4),
    exit_price Decimal(12, 4),
    quantity UInt32,
    commission Decimal(12, 4) DEFAULT 0,
    pnl Decimal(12, 4),
    pnl_percent Decimal(8, 4),
    status String DEFAULT 'open',
    entry_signal String, -- JSON as String
    exit_signal String, -- JSON as String
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (backtest_id, entry_date)
SETTINGS index_granularity = 8192;

-- Backtest Equity Curve table
CREATE TABLE IF NOT EXISTS backtest_equity_curve (
    id UInt32,
    backtest_id UInt32,
    trade_date Date,
    portfolio_value Decimal(15, 2),
    cash Decimal(15, 2),
    positions_value Decimal(15, 2),
    daily_return Decimal(10, 6),
    cumulative_return Decimal(10, 6),
    drawdown Decimal(10, 6),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (backtest_id, trade_date)
SETTINGS index_granularity = 8192;

-- Screens table
CREATE TABLE IF NOT EXISTS screens (
    id UInt32,
    name String,
    description String,
    criteria String, -- JSON as String
    created_by String,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Screen Results table
CREATE TABLE IF NOT EXISTS screen_results (
    id UInt32,
    screen_id UInt32,
    symbol_id UInt32,
    scan_date Date,
    score Decimal(8, 4),
    criteria_met String, -- JSON as String
    market_data String, -- JSON as String
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(scan_date)
ORDER BY (screen_id, scan_date, score DESC)
SETTINGS index_granularity = 8192;

-- Watchlists table
CREATE TABLE IF NOT EXISTS watchlists (
    id UInt32,
    name String,
    description String,
    created_by String,
    is_public UInt8 DEFAULT 0,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Watchlist Symbols table
CREATE TABLE IF NOT EXISTS watchlist_symbols (
    id UInt32,
    watchlist_id UInt32,
    symbol_id UInt32,
    added_date Date DEFAULT today(),
    notes String,
    target_price Decimal(12, 4),
    stop_loss Decimal(12, 4),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (watchlist_id, symbol_id)
SETTINGS index_granularity = 8192;

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id UInt32,
    symbol_id UInt32,
    alert_type String,
    condition_type String,
    target_value Decimal(12, 4),
    current_value Decimal(12, 4),
    is_triggered UInt8 DEFAULT 0,
    is_active UInt8 DEFAULT 1,
    created_by String,
    triggered_at DateTime,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;