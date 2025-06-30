-- ClickHouse Stakeholders and Ownership Tables
-- Comprehensive ownership and insider trading data

USE stockdb;

-- Stakeholder Types table
CREATE TABLE IF NOT EXISTS stakeholder_types (
    id UInt32,
    code String,
    name String,
    category String,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Stakeholders table
CREATE TABLE IF NOT EXISTS stakeholders (
    id UInt64,
    stakeholder_type_id UInt32,
    name String,
    legal_name String,
    short_name String,
    first_name String,
    last_name String,
    middle_name String,
    title String,
    organization_type String,
    parent_organization_id UInt64,
    address String, -- JSON as String
    phone String,
    email String,
    website String,
    cik String,
    lei String,
    tax_id String,
    country_id UInt32,
    is_insider UInt8 DEFAULT 0,
    is_institutional UInt8 DEFAULT 0,
    is_active UInt8 DEFAULT 1,
    aum Decimal(20, 2),
    aum_date Date,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Stakeholder Relationships table
CREATE TABLE IF NOT EXISTS stakeholder_relationships (
    id UInt64,
    stakeholder_id UInt64,
    related_stakeholder_id UInt64,
    relationship_type String,
    relationship_description String,
    start_date Date,
    end_date Date,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (stakeholder_id, related_stakeholder_id)
SETTINGS index_granularity = 8192;

-- Ownership Records table
CREATE TABLE IF NOT EXISTS ownership_records (
    id UInt64,
    company_id UInt32,
    stakeholder_id UInt64,
    shares_owned UInt64,
    ownership_percentage Decimal(8, 4),
    voting_percentage Decimal(8, 4),
    position_type String,
    security_type String,
    as_of_date Date,
    filing_date Date,
    form_type String,
    filing_url String,
    change_in_shares Int64,
    change_percentage Decimal(8, 4),
    cost_basis Decimal(15, 4),
    market_value Decimal(20, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(as_of_date)
ORDER BY (company_id, stakeholder_id, as_of_date)
SETTINGS index_granularity = 8192;

-- Ownership Changes table
CREATE TABLE IF NOT EXISTS ownership_changes (
    id UInt64,
    ownership_record_id UInt64,
    change_type String,
    transaction_date Date,
    shares_transacted UInt64,
    price_per_share Decimal(15, 4),
    total_value Decimal(20, 2),
    shares_before UInt64,
    shares_after UInt64,
    percentage_before Decimal(8, 4),
    percentage_after Decimal(8, 4),
    transaction_code String,
    equity_swap_involved UInt8 DEFAULT 0,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(transaction_date)
ORDER BY (ownership_record_id, transaction_date)
SETTINGS index_granularity = 8192;

-- Insider Transactions table
CREATE TABLE IF NOT EXISTS insider_transactions (
    id UInt64,
    company_id UInt32,
    stakeholder_id UInt64,
    transaction_date Date,
    transaction_type String,
    security_type String,
    shares_transacted UInt64,
    price_per_share Decimal(15, 4),
    total_value Decimal(20, 2),
    shares_owned_after UInt64,
    form_type String,
    filing_date Date,
    filing_url String,
    transaction_code String,
    acquisition_disposition String,
    is_10b5_1_plan UInt8 DEFAULT 0,
    is_derivative UInt8 DEFAULT 0,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(transaction_date)
ORDER BY (company_id, transaction_date)
SETTINGS index_granularity = 8192;

-- Executives table
CREATE TABLE IF NOT EXISTS executives (
    id UInt64,
    company_id UInt32,
    stakeholder_id UInt64,
    title String,
    department String,
    level String,
    start_date Date,
    end_date Date,
    is_current UInt8 DEFAULT 1,
    reports_to_id UInt64,
    biography String,
    education String, -- JSON as String
    previous_experience String, -- JSON as String
    base_salary Decimal(15, 2),
    total_compensation Decimal(15, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (company_id, stakeholder_id)
SETTINGS index_granularity = 8192;

-- Board Members table
CREATE TABLE IF NOT EXISTS board_members (
    id UInt64,
    company_id UInt32,
    stakeholder_id UInt64,
    position String,
    committee_memberships Array(String),
    appointment_date Date,
    term_end_date Date,
    is_current UInt8 DEFAULT 1,
    is_independent UInt8 DEFAULT 1,
    is_executive UInt8 DEFAULT 0,
    age UInt32,
    qualifications Array(String),
    other_board_positions String, -- JSON as String
    annual_retainer Decimal(15, 2),
    meeting_fees Decimal(15, 2),
    equity_compensation Decimal(15, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (company_id, stakeholder_id)
SETTINGS index_granularity = 8192;

-- Executive Compensation table
CREATE TABLE IF NOT EXISTS executive_compensation (
    id UInt64,
    executive_id UInt64,
    fiscal_year UInt32,
    base_salary Decimal(15, 2),
    bonus Decimal(15, 2),
    non_equity_incentive Decimal(15, 2),
    stock_awards Decimal(15, 2),
    option_awards Decimal(15, 2),
    other_compensation Decimal(15, 2),
    pension_value Decimal(15, 2),
    deferred_compensation Decimal(15, 2),
    total_compensation Decimal(15, 2),
    ceo_pay_ratio Decimal(8, 2),
    median_employee_ratio Decimal(8, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (executive_id, fiscal_year)
SETTINGS index_granularity = 8192;