-- Sample data for ClickHouse Stock Database
USE stockdb;

-- Insert sample companies
INSERT INTO companies (id, name, sector_id, industry_id, is_active, is_public) VALUES
(1, 'Apple Inc.', 1, 1, 1, 1),
(2, 'Microsoft Corporation', 1, 2, 1, 1),
(3, 'Alphabet Inc.', 1, 3, 1, 1),
(4, 'Amazon.com Inc.', 2, 4, 1, 1),
(5, 'Tesla Inc.', 3, 5, 1, 1);

-- Insert sample securities
INSERT INTO securities (id, company_id, symbol, name, is_active) VALUES
(1, 1, 'AAPL', 'Apple Inc. Common Stock', 1),
(2, 2, 'MSFT', 'Microsoft Corporation Common Stock', 1),
(3, 3, 'GOOGL', 'Alphabet Inc. Class A Common Stock', 1),
(4, 4, 'AMZN', 'Amazon.com Inc. Common Stock', 1),
(5, 5, 'TSLA', 'Tesla Inc. Common Stock', 1);

-- Insert sample OHLCV data
INSERT INTO ohlcv_daily (id, security_id, trade_date, open_price, high_price, low_price, close_price, volume) VALUES
(1, 1, '2024-01-02', 185.64, 186.95, 185.00, 185.64, 52164200),
(2, 1, '2024-01-03', 184.22, 185.88, 183.43, 184.25, 47471800),
(3, 2, '2024-01-02', 374.58, 375.61, 372.85, 374.58, 19816500),
(4, 2, '2024-01-03', 373.89, 376.30, 373.20, 376.04, 17748400),
(5, 3, '2024-01-02', 140.23, 141.40, 139.65, 140.93, 27621100);

-- Insert sample strategies
INSERT INTO strategies (id, name, description, parameters, created_by, is_active) VALUES
(1, 'Simple Moving Average Crossover', 'Buy when short MA crosses above long MA', '{"short_period": 20, "long_period": 50, "stop_loss": 0.05, "take_profit": 0.15}', 'system', 1),
(2, 'RSI Mean Reversion', 'Buy oversold, sell overbought based on RSI', '{"oversold": 30, "overbought": 70, "stop_loss": 0.03}', 'system', 1),
(3, 'Bollinger Bands Breakout', 'Buy on upper band breakout', '{"period": 20, "std_dev": 2, "stop_loss": 0.04, "take_profit": 0.12}', 'system', 1);

-- Insert sample screens
INSERT INTO screens (id, name, description, criteria, created_by, is_active) VALUES
(1, 'High Volume Breakout', 'Stocks with high volume and price breakout', '{"volume_ratio": {"min": 2.0}, "price_change": {"min": 0.05}, "rsi": {"max": 70}}', 'system', 1),
(2, 'Oversold Value Stocks', 'Undervalued stocks with oversold RSI', '{"rsi": {"max": 30}, "pe_ratio": {"max": 15}, "market_cap": {"min": 1000000000}}', 'system', 1),
(3, 'Momentum Stocks', 'Stocks with strong momentum indicators', '{"rsi": {"min": 60}, "macd": {"min": 0}, "price_change_5d": {"min": 0.10}}', 'system', 1);

-- Insert sample watchlists
INSERT INTO watchlists (id, name, description, created_by, is_public) VALUES
(1, 'Tech Giants', 'Major technology companies', 'admin', 1),
(2, 'Growth Stocks', 'High growth potential stocks', 'admin', 0);

-- Insert sample watchlist symbols
INSERT INTO watchlist_symbols (id, watchlist_id, symbol_id, added_date) VALUES
(1, 1, 1, '2024-01-01'),
(2, 1, 2, '2024-01-01'),
(3, 1, 3, '2024-01-01'),
(4, 2, 4, '2024-01-01'),
(5, 2, 5, '2024-01-01');

-- Insert sample users
INSERT INTO users (id, username, email, password_hash, is_active, is_verified) VALUES
(1, 'admin', 'admin@stockterminal.com', '$2b$10$example_hash', 1, 1),
(2, 'demo', 'demo@stockterminal.com', '$2b$10$example_hash', 1, 1);