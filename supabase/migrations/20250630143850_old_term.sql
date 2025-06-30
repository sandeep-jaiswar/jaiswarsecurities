/*
  # Core Company and Market Data Tables
  
  1. Core Tables
    - companies: Master company information
    - exchanges: Stock exchanges
    - sectors_industries: Sector and industry classifications
    - currencies: Currency definitions
    - countries: Country information
  
  2. Security Tables
    - securities: Individual securities (stocks, bonds, etc.)
    - security_types: Types of securities
    - trading_sessions: Trading session information
*/

-- Countries table
CREATE TABLE IF NOT EXISTS countries (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) UNIQUE NOT NULL, -- ISO 3166-1 alpha-3
    name VARCHAR(100) NOT NULL,
    alpha_2 VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2
    region VARCHAR(50),
    sub_region VARCHAR(50),
    currency_code VARCHAR(3),
    phone_code VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Currencies table
CREATE TABLE IF NOT EXISTS currencies (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) UNIQUE NOT NULL, -- ISO 4217
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimal_places INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exchanges table
CREATE TABLE IF NOT EXISTS exchanges (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL, -- NYSE, NASDAQ, LSE, etc.
    name VARCHAR(100) NOT NULL,
    country_id INTEGER REFERENCES countries(id),
    currency_id INTEGER REFERENCES currencies(id),
    timezone VARCHAR(50),
    trading_hours JSONB, -- {"open": "09:30", "close": "16:00", "days": ["MON", "TUE", "WED", "THU", "FRI"]}
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sectors and Industries
CREATE TABLE IF NOT EXISTS sectors (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS industries (
    id SERIAL PRIMARY KEY,
    sector_id INTEGER REFERENCES sectors(id),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Security types
CREATE TABLE IF NOT EXISTS security_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL, -- STOCK, BOND, ETF, OPTION, FUTURE, etc.
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Companies master table
CREATE TABLE IF NOT EXISTS companies (
    id SERIAL PRIMARY KEY,
    cik VARCHAR(20) UNIQUE, -- SEC Central Index Key
    lei VARCHAR(20) UNIQUE, -- Legal Entity Identifier
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(300),
    short_name VARCHAR(100),
    former_names TEXT[], -- Array of former company names
    
    -- Classification
    sector_id INTEGER REFERENCES sectors(id),
    industry_id INTEGER REFERENCES industries(id),
    sub_industry VARCHAR(100),
    
    -- Location
    headquarters_country_id INTEGER REFERENCES countries(id),
    headquarters_address JSONB, -- Full address structure
    incorporation_country_id INTEGER REFERENCES countries(id),
    incorporation_date DATE,
    
    -- Business Information
    business_description TEXT,
    website VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(100),
    
    -- Company Details
    employee_count INTEGER,
    fiscal_year_end VARCHAR(5), -- MM-DD format
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    delisting_date DATE,
    delisting_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Securities table (stocks, bonds, ETFs, etc.)
CREATE TABLE IF NOT EXISTS securities (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    security_type_id INTEGER REFERENCES security_types(id),
    
    -- Identifiers
    symbol VARCHAR(20) NOT NULL,
    isin VARCHAR(12) UNIQUE, -- International Securities Identification Number
    cusip VARCHAR(9), -- Committee on Uniform Securities Identification Procedures
    sedol VARCHAR(7), -- Stock Exchange Daily Official List
    
    -- Trading Information
    exchange_id INTEGER REFERENCES exchanges(id),
    currency_id INTEGER REFERENCES currencies(id),
    
    -- Security Details
    name VARCHAR(200) NOT NULL,
    description TEXT,
    shares_outstanding BIGINT,
    shares_float BIGINT,
    par_value DECIMAL(15,4),
    
    -- Trading Status
    is_active BOOLEAN DEFAULT TRUE,
    listing_date DATE,
    delisting_date DATE,
    trading_status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, HALTED, DELISTED
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(symbol, exchange_id)
);

-- Trading sessions
CREATE TABLE IF NOT EXISTS trading_sessions (
    id SERIAL PRIMARY KEY,
    exchange_id INTEGER REFERENCES exchanges(id),
    session_date DATE NOT NULL,
    session_type VARCHAR(20) NOT NULL, -- REGULAR, PRE_MARKET, AFTER_HOURS
    open_time TIMESTAMPTZ,
    close_time TIMESTAMPTZ,
    is_trading_day BOOLEAN DEFAULT TRUE,
    holiday_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(exchange_id, session_date, session_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_companies_sector ON companies(sector_id);
CREATE INDEX IF NOT EXISTS idx_companies_industry ON companies(industry_id);
CREATE INDEX IF NOT EXISTS idx_companies_country ON companies(headquarters_country_id);
CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(is_active);
CREATE INDEX IF NOT EXISTS idx_companies_public ON companies(is_public);

CREATE INDEX IF NOT EXISTS idx_securities_company ON securities(company_id);
CREATE INDEX IF NOT EXISTS idx_securities_exchange ON securities(exchange_id);
CREATE INDEX IF NOT EXISTS idx_securities_symbol ON securities(symbol);
CREATE INDEX IF NOT EXISTS idx_securities_active ON securities(is_active);
CREATE INDEX IF NOT EXISTS idx_securities_type ON securities(security_type_id);

CREATE INDEX IF NOT EXISTS idx_trading_sessions_exchange_date ON trading_sessions(exchange_id, session_date);