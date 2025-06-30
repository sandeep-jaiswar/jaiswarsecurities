-- ClickHouse Core Tables Migration
-- Migrated from Supabase PostgreSQL schema to ClickHouse

USE stockdb;

-- Countries table
CREATE TABLE IF NOT EXISTS countries (
    id UInt32,
    code String,
    name String,
    alpha_2 String,
    region String,
    sub_region String,
    currency_code String,
    phone_code String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Currencies table
CREATE TABLE IF NOT EXISTS currencies (
    id UInt32,
    code String,
    name String,
    symbol String,
    decimal_places UInt8 DEFAULT 2,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Exchanges table
CREATE TABLE IF NOT EXISTS exchanges (
    id UInt32,
    code String,
    name String,
    country_id UInt32,
    currency_id UInt32,
    timezone String,
    trading_hours String, -- JSON as String in ClickHouse
    website String,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Sectors table
CREATE TABLE IF NOT EXISTS sectors (
    id UInt32,
    code String,
    name String,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Industries table
CREATE TABLE IF NOT EXISTS industries (
    id UInt32,
    sector_id UInt32,
    code String,
    name String,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Security Types table
CREATE TABLE IF NOT EXISTS security_types (
    id UInt32,
    code String,
    name String,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Companies table (enhanced from Supabase)
CREATE TABLE IF NOT EXISTS companies (
    id UInt32,
    cik String,
    lei String,
    name String,
    legal_name String,
    short_name String,
    former_names Array(String),
    sector_id UInt32,
    industry_id UInt32,
    sub_industry String,
    headquarters_country_id UInt32,
    headquarters_address String, -- JSON as String
    incorporation_country_id UInt32,
    incorporation_date Date,
    business_description String,
    website String,
    phone String,
    email String,
    employee_count UInt32,
    fiscal_year_end String,
    is_active UInt8 DEFAULT 1,
    is_public UInt8 DEFAULT 1,
    delisting_date Date,
    delisting_reason String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Securities table (enhanced from Supabase)
CREATE TABLE IF NOT EXISTS securities (
    id UInt32,
    company_id UInt32,
    security_type_id UInt32,
    symbol String,
    isin String,
    cusip String,
    sedol String,
    exchange_id UInt32,
    currency_id UInt32,
    name String,
    description String,
    shares_outstanding UInt64,
    shares_float UInt64,
    par_value Decimal(15, 4),
    is_active UInt8 DEFAULT 1,
    listing_date Date,
    delisting_date Date,
    trading_status String DEFAULT 'ACTIVE',
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (symbol, exchange_id)
SETTINGS index_granularity = 8192;

-- Trading Sessions table
CREATE TABLE IF NOT EXISTS trading_sessions (
    id UInt32,
    exchange_id UInt32,
    session_date Date,
    session_type String,
    open_time DateTime,
    close_time DateTime,
    is_trading_day UInt8 DEFAULT 1,
    holiday_name String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (exchange_id, session_date)
SETTINGS index_granularity = 8192;