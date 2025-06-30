-- ClickHouse Schema for Stock Screening System
USE stockdb;

-- Companies table
CREATE TABLE IF NOT EXISTS companies (
    id UInt32,
    cik String,
    lei String,
    name String,
    legal_name String,
    short_name String,
    former_names Array(String),
    sector_id UInt32,
    industry_id UInt32,
    sub_industry String,
    headquarters_country_id UInt32,
    headquarters_address String,
    incorporation_country_id UInt32,
    incorporation_date Date,
    business_description String,
    website String,
    phone String,
    email String,
    employee_count UInt32,
    fiscal_year_end String,
    is_active UInt8 DEFAULT 1,
    is_public UInt8 DEFAULT 1,
    delisting_date Date,
    delisting_reason String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Securities table
CREATE TABLE IF NOT EXISTS securities (
    id UInt32,
    company_id UInt32,
    security_type_id UInt32,
    symbol String,
    isin String,
    cusip String,
    sedol String,
    exchange_id UInt32,
    currency_id UInt32,
    name String,
    description String,
    shares_outstanding UInt64,
    shares_float UInt64,
    par_value Decimal(15, 4),
    is_active UInt8 DEFAULT 1,
    listing_date Date,
    delisting_date Date,
    trading_status String DEFAULT 'ACTIVE',
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (symbol, exchange_id)
SETTINGS index_granularity = 8192;

-- OHLCV Daily data (partitioned by date for performance)
CREATE TABLE IF NOT EXISTS ohlcv_daily (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    open_price Decimal(15, 4),
    high_price Decimal(15, 4),
    low_price Decimal(15, 4),
    close_price Decimal(15, 4),
    adjusted_close Decimal(15, 4),
    volume UInt64 DEFAULT 0,
    volume_weighted_price Decimal(15, 4),
    trade_count UInt32,
    turnover Decimal(20, 4),
    data_source String,
    data_quality_score Decimal(3, 2),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date)
SETTINGS index_granularity = 8192;

-- OHLCV Intraday data (partitioned by date)
CREATE TABLE IF NOT EXISTS ohlcv_intraday (
    id UInt64,
    security_id UInt32,
    timestamp DateTime,
    open_price Decimal(15, 4),
    high_price Decimal(15, 4),
    low_price Decimal(15, 4),
    close_price Decimal(15, 4),
    volume UInt64 DEFAULT 0,
    volume_weighted_price Decimal(15, 4),
    trade_count UInt32,
    bid_price Decimal(15, 4),
    ask_price Decimal(15, 4),
    bid_size UInt32,
    ask_size UInt32,
    spread Decimal(15, 4),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (security_id, timestamp)
SETTINGS index_granularity = 8192;

-- Technical Indicators (partitioned by date)
CREATE TABLE IF NOT EXISTS technical_indicators (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    sma_5 Decimal(15, 4),
    sma_10 Decimal(15, 4),
    sma_20 Decimal(15, 4),
    sma_50 Decimal(15, 4),
    sma_100 Decimal(15, 4),
    sma_200 Decimal(15, 4),
    ema_5 Decimal(15, 4),
    ema_10 Decimal(15, 4),
    ema_12 Decimal(15, 4),
    ema_20 Decimal(15, 4),
    ema_26 Decimal(15, 4),
    ema_50 Decimal(15, 4),
    ema_100 Decimal(15, 4),
    ema_200 Decimal(15, 4),
    rsi_14 Decimal(8, 4),
    rsi_21 Decimal(8, 4),
    stoch_k Decimal(8, 4),
    stoch_d Decimal(8, 4),
    williams_r Decimal(8, 4),
    macd Decimal(15, 4),
    macd_signal Decimal(15, 4),
    macd_histogram Decimal(15, 4),
    bb_upper Decimal(15, 4),
    bb_middle Decimal(15, 4),
    bb_lower Decimal(15, 4),
    bb_width Decimal(8, 4),
    bb_percent Decimal(8, 4),
    volume_sma_20 UInt64,
    volume_ratio Decimal(8, 4),
    on_balance_volume Int64,
    accumulation_distribution Decimal(20, 4),
    chaikin_money_flow Decimal(8, 4),
    volume_price_trend Decimal(20, 4),
    atr_14 Decimal(15, 4),
    atr_21 Decimal(15, 4),
    true_range Decimal(15, 4),
    volatility_10d Decimal(8, 4),
    volatility_30d Decimal(8, 4),
    adx_14 Decimal(8, 4),
    di_plus Decimal(8, 4),
    di_minus Decimal(8, 4),
    aroon_up Decimal(8, 4),
    aroon_down Decimal(8, 4),
    aroon_oscillator Decimal(8, 4),
    pivot_point Decimal(15, 4),
    resistance_1 Decimal(15, 4),
    resistance_2 Decimal(15, 4),
    resistance_3 Decimal(15, 4),
    support_1 Decimal(15, 4),
    support_2 Decimal(15, 4),
    support_3 Decimal(15, 4),
    price_vs_sma20 Decimal(8, 4),
    price_vs_sma50 Decimal(8, 4),
    price_vs_sma200 Decimal(8, 4),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date)
SETTINGS index_granularity = 8192;

-- News Articles (partitioned by date)
CREATE TABLE IF NOT EXISTS news_articles (
    id UInt64,
    title String,
    summary String,
    content String,
    url String,
    news_source_id UInt32,
    author String,
    news_category_id UInt32,
    tags Array(String),
    published_at DateTime,
    updated_at DateTime,
    word_count UInt32,
    reading_time_minutes UInt32,
    language String DEFAULT 'en',
    view_count UInt32 DEFAULT 0,
    share_count UInt32 DEFAULT 0,
    comment_count UInt32 DEFAULT 0,
    is_duplicate UInt8 DEFAULT 0,
    duplicate_of UInt64,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(published_at)
ORDER BY (published_at, id)
SETTINGS index_granularity = 8192;

-- News Sentiment (partitioned by date)
CREATE TABLE IF NOT EXISTS news_sentiment (
    id UInt64,
    news_article_id UInt64,
    company_id UInt32,
    overall_sentiment Decimal(3, 2),
    sentiment_label String,
    confidence_score Decimal(3, 2),
    positive_score Decimal(3, 2),
    negative_score Decimal(3, 2),
    neutral_score Decimal(3, 2),
    analysis_model String,
    analysis_date DateTime DEFAULT now(),
    key_phrases Array(String),
    named_entities String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(analysis_date)
ORDER BY (news_article_id, company_id)
SETTINGS index_granularity = 8192;

-- Backtests
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

-- Backtest Trades
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
    entry_signal String,
    exit_signal String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (backtest_id, entry_date)
SETTINGS index_granularity = 8192;

-- Backtest Equity Curve
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

-- Watchlists
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

-- Watchlist Symbols
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

-- Alerts
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

-- Users
CREATE TABLE IF NOT EXISTS users (
    id UInt64,
    username String,
    email String,
    password_hash String,
    salt String,
    first_name String,
    last_name String,
    display_name String,
    is_active UInt8 DEFAULT 1,
    is_verified UInt8 DEFAULT 0,
    is_locked UInt8 DEFAULT 0,
    failed_login_attempts UInt32 DEFAULT 0,
    last_login_at DateTime,
    password_changed_at DateTime DEFAULT now(),
    email_verification_token String,
    email_verified_at DateTime,
    password_reset_token String,
    password_reset_expires_at DateTime,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Strategies
CREATE TABLE IF NOT EXISTS strategies (
    id UInt32,
    name String,
    description String,
    parameters String,
    created_by String,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Screens
CREATE TABLE IF NOT EXISTS screens (
    id UInt32,
    name String,
    description String,
    criteria String,
    created_by String,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Screen Results
CREATE TABLE IF NOT EXISTS screen_results (
    id UInt32,
    screen_id UInt32,
    symbol_id UInt32,
    scan_date Date,
    score Decimal(8, 4),
    criteria_met String,
    market_data String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (screen_id, scan_date, score DESC)
SETTINGS index_granularity = 8192;