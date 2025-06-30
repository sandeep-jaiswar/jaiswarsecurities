/*
  # Stakeholders and Ownership Tables
  
  1. Stakeholders
    - stakeholders: Individual and institutional stakeholders
    - stakeholder_types: Types of stakeholders
    - stakeholder_relationships: Relationships between stakeholders
  
  2. Ownership
    - ownership_records: Ownership positions
    - ownership_changes: Changes in ownership
    - insider_transactions: Insider trading activity
  
  3. Management
    - executives: Company executives
    - board_members: Board of directors
    - compensation: Executive compensation
*/

-- Stakeholder types
CREATE TABLE IF NOT EXISTS stakeholder_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- INDIVIDUAL, INSTITUTIONAL, GOVERNMENT, INSIDER
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stakeholders (individuals and institutions)
CREATE TABLE IF NOT EXISTS stakeholders (
    id BIGSERIAL PRIMARY KEY,
    stakeholder_type_id INTEGER REFERENCES stakeholder_types(id),
    
    -- Basic information
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(300),
    short_name VARCHAR(100),
    
    -- Individual-specific fields
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    middle_name VARCHAR(100),
    title VARCHAR(100),
    
    -- Organization-specific fields
    organization_type VARCHAR(50), -- MUTUAL_FUND, HEDGE_FUND, PENSION_FUND, BANK, etc.
    parent_organization_id BIGINT REFERENCES stakeholders(id),
    
    -- Contact information
    address JSONB,
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(255),
    
    -- Identifiers
    cik VARCHAR(20), -- SEC Central Index Key
    lei VARCHAR(20), -- Legal Entity Identifier
    tax_id VARCHAR(50),
    
    -- Classification
    country_id INTEGER REFERENCES countries(id),
    is_insider BOOLEAN DEFAULT FALSE,
    is_institutional BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Assets under management (for institutions)
    aum DECIMAL(20,2),
    aum_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stakeholder relationships
CREATE TABLE IF NOT EXISTS stakeholder_relationships (
    id BIGSERIAL PRIMARY KEY,
    stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    related_stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    
    relationship_type VARCHAR(50) NOT NULL, -- SUBSIDIARY, AFFILIATE, ADVISOR, FAMILY, etc.
    relationship_description TEXT,
    
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(stakeholder_id, related_stakeholder_id, relationship_type)
);

-- Ownership records
CREATE TABLE IF NOT EXISTS ownership_records (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    
    -- Ownership details
    shares_owned BIGINT NOT NULL,
    ownership_percentage DECIMAL(8,4),
    voting_percentage DECIMAL(8,4),
    
    -- Position details
    position_type VARCHAR(50), -- DIRECT, INDIRECT, BENEFICIAL
    security_type VARCHAR(50), -- COMMON_STOCK, PREFERRED_STOCK, OPTIONS, WARRANTS
    
    -- Timing
    as_of_date DATE NOT NULL,
    filing_date DATE,
    
    -- Filing information
    form_type VARCHAR(20), -- 13F, 13G, 13D, 4, etc.
    filing_url VARCHAR(500),
    
    -- Position changes
    change_in_shares BIGINT,
    change_percentage DECIMAL(8,4),
    
    -- Additional data
    cost_basis DECIMAL(15,4),
    market_value DECIMAL(20,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, stakeholder_id, as_of_date, position_type, security_type)
);

-- Ownership changes tracking
CREATE TABLE IF NOT EXISTS ownership_changes (
    id BIGSERIAL PRIMARY KEY,
    ownership_record_id BIGINT NOT NULL REFERENCES ownership_records(id) ON DELETE CASCADE,
    
    -- Change details
    change_type VARCHAR(50) NOT NULL, -- PURCHASE, SALE, GRANT, EXERCISE, CONVERSION
    transaction_date DATE NOT NULL,
    
    -- Transaction details
    shares_transacted BIGINT NOT NULL,
    price_per_share DECIMAL(15,4),
    total_value DECIMAL(20,2),
    
    -- Before/after positions
    shares_before BIGINT,
    shares_after BIGINT,
    percentage_before DECIMAL(8,4),
    percentage_after DECIMAL(8,4),
    
    -- Transaction metadata
    transaction_code VARCHAR(10), -- SEC transaction codes
    equity_swap_involved BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insider transactions
CREATE TABLE IF NOT EXISTS insider_transactions (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    
    -- Transaction details
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- PURCHASE, SALE, GRANT, EXERCISE
    security_type VARCHAR(50),
    
    -- Quantities and prices
    shares_transacted BIGINT NOT NULL,
    price_per_share DECIMAL(15,4),
    total_value DECIMAL(20,2),
    
    -- Position after transaction
    shares_owned_after BIGINT,
    
    -- Filing information
    form_type VARCHAR(10), -- Form 4, Form 5
    filing_date DATE,
    filing_url VARCHAR(500),
    
    -- Transaction codes
    transaction_code VARCHAR(10),
    acquisition_disposition VARCHAR(1), -- A (acquisition) or D (disposition)
    
    -- Additional flags
    is_10b5_1_plan BOOLEAN DEFAULT FALSE,
    is_derivative BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company executives
CREATE TABLE IF NOT EXISTS executives (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    
    -- Position details
    title VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    level VARCHAR(50), -- C_LEVEL, VP, DIRECTOR, MANAGER
    
    -- Employment period
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Reporting structure
    reports_to_id BIGINT REFERENCES executives(id),
    
    -- Background
    biography TEXT,
    education JSONB, -- Array of education records
    previous_experience JSONB, -- Array of previous positions
    
    -- Compensation (basic info, detailed in compensation table)
    base_salary DECIMAL(15,2),
    total_compensation DECIMAL(15,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, stakeholder_id, title, start_date)
);

-- Board of directors
CREATE TABLE IF NOT EXISTS board_members (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    stakeholder_id BIGINT NOT NULL REFERENCES stakeholders(id) ON DELETE CASCADE,
    
    -- Board position
    position VARCHAR(50), -- CHAIRMAN, DIRECTOR, LEAD_DIRECTOR
    committee_memberships TEXT[], -- Array of committee names
    
    -- Term details
    appointment_date DATE NOT NULL,
    term_end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Director characteristics
    is_independent BOOLEAN DEFAULT TRUE,
    is_executive BOOLEAN DEFAULT FALSE,
    age INTEGER,
    
    -- Qualifications
    qualifications TEXT[],
    other_board_positions JSONB,
    
    -- Compensation
    annual_retainer DECIMAL(15,2),
    meeting_fees DECIMAL(15,2),
    equity_compensation DECIMAL(15,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, stakeholder_id, appointment_date)
);

-- Executive compensation
CREATE TABLE IF NOT EXISTS executive_compensation (
    id BIGSERIAL PRIMARY KEY,
    executive_id BIGINT NOT NULL REFERENCES executives(id) ON DELETE CASCADE,
    
    -- Compensation period
    fiscal_year INTEGER NOT NULL,
    
    -- Cash compensation
    base_salary DECIMAL(15,2),
    bonus DECIMAL(15,2),
    non_equity_incentive DECIMAL(15,2),
    
    -- Equity compensation
    stock_awards DECIMAL(15,2),
    option_awards DECIMAL(15,2),
    
    -- Other compensation
    other_compensation DECIMAL(15,2),
    pension_value DECIMAL(15,2),
    deferred_compensation DECIMAL(15,2),
    
    -- Total compensation
    total_compensation DECIMAL(15,2),
    
    -- Pay ratios
    ceo_pay_ratio DECIMAL(8,2), -- Ratio to CEO pay
    median_employee_ratio DECIMAL(8,2), -- Ratio to median employee
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(executive_id, fiscal_year)
);

-- Indexes for stakeholders and ownership
CREATE INDEX IF NOT EXISTS idx_stakeholders_type ON stakeholders(stakeholder_type_id);
CREATE INDEX IF NOT EXISTS idx_stakeholders_name ON stakeholders(name);
CREATE INDEX IF NOT EXISTS idx_stakeholders_country ON stakeholders(country_id);
CREATE INDEX IF NOT EXISTS idx_stakeholders_insider ON stakeholders(is_insider);
CREATE INDEX IF NOT EXISTS idx_stakeholders_institutional ON stakeholders(is_institutional);

CREATE INDEX IF NOT EXISTS idx_ownership_records_company ON ownership_records(company_id);
CREATE INDEX IF NOT EXISTS idx_ownership_records_stakeholder ON ownership_records(stakeholder_id);
CREATE INDEX IF NOT EXISTS idx_ownership_records_date ON ownership_records(as_of_date DESC);
CREATE INDEX IF NOT EXISTS idx_ownership_records_percentage ON ownership_records(ownership_percentage DESC);

CREATE INDEX IF NOT EXISTS idx_ownership_changes_record ON ownership_changes(ownership_record_id);
CREATE INDEX IF NOT EXISTS idx_ownership_changes_date ON ownership_changes(transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_insider_transactions_company ON insider_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_insider_transactions_stakeholder ON insider_transactions(stakeholder_id);
CREATE INDEX IF NOT EXISTS idx_insider_transactions_date ON insider_transactions(transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_executives_company ON executives(company_id);
CREATE INDEX IF NOT EXISTS idx_executives_current ON executives(is_current);
CREATE INDEX IF NOT EXISTS idx_executives_level ON executives(level);

CREATE INDEX IF NOT EXISTS idx_board_members_company ON board_members(company_id);
CREATE INDEX IF NOT EXISTS idx_board_members_current ON board_members(is_current);
CREATE INDEX IF NOT EXISTS idx_board_members_independent ON board_members(is_independent);

CREATE INDEX IF NOT EXISTS idx_executive_compensation_executive ON executive_compensation(executive_id);
CREATE INDEX IF NOT EXISTS idx_executive_compensation_year ON executive_compensation(fiscal_year DESC);