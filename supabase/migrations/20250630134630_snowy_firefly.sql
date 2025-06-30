--liquibase formatted sql

--changeset architect:003-add-backtesting-tables
--comment: Create tables for backtesting functionality

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

CREATE TABLE IF NOT EXISTS backtests (
    id SERIAL PRIMARY KEY,
    strategy_id INTEGER REFERENCES strategies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    initial_capital DECIMAL(15, 2) NOT NULL,
    commission DECIMAL(8, 6) DEFAULT 0.001,
    slippage DECIMAL(8, 6) DEFAULT 0.001,
    status VARCHAR(20) DEFAULT 'pending',
    total_return DECIMAL(10, 4),
    annual_return DECIMAL(10, 4),
    max_drawdown DECIMAL(10, 4),
    sharpe_ratio DECIMAL(8, 4),
    sortino_ratio DECIMAL(8, 4),
    win_rate DECIMAL(8, 4),
    profit_factor DECIMAL(8, 4),
    total_trades INTEGER,
    winning_trades INTEGER,
    losing_trades INTEGER,
    avg_win DECIMAL(12, 4),
    avg_loss DECIMAL(12, 4),
    largest_win DECIMAL(12, 4),
    largest_loss DECIMAL(12, 4),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS backtest_trades (
    id SERIAL PRIMARY KEY,
    backtest_id INTEGER REFERENCES backtests(id) ON DELETE CASCADE,
    symbol_id INTEGER REFERENCES symbols(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    exit_date DATE,
    side VARCHAR(10) NOT NULL CHECK (side IN ('long', 'short')),
    entry_price DECIMAL(12, 4) NOT NULL,
    exit_price DECIMAL(12, 4),
    quantity INTEGER NOT NULL,
    commission DECIMAL(12, 4) DEFAULT 0,
    pnl DECIMAL(12, 4),
    pnl_percent DECIMAL(8, 4),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    entry_signal JSONB,
    exit_signal JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS backtest_equity_curve (
    id SERIAL PRIMARY KEY,
    backtest_id INTEGER REFERENCES backtests(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    portfolio_value DECIMAL(15, 2) NOT NULL,
    cash DECIMAL(15, 2) NOT NULL,
    positions_value DECIMAL(15, 2) NOT NULL,
    daily_return DECIMAL(10, 6),
    cumulative_return DECIMAL(10, 6),
    drawdown DECIMAL(10, 6),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(backtest_id, trade_date)
);

-- Insert sample strategies
INSERT INTO strategies (name, description, parameters) VALUES
('Simple Moving Average Crossover', 'Buy when short MA crosses above long MA, sell when opposite', 
 '{"short_ma": 20, "long_ma": 50, "stop_loss": 0.05, "take_profit": 0.15}'),
('RSI Mean Reversion', 'Buy when RSI < 30, sell when RSI > 70',
 '{"rsi_period": 14, "oversold": 30, "overbought": 70, "stop_loss": 0.03}'),
('Bollinger Bands Breakout', 'Buy on upper band breakout, sell on lower band breakdown',
 '{"bb_period": 20, "bb_std": 2, "stop_loss": 0.04, "take_profit": 0.12}')
ON CONFLICT (name) DO NOTHING;

-- Indexes for backtesting tables
CREATE INDEX IF NOT EXISTS idx_backtests_strategy ON backtests(strategy_id);
CREATE INDEX IF NOT EXISTS idx_backtests_status ON backtests(status);
CREATE INDEX IF NOT EXISTS idx_backtests_dates ON backtests(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_backtest ON backtest_trades(backtest_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_symbol ON backtest_trades(symbol_id);
CREATE INDEX IF NOT EXISTS idx_backtest_trades_dates ON backtest_trades(entry_date, exit_date);
CREATE INDEX IF NOT EXISTS idx_backtest_equity_backtest_date ON backtest_equity_curve(backtest_id, trade_date);

--rollback DROP INDEX IF EXISTS idx_backtest_equity_backtest_date;
--rollback DROP INDEX IF EXISTS idx_backtest_trades_dates;
--rollback DROP INDEX IF EXISTS idx_backtest_trades_symbol;
--rollback DROP INDEX IF EXISTS idx_backtest_trades_backtest;
--rollback DROP INDEX IF EXISTS idx_backtests_dates;
--rollback DROP INDEX IF EXISTS idx_backtests_status;
--rollback DROP INDEX IF EXISTS idx_backtests_strategy;
--rollback DROP TABLE IF EXISTS backtest_equity_curve CASCADE;
--rollback DROP TABLE IF EXISTS backtest_trades CASCADE;
--rollback DROP TABLE IF EXISTS backtests CASCADE;
--rollback DROP TABLE IF EXISTS strategies CASCADE;