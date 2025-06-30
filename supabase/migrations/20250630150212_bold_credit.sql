-- =====================================================
-- SEED DATA FOR STOCK SCREENING SYSTEM
-- =====================================================

-- Insert countries
INSERT INTO countries (code, name, alpha_2, region, currency_code) VALUES
('USA', 'United States', 'US', 'North America', 'USD'),
('CAN', 'Canada', 'CA', 'North America', 'CAD'),
('GBR', 'United Kingdom', 'GB', 'Europe', 'GBP'),
('DEU', 'Germany', 'DE', 'Europe', 'EUR'),
('FRA', 'France', 'FR', 'Europe', 'EUR'),
('JPN', 'Japan', 'JP', 'Asia', 'JPY'),
('CHN', 'China', 'CN', 'Asia', 'CNY'),
('IND', 'India', 'IN', 'Asia', 'INR'),
('AUS', 'Australia', 'AU', 'Oceania', 'AUD'),
('BRA', 'Brazil', 'BR', 'South America', 'BRL')
ON CONFLICT (code) DO NOTHING;

-- Insert currencies
INSERT INTO currencies (code, name, symbol, decimal_places) VALUES
('USD', 'US Dollar', '$', 2),
('EUR', 'Euro', '€', 2),
('GBP', 'British Pound', '£', 2),
('JPY', 'Japanese Yen', '¥', 0),
('CAD', 'Canadian Dollar', 'C$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('CHF', 'Swiss Franc', 'CHF', 2),
('CNY', 'Chinese Yuan', '¥', 2),
('INR', 'Indian Rupee', '₹', 2),
('BRL', 'Brazilian Real', 'R$', 2)
ON CONFLICT (code) DO NOTHING;

-- Insert exchanges
INSERT INTO exchanges (code, name, country_id, currency_id, timezone) VALUES
('NYSE', 'New York Stock Exchange', (SELECT id FROM countries WHERE code = 'USA'), (SELECT id FROM currencies WHERE code = 'USD'), 'America/New_York'),
('NASDAQ', 'NASDAQ', (SELECT id FROM countries WHERE code = 'USA'), (SELECT id FROM currencies WHERE code = 'USD'), 'America/New_York'),
('LSE', 'London Stock Exchange', (SELECT id FROM countries WHERE code = 'GBR'), (SELECT id FROM currencies WHERE code = 'GBP'), 'Europe/London'),
('TSE', 'Tokyo Stock Exchange', (SELECT id FROM countries WHERE code = 'JPN'), (SELECT id FROM currencies WHERE code = 'JPY'), 'Asia/Tokyo'),
('TSX', 'Toronto Stock Exchange', (SELECT id FROM countries WHERE code = 'CAN'), (SELECT id FROM currencies WHERE code = 'CAD'), 'America/Toronto'),
('ASX', 'Australian Securities Exchange', (SELECT id FROM countries WHERE code = 'AUS'), (SELECT id FROM currencies WHERE code = 'AUD'), 'Australia/Sydney'),
('XETRA', 'XETRA', (SELECT id FROM countries WHERE code = 'DEU'), (SELECT id FROM currencies WHERE code = 'EUR'), 'Europe/Berlin'),
('SSE', 'Shanghai Stock Exchange', (SELECT id FROM countries WHERE code = 'CHN'), (SELECT id FROM currencies WHERE code = 'CNY'), 'Asia/Shanghai'),
('BSE', 'Bombay Stock Exchange', (SELECT id FROM countries WHERE code = 'IND'), (SELECT id FROM currencies WHERE code = 'INR'), 'Asia/Kolkata'),
('B3', 'B3 - Brasil Bolsa Balcão', (SELECT id FROM countries WHERE code = 'BRA'), (SELECT id FROM currencies WHERE code = 'BRL'), 'America/Sao_Paulo')
ON CONFLICT (code) DO NOTHING;

-- Insert sectors
INSERT INTO sectors (code, name, description) VALUES
('TECH', 'Technology', 'Companies involved in the design, development, and support of computer operating systems and applications'),
('FINL', 'Financial Services', 'Companies providing financial services including banks, investment funds, insurance companies'),
('HLTH', 'Healthcare', 'Companies involved in medical services, pharmaceuticals, and medical equipment'),
('CONS', 'Consumer Discretionary', 'Companies that sell non-essential goods and services'),
('CSTA', 'Consumer Staples', 'Companies that sell essential goods and services'),
('INDU', 'Industrials', 'Companies involved in manufacturing, construction, and industrial services'),
('ENRG', 'Energy', 'Companies involved in oil, gas, and renewable energy'),
('UTIL', 'Utilities', 'Companies providing essential services like electricity, gas, and water'),
('MATR', 'Materials', 'Companies involved in the discovery, development, and processing of raw materials'),
('REAL', 'Real Estate', 'Companies involved in real estate development, management, and investment'),
('COMM', 'Communication Services', 'Companies providing communication services and media content')
ON CONFLICT (code) DO NOTHING;

-- Insert industries
INSERT INTO industries (sector_id, code, name, description) VALUES
((SELECT id FROM sectors WHERE code = 'TECH'), 'SOFTWARE', 'Software', 'Software development and services'),
((SELECT id FROM sectors WHERE code = 'TECH'), 'HARDWARE', 'Hardware', 'Computer and electronic hardware'),
((SELECT id FROM sectors WHERE code = 'TECH'), 'SEMICOND', 'Semiconductors', 'Semiconductor and related devices'),
((SELECT id FROM sectors WHERE code = 'TECH'), 'INTERNET', 'Internet Services', 'Internet-based services and platforms'),
((SELECT id FROM sectors WHERE code = 'FINL'), 'BANKING', 'Banking', 'Commercial and investment banking'),
((SELECT id FROM sectors WHERE code = 'FINL'), 'INSURANCE', 'Insurance', 'Insurance services'),
((SELECT id FROM sectors WHERE code = 'FINL'), 'PAYMENTS', 'Payment Processing', 'Payment processing and financial technology'),
((SELECT id FROM sectors WHERE code = 'HLTH'), 'PHARMA', 'Pharmaceuticals', 'Pharmaceutical development and manufacturing'),
((SELECT id FROM sectors WHERE code = 'HLTH'), 'BIOTECH', 'Biotechnology', 'Biotechnology research and development'),
((SELECT id FROM sectors WHERE code = 'HLTH'), 'MEDDEV', 'Medical Devices', 'Medical device manufacturing'),
((SELECT id FROM sectors WHERE code = 'CONS'), 'RETAIL', 'Retail', 'Retail and e-commerce'),
((SELECT id FROM sectors WHERE code = 'CONS'), 'AUTO', 'Automotive', 'Automotive manufacturing and services'),
((SELECT id FROM sectors WHERE code = 'CONS'), 'MEDIA', 'Media & Entertainment', 'Media, entertainment, and content creation'),
((SELECT id FROM sectors WHERE code = 'CSTA'), 'FOOD', 'Food & Beverages', 'Food and beverage production'),
((SELECT id FROM sectors WHERE code = 'CSTA'), 'HOUSEHOLD', 'Household Products', 'Household and personal care products'),
((SELECT id FROM sectors WHERE code = 'ENRG'), 'OIL_GAS', 'Oil & Gas', 'Oil and gas exploration and production'),
((SELECT id FROM sectors WHERE code = 'ENRG'), 'RENEWABLE', 'Renewable Energy', 'Renewable energy and clean technology')
ON CONFLICT (code) DO NOTHING;

-- Insert security types
INSERT INTO security_types (code, name, description) VALUES
('STOCK', 'Common Stock', 'Common equity shares'),
('PREF', 'Preferred Stock', 'Preferred equity shares'),
('ETF', 'Exchange Traded Fund', 'Exchange traded funds'),
('BOND', 'Bond', 'Corporate and government bonds'),
('OPTION', 'Option', 'Stock options'),
('FUTURE', 'Future', 'Futures contracts'),
('WARRANT', 'Warrant', 'Stock warrants'),
('ADR', 'American Depositary Receipt', 'American Depositary Receipts'),
('REIT', 'Real Estate Investment Trust', 'Real Estate Investment Trusts')
ON CONFLICT (code) DO NOTHING;

-- Insert sample companies
INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) VALUES
('Apple Inc.', 'Apple Inc.', 'Apple', 
 (SELECT id FROM sectors WHERE code = 'TECH'), 
 (SELECT id FROM industries WHERE code = 'HARDWARE'),
 (SELECT id FROM countries WHERE code = 'USA'),
 'https://www.apple.com',
 'Designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories.',
 164000),
 
('Microsoft Corporation', 'Microsoft Corporation', 'Microsoft',
 (SELECT id FROM sectors WHERE code = 'TECH'),
 (SELECT id FROM industries WHERE code = 'SOFTWARE'),
 (SELECT id FROM countries WHERE code = 'USA'),
 'https://www.microsoft.com',
 'Develops, licenses, and supports software, services, devices, and solutions.',
 221000),
 
('Alphabet Inc.', 'Alphabet Inc.', 'Google',
 (SELECT id FROM sectors WHERE code = 'TECH'),
 (SELECT id FROM industries WHERE code = 'INTERNET'),
 (SELECT id FROM countries WHERE code = 'USA'),
 'https://www.alphabet.com',
 'Provides online advertising services and cloud computing services.',
 190000),
 
('Amazon.com Inc.', 'Amazon.com, Inc.', 'Amazon',
 (SELECT id FROM sectors WHERE code = 'CONS'),
 (SELECT id FROM industries WHERE code = 'RETAIL'),
 (SELECT id FROM countries WHERE code = 'USA'),
 'https://www.amazon.com',
 'Offers a range of products and services through its websites.',
 1540000),
 
('Tesla Inc.', 'Tesla, Inc.', 'Tesla',
 (SELECT id FROM sectors WHERE code = 'CONS'),
 (SELECT id FROM industries WHERE code = 'AUTO'),
 (SELECT id FROM countries WHERE code = 'USA'),
 'https://www.tesla.com',
 'Designs, develops, manufactures, and sells electric vehicles and energy storage systems.',
 140000)
ON CONFLICT (name) DO NOTHING;

-- Insert sample securities
INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) VALUES
((SELECT id FROM companies WHERE name = 'Apple Inc.'), 
 (SELECT id FROM security_types WHERE code = 'STOCK'),
 'AAPL',
 (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
 (SELECT id FROM currencies WHERE code = 'USD'),
 'Apple Inc. Common Stock',
 15550000000),
 
((SELECT id FROM companies WHERE name = 'Microsoft Corporation'),
 (SELECT id FROM security_types WHERE code = 'STOCK'),
 'MSFT',
 (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
 (SELECT id FROM currencies WHERE code = 'USD'),
 'Microsoft Corporation Common Stock',
 7430000000),
 
((SELECT id FROM companies WHERE name = 'Alphabet Inc.'),
 (SELECT id FROM security_types WHERE code = 'STOCK'),
 'GOOGL',
 (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
 (SELECT id FROM currencies WHERE code = 'USD'),
 'Alphabet Inc. Class A Common Stock',
 5840000000),
 
((SELECT id FROM companies WHERE name = 'Amazon.com Inc.'),
 (SELECT id FROM security_types WHERE code = 'STOCK'),
 'AMZN',
 (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
 (SELECT id FROM currencies WHERE code = 'USD'),
 'Amazon.com Inc. Common Stock',
 10700000000),
 
((SELECT id FROM companies WHERE name = 'Tesla Inc.'),
 (SELECT id FROM security_types WHERE code = 'STOCK'),
 'TSLA',
 (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
 (SELECT id FROM currencies WHERE code = 'USD'),
 'Tesla Inc. Common Stock',
 3170000000)
ON CONFLICT (symbol, exchange_id) DO NOTHING;

-- Insert legacy symbols for backward compatibility
INSERT INTO symbols (symbol, yticker, name, exchange, industry, sector, market_cap) VALUES
('AAPL', 'AAPL', 'Apple Inc.', 'NASDAQ', 'Hardware', 'Technology', 3000000000000),
('MSFT', 'MSFT', 'Microsoft Corporation', 'NASDAQ', 'Software', 'Technology', 2800000000000),
('GOOGL', 'GOOGL', 'Alphabet Inc.', 'NASDAQ', 'Internet Services', 'Technology', 1700000000000),
('AMZN', 'AMZN', 'Amazon.com Inc.', 'NASDAQ', 'Retail', 'Consumer Discretionary', 1500000000000),
('TSLA', 'TSLA', 'Tesla Inc.', 'NASDAQ', 'Automotive', 'Consumer Discretionary', 800000000000)
ON CONFLICT (symbol) DO NOTHING;

-- Insert default roles
INSERT INTO roles (name, description, is_system_role) VALUES
('admin', 'System administrator with full access', true),
('analyst', 'Financial analyst with advanced features', false),
('trader', 'Active trader with trading features', false),
('investor', 'Long-term investor with basic features', false),
('viewer', 'Read-only access to public data', false)
ON CONFLICT (name) DO NOTHING;

-- Insert permissions
INSERT INTO permissions (name, description, resource, action) VALUES
('screens.create', 'Create new screens', 'screens', 'create'),
('screens.read', 'View screens', 'screens', 'read'),
('screens.update', 'Modify screens', 'screens', 'update'),
('screens.delete', 'Delete screens', 'screens', 'delete'),
('screens.execute', 'Run screens', 'screens', 'execute'),
('backtests.create', 'Create backtests', 'backtests', 'create'),
('backtests.read', 'View backtests', 'backtests', 'read'),
('backtests.update', 'Modify backtests', 'backtests', 'update'),
('backtests.delete', 'Delete backtests', 'backtests', 'delete'),
('backtests.execute', 'Run backtests', 'backtests', 'execute'),
('watchlists.create', 'Create watchlists', 'watchlists', 'create'),
('watchlists.read', 'View watchlists', 'watchlists', 'read'),
('watchlists.update', 'Modify watchlists', 'watchlists', 'update'),
('watchlists.delete', 'Delete watchlists', 'watchlists', 'delete'),
('alerts.create', 'Create alerts', 'alerts', 'create'),
('alerts.read', 'View alerts', 'alerts', 'read'),
('alerts.update', 'Modify alerts', 'alerts', 'update'),
('alerts.delete', 'Delete alerts', 'alerts', 'delete'),
('market_data.read', 'Access market data', 'market_data', 'read'),
('financial_data.read', 'Access financial data', 'financial_data', 'read'),
('news.read', 'Access news data', 'news', 'read'),
('admin.users', 'Manage users', 'users', 'admin'),
('admin.system', 'System administration', 'system', 'admin')
ON CONFLICT (name) DO NOTHING;

-- Insert pattern types
INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) VALUES
('HEAD_SHOULDERS', 'Head and Shoulders', 'REVERSAL', 'Bearish reversal pattern', 25.0, 75.0, 15, 50),
('DOUBLE_TOP', 'Double Top', 'REVERSAL', 'Bearish reversal pattern', 30.0, 70.0, 10, 30),
('DOUBLE_BOTTOM', 'Double Bottom', 'REVERSAL', 'Bullish reversal pattern', 70.0, 30.0, 10, 30),
('TRIANGLE_ASCENDING', 'Ascending Triangle', 'CONTINUATION', 'Bullish continuation pattern', 65.0, 35.0, 8, 25),
('TRIANGLE_DESCENDING', 'Descending Triangle', 'CONTINUATION', 'Bearish continuation pattern', 35.0, 65.0, 8, 25),
('FLAG_BULL', 'Bull Flag', 'CONTINUATION', 'Bullish continuation pattern', 75.0, 25.0, 5, 15),
('FLAG_BEAR', 'Bear Flag', 'CONTINUATION', 'Bearish continuation pattern', 25.0, 75.0, 5, 15),
('WEDGE_RISING', 'Rising Wedge', 'REVERSAL', 'Bearish reversal pattern', 30.0, 70.0, 10, 40),
('WEDGE_FALLING', 'Falling Wedge', 'REVERSAL', 'Bullish reversal pattern', 70.0, 30.0, 10, 40),
('CUP_HANDLE', 'Cup and Handle', 'CONTINUATION', 'Bullish continuation pattern', 80.0, 20.0, 20, 60)
ON CONFLICT (code) DO NOTHING;

-- Insert sample strategies
INSERT INTO strategies (name, description, parameters) VALUES
('Simple Moving Average Crossover', 'Buy when short MA crosses above long MA, sell when it crosses below', 
 '{"short_period": 20, "long_period": 50, "stop_loss": 0.05, "take_profit": 0.15}'),
('RSI Mean Reversion', 'Buy when RSI is oversold, sell when overbought', 
 '{"rsi_period": 14, "oversold": 30, "overbought": 70, "stop_loss": 0.03}'),
('Bollinger Bands Breakout', 'Buy on upper band breakout, sell on lower band breakdown', 
 '{"period": 20, "std_dev": 2, "stop_loss": 0.04, "take_profit": 0.12}'),
('Momentum Strategy', 'Buy stocks with strong momentum, sell when momentum weakens', 
 '{"lookback_period": 10, "momentum_threshold": 0.05, "stop_loss": 0.06}'),
('Value Strategy', 'Buy undervalued stocks based on fundamental metrics', 
 '{"pe_max": 15, "pb_max": 2, "debt_to_equity_max": 0.5, "roe_min": 0.15}')
ON CONFLICT (name) DO NOTHING;

-- Insert sample screens
INSERT INTO screens (name, description, criteria) VALUES
('High Volume Breakout', 'Stocks breaking out with high volume', 
 '{"volume_ratio": {"min": 2.0}, "price_change_1d": {"min": 0.05}, "rsi_14": {"max": 80}}'),
('Oversold Value Stocks', 'Undervalued stocks that are oversold', 
 '{"rsi_14": {"max": 30}, "pe_ratio": {"max": 15}, "pb_ratio": {"max": 2}}'),
('Momentum Stocks', 'Stocks with strong price momentum', 
 '{"price_change_1w": {"min": 0.10}, "price_change_1m": {"min": 0.20}, "volume_ratio": {"min": 1.5}}'),
('Dividend Aristocrats', 'High-quality dividend paying stocks', 
 '{"dividend_yield": {"min": 0.02}, "roe": {"min": 0.15}, "debt_to_equity": {"max": 0.5}}'),
('Small Cap Growth', 'Small cap stocks with growth potential', 
 '{"market_cap": {"min": 300000000, "max": 2000000000}, "revenue_growth": {"min": 0.15}}'
)
ON CONFLICT (name) DO NOTHING;

-- Insert sample watchlists
INSERT INTO watchlists (name, description, created_by, is_public) VALUES
('Tech Giants', 'Major technology companies', 'system', true),
('Dividend Stocks', 'High dividend yield stocks', 'system', true),
('Growth Stocks', 'High growth potential stocks', 'system', true),
('Value Picks', 'Undervalued stock opportunities', 'system', false),
('Momentum Plays', 'Stocks with strong momentum', 'system', false)
ON CONFLICT DO NOTHING;

-- Insert watchlist symbols
INSERT INTO watchlist_symbols (watchlist_id, security_id, notes) VALUES
((SELECT id FROM watchlists WHERE name = 'Tech Giants'), 
 (SELECT id FROM securities WHERE symbol = 'AAPL'), 'Leading smartphone manufacturer'),
((SELECT id FROM watchlists WHERE name = 'Tech Giants'), 
 (SELECT id FROM securities WHERE symbol = 'MSFT'), 'Cloud computing leader'),
((SELECT id FROM watchlists WHERE name = 'Tech Giants'), 
 (SELECT id FROM securities WHERE symbol = 'GOOGL'), 'Search and advertising giant'),
((SELECT id FROM watchlists WHERE name = 'Growth Stocks'), 
 (SELECT id FROM securities WHERE symbol = 'TSLA'), 'Electric vehicle pioneer'),
((SELECT id FROM watchlists WHERE name = 'Growth Stocks'), 
 (SELECT id FROM securities WHERE symbol = 'AMZN'), 'E-commerce and cloud leader')
ON CONFLICT (watchlist_id, security_id) DO NOTHING;

-- Update table statistics
ANALYZE countries;
ANALYZE currencies;
ANALYZE exchanges;
ANALYZE sectors;
ANALYZE industries;
ANALYZE security_types;
ANALYZE companies;
ANALYZE securities;
ANALYZE symbols;
ANALYZE roles;
ANALYZE permissions;
ANALYZE pattern_types;
ANALYZE strategies;
ANALYZE screens;
ANALYZE watchlists;
ANALYZE watchlist_symbols;