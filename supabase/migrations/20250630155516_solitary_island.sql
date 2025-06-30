-- ClickHouse Technical Indicators Tables
-- Comprehensive technical analysis data

USE stockdb;

-- Technical Indicators table (partitioned by month)
CREATE TABLE IF NOT EXISTS technical_indicators (
    id UInt64,
    security_id UInt32,
    trade_date Date,
    -- Simple Moving Averages
    sma_5 Decimal(15, 4),
    sma_10 Decimal(15, 4),
    sma_20 Decimal(15, 4),
    sma_50 Decimal(15, 4),
    sma_100 Decimal(15, 4),
    sma_200 Decimal(15, 4),
    -- Exponential Moving Averages
    ema_5 Decimal(15, 4),
    ema_10 Decimal(15, 4),
    ema_12 Decimal(15, 4),
    ema_20 Decimal(15, 4),
    ema_26 Decimal(15, 4),
    ema_50 Decimal(15, 4),
    ema_100 Decimal(15, 4),
    ema_200 Decimal(15, 4),
    -- Momentum Indicators
    rsi_14 Decimal(8, 4),
    rsi_21 Decimal(8, 4),
    stoch_k Decimal(8, 4),
    stoch_d Decimal(8, 4),
    williams_r Decimal(8, 4),
    -- MACD
    macd Decimal(15, 4),
    macd_signal Decimal(15, 4),
    macd_histogram Decimal(15, 4),
    -- Bollinger Bands
    bb_upper Decimal(15, 4),
    bb_middle Decimal(15, 4),
    bb_lower Decimal(15, 4),
    bb_width Decimal(8, 4),
    bb_percent Decimal(8, 4),
    -- Volume Indicators
    volume_sma_20 UInt64,
    volume_ratio Decimal(8, 4),
    on_balance_volume Int64,
    accumulation_distribution Decimal(20, 4),
    chaikin_money_flow Decimal(8, 4),
    volume_price_trend Decimal(20, 4),
    -- Volatility Indicators
    atr_14 Decimal(15, 4),
    atr_21 Decimal(15, 4),
    true_range Decimal(15, 4),
    volatility_10d Decimal(8, 4),
    volatility_30d Decimal(8, 4),
    -- Trend Indicators
    adx_14 Decimal(8, 4),
    di_plus Decimal(8, 4),
    di_minus Decimal(8, 4),
    aroon_up Decimal(8, 4),
    aroon_down Decimal(8, 4),
    aroon_oscillator Decimal(8, 4),
    -- Support/Resistance
    pivot_point Decimal(15, 4),
    resistance_1 Decimal(15, 4),
    resistance_2 Decimal(15, 4),
    resistance_3 Decimal(15, 4),
    support_1 Decimal(15, 4),
    support_2 Decimal(15, 4),
    support_3 Decimal(15, 4),
    -- Price Comparisons
    price_vs_sma20 Decimal(8, 4),
    price_vs_sma50 Decimal(8, 4),
    price_vs_sma200 Decimal(8, 4),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date)
SETTINGS index_granularity = 8192;

-- Custom Indicators table
CREATE TABLE IF NOT EXISTS custom_indicators (
    id UInt64,
    security_id UInt32,
    indicator_definition_id UInt32,
    trade_date Date,
    indicator_name String,
    value Decimal(20, 8),
    parameters String, -- JSON as String
    calculation_method String,
    created_by String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(trade_date)
ORDER BY (security_id, trade_date, indicator_name)
SETTINGS index_granularity = 8192;

-- Indicator Definitions table
CREATE TABLE IF NOT EXISTS indicator_definitions (
    id UInt32,
    code String,
    name String,
    description String,
    category String,
    formula String,
    parameters String, -- JSON as String
    data_type String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Chart Patterns table
CREATE TABLE IF NOT EXISTS chart_patterns (
    id UInt64,
    security_id UInt32,
    pattern_type_id UInt32,
    start_date Date,
    end_date Date,
    detection_date Date,
    pattern_name String,
    confidence_score Decimal(5, 2),
    strength String,
    direction String,
    breakout_price Decimal(15, 4),
    target_price Decimal(15, 4),
    stop_loss_price Decimal(15, 4),
    key_points String, -- JSON as String
    volume_confirmation UInt8 DEFAULT 0,
    status String DEFAULT 'ACTIVE',
    completion_date Date,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(detection_date)
ORDER BY (security_id, detection_date)
SETTINGS index_granularity = 8192;

-- Pattern Types table
CREATE TABLE IF NOT EXISTS pattern_types (
    id UInt32,
    code String,
    name String,
    category String,
    description String,
    bullish_probability Decimal(5, 2),
    bearish_probability Decimal(5, 2),
    min_periods UInt32,
    max_periods UInt32,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Support/Resistance Levels table
CREATE TABLE IF NOT EXISTS support_resistance_levels (
    id UInt64,
    security_id UInt32,
    price_level Decimal(15, 4),
    level_type String,
    strength UInt32,
    first_touch_date Date,
    last_touch_date Date,
    touch_count UInt32,
    is_active UInt8 DEFAULT 1,
    break_date Date,
    break_volume UInt64,
    time_frame String,
    formation_method String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (security_id, price_level)
SETTINGS index_granularity = 8192;