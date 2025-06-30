/*
  # Seed Data for Stock Screening System
  
  This file contains initial data to populate the database with:
  1. Reference data (countries, currencies, exchanges, sectors)
  2. Sample companies and securities
  3. System configuration data
  4. Default user roles and permissions
*/

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

-- Insert market data sources
INSERT INTO market_data_sources (name, description, api_endpoint, api_key_required, rate_limit_per_minute) VALUES
('Alpha Vantage', 'Real-time and historical stock market data', 'https://www.alphavantage.co/query', true, 5),
('Yahoo Finance', 'Free stock market data', 'https://query1.finance.yahoo.com/v8/finance/chart', false, 2000),
('Polygon.io', 'Real-time and historical market data', 'https://api.polygon.io/v2', true, 1000),
('IEX Cloud', 'Financial data infrastructure', 'https://cloud.iexapis.com/stable', true, 100),
('Quandl', 'Financial and economic data', 'https://www.quandl.com/api/v3', true, 300),
('Finnhub', 'Real-time stock market data', 'https://finnhub.io/api/v1', true, 60)
ON CONFLICT (name) DO NOTHING;

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

-- Insert indicator definitions
INSERT INTO indicator_definitions (code, name, description, category, data_type) VALUES
('SMA', 'Simple Moving Average', 'Simple moving average of closing prices', 'TREND', 'PRICE'),
('EMA', 'Exponential Moving Average', 'Exponential moving average of closing prices', 'TREND', 'PRICE'),
('RSI', 'Relative Strength Index', 'Momentum oscillator measuring speed and magnitude of price changes', 'MOMENTUM', 'PERCENTAGE'),
('MACD', 'Moving Average Convergence Divergence', 'Trend-following momentum indicator', 'MOMENTUM', 'PRICE'),
('BB', 'Bollinger Bands', 'Volatility bands around moving average', 'VOLATILITY', 'PRICE'),
('STOCH', 'Stochastic Oscillator', 'Momentum indicator comparing closing price to price range', 'MOMENTUM', 'PERCENTAGE'),
('ATR', 'Average True Range', 'Volatility indicator measuring price range', 'VOLATILITY', 'PRICE'),
('ADX', 'Average Directional Index', 'Trend strength indicator', 'TREND', 'INDEX'),
('OBV', 'On Balance Volume', 'Volume-based momentum indicator', 'VOLUME', 'INDEX'),
('VWAP', 'Volume Weighted Average Price', 'Average price weighted by volume', 'PRICE', 'PRICE')
ON CONFLICT (code) DO NOTHING;

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

-- Insert event types
INSERT INTO event_types (code, name, category, description, impact_level) VALUES
('EARNINGS', 'Earnings Release', 'EARNINGS', 'Quarterly earnings announcement', 'HIGH'),
('DIVIDEND', 'Dividend Declaration', 'CORPORATE_ACTION', 'Dividend payment announcement', 'MEDIUM'),
('SPLIT', 'Stock Split', 'CORPORATE_ACTION', 'Stock split announcement', 'MEDIUM'),
('MERGER', 'Merger & Acquisition', 'CORPORATE_ACTION', 'Merger or acquisition announcement', 'HIGH'),
('SPINOFF', 'Spinoff', 'CORPORATE_ACTION', 'Corporate spinoff', 'MEDIUM'),
('GUIDANCE', 'Guidance Update', 'EARNINGS', 'Management guidance update', 'HIGH'),
('FDA_APPROVAL', 'FDA Approval', 'REGULATORY', 'FDA drug approval', 'HIGH'),
('PRODUCT_LAUNCH', 'Product Launch', 'CORPORATE_ACTION', 'New product launch', 'MEDIUM'),
('EXECUTIVE_CHANGE', 'Executive Change', 'CORPORATE_ACTION', 'Executive appointment or departure', 'MEDIUM'),
('LAWSUIT', 'Legal Action', 'REGULATORY', 'Legal proceedings', 'MEDIUM')
ON CONFLICT (code) DO NOTHING;

-- Insert news sources
INSERT INTO news_sources (code, name, website, credibility_score, bias_score) VALUES
('REUTERS', 'Reuters', 'https://www.reuters.com', 0.95, 0.0),
('BLOOMBERG', 'Bloomberg', 'https://www.bloomberg.com', 0.92, 0.1),
('WSJ', 'Wall Street Journal', 'https://www.wsj.com', 0.90, 0.2),
('CNBC', 'CNBC', 'https://www.cnbc.com', 0.85, 0.1),
('MARKETWATCH', 'MarketWatch', 'https://www.marketwatch.com', 0.82, 0.0),
('YAHOO_FINANCE', 'Yahoo Finance', 'https://finance.yahoo.com', 0.80, 0.0),
('SEEKING_ALPHA', 'Seeking Alpha', 'https://seekingalpha.com', 0.75, 0.0),
('MOTLEY_FOOL', 'The Motley Fool', 'https://www.fool.com', 0.70, 0.1),
('BENZINGA', 'Benzinga', 'https://www.benzinga.com', 0.72, 0.0),
('ZACKS', 'Zacks Investment Research', 'https://www.zacks.com', 0.78, 0.0)
ON CONFLICT (code) DO NOTHING;

-- Insert news categories
INSERT INTO news_categories (code, name, description) VALUES
('EARNINGS', 'Earnings', 'Earnings reports and related news'),
('MERGERS', 'Mergers & Acquisitions', 'M&A activity and rumors'),
('ANALYST', 'Analyst Coverage', 'Analyst ratings and price targets'),
('PRODUCT', 'Product News', 'New product launches and updates'),
('REGULATORY', 'Regulatory', 'Regulatory approvals and compliance'),
('EXECUTIVE', 'Executive News', 'Executive appointments and departures'),
('FINANCIAL', 'Financial Results', 'Financial performance and metrics'),
('MARKET', 'Market News', 'General market and sector news'),
('ECONOMIC', 'Economic News', 'Economic indicators and policy'),
('TECHNOLOGY', 'Technology', 'Technology developments and innovations')
ON CONFLICT (code) DO NOTHING;

-- Insert stakeholder types
INSERT INTO stakeholder_types (code, name, category, description) VALUES
('INDIVIDUAL', 'Individual Investor', 'INDIVIDUAL', 'Individual retail investor'),
('MUTUAL_FUND', 'Mutual Fund', 'INSTITUTIONAL', 'Mutual fund company'),
('HEDGE_FUND', 'Hedge Fund', 'INSTITUTIONAL', 'Hedge fund'),
('PENSION_FUND', 'Pension Fund', 'INSTITUTIONAL', 'Pension fund'),
('INSURANCE', 'Insurance Company', 'INSTITUTIONAL', 'Insurance company'),
('BANK', 'Bank', 'INSTITUTIONAL', 'Commercial or investment bank'),
('SOVEREIGN', 'Sovereign Wealth Fund', 'GOVERNMENT', 'Government investment fund'),
('ENDOWMENT', 'Endowment', 'INSTITUTIONAL', 'University or foundation endowment'),
('FAMILY_OFFICE', 'Family Office', 'INSTITUTIONAL', 'Family office'),
('INSIDER', 'Corporate Insider', 'INSIDER', 'Company executive or board member')
ON CONFLICT (code) DO NOTHING;

-- Insert economic indicators
INSERT INTO economic_indicators (code, name, description, category, frequency, unit, country_id) VALUES
('GDP', 'Gross Domestic Product', 'Total economic output', 'GDP', 'QUARTERLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')),
('CPI', 'Consumer Price Index', 'Inflation measure', 'INFLATION', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')),
('UNEMPLOYMENT', 'Unemployment Rate', 'Percentage of unemployed workers', 'EMPLOYMENT', 'MONTHLY', 'Percentage', (SELECT id FROM countries WHERE code = 'USA')),
('FED_RATE', 'Federal Funds Rate', 'Federal Reserve interest rate', 'INTEREST_RATES', 'IRREGULAR', 'Percentage', (SELECT id FROM countries WHERE code = 'USA')),
('RETAIL_SALES', 'Retail Sales', 'Consumer spending measure', 'CONSUMPTION', 'MONTHLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')),
('INDUSTRIAL_PRODUCTION', 'Industrial Production', 'Manufacturing output', 'PRODUCTION', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')),
('HOUSING_STARTS', 'Housing Starts', 'New residential construction', 'HOUSING', 'MONTHLY', 'Thousands', (SELECT id FROM countries WHERE code = 'USA')),
('TRADE_BALANCE', 'Trade Balance', 'Exports minus imports', 'TRADE', 'MONTHLY', 'Billions USD', (SELECT id FROM countries WHERE code = 'USA')),
('CONSUMER_CONFIDENCE', 'Consumer Confidence', 'Consumer sentiment index', 'SENTIMENT', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA')),
('PMI', 'Purchasing Managers Index', 'Manufacturing activity index', 'MANUFACTURING', 'MONTHLY', 'Index', (SELECT id FROM countries WHERE code = 'USA'))
ON CONFLICT (code) DO NOTHING;

-- Insert screen criteria
INSERT INTO screen_criteria (code, name, description, category, data_type, operator_types) VALUES
('MARKET_CAP', 'Market Capitalization', 'Total market value of company shares', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('PE_RATIO', 'Price-to-Earnings Ratio', 'Stock price divided by earnings per share', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('PB_RATIO', 'Price-to-Book Ratio', 'Stock price divided by book value per share', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('DIVIDEND_YIELD', 'Dividend Yield', 'Annual dividend divided by stock price', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('ROE', 'Return on Equity', 'Net income divided by shareholders equity', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('DEBT_TO_EQUITY', 'Debt-to-Equity Ratio', 'Total debt divided by shareholders equity', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('REVENUE_GROWTH', 'Revenue Growth', 'Year-over-year revenue growth rate', 'FUNDAMENTAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('RSI_14', 'RSI (14-day)', 'Relative Strength Index over 14 days', 'TECHNICAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('PRICE_VS_SMA50', 'Price vs SMA(50)', 'Current price relative to 50-day moving average', 'TECHNICAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN']),
('VOLUME_RATIO', 'Volume Ratio', 'Current volume relative to average volume', 'TECHNICAL', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN']),
('PRICE_CHANGE_1D', '1-Day Price Change', 'Price change over 1 day', 'PRICE', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('PRICE_CHANGE_1W', '1-Week Price Change', 'Price change over 1 week', 'PRICE', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('PRICE_CHANGE_1M', '1-Month Price Change', 'Price change over 1 month', 'PRICE', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('AVG_VOLUME', 'Average Volume', 'Average daily trading volume', 'VOLUME', 'NUMERIC', ARRAY['GREATER_THAN', 'LESS_THAN', 'BETWEEN']),
('SECTOR', 'Sector', 'Company sector classification', 'FUNDAMENTAL', 'STRING', ARRAY['EQUALS', 'IN', 'NOT_IN']),
('EXCHANGE', 'Exchange', 'Stock exchange listing', 'FUNDAMENTAL', 'STRING', ARRAY['EQUALS', 'IN', 'NOT_IN'])
ON CONFLICT (code) DO NOTHING;

-- Insert ratio definitions
INSERT INTO ratio_definitions (code, name, category, description, formula) VALUES
('GROSS_MARGIN', 'Gross Margin', 'PROFITABILITY', 'Gross profit as percentage of revenue', '(Revenue - COGS) / Revenue * 100'),
('OPERATING_MARGIN', 'Operating Margin', 'PROFITABILITY', 'Operating income as percentage of revenue', 'Operating Income / Revenue * 100'),
('NET_MARGIN', 'Net Margin', 'PROFITABILITY', 'Net income as percentage of revenue', 'Net Income / Revenue * 100'),
('ROA', 'Return on Assets', 'PROFITABILITY', 'Net income as percentage of total assets', 'Net Income / Total Assets * 100'),
('ROE', 'Return on Equity', 'PROFITABILITY', 'Net income as percentage of shareholders equity', 'Net Income / Shareholders Equity * 100'),
('CURRENT_RATIO', 'Current Ratio', 'LIQUIDITY', 'Current assets divided by current liabilities', 'Current Assets / Current Liabilities'),
('QUICK_RATIO', 'Quick Ratio', 'LIQUIDITY', 'Quick assets divided by current liabilities', '(Current Assets - Inventory) / Current Liabilities'),
('DEBT_TO_EQUITY', 'Debt-to-Equity', 'LEVERAGE', 'Total debt divided by shareholders equity', 'Total Debt / Shareholders Equity'),
('INTEREST_COVERAGE', 'Interest Coverage', 'LEVERAGE', 'Operating income divided by interest expense', 'Operating Income / Interest Expense'),
('ASSET_TURNOVER', 'Asset Turnover', 'EFFICIENCY', 'Revenue divided by average total assets', 'Revenue / Average Total Assets'),
('INVENTORY_TURNOVER', 'Inventory Turnover', 'EFFICIENCY', 'Cost of goods sold divided by average inventory', 'COGS / Average Inventory'),
('PE_RATIO', 'Price-to-Earnings', 'VALUATION', 'Stock price divided by earnings per share', 'Stock Price / EPS'),
('PB_RATIO', 'Price-to-Book', 'VALUATION', 'Stock price divided by book value per share', 'Stock Price / Book Value per Share'),
('PS_RATIO', 'Price-to-Sales', 'VALUATION', 'Market cap divided by revenue', 'Market Cap / Revenue'),
('EV_REVENUE', 'EV/Revenue', 'VALUATION', 'Enterprise value divided by revenue', 'Enterprise Value / Revenue'),
('EV_EBITDA', 'EV/EBITDA', 'VALUATION', 'Enterprise value divided by EBITDA', 'Enterprise Value / EBITDA')
ON CONFLICT (code) DO NOTHING;

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
ANALYZE screen_criteria;
ANALYZE ratio_definitions;