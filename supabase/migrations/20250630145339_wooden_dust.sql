-- Seed data for Stock Screening System
-- This populates the database with reference data and sample companies

-- Insert countries
INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'USA', 'United States', 'US', 'North America', 'USD'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'USA');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'CAN', 'Canada', 'CA', 'North America', 'CAD'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'CAN');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'GBR', 'United Kingdom', 'GB', 'Europe', 'GBP'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'GBR');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'DEU', 'Germany', 'DE', 'Europe', 'EUR'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'DEU');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'FRA', 'France', 'FR', 'Europe', 'EUR'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'FRA');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'JPN', 'Japan', 'JP', 'Asia', 'JPY'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'JPN');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'CHN', 'China', 'CN', 'Asia', 'CNY'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'CHN');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'IND', 'India', 'IN', 'Asia', 'INR'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'IND');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'AUS', 'Australia', 'AU', 'Oceania', 'AUD'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'AUS');

INSERT INTO countries (code, name, alpha_2, region, currency_code) 
SELECT 'BRA', 'Brazil', 'BR', 'South America', 'BRL'
WHERE NOT EXISTS (SELECT 1 FROM countries WHERE code = 'BRA');

-- Insert currencies
INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'USD', 'US Dollar', '$', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'USD');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'EUR', 'Euro', '€', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'EUR');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'GBP', 'British Pound', '£', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'GBP');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'JPY', 'Japanese Yen', '¥', 0
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'JPY');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'CAD', 'Canadian Dollar', 'C$', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'CAD');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'AUD', 'Australian Dollar', 'A$', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'AUD');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'CHF', 'Swiss Franc', 'CHF', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'CHF');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'CNY', 'Chinese Yuan', '¥', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'CNY');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'INR', 'Indian Rupee', '₹', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'INR');

INSERT INTO currencies (code, name, symbol, decimal_places) 
SELECT 'BRL', 'Brazilian Real', 'R$', 2
WHERE NOT EXISTS (SELECT 1 FROM currencies WHERE code = 'BRL');

-- Insert exchanges
INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'NYSE', 'New York Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'USA'), 
       (SELECT id FROM currencies WHERE code = 'USD'), 
       'America/New_York'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'NYSE');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'NASDAQ', 'NASDAQ', 
       (SELECT id FROM countries WHERE code = 'USA'), 
       (SELECT id FROM currencies WHERE code = 'USD'), 
       'America/New_York'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'NASDAQ');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'LSE', 'London Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'GBR'), 
       (SELECT id FROM currencies WHERE code = 'GBP'), 
       'Europe/London'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'LSE');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'TSE', 'Tokyo Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'JPN'), 
       (SELECT id FROM currencies WHERE code = 'JPY'), 
       'Asia/Tokyo'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'TSE');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'TSX', 'Toronto Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'CAN'), 
       (SELECT id FROM currencies WHERE code = 'CAD'), 
       'America/Toronto'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'TSX');

-- Insert sectors
INSERT INTO sectors (code, name, description) 
SELECT 'TECH', 'Technology', 'Companies involved in the design, development, and support of computer operating systems and applications'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'TECH');

INSERT INTO sectors (code, name, description) 
SELECT 'FINL', 'Financial Services', 'Companies providing financial services including banks, investment funds, insurance companies'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'FINL');

INSERT INTO sectors (code, name, description) 
SELECT 'HLTH', 'Healthcare', 'Companies involved in medical services, pharmaceuticals, and medical equipment'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'HLTH');

INSERT INTO sectors (code, name, description) 
SELECT 'CONS', 'Consumer Discretionary', 'Companies that sell non-essential goods and services'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'CONS');

INSERT INTO sectors (code, name, description) 
SELECT 'CSTA', 'Consumer Staples', 'Companies that sell essential goods and services'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'CSTA');

INSERT INTO sectors (code, name, description) 
SELECT 'INDU', 'Industrials', 'Companies involved in manufacturing, construction, and industrial services'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'INDU');

INSERT INTO sectors (code, name, description) 
SELECT 'ENRG', 'Energy', 'Companies involved in oil, gas, and renewable energy'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'ENRG');

INSERT INTO sectors (code, name, description) 
SELECT 'UTIL', 'Utilities', 'Companies providing essential services like electricity, gas, and water'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'UTIL');

INSERT INTO sectors (code, name, description) 
SELECT 'MATR', 'Materials', 'Companies involved in the discovery, development, and processing of raw materials'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'MATR');

INSERT INTO sectors (code, name, description) 
SELECT 'REAL', 'Real Estate', 'Companies involved in real estate development, management, and investment'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'REAL');

INSERT INTO sectors (code, name, description) 
SELECT 'COMM', 'Communication Services', 'Companies providing communication services and media content'
WHERE NOT EXISTS (SELECT 1 FROM sectors WHERE code = 'COMM');

-- Insert industries
INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'TECH'), 'SOFTWARE', 'Software', 'Software development and services'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'SOFTWARE');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'TECH'), 'HARDWARE', 'Hardware', 'Computer and electronic hardware'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'HARDWARE');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'TECH'), 'SEMICOND', 'Semiconductors', 'Semiconductor and related devices'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'SEMICOND');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'TECH'), 'INTERNET', 'Internet Services', 'Internet-based services and platforms'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'INTERNET');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'FINL'), 'BANKING', 'Banking', 'Commercial and investment banking'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'BANKING');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'FINL'), 'INSURANCE', 'Insurance', 'Insurance services'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'INSURANCE');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CONS'), 'RETAIL', 'Retail', 'Retail and e-commerce'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'RETAIL');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CONS'), 'AUTO', 'Automotive', 'Automotive manufacturing and services'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'AUTO');

-- Insert security types
INSERT INTO security_types (code, name, description) 
SELECT 'STOCK', 'Common Stock', 'Common equity shares'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'STOCK');

INSERT INTO security_types (code, name, description) 
SELECT 'PREF', 'Preferred Stock', 'Preferred equity shares'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'PREF');

INSERT INTO security_types (code, name, description) 
SELECT 'ETF', 'Exchange Traded Fund', 'Exchange traded funds'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'ETF');

INSERT INTO security_types (code, name, description) 
SELECT 'BOND', 'Bond', 'Corporate and government bonds'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'BOND');

-- Insert sample companies
INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) 
SELECT 'Apple Inc.', 'Apple Inc.', 'Apple', 
       (SELECT id FROM sectors WHERE code = 'TECH'), 
       (SELECT id FROM industries WHERE code = 'HARDWARE'),
       (SELECT id FROM countries WHERE code = 'USA'),
       'https://www.apple.com',
       'Designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories.',
       164000
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE name = 'Apple Inc.');

INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) 
SELECT 'Microsoft Corporation', 'Microsoft Corporation', 'Microsoft',
       (SELECT id FROM sectors WHERE code = 'TECH'),
       (SELECT id FROM industries WHERE code = 'SOFTWARE'),
       (SELECT id FROM countries WHERE code = 'USA'),
       'https://www.microsoft.com',
       'Develops, licenses, and supports software, services, devices, and solutions.',
       221000
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE name = 'Microsoft Corporation');

INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) 
SELECT 'Alphabet Inc.', 'Alphabet Inc.', 'Google',
       (SELECT id FROM sectors WHERE code = 'TECH'),
       (SELECT id FROM industries WHERE code = 'INTERNET'),
       (SELECT id FROM countries WHERE code = 'USA'),
       'https://www.alphabet.com',
       'Provides online advertising services and cloud computing services.',
       190000
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE name = 'Alphabet Inc.');

INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) 
SELECT 'Amazon.com Inc.', 'Amazon.com, Inc.', 'Amazon',
       (SELECT id FROM sectors WHERE code = 'CONS'),
       (SELECT id FROM industries WHERE code = 'RETAIL'),
       (SELECT id FROM countries WHERE code = 'USA'),
       'https://www.amazon.com',
       'Offers a range of products and services through its websites.',
       1540000
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE name = 'Amazon.com Inc.');

INSERT INTO companies (
    name, legal_name, short_name, sector_id, industry_id, 
    headquarters_country_id, website, business_description, employee_count
) 
SELECT 'Tesla Inc.', 'Tesla, Inc.', 'Tesla',
       (SELECT id FROM sectors WHERE code = 'CONS'),
       (SELECT id FROM industries WHERE code = 'AUTO'),
       (SELECT id FROM countries WHERE code = 'USA'),
       'https://www.tesla.com',
       'Designs, develops, manufactures, and sells electric vehicles and energy storage systems.',
       140000
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE name = 'Tesla Inc.');

-- Insert sample securities
INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) 
SELECT (SELECT id FROM companies WHERE name = 'Apple Inc.'), 
       (SELECT id FROM security_types WHERE code = 'STOCK'),
       'AAPL',
       (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
       (SELECT id FROM currencies WHERE code = 'USD'),
       'Apple Inc. Common Stock',
       15550000000
WHERE NOT EXISTS (SELECT 1 FROM securities WHERE symbol = 'AAPL' AND exchange_id = (SELECT id FROM exchanges WHERE code = 'NASDAQ'));

INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) 
SELECT (SELECT id FROM companies WHERE name = 'Microsoft Corporation'),
       (SELECT id FROM security_types WHERE code = 'STOCK'),
       'MSFT',
       (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
       (SELECT id FROM currencies WHERE code = 'USD'),
       'Microsoft Corporation Common Stock',
       7430000000
WHERE NOT EXISTS (SELECT 1 FROM securities WHERE symbol = 'MSFT' AND exchange_id = (SELECT id FROM exchanges WHERE code = 'NASDAQ'));

INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) 
SELECT (SELECT id FROM companies WHERE name = 'Alphabet Inc.'),
       (SELECT id FROM security_types WHERE code = 'STOCK'),
       'GOOGL',
       (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
       (SELECT id FROM currencies WHERE code = 'USD'),
       'Alphabet Inc. Class A Common Stock',
       5840000000
WHERE NOT EXISTS (SELECT 1 FROM securities WHERE symbol = 'GOOGL' AND exchange_id = (SELECT id FROM exchanges WHERE code = 'NASDAQ'));

INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) 
SELECT (SELECT id FROM companies WHERE name = 'Amazon.com Inc.'),
       (SELECT id FROM security_types WHERE code = 'STOCK'),
       'AMZN',
       (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
       (SELECT id FROM currencies WHERE code = 'USD'),
       'Amazon.com Inc. Common Stock',
       10700000000
WHERE NOT EXISTS (SELECT 1 FROM securities WHERE symbol = 'AMZN' AND exchange_id = (SELECT id FROM exchanges WHERE code = 'NASDAQ'));

INSERT INTO securities (
    company_id, security_type_id, symbol, exchange_id, currency_id, name, shares_outstanding
) 
SELECT (SELECT id FROM companies WHERE name = 'Tesla Inc.'),
       (SELECT id FROM security_types WHERE code = 'STOCK'),
       'TSLA',
       (SELECT id FROM exchanges WHERE code = 'NASDAQ'),
       (SELECT id FROM currencies WHERE code = 'USD'),
       'Tesla Inc. Common Stock',
       3170000000
WHERE NOT EXISTS (SELECT 1 FROM securities WHERE symbol = 'TSLA' AND exchange_id = (SELECT id FROM exchanges WHERE code = 'NASDAQ'));

-- Insert default roles
INSERT INTO roles (name, description, is_system_role) 
SELECT 'admin', 'System administrator with full access', true
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'admin');

INSERT INTO roles (name, description, is_system_role) 
SELECT 'analyst', 'Financial analyst with advanced features', false
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'analyst');

INSERT INTO roles (name, description, is_system_role) 
SELECT 'trader', 'Active trader with trading features', false
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'trader');

INSERT INTO roles (name, description, is_system_role) 
SELECT 'investor', 'Long-term investor with basic features', false
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'investor');

INSERT INTO roles (name, description, is_system_role) 
SELECT 'viewer', 'Read-only access to public data', false
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'viewer');

-- Insert permissions
INSERT INTO permissions (name, description, resource, action) 
SELECT 'screens.create', 'Create new screens', 'screens', 'create'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'screens.create');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'screens.read', 'View screens', 'screens', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'screens.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'screens.execute', 'Run screens', 'screens', 'execute'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'screens.execute');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'backtests.create', 'Create backtests', 'backtests', 'create'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'backtests.create');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'backtests.read', 'View backtests', 'backtests', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'backtests.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'backtests.execute', 'Run backtests', 'backtests', 'execute'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'backtests.execute');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'watchlists.create', 'Create watchlists', 'watchlists', 'create'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'watchlists.create');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'watchlists.read', 'View watchlists', 'watchlists', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'watchlists.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'alerts.create', 'Create alerts', 'alerts', 'create'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'alerts.create');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'market_data.read', 'Access market data', 'market_data', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'market_data.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'financial_data.read', 'Access financial data', 'financial_data', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'financial_data.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'admin.system', 'System administration', 'system', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'admin.system');

-- Insert sample strategies
INSERT INTO strategies (name, description, parameters) 
SELECT 'Simple Moving Average Crossover', 
       'Buy when short MA crosses above long MA, sell when short MA crosses below long MA',
       '{"short_period": 20, "long_period": 50, "stop_loss": 0.05, "take_profit": 0.10}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM strategies WHERE name = 'Simple Moving Average Crossover');

INSERT INTO strategies (name, description, parameters) 
SELECT 'RSI Mean Reversion', 
       'Buy when RSI is oversold, sell when RSI is overbought',
       '{"rsi_period": 14, "oversold": 30, "overbought": 70, "stop_loss": 0.03}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM strategies WHERE name = 'RSI Mean Reversion');

INSERT INTO strategies (name, description, parameters) 
SELECT 'Bollinger Bands Breakout', 
       'Buy on upper band breakout, sell on lower band breakdown',
       '{"bb_period": 20, "bb_std": 2, "stop_loss": 0.04, "take_profit": 0.08}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM strategies WHERE name = 'Bollinger Bands Breakout');

-- Insert sample screens
INSERT INTO screens (name, description, criteria) 
SELECT 'High Volume Breakout', 
       'Stocks with high volume and price breakout',
       '{"volume_ratio": {"min": 2.0}, "price_change_1d": {"min": 0.05}, "rsi_14": {"max": 80}}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM screens WHERE name = 'High Volume Breakout');

INSERT INTO screens (name, description, criteria) 
SELECT 'Oversold Value Stocks', 
       'Undervalued stocks with oversold technical indicators',
       '{"pe_ratio": {"max": 15}, "pb_ratio": {"max": 2}, "rsi_14": {"max": 35}}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM screens WHERE name = 'Oversold Value Stocks');

INSERT INTO screens (name, description, criteria) 
SELECT 'Momentum Stocks', 
       'Stocks with strong price momentum and technical strength',
       '{"price_change_1w": {"min": 0.10}, "price_vs_sma50": {"min": 1.05}, "rsi_14": {"min": 60}}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM screens WHERE name = 'Momentum Stocks');

-- Update table statistics
ANALYZE countries;
ANALYZE currencies;
ANALYZE exchanges;
ANALYZE sectors;
ANALYZE industries;
ANALYZE security_types;
ANALYZE companies;
ANALYZE securities;
ANALYZE roles;
ANALYZE permissions;
ANALYZE strategies;
ANALYZE screens;