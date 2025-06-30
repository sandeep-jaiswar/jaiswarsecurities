/*
  # Seed data for stock screening system

  1. Sample Data
    - Insert 20 major stock symbols with realistic market data
    - Generate OHLCV data for the last 30 trading days
    - Create technical indicators for analysis
    - Set up sample strategies, screens, and watchlists

  2. Configuration
    - Market data sources configuration
    - Sample alerts and screening criteria
    - Backtest examples

  3. Performance
    - Update table statistics for optimal query performance
*/

-- Insert sample symbols
INSERT INTO symbols (symbol, yticker, name, exchange, industry, sector, market_cap) VALUES
('AAPL', 'AAPL', 'Apple Inc.', 'NASDAQ', 'Consumer Electronics', 'Technology', 3000000000000),
('MSFT', 'MSFT', 'Microsoft Corporation', 'NASDAQ', 'Software', 'Technology', 2800000000000),
('GOOGL', 'GOOGL', 'Alphabet Inc.', 'NASDAQ', 'Internet Services', 'Technology', 1800000000000),
('AMZN', 'AMZN', 'Amazon.com Inc.', 'NASDAQ', 'E-commerce', 'Consumer Discretionary', 1600000000000),
('TSLA', 'TSLA', 'Tesla Inc.', 'NASDAQ', 'Electric Vehicles', 'Consumer Discretionary', 800000000000),
('META', 'META', 'Meta Platforms Inc.', 'NASDAQ', 'Social Media', 'Technology', 900000000000),
('NVDA', 'NVDA', 'NVIDIA Corporation', 'NASDAQ', 'Semiconductors', 'Technology', 1200000000000),
('JPM', 'JPM', 'JPMorgan Chase & Co.', 'NYSE', 'Banking', 'Financial Services', 500000000000),
('JNJ', 'JNJ', 'Johnson & Johnson', 'NYSE', 'Pharmaceuticals', 'Healthcare', 450000000000),
('V', 'V', 'Visa Inc.', 'NYSE', 'Payment Processing', 'Financial Services', 480000000000),
('PG', 'PG', 'Procter & Gamble Co.', 'NYSE', 'Consumer Goods', 'Consumer Staples', 380000000000),
('UNH', 'UNH', 'UnitedHealth Group Inc.', 'NYSE', 'Health Insurance', 'Healthcare', 520000000000),
('HD', 'HD', 'Home Depot Inc.', 'NYSE', 'Home Improvement', 'Consumer Discretionary', 350000000000),
('MA', 'MA', 'Mastercard Inc.', 'NYSE', 'Payment Processing', 'Financial Services', 360000000000),
('DIS', 'DIS', 'Walt Disney Co.', 'NYSE', 'Entertainment', 'Communication Services', 200000000000),
('ADBE', 'ADBE', 'Adobe Inc.', 'NASDAQ', 'Software', 'Technology', 240000000000),
('NFLX', 'NFLX', 'Netflix Inc.', 'NASDAQ', 'Streaming', 'Communication Services', 180000000000),
('CRM', 'CRM', 'Salesforce Inc.', 'NYSE', 'Cloud Software', 'Technology', 220000000000),
('PYPL', 'PYPL', 'PayPal Holdings Inc.', 'NASDAQ', 'Payment Processing', 'Financial Services', 120000000000),
('INTC', 'INTC', 'Intel Corporation', 'NASDAQ', 'Semiconductors', 'Technology', 200000000000)
ON CONFLICT (symbol) DO NOTHING;

-- Insert sample OHLCV data (last 30 days for AAPL)
DO $$
DECLARE
    symbol_id_var INTEGER;
    date_var DATE;
    base_price NUMERIC(12,4) := 150.0000;
    price_var NUMERIC(12,4);
    volume_var BIGINT;
    i INTEGER;
BEGIN
    -- Get AAPL symbol ID
    SELECT id INTO symbol_id_var FROM symbols WHERE symbol = 'AAPL';
    
    -- Generate data for last 30 days
    FOR i IN 0..29 LOOP
        date_var := CURRENT_DATE - INTERVAL '1 day' * i;
        
        -- Skip weekends
        IF EXTRACT(DOW FROM date_var) NOT IN (0, 6) THEN
            -- Generate realistic price movement (keep within numeric(12,4) bounds)
            price_var := base_price + (RANDOM() - 0.5) * 10.0;
            -- Ensure price stays within bounds
            price_var := GREATEST(1.0000, LEAST(9999.9999, price_var));
            volume_var := 50000000 + (RANDOM() * 30000000)::BIGINT;
            
            INSERT INTO ohlcv (symbol_id, trade_date, open_price, high_price, low_price, close_price, adjusted_close, volume)
            VALUES (
                symbol_id_var,
                date_var,
                price_var,
                LEAST(9999.9999, price_var + (RANDOM() * 5.0)::NUMERIC(12,4)),
                GREATEST(1.0000, price_var - (RANDOM() * 5.0)::NUMERIC(12,4)),
                LEAST(9999.9999, price_var + (RANDOM() - 0.5) * 3.0),
                LEAST(9999.9999, price_var + (RANDOM() - 0.5) * 3.0),
                volume_var
            )
            ON CONFLICT (symbol_id, trade_date) DO NOTHING;
            
            -- Update base price for next day (keep within bounds)
            base_price := GREATEST(1.0000, LEAST(9999.9999, price_var + (RANDOM() - 0.5) * 2.0));
        END IF;
    END LOOP;
END $$;

-- Insert sample indicators data
DO $$
DECLARE
    symbol_id_var INTEGER;
    date_var DATE;
    close_price_var NUMERIC(12,4);
    i INTEGER;
BEGIN
    -- Get AAPL symbol ID
    SELECT id INTO symbol_id_var FROM symbols WHERE symbol = 'AAPL';
    
    -- Generate indicators for last 30 days
    FOR i IN 0..29 LOOP
        date_var := CURRENT_DATE - INTERVAL '1 day' * i;
        
        -- Skip weekends
        IF EXTRACT(DOW FROM date_var) NOT IN (0, 6) THEN
            -- Get close price for this date
            SELECT close_price INTO close_price_var 
            FROM ohlcv 
            WHERE symbol_id = symbol_id_var AND trade_date = date_var;
            
            IF close_price_var IS NOT NULL THEN
                INSERT INTO indicators (
                    symbol_id, trade_date, sma_20, sma_50, sma_200, ema_12, ema_26,
                    rsi_14, macd, macd_signal, macd_histogram,
                    bb_upper, bb_middle, bb_lower, stoch_k, stoch_d, williams_r, atr_14
                )
                VALUES (
                    symbol_id_var,
                    date_var,
                    LEAST(9999.9999, close_price_var + (RANDOM() - 0.5) * 2.0), -- SMA 20
                    LEAST(9999.9999, close_price_var + (RANDOM() - 0.5) * 3.0), -- SMA 50
                    LEAST(9999.9999, close_price_var + (RANDOM() - 0.5) * 5.0), -- SMA 200
                    LEAST(9999.9999, close_price_var + (RANDOM() - 0.5) * 1.0), -- EMA 12
                    LEAST(9999.9999, close_price_var + (RANDOM() - 0.5) * 2.0), -- EMA 26
                    (30.0 + RANDOM() * 40.0)::NUMERIC(8,4), -- RSI (30-70)
                    ((RANDOM() - 0.5) * 2.0)::NUMERIC(12,4), -- MACD
                    ((RANDOM() - 0.5) * 1.5)::NUMERIC(12,4), -- MACD Signal
                    ((RANDOM() - 0.5) * 0.5)::NUMERIC(12,4), -- MACD Histogram
                    LEAST(9999.9999, close_price_var + 5.0 + RANDOM() * 3.0), -- BB Upper
                    close_price_var, -- BB Middle
                    GREATEST(1.0000, close_price_var - 5.0 - RANDOM() * 3.0), -- BB Lower
                    (20.0 + RANDOM() * 60.0)::NUMERIC(8,4), -- Stoch K
                    (20.0 + RANDOM() * 60.0)::NUMERIC(8,4), -- Stoch D
                    (-80.0 + RANDOM() * 60.0)::NUMERIC(8,4), -- Williams R
                    (1.0 + RANDOM() * 3.0)::NUMERIC(12,4) -- ATR
                )
                ON CONFLICT (symbol_id, trade_date) DO NOTHING;
            END IF;
        END IF;
    END LOOP;
END $$;

-- Insert sample strategies
INSERT INTO strategies (name, description, parameters, created_by, is_active) VALUES
('Simple Moving Average Crossover', 'Buy when short MA crosses above long MA, sell when it crosses below', 
 '{"short_period": 20, "long_period": 50, "stop_loss": 0.05, "take_profit": 0.10}'::jsonb, 'system', true),
('RSI Mean Reversion', 'Buy when RSI is oversold, sell when overbought', 
 '{"oversold": 30, "overbought": 70, "stop_loss": 0.03}'::jsonb, 'system', true),
('Bollinger Bands Breakout', 'Buy on upper band breakout, sell on lower band breakdown', 
 '{"period": 20, "std_dev": 2, "stop_loss": 0.04, "take_profit": 0.08}'::jsonb, 'system', true),
('MACD Signal', 'Buy when MACD crosses above signal line, sell when below', 
 '{"fast_period": 12, "slow_period": 26, "signal_period": 9, "stop_loss": 0.05}'::jsonb, 'system', true)
ON CONFLICT (name) DO NOTHING;

-- Insert sample screens
INSERT INTO screens (name, description, criteria, created_by, is_active) VALUES
('High Volume Breakout', 'Stocks with high volume and price breakout', 
 '{"volume_ratio": {"min": 2.0}, "price_change": {"min": 0.05}, "rsi": {"max": 70}}'::jsonb, 'system', true),
('Oversold Value Stocks', 'Undervalued stocks with oversold RSI', 
 '{"rsi": {"max": 30}, "pe_ratio": {"max": 15}, "market_cap": {"min": 1000000000}}'::jsonb, 'system', true),
('Momentum Stocks', 'Stocks with strong momentum indicators', 
 '{"rsi": {"min": 60, "max": 80}, "macd": {"min": 0}, "price_change_20d": {"min": 0.10}}'::jsonb, 'system', true),
('Technical Breakout', 'Stocks breaking above resistance levels', 
 '{"price_vs_sma20": {"min": 1.02}, "volume_ratio": {"min": 1.5}, "rsi": {"min": 50}}'::jsonb, 'system', true)
ON CONFLICT (name) DO NOTHING;

-- Insert sample market data sources
INSERT INTO market_data_sources (name, api_endpoint, api_key_required, rate_limit_per_minute, is_active) VALUES
('Alpha Vantage', 'https://www.alphavantage.co/query', true, 5, true),
('Yahoo Finance', 'https://query1.finance.yahoo.com/v8/finance/chart', false, 2000, true),
('Polygon.io', 'https://api.polygon.io/v2', true, 1000, true),
('IEX Cloud', 'https://cloud.iexapis.com/stable', true, 100, true)
ON CONFLICT (name) DO NOTHING;

-- Insert sample watchlists
INSERT INTO watchlists (name, description, created_by, is_public) VALUES
('Tech Giants', 'Large technology companies', 'system', true),
('Dividend Aristocrats', 'Companies with consistent dividend growth', 'system', true),
('Growth Stocks', 'High growth potential stocks', 'system', true),
('Value Picks', 'Undervalued stocks with potential', 'system', true)
ON CONFLICT DO NOTHING;

-- Insert sample watchlist symbols for Tech Giants
INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
SELECT 
    w.id as watchlist_id,
    s.id as symbol_id,
    'Technology leader' as notes
FROM watchlists w
CROSS JOIN symbols s
WHERE w.name = 'Tech Giants' 
AND s.symbol IN ('AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'NVDA')
ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;

-- Insert sample watchlist symbols for Growth Stocks
INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
SELECT 
    w.id as watchlist_id,
    s.id as symbol_id,
    'High growth potential' as notes
FROM watchlists w
CROSS JOIN symbols s
WHERE w.name = 'Growth Stocks' 
AND s.symbol IN ('TSLA', 'NFLX', 'ADBE', 'CRM')
ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;

-- Insert sample watchlist symbols for Dividend Aristocrats
INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
SELECT 
    w.id as watchlist_id,
    s.id as symbol_id,
    'Consistent dividend payer' as notes
FROM watchlists w
CROSS JOIN symbols s
WHERE w.name = 'Dividend Aristocrats' 
AND s.symbol IN ('JNJ', 'PG', 'V', 'MA', 'UNH')
ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;

-- Insert sample watchlist symbols for Value Picks
INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
SELECT 
    w.id as watchlist_id,
    s.id as symbol_id,
    'Undervalued opportunity' as notes
FROM watchlists w
CROSS JOIN symbols s
WHERE w.name = 'Value Picks' 
AND s.symbol IN ('JPM', 'HD', 'DIS', 'INTC', 'PYPL')
ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;

-- Insert sample alerts for AAPL
INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
SELECT 
    s.id as symbol_id,
    'price' as alert_type,
    'above' as condition_type,
    160.0000 as target_value,
    'system' as created_by,
    true as is_active
FROM symbols s
WHERE s.symbol = 'AAPL';

INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
SELECT 
    s.id as symbol_id,
    'price' as alert_type,
    'below' as condition_type,
    140.0000 as target_value,
    'system' as created_by,
    true as is_active
FROM symbols s
WHERE s.symbol = 'AAPL';

INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
SELECT 
    s.id as symbol_id,
    'rsi' as alert_type,
    'above' as condition_type,
    70.0000 as target_value,
    'system' as created_by,
    true as is_active
FROM symbols s
WHERE s.symbol = 'AAPL';

INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
SELECT 
    s.id as symbol_id,
    'rsi' as alert_type,
    'below' as condition_type,
    30.0000 as target_value,
    'system' as created_by,
    true as is_active
FROM symbols s
WHERE s.symbol = 'AAPL';

-- Insert volume alert for TSLA
INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
SELECT 
    s.id as symbol_id,
    'volume' as alert_type,
    'above' as condition_type,
    100000000.0000 as target_value,
    'system' as created_by,
    true as is_active
FROM symbols s
WHERE s.symbol = 'TSLA';

-- Create sample screen results
INSERT INTO screen_results (screen_id, symbol_id, scan_date, score, criteria_met, market_data)
SELECT 
    sc.id as screen_id,
    sym.id as symbol_id,
    CURRENT_DATE as scan_date,
    (50.0 + RANDOM() * 50.0)::NUMERIC(8,4) as score,
    '{"rsi_check": true, "volume_check": true}'::jsonb as criteria_met,
    json_build_object(
        'close_price', (150.0 + RANDOM() * 50.0)::NUMERIC(12,4),
        'volume', (1000000 + RANDOM() * 5000000)::BIGINT,
        'rsi', (30.0 + RANDOM() * 40.0)::NUMERIC(8,4)
    )::jsonb as market_data
FROM screens sc
CROSS JOIN (SELECT id FROM symbols LIMIT 5) sym
WHERE sc.name = 'High Volume Breakout'
ON CONFLICT (screen_id, symbol_id, scan_date) DO NOTHING;

-- Create sample backtest
INSERT INTO backtests (strategy_id, name, start_date, end_date, initial_capital, commission, slippage, status)
SELECT 
    st.id as strategy_id,
    'Sample SMA Crossover Backtest' as name,
    (CURRENT_DATE - INTERVAL '1 year')::date as start_date,
    (CURRENT_DATE - INTERVAL '1 day')::date as end_date,
    100000.00 as initial_capital,
    0.001000 as commission,
    0.001000 as slippage,
    'completed' as status
FROM strategies st
WHERE st.name = 'Simple Moving Average Crossover'
LIMIT 1;

-- Update table statistics for better query performance
ANALYZE symbols;
ANALYZE ohlcv;
ANALYZE indicators;
ANALYZE strategies;
ANALYZE screens;
ANALYZE watchlists;
ANALYZE watchlist_symbols;
ANALYZE alerts;
ANALYZE screen_results;
ANALYZE backtests;