-- Seed data for stock screening system

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
    base_price DECIMAL := 150.00;
    price_var DECIMAL;
    volume_var BIGINT;
BEGIN
    -- Get AAPL symbol ID
    SELECT id INTO symbol_id_var FROM symbols WHERE symbol = 'AAPL';
    
    -- Generate data for last 30 days
    FOR i IN 0..29 LOOP
        date_var := CURRENT_DATE - INTERVAL '1 day' * i;
        
        -- Skip weekends
        IF EXTRACT(DOW FROM date_var) NOT IN (0, 6) THEN
            -- Generate realistic price movement
            price_var := base_price + (RANDOM() - 0.5) * 10;
            volume_var := 50000000 + (RANDOM() * 30000000)::BIGINT;
            
            INSERT INTO ohlcv (symbol_id, trade_date, open_price, high_price, low_price, close_price, adjusted_close, volume)
            VALUES (
                symbol_id_var,
                date_var,
                price_var,
                price_var + (RANDOM() * 5),
                price_var - (RANDOM() * 5),
                price_var + (RANDOM() - 0.5) * 3,
                price_var + (RANDOM() - 0.5) * 3,
                volume_var
            )
            ON CONFLICT (symbol_id, trade_date) DO NOTHING;
            
            -- Update base price for next day
            base_price := price_var + (RANDOM() - 0.5) * 2;
        END IF;
    END LOOP;
END $$;

-- Insert sample indicators data
DO $$
DECLARE
    symbol_id_var INTEGER;
    date_var DATE;
    close_price_var DECIMAL;
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
                    close_price_var + (RANDOM() - 0.5) * 2, -- SMA 20
                    close_price_var + (RANDOM() - 0.5) * 3, -- SMA 50
                    close_price_var + (RANDOM() - 0.5) * 5, -- SMA 200
                    close_price_var + (RANDOM() - 0.5) * 1, -- EMA 12
                    close_price_var + (RANDOM() - 0.5) * 2, -- EMA 26
                    30 + RANDOM() * 40, -- RSI (30-70)
                    (RANDOM() - 0.5) * 2, -- MACD
                    (RANDOM() - 0.5) * 1.5, -- MACD Signal
                    (RANDOM() - 0.5) * 0.5, -- MACD Histogram
                    close_price_var + 5 + RANDOM() * 3, -- BB Upper
                    close_price_var, -- BB Middle
                    close_price_var - 5 - RANDOM() * 3, -- BB Lower
                    20 + RANDOM() * 60, -- Stoch K
                    20 + RANDOM() * 60, -- Stoch D
                    -80 + RANDOM() * 60, -- Williams R
                    1 + RANDOM() * 3 -- ATR
                )
                ON CONFLICT (symbol_id, trade_date) DO NOTHING;
            END IF;
        END IF;
    END LOOP;
END $$;

-- Insert sample watchlists
INSERT INTO watchlists (name, description, created_by, is_public) VALUES
('Tech Giants', 'Large technology companies', 'system', true),
('Dividend Aristocrats', 'Companies with consistent dividend growth', 'system', true),
('Growth Stocks', 'High growth potential stocks', 'system', true),
('Value Picks', 'Undervalued stocks with potential', 'system', true)
ON CONFLICT DO NOTHING;

-- Insert sample watchlist symbols
DO $$
DECLARE
    watchlist_id_var INTEGER;
    symbol_id_var INTEGER;
BEGIN
    -- Tech Giants watchlist
    SELECT id INTO watchlist_id_var FROM watchlists WHERE name = 'Tech Giants';
    
    FOR symbol_name IN SELECT unnest(ARRAY['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'NVDA']) LOOP
        SELECT id INTO symbol_id_var FROM symbols WHERE symbol = symbol_name;
        
        INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
        VALUES (watchlist_id_var, symbol_id_var, 'Technology leader')
        ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;
    END LOOP;
    
    -- Growth Stocks watchlist
    SELECT id INTO watchlist_id_var FROM watchlists WHERE name = 'Growth Stocks';
    
    FOR symbol_name IN SELECT unnest(ARRAY['TSLA', 'NFLX', 'ADBE', 'CRM']) LOOP
        SELECT id INTO symbol_id_var FROM symbols WHERE symbol = symbol_name;
        
        INSERT INTO watchlist_symbols (watchlist_id, symbol_id, notes)
        VALUES (watchlist_id_var, symbol_id_var, 'High growth potential')
        ON CONFLICT (watchlist_id, symbol_id) DO NOTHING;
    END LOOP;
END $$;

-- Insert sample alerts
DO $$
DECLARE
    symbol_id_var INTEGER;
BEGIN
    -- Price alerts for AAPL
    SELECT id INTO symbol_id_var FROM symbols WHERE symbol = 'AAPL';
    
    INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
    VALUES 
    (symbol_id_var, 'price', 'above', 160.00, 'system', true),
    (symbol_id_var, 'price', 'below', 140.00, 'system', true),
    (symbol_id_var, 'rsi', 'above', 70.00, 'system', true),
    (symbol_id_var, 'rsi', 'below', 30.00, 'system', true);
    
    -- Volume alert for TSLA
    SELECT id INTO symbol_id_var FROM symbols WHERE symbol = 'TSLA';
    
    INSERT INTO alerts (symbol_id, alert_type, condition_type, target_value, created_by, is_active)
    VALUES (symbol_id_var, 'volume', 'above', 100000000, 'system', true);
END $$;

-- Update statistics
ANALYZE symbols;
ANALYZE ohlcv;
ANALYZE indicators;
ANALYZE watchlists;
ANALYZE watchlist_symbols;
ANALYZE alerts;

-- Create some sample screen results
INSERT INTO screen_results (screen_id, symbol_id, scan_date, score, criteria_met, market_data)
SELECT 
    s.id as screen_id,
    sym.id as symbol_id,
    CURRENT_DATE as scan_date,
    50 + RANDOM() * 50 as score,
    '{"rsi_check": true, "volume_check": true}'::jsonb as criteria_met,
    json_build_object(
        'close_price', 150 + RANDOM() * 50,
        'volume', 1000000 + RANDOM() * 5000000,
        'rsi', 30 + RANDOM() * 40
    )::jsonb as market_data
FROM screens s
CROSS JOIN (SELECT id FROM symbols LIMIT 5) sym
WHERE s.name = 'High Volume Breakout'
ON CONFLICT (screen_id, symbol_id, scan_date) DO NOTHING;

COMMIT;