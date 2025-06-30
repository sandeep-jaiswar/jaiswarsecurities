-- ClickHouse Seed Data
-- Sample data for development and testing

USE stockdb;

-- Insert sample countries
INSERT INTO countries (id, code, name, alpha_2, region, currency_code) VALUES
(1, 'USA', 'United States', 'US', 'North America', 'USD'),
(2, 'CAN', 'Canada', 'CA', 'North America', 'CAD'),
(3, 'GBR', 'United Kingdom', 'GB', 'Europe', 'GBP'),
(4, 'DEU', 'Germany', 'DE', 'Europe', 'EUR'),
(5, 'JPN', 'Japan', 'JP', 'Asia', 'JPY');

-- Insert sample currencies
INSERT INTO currencies (id, code, name, symbol) VALUES
(1, 'USD', 'US Dollar', '$'),
(2, 'EUR', 'Euro', '€'),
(3, 'GBP', 'British Pound', '£'),
(4, 'JPY', 'Japanese Yen', '¥'),
(5, 'CAD', 'Canadian Dollar', 'C$');

-- Insert sample exchanges
INSERT INTO exchanges (id, code, name, country_id, currency_id, timezone) VALUES
(1, 'NASDAQ', 'NASDAQ Stock Market', 1, 1, 'America/New_York'),
(2, 'NYSE', 'New York Stock Exchange', 1, 1, 'America/New_York'),
(3, 'LSE', 'London Stock Exchange', 3, 3, 'Europe/London'),
(4, 'TSE', 'Tokyo Stock Exchange', 5, 4, 'Asia/Tokyo'),
(5, 'TSX', 'Toronto Stock Exchange', 2, 5, 'America/Toronto');

-- Insert sample sectors
INSERT INTO sectors (id, code, name, description) VALUES
(1, 'TECH', 'Technology', 'Technology companies'),
(2, 'FINL', 'Financial', 'Financial services'),
(3, 'HLTH', 'Healthcare', 'Healthcare and pharmaceuticals'),
(4, 'CONS', 'Consumer', 'Consumer goods and services'),
(5, 'ENGY', 'Energy', 'Energy and utilities');

-- Insert sample industries
INSERT INTO industries (id, sector_id, code, name, description) VALUES
(1, 1, 'SOFT', 'Software', 'Software development'),
(2, 1, 'SEMI', 'Semiconductors', 'Semiconductor manufacturing'),
(3, 1, 'INET', 'Internet', 'Internet services'),
(4, 2, 'BANK', 'Banking', 'Commercial banking'),
(5, 3, 'AUTO', 'Automotive', 'Automotive manufacturing');

-- Insert sample security types
INSERT INTO security_types (id, code, name, description) VALUES
(1, 'CS', 'Common Stock', 'Common shares'),
(2, 'PS', 'Preferred Stock', 'Preferred shares'),
(3, 'ETF', 'Exchange Traded Fund', 'Exchange traded funds'),
(4, 'BOND', 'Bond', 'Corporate bonds'),
(5, 'OPT', 'Option', 'Stock options');

-- Insert sample companies
INSERT INTO companies (id, name, sector_id, industry_id, is_active, is_public) VALUES
(1, 'Apple Inc.', 1, 1, 1, 1),
(2, 'Microsoft Corporation', 1, 1, 1, 1),
(3, 'Alphabet Inc.', 1, 3, 1, 1),
(4, 'Amazon.com Inc.', 4, 3, 1, 1),
(5, 'Tesla Inc.', 5, 5, 1, 1),
(6, 'Meta Platforms Inc.', 1, 3, 1, 1),
(7, 'NVIDIA Corporation', 1, 2, 1, 1),
(8, 'JPMorgan Chase & Co.', 2, 4, 1, 1),
(9, 'Johnson & Johnson', 3, 3, 1, 1),
(10, 'Berkshire Hathaway Inc.', 2, 4, 1, 1);

-- Insert sample securities
INSERT INTO securities (id, company_id, security_type_id, symbol, exchange_id, currency_id, name, is_active) VALUES
(1, 1, 1, 'AAPL', 2, 1, 'Apple Inc. Common Stock', 1),
(2, 2, 1, 'MSFT', 2, 1, 'Microsoft Corporation Common Stock', 1),
(3, 3, 1, 'GOOGL', 1, 1, 'Alphabet Inc. Class A Common Stock', 1),
(4, 4, 1, 'AMZN', 1, 1, 'Amazon.com Inc. Common Stock', 1),
(5, 5, 1, 'TSLA', 1, 1, 'Tesla Inc. Common Stock', 1),
(6, 6, 1, 'META', 1, 1, 'Meta Platforms Inc. Common Stock', 1),
(7, 7, 1, 'NVDA', 1, 1, 'NVIDIA Corporation Common Stock', 1),
(8, 8, 1, 'JPM', 2, 1, 'JPMorgan Chase & Co. Common Stock', 1),
(9, 9, 1, 'JNJ', 2, 1, 'Johnson & Johnson Common Stock', 1),
(10, 10, 1, 'BRK.A', 2, 1, 'Berkshire Hathaway Inc. Class A Common Stock', 1);

-- Insert sample OHLCV data (last 30 days)
INSERT INTO ohlcv_daily (id, security_id, trade_date, open_price, high_price, low_price, close_price, volume) VALUES
-- AAPL data
(1, 1, '2024-01-02', 185.64, 186.95, 185.00, 185.64, 52164200),
(2, 1, '2024-01-03', 184.22, 185.88, 183.43, 184.25, 47471800),
(3, 1, '2024-01-04', 182.15, 184.26, 180.93, 181.91, 59144100),
(4, 1, '2024-01-05', 181.99, 182.76, 180.17, 181.18, 48087700),
-- MSFT data
(5, 2, '2024-01-02', 374.58, 375.61, 372.85, 374.58, 19816500),
(6, 2, '2024-01-03', 373.89, 376.30, 373.20, 376.04, 17748400),
(7, 2, '2024-01-04', 375.37, 378.54, 374.51, 378.54, 20803700),
(8, 2, '2024-01-05', 378.14, 380.23, 376.64, 379.58, 18291200),
-- GOOGL data
(9, 3, '2024-01-02', 140.23, 141.40, 139.65, 140.93, 27621100),
(10, 3, '2024-01-03', 140.68, 142.65, 140.46, 142.65, 24185200);

-- Insert sample strategies
INSERT INTO strategies (id, name, description, parameters, created_by, is_active) VALUES
(1, 'Simple Moving Average Crossover', 'Buy when short MA crosses above long MA', '{"short_period": 20, "long_period": 50, "stop_loss": 0.05, "take_profit": 0.15}', 'system', 1),
(2, 'RSI Mean Reversion', 'Buy oversold, sell overbought based on RSI', '{"oversold": 30, "overbought": 70, "stop_loss": 0.03}', 'system', 1),
(3, 'Bollinger Bands Breakout', 'Buy on upper band breakout', '{"period": 20, "std_dev": 2, "stop_loss": 0.04, "take_profit": 0.12}', 'system', 1),
(4, 'MACD Signal', 'Trade based on MACD crossovers', '{"fast_period": 12, "slow_period": 26, "signal_period": 9}', 'system', 1),
(5, 'Volume Breakout', 'Trade on high volume breakouts', '{"volume_threshold": 2.0, "price_change": 0.03}', 'system', 1);

-- Insert sample screens
INSERT INTO screens (id, name, description, criteria, created_by, is_active) VALUES
(1, 'High Volume Breakout', 'Stocks with high volume and price breakout', '{"volume_ratio": {"min": 2.0}, "price_change": {"min": 0.05}, "rsi": {"max": 70}}', 'system', 1),
(2, 'Oversold Value Stocks', 'Undervalued stocks with oversold RSI', '{"rsi": {"max": 30}, "pe_ratio": {"max": 15}, "market_cap": {"min": 1000000000}}', 'system', 1),
(3, 'Momentum Stocks', 'Stocks with strong momentum indicators', '{"rsi": {"min": 60}, "macd": {"min": 0}, "price_change_5d": {"min": 0.10}}', 'system', 1),
(4, 'Large Cap Growth', 'Large cap stocks with growth potential', '{"market_cap": {"min": 10000000000}, "revenue_growth": {"min": 0.15}, "pe_ratio": {"max": 30}}', 'system', 1),
(5, 'Dividend Aristocrats', 'Stocks with consistent dividend growth', '{"dividend_yield": {"min": 0.02}, "dividend_growth": {"min": 0.05}, "payout_ratio": {"max": 0.6}}', 'system', 1);

-- Insert sample watchlists
INSERT INTO watchlists (id, name, description, created_by, is_public) VALUES
(1, 'Tech Giants', 'Major technology companies', 'admin', 1),
(2, 'Growth Stocks', 'High growth potential stocks', 'admin', 0),
(3, 'Dividend Stocks', 'Dividend paying stocks', 'admin', 1),
(4, 'Value Picks', 'Undervalued opportunities', 'admin', 0),
(5, 'Momentum Plays', 'High momentum stocks', 'admin', 1);

-- Insert sample watchlist symbols
INSERT INTO watchlist_symbols (id, watchlist_id, symbol_id, added_date) VALUES
(1, 1, 1, '2024-01-01'),  -- AAPL in Tech Giants
(2, 1, 2, '2024-01-01'),  -- MSFT in Tech Giants
(3, 1, 3, '2024-01-01'),  -- GOOGL in Tech Giants
(4, 1, 6, '2024-01-01'),  -- META in Tech Giants
(5, 1, 7, '2024-01-01'),  -- NVDA in Tech Giants
(6, 2, 4, '2024-01-01'),  -- AMZN in Growth Stocks
(7, 2, 5, '2024-01-01'),  -- TSLA in Growth Stocks
(8, 3, 9, '2024-01-01'),  -- JNJ in Dividend Stocks
(9, 3, 8, '2024-01-01'),  -- JPM in Dividend Stocks
(10, 4, 10, '2024-01-01'); -- BRK.A in Value Picks

-- Insert sample users
INSERT INTO users (id, username, email, password_hash, first_name, last_name, is_active, is_verified) VALUES
(1, 'admin', 'admin@stockterminal.com', '$2b$10$example_hash_admin', 'Admin', 'User', 1, 1),
(2, 'demo', 'demo@stockterminal.com', '$2b$10$example_hash_demo', 'Demo', 'User', 1, 1),
(3, 'trader1', 'trader1@stockterminal.com', '$2b$10$example_hash_trader1', 'John', 'Trader', 1, 1),
(4, 'analyst1', 'analyst1@stockterminal.com', '$2b$10$example_hash_analyst1', 'Jane', 'Analyst', 1, 1);

-- Insert sample roles
INSERT INTO roles (id, name, description, is_system_role) VALUES
(1, 'admin', 'System administrator', 1),
(2, 'trader', 'Professional trader', 0),
(3, 'analyst', 'Financial analyst', 0),
(4, 'viewer', 'Read-only access', 0);

-- Insert sample permissions
INSERT INTO permissions (id, name, description, resource, action) VALUES
(1, 'view_market_data', 'View market data', 'market_data', 'read'),
(2, 'manage_watchlists', 'Manage watchlists', 'watchlists', 'write'),
(3, 'run_backtests', 'Run backtesting', 'backtests', 'execute'),
(4, 'admin_users', 'Manage users', 'users', 'admin'),
(5, 'view_analytics', 'View analytics', 'analytics', 'read');

-- Insert sample role permissions
INSERT INTO role_permissions (id, role_id, permission_id) VALUES
(1, 1, 1), (2, 1, 2), (3, 1, 3), (4, 1, 4), (5, 1, 5),  -- Admin gets all
(6, 2, 1), (7, 2, 2), (8, 2, 3), (9, 2, 5),              -- Trader gets most
(10, 3, 1), (11, 3, 5),                                   -- Analyst gets view access
(12, 4, 1);                                               -- Viewer gets read-only

-- Insert sample user roles
INSERT INTO user_roles (id, user_id, role_id, assigned_by) VALUES
(1, 1, 1, 1),  -- admin user gets admin role
(2, 2, 4, 1),  -- demo user gets viewer role
(3, 3, 2, 1),  -- trader1 gets trader role
(4, 4, 3, 1);  -- analyst1 gets analyst role

-- Insert sample news sources
INSERT INTO news_sources (id, code, name, website, credibility_score, is_active) VALUES
(1, 'REUTERS', 'Reuters', 'https://reuters.com', 0.95, 1),
(2, 'BLOOMBERG', 'Bloomberg', 'https://bloomberg.com', 0.92, 1),
(3, 'CNBC', 'CNBC', 'https://cnbc.com', 0.85, 1),
(4, 'WSJ', 'Wall Street Journal', 'https://wsj.com', 0.90, 1),
(5, 'FT', 'Financial Times', 'https://ft.com', 0.88, 1);

-- Insert sample news categories
INSERT INTO news_categories (id, code, name, description) VALUES
(1, 'EARNINGS', 'Earnings', 'Company earnings reports'),
(2, 'M&A', 'Mergers & Acquisitions', 'M&A activity'),
(3, 'ECON', 'Economic', 'Economic indicators and policy'),
(4, 'TECH', 'Technology', 'Technology sector news'),
(5, 'MARKET', 'Market', 'General market news');