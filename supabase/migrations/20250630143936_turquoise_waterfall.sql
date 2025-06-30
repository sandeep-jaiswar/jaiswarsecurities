/*
  # Technical Analysis Tables
  
  1. Technical Indicators
    - technical_indicators: Comprehensive technical indicators
    - custom_indicators: User-defined indicators
    - indicator_definitions: Metadata for indicators
  
  2. Chart Patterns
    - chart_patterns: Detected chart patterns
    - pattern_types: Pattern definitions
  
  3. Support/Resistance
    - support_resistance_levels: Key price levels
*/

-- Indicator definitions
CREATE TABLE IF NOT EXISTS indicator_definitions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- TREND, MOMENTUM, VOLATILITY, VOLUME, OSCILLATOR
    formula TEXT,
    parameters JSONB, -- Default parameters
    data_type VARCHAR(20), -- PRICE, PERCENTAGE, RATIO, INDEX
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Technical indicators
CREATE TABLE IF NOT EXISTS technical_indicators (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    trade_date DATE NOT NULL,
    
    -- Moving Averages
    sma_5 DECIMAL(15,4),
    sma_10 DECIMAL(15,4),
    sma_20 DECIMAL(15,4),
    sma_50 DECIMAL(15,4),
    sma_100 DECIMAL(15,4),
    sma_200 DECIMAL(15,4),
    
    ema_5 DECIMAL(15,4),
    ema_10 DECIMAL(15,4),
    ema_12 DECIMAL(15,4),
    ema_20 DECIMAL(15,4),
    ema_26 DECIMAL(15,4),
    ema_50 DECIMAL(15,4),
    ema_100 DECIMAL(15,4),
    ema_200 DECIMAL(15,4),
    
    -- Momentum Indicators
    rsi_14 DECIMAL(8,4),
    rsi_21 DECIMAL(8,4),
    stoch_k DECIMAL(8,4),
    stoch_d DECIMAL(8,4),
    williams_r DECIMAL(8,4),
    
    -- MACD
    macd DECIMAL(15,4),
    macd_signal DECIMAL(15,4),
    macd_histogram DECIMAL(15,4),
    
    -- Bollinger Bands
    bb_upper DECIMAL(15,4),
    bb_middle DECIMAL(15,4),
    bb_lower DECIMAL(15,4),
    bb_width DECIMAL(8,4),
    bb_percent DECIMAL(8,4),
    
    -- Volume Indicators
    volume_sma_20 BIGINT,
    volume_ratio DECIMAL(8,4),
    on_balance_volume BIGINT,
    accumulation_distribution DECIMAL(20,4),
    chaikin_money_flow DECIMAL(8,4),
    volume_price_trend DECIMAL(20,4),
    
    -- Volatility Indicators
    atr_14 DECIMAL(15,4),
    atr_21 DECIMAL(15,4),
    true_range DECIMAL(15,4),
    volatility_10d DECIMAL(8,4),
    volatility_30d DECIMAL(8,4),
    
    -- Trend Indicators
    adx_14 DECIMAL(8,4),
    di_plus DECIMAL(8,4),
    di_minus DECIMAL(8,4),
    aroon_up DECIMAL(8,4),
    aroon_down DECIMAL(8,4),
    aroon_oscillator DECIMAL(8,4),
    
    -- Price Action
    pivot_point DECIMAL(15,4),
    resistance_1 DECIMAL(15,4),
    resistance_2 DECIMAL(15,4),
    resistance_3 DECIMAL(15,4),
    support_1 DECIMAL(15,4),
    support_2 DECIMAL(15,4),
    support_3 DECIMAL(15,4),
    
    -- Custom calculations
    price_vs_sma20 DECIMAL(8,4), -- (price - sma20) / sma20 * 100
    price_vs_sma50 DECIMAL(8,4),
    price_vs_sma200 DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, trade_date)
);

-- Custom indicators (user-defined)
CREATE TABLE IF NOT EXISTS custom_indicators (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    indicator_definition_id INTEGER REFERENCES indicator_definitions(id),
    trade_date DATE NOT NULL,
    
    indicator_name VARCHAR(100) NOT NULL,
    value DECIMAL(20,8),
    parameters JSONB,
    calculation_method TEXT,
    
    created_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(security_id, trade_date, indicator_name, created_by)
);

-- Pattern types
CREATE TABLE IF NOT EXISTS pattern_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- REVERSAL, CONTINUATION, BILATERAL
    description TEXT,
    bullish_probability DECIMAL(5,2), -- Historical success rate
    bearish_probability DECIMAL(5,2),
    min_periods INTEGER, -- Minimum periods to form pattern
    max_periods INTEGER, -- Maximum periods to form pattern
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chart patterns
CREATE TABLE IF NOT EXISTS chart_patterns (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    pattern_type_id INTEGER REFERENCES pattern_types(id),
    
    -- Pattern timing
    start_date DATE NOT NULL,
    end_date DATE,
    detection_date DATE NOT NULL,
    
    -- Pattern characteristics
    pattern_name VARCHAR(100) NOT NULL,
    confidence_score DECIMAL(5,2), -- 0-100
    strength VARCHAR(20), -- WEAK, MODERATE, STRONG
    direction VARCHAR(20), -- BULLISH, BEARISH, NEUTRAL
    
    -- Price levels
    breakout_price DECIMAL(15,4),
    target_price DECIMAL(15,4),
    stop_loss_price DECIMAL(15,4),
    
    -- Pattern data
    key_points JSONB, -- Array of {date, price, type} objects
    volume_confirmation BOOLEAN DEFAULT FALSE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, COMPLETED, FAILED, INVALIDATED
    completion_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support and resistance levels
CREATE TABLE IF NOT EXISTS support_resistance_levels (
    id BIGSERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL REFERENCES securities(id) ON DELETE CASCADE,
    
    -- Level details
    price_level DECIMAL(15,4) NOT NULL,
    level_type VARCHAR(20) NOT NULL, -- SUPPORT, RESISTANCE
    strength INTEGER NOT NULL, -- 1-10 scale
    
    -- Formation details
    first_touch_date DATE NOT NULL,
    last_touch_date DATE NOT NULL,
    touch_count INTEGER NOT NULL,
    
    -- Validation
    is_active BOOLEAN DEFAULT TRUE,
    break_date DATE,
    break_volume BIGINT,
    
    -- Additional data
    time_frame VARCHAR(20), -- DAILY, WEEKLY, MONTHLY
    formation_method VARCHAR(50), -- SWING_POINTS, VOLUME_PROFILE, FIBONACCI
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for technical analysis
CREATE INDEX IF NOT EXISTS idx_technical_indicators_security_date ON technical_indicators(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_rsi ON technical_indicators(rsi_14);
CREATE INDEX IF NOT EXISTS idx_technical_indicators_macd ON technical_indicators(macd);

CREATE INDEX IF NOT EXISTS idx_custom_indicators_security_date ON custom_indicators(security_id, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_custom_indicators_name ON custom_indicators(indicator_name);

CREATE INDEX IF NOT EXISTS idx_chart_patterns_security ON chart_patterns(security_id);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_type ON chart_patterns(pattern_type_id);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_detection_date ON chart_patterns(detection_date DESC);
CREATE INDEX IF NOT EXISTS idx_chart_patterns_status ON chart_patterns(status);

CREATE INDEX IF NOT EXISTS idx_support_resistance_security ON support_resistance_levels(security_id);
CREATE INDEX IF NOT EXISTS idx_support_resistance_price ON support_resistance_levels(price_level);
CREATE INDEX IF NOT EXISTS idx_support_resistance_active ON support_resistance_levels(is_active);