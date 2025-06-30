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

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'ASX', 'Australian Securities Exchange', 
       (SELECT id FROM countries WHERE code = 'AUS'), 
       (SELECT id FROM currencies WHERE code = 'AUD'), 
       'Australia/Sydney'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'ASX');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'XETRA', 'XETRA', 
       (SELECT id FROM countries WHERE code = 'DEU'), 
       (SELECT id FROM currencies WHERE code = 'EUR'), 
       'Europe/Berlin'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'XETRA');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'SSE', 'Shanghai Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'CHN'), 
       (SELECT id FROM currencies WHERE code = 'CNY'), 
       'Asia/Shanghai'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'SSE');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'BSE', 'Bombay Stock Exchange', 
       (SELECT id FROM countries WHERE code = 'IND'), 
       (SELECT id FROM currencies WHERE code = 'INR'), 
       'Asia/Kolkata'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'BSE');

INSERT INTO exchanges (code, name, country_id, currency_id, timezone) 
SELECT 'B3', 'B3 - Brasil Bolsa Balcão', 
       (SELECT id FROM countries WHERE code = 'BRA'), 
       (SELECT id FROM currencies WHERE code = 'BRL'), 
       'America/Sao_Paulo'
WHERE NOT EXISTS (SELECT 1 FROM exchanges WHERE code = 'B3');

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
SELECT (SELECT id FROM sectors WHERE code = 'FINL'), 'PAYMENTS', 'Payment Processing', 'Payment processing and financial technology'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'PAYMENTS');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'HLTH'), 'PHARMA', 'Pharmaceuticals', 'Pharmaceutical development and manufacturing'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'PHARMA');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'HLTH'), 'BIOTECH', 'Biotechnology', 'Biotechnology research and development'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'BIOTECH');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'HLTH'), 'MEDDEV', 'Medical Devices', 'Medical device manufacturing'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'MEDDEV');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CONS'), 'RETAIL', 'Retail', 'Retail and e-commerce'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'RETAIL');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CONS'), 'AUTO', 'Automotive', 'Automotive manufacturing and services'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'AUTO');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CONS'), 'MEDIA', 'Media & Entertainment', 'Media, entertainment, and content creation'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'MEDIA');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CSTA'), 'FOOD', 'Food & Beverages', 'Food and beverage production'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'FOOD');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'CSTA'), 'HOUSEHOLD', 'Household Products', 'Household and personal care products'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'HOUSEHOLD');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'ENRG'), 'OIL_GAS', 'Oil & Gas', 'Oil and gas exploration and production'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'OIL_GAS');

INSERT INTO industries (sector_id, code, name, description) 
SELECT (SELECT id FROM sectors WHERE code = 'ENRG'), 'RENEWABLE', 'Renewable Energy', 'Renewable energy and clean technology'
WHERE NOT EXISTS (SELECT 1 FROM industries WHERE code = 'RENEWABLE');

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

INSERT INTO security_types (code, name, description) 
SELECT 'OPTION', 'Option', 'Stock options'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'OPTION');

INSERT INTO security_types (code, name, description) 
SELECT 'FUTURE', 'Future', 'Futures contracts'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'FUTURE');

INSERT INTO security_types (code, name, description) 
SELECT 'WARRANT', 'Warrant', 'Stock warrants'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'WARRANT');

INSERT INTO security_types (code, name, description) 
SELECT 'ADR', 'American Depositary Receipt', 'American Depositary Receipts'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'ADR');

INSERT INTO security_types (code, name, description) 
SELECT 'REIT', 'Real Estate Investment Trust', 'Real Estate Investment Trusts'
WHERE NOT EXISTS (SELECT 1 FROM security_types WHERE code = 'REIT');

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

-- Insert market data sources
INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'Alpha Vantage', 'Real-time and historical stock market data', 'https://www.alphavantage.co/query', true, 5
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'Alpha Vantage');

INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'Yahoo Finance', 'Free stock market data', 'https://query1.finance.yahoo.com/v8/finance/chart', false, 2000
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'Yahoo Finance');

INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'Polygon.io', 'Real-time and historical market data', 'https://api.polygon.io/v2', true, 1000
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'Polygon.io');

INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'IEX Cloud', 'Financial data infrastructure', 'https://cloud.iexapis.com/stable', true, 100
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'IEX Cloud');

INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'Quandl', 'Financial and economic data', 'https://www.quandl.com/api/v3', true, 300
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'Quandl');

INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) 
SELECT 'Finnhub', 'Real-time stock market data', 'https://finnhub.io/api/v1', true, 60
WHERE NOT EXISTS (SELECT 1 FROM market_data_sources WHERE name = 'Finnhub');

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
SELECT 'screens.update', 'Modify screens', 'screens', 'update'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'screens.update');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'screens.delete', 'Delete screens', 'screens', 'delete'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'screens.delete');

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
SELECT 'backtests.update', 'Modify backtests', 'backtests', 'update'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'backtests.update');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'backtests.delete', 'Delete backtests', 'backtests', 'delete'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'backtests.delete');

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
SELECT 'watchlists.update', 'Modify watchlists', 'watchlists', 'update'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'watchlists.update');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'watchlists.delete', 'Delete watchlists', 'watchlists', 'delete'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'watchlists.delete');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'alerts.create', 'Create alerts', 'alerts', 'create'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'alerts.create');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'alerts.read', 'View alerts', 'alerts', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'alerts.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'alerts.update', 'Modify alerts', 'alerts', 'update'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'alerts.update');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'alerts.delete', 'Delete alerts', 'alerts', 'delete'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'alerts.delete');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'market_data.read', 'Access market data', 'market_data', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'market_data.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'financial_data.read', 'Access financial data', 'financial_data', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'financial_data.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'news.read', 'Access news data', 'news', 'read'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'news.read');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'admin.users', 'Manage users', 'users', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'admin.users');

INSERT INTO permissions (name, description, resource, action) 
SELECT 'admin.system', 'System administration', 'system', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'admin.system');

-- Insert indicator definitions
INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'SMA', 'Simple Moving Average', 'Simple moving average of closing prices', 'TREND', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'SMA');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'EMA', 'Exponential Moving Average', 'Exponential moving average of closing prices', 'TREND', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'EMA');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'RSI', 'Relative Strength Index', 'Momentum oscillator measuring speed and magnitude of price changes', 'MOMENTUM', 'PERCENTAGE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'RSI');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'MACD', 'Moving Average Convergence Divergence', 'Trend-following momentum indicator', 'MOMENTUM', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'MACD');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'BB', 'Bollinger Bands', 'Volatility bands around moving average', 'VOLATILITY', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'BB');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'STOCH', 'Stochastic Oscillator', 'Momentum indicator comparing closing price to price range', 'MOMENTUM', 'PERCENTAGE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'STOCH');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'ATR', 'Average True Range', 'Volatility indicator measuring price range', 'VOLATILITY', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'ATR');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'ADX', 'Average Directional Index', 'Trend strength indicator', 'TREND', 'INDEX'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'ADX');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'OBV', 'On Balance Volume', 'Volume-based momentum indicator', 'VOLUME', 'INDEX'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'OBV');

INSERT INTO indicator_definitions (code, name, description, category, data_type) 
SELECT 'VWAP', 'Volume Weighted Average Price', 'Average price weighted by volume', 'PRICE', 'PRICE'
WHERE NOT EXISTS (SELECT 1 FROM indicator_definitions WHERE code = 'VWAP');

-- Insert pattern types
INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'HEAD_SHOULDERS', 'Head and Shoulders', 'REVERSAL', 'Bearish reversal pattern', 25.0, 75.0, 15, 50
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'HEAD_SHOULDERS');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'DOUBLE_TOP', 'Double Top', 'REVERSAL', 'Bearish reversal pattern', 30.0, 70.0, 10, 30
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'DOUBLE_TOP');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'DOUBLE_BOTTOM', 'Double Bottom', 'REVERSAL', 'Bullish reversal pattern', 70.0, 30.0, 10, 30
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'DOUBLE_BOTTOM');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'TRIANGLE_ASCENDING', 'Ascending Triangle', 'CONTINUATION', 'Bullish continuation pattern', 65.0, 35.0, 8, 25
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'TRIANGLE_ASCENDING');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'TRIANGLE_DESCENDING', 'Descending Triangle', 'CONTINUATION', 'Bearish continuation pattern', 35.0, 65.0, 8, 25
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'TRIANGLE_DESCENDING');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'FLAG_BULL', 'Bull Flag', 'CONTINUATION', 'Bullish continuation pattern', 75.0, 25.0, 5, 15
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'FLAG_BULL');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'FLAG_BEAR', 'Bear Flag', 'CONTINUATION', 'Bearish continuation pattern', 25.0, 75.0, 5, 15
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'FLAG_BEAR');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'WEDGE_RISING', 'Rising Wedge', 'REVERSAL', 'Bearish reversal pattern', 30.0, 70.0, 10, 40
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'WEDGE_RISING');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'WEDGE_FALLING', 'Falling Wedge', 'REVERSAL', 'Bullish reversal pattern', 70.0, 30.0, 10, 40
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'WEDGE_FALLING');

INSERT INTO pattern_types (code, name, category, description, bullish_probability, bearish_probability, min_periods, max_periods) 
SELECT 'CUP_HANDLE', 'Cup and Handle', 'CONTINUATION', 'Bullish continuation pattern', 80.0, 20.0, 20, 60
WHERE NOT EXISTS (SELECT 1 FROM pattern_types WHERE code = 'CUP_HANDLE');

-- Insert event types
INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'EARNINGS', 'Earnings Release', 'EARNINGS', 'Quarterly earnings announcement', 'HIGH'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'EARNINGS');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'DIVIDEND', 'Dividend Declaration', 'CORPORATE_ACTION', 'Dividend payment announcement', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'DIVIDEND');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'SPLIT', 'Stock Split', 'CORPORATE_ACTION', 'Stock split announcement', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'SPLIT');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'MERGER', 'Merger & Acquisition', 'CORPORATE_ACTION', 'Merger or acquisition announcement', 'HIGH'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'MERGER');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'SPINOFF', 'Spinoff', 'CORPORATE_ACTION', 'Corporate spinoff', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'SPINOFF');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'GUIDANCE', 'Guidance Update', 'EARNINGS', 'Management guidance update', 'HIGH'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'GUIDANCE');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'FDA_APPROVAL', 'FDA Approval', 'REGULATORY', 'FDA drug approval', 'HIGH'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'FDA_APPROVAL');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'PRODUCT_LAUNCH', 'Product Launch', 'CORPORATE_ACTION', 'New product launch', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'PRODUCT_LAUNCH');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'EXECUTIVE_CHANGE', 'Executive Change', 'CORPORATE_ACTION', 'Executive appointment or departure', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'EXECUTIVE_CHANGE');

INSERT INTO event_types (code, name, category, description, impact_level) 
SELECT 'LAWSUIT', 'Legal Action', 'REGULATORY', 'Legal proceedings', 'MEDIUM'
WHERE NOT EXISTS (SELECT 1 FROM event_types WHERE code = 'LAWSUIT');

-- Insert news sources
INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'REUTERS', 'Reuters', 'https://www.reuters.com', 0.95, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'REUTERS');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'BLOOMBERG', 'Bloomberg', 'https://www.bloomberg.com', 0.92, 0.1
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'BLOOMBERG');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'WSJ', 'Wall Street Journal', 'https://www.wsj.com', 0.90, 0.2
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'WSJ');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'CNBC', 'CNBC', 'https://www.cnbc.com', 0.85, 0.1
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'CNBC');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'MARKETWATCH', 'MarketWatch', 'https://www.marketwatch.com', 0.82, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'MARKETWATCH');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'YAHOO_FINANCE', 'Yahoo Finance', 'https://finance.yahoo.com', 0.80, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'YAHOO_FINANCE');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'SEEKING_ALPHA', 'Seeking Alpha', 'https://seekingalpha.com', 0.75, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'SEEKING_ALPHA');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'MOTLEY_FOOL', 'The Motley Fool', 'https://www.fool.com', 0.70, 0.1
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'MOTLEY_FOOL');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'BENZINGA', 'Benzinga', 'https://www.benzinga.com', 0.72, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'BENZINGA');

INSERT INTO news_sources (code, name, website, credibility_score, bias_score) 
SELECT 'ZACKS', 'Zacks Investment Research', 'https://www.zacks.com', 0.78, 0.0
WHERE NOT EXISTS (SELECT 1 FROM news_sources WHERE code = 'ZACKS');

-- Insert news categories
INSERT INTO news_categories (code, name, description) 
SELECT 'EARNINGS', 'Earnings', 'Earnings reports and related news'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'EARNINGS');

INSERT INTO news_categories (code, name, description) 
SELECT 'MERGERS', 'Mergers & Acquisitions', 'M&A activity and rumors'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'MERGERS');

INSERT INTO news_categories (code, name, description) 
SELECT 'ANALYST', 'Analyst Coverage', 'Analyst ratings and price targets'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'ANALYST');

INSERT INTO news_categories (code, name, description) 
SELECT 'PRODUCT', 'Product News', 'New product launches and updates'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'PRODUCT');

INSERT INTO news_categories (code, name, description) 
SELECT 'REGULATORY', 'Regulatory', 'Regulatory approvals and compliance'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'REGULATORY');

INSERT INTO news_categories (code, name, description) 
SELECT 'EXECUTIVE', 'Executive News', 'Executive appointments and departures'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'EXECUTIVE');

INSERT INTO news_categories (code, name, description) 
SELECT 'FINANCIAL', 'Financial Results', 'Financial performance and metrics'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'FINANCIAL');

INSERT INTO news_categories (code, name, description) 
SELECT 'MARKET', 'Market News', 'General market and sector news'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'MARKET');

INSERT INTO news_categories (code, name, description) 
SELECT 'ECONOMIC', 'Economic News', 'Economic indicators and policy'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'ECONOMIC');

INSERT INTO news_categories (code, name, description) 
SELECT 'TECHNOLOGY', 'Technology', 'Technology developments and innovations'
WHERE NOT EXISTS (SELECT 1 FROM news_categories WHERE code = 'TECHNOLOGY');

-- Insert stakeholder types
INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'INDIVIDUAL', 'Individual Investor', 'INDIVIDUAL', 'Individual retail investor'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'INDIVIDUAL');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'MUTUAL_FUND', 'Mutual Fund', 'INSTITUTIONAL', 'Mutual fund company'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'MUTUAL_FUND');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'HEDGE_FUND', 'Hedge Fund', 'INSTITUTIONAL', 'Hedge fund'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'HEDGE_FUND');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'PENSION_FUND', 'Pension Fund', 'INSTITUTIONAL', 'Pension fund'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'PENSION_FUND');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'INSURANCE', 'Insurance Company', 'INSTITUTIONAL', 'Insurance company'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'INSURANCE');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'BANK', 'Bank', 'INSTITUTIONAL', 'Commercial or investment bank'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'BANK');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'SOVEREIGN', 'Sovereign Wealth Fund', 'GOVERNMENT', 'Government investment fund'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'SOVEREIGN');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'ENDOWMENT', 'Endowment', 'INSTITUTIONAL', 'University or foundation endowment'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'ENDOWMENT');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'FAMILY_OFFICE', 'Family Office', 'INSTITUTIONAL', 'Family office'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'FAMILY_OFFICE');

INSERT INTO stakeholder_types (code, name, category, description) 
SELECT 'INSIDER', 'Corporate Insider', 'INSIDER', 'Company executive or board member'
WHERE NOT EXISTS (SELECT 1 FROM stakeholder_types WHERE code = 'INSIDER');

-- Insert economic indicators
INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'GDP', 'Gross Domestic Product', 'Total economic output', 'GDP', 'QUARTERLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'GDP');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'CPI', 'Consumer Price Index', 'Inflation measure', 'INFLATION', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'CPI');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'UNEMPLOYMENT', 'Unemployment Rate', 'Percentage of unemployed workers', 'EMPLOYMENT', 'MONTHLY', 'Percentage', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'UNEMPLOYMENT');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'FED_RATE', 'Federal Funds Rate', 'Federal Reserve interest rate', 'INTEREST_RATES', 'IRREGULAR', 'Percentage', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'FED_RATE');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'RETAIL_SALES', 'Retail Sales', 'Consumer spending measure', 'CONSUMPTION', 'MONTHLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'RETAIL_SALES');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'INDUSTRIAL_PRODUCTION', 'Industrial Production', 'Manufacturing output', 'PRODUCTION', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'INDUSTRIAL_PRODUCTION');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'HOUSING_STARTS', 'Housing Starts', 'New residential construction', 'HOUSING', 'MONTHLY', 'Thousands', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'HOUSING_STARTS');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'TRADE_BALANCE', 'Trade Balance', 'Exports minus imports', 'TRADE', 'MONTHLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'TRADE_BALANCE');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'CONSUMER_CONFIDENCE', 'Consumer Confidence', 'Consumer sentiment index', 'SENTIMENT', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'CONSUMER_CONFIDENCE');

INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) 
SELECT 'PMI', 'Purchasing Managers Index', 'Manufacturing activity index', 'MANUFACTURING', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')
WHERE NOT EXISTS (SELECT 1 FROM economic_indicators WHERE code = 'PMI');

-- Insert ratio definitions
INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'GROSS_MARGIN', 'Gross Margin', 'PROFITABILITY', 'Gross profit as percentage of revenue', '(Revenue - COGS) / Revenue * 100'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'GROSS_MARGIN');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'OPERATING_MARGIN', 'Operating Margin', 'PROFITABILITY', 'Operating income as percentage of revenue', 'Operating Income / Revenue * 100'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'OPERATING_MARGIN');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'NET_MARGIN', 'Net Margin', 'PROFITABILITY', 'Net income as percentage of revenue', 'Net Income / Revenue * 100'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'NET_MARGIN');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'ROA', 'Return on Assets', 'PROFITABILITY', 'Net income as percentage of total assets', 'Net Income / Total Assets * 100'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'ROA');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'ROE', 'Return on Equity', 'PROFITABILITY', 'Net income as percentage of shareholders equity', 'Net Income / Shareholders Equity * 100'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'ROE');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'CURRENT_RATIO', 'Current Ratio', 'LIQUIDITY', 'Current assets divided by current liabilities', 'Current Assets / Current Liabilities'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'CURRENT_RATIO');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'QUICK_RATIO', 'Quick Ratio', 'LIQUIDITY', 'Quick assets divided by current liabilities', '(Current Assets - Inventory) / Current Liabilities'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'QUICK_RATIO');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'DEBT_TO_EQUITY', 'Debt-to-Equity', 'LEVERAGE', 'Total debt divided by shareholders equity', 'Total Debt / Shareholders Equity'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'DEBT_TO_EQUITY');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'INTEREST_COVERAGE', 'Interest Coverage', 'LEVERAGE', 'Operating income divided by interest expense', 'Operating Income / Interest Expense'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'INTEREST_COVERAGE');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'ASSET_TURNOVER', 'Asset Turnover', 'EFFICIENCY', 'Revenue divided by average total assets', 'Revenue / Average Total Assets'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'ASSET_TURNOVER');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'INVENTORY_TURNOVER', 'Inventory Turnover', 'EFFICIENCY', 'Cost of goods sold divided by average inventory', 'COGS / Average Inventory'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'INVENTORY_TURNOVER');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'PE_RATIO', 'Price-to-Earnings', 'VALUATION', 'Stock price divided by earnings per share', 'Stock Price / EPS'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'PE_RATIO');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'PB_RATIO', 'Price-to-Book', 'VALUATION', 'Stock price divided by book value per share', 'Stock Price / Book Value per Share'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'PB_RATIO');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'PS_RATIO', 'Price-to-Sales', 'VALUATION', 'Market cap divided by revenue', 'Market Cap / Revenue'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'PS_RATIO');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'EV_REVENUE', 'EV/Revenue', 'VALUATION', 'Enterprise value divided by revenue', 'Enterprise Value / Revenue'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'EV_REVENUE');

INSERT INTO ratio_definitions (code, name, category, description, formula) 
SELECT 'EV_EBITDA', 'EV/EBITDA', 'VALUATION', 'Enterprise value divided by EBITDA', 'Enterprise Value / EBITDA'
WHERE NOT EXISTS (SELECT 1 FROM ratio_definitions WHERE code = 'EV_EBITDA');

-- Update table statistics
ANALYZE countries;
ANALYZE currencies;
ANALYZE exchanges;
ANALYZE sectors;
ANALYZE industries;
ANALYZE security_types;
ANALYZE companies;
ANALYZE securities;
ANALYZE market_data_sources;
ANALYZE roles;
ANALYZE permissions;
ANALYZE indicator_definitions;
ANALYZE pattern_types;
ANALYZE event_types;
ANALYZE news_sources;
ANALYZE news_categories;
ANALYZE stakeholder_types;
ANALYZE economic_indicators;
ANALYZE ratio_definitions;