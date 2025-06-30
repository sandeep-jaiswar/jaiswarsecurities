/*
  # Financial Data Tables
  
  1. Financial Statements
    - income_statements: Income statement data
    - balance_sheets: Balance sheet data
    - cash_flow_statements: Cash flow data
    - financial_periods: Reporting periods
  
  2. Financial Ratios
    - financial_ratios: Calculated financial ratios
    - ratio_definitions: Ratio metadata
  
  3. Estimates and Guidance
    - analyst_estimates: Analyst estimates
    - company_guidance: Company guidance
*/

-- Financial reporting periods
CREATE TABLE IF NOT EXISTS financial_periods (
    id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Period information
    period_type VARCHAR(20) NOT NULL, -- ANNUAL, QUARTERLY, TTM
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER, -- 1, 2, 3, 4 (NULL for annual)
    
    -- Dates
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    report_date DATE, -- When the report was filed
    
    -- Filing information
    filing_type VARCHAR(20), -- 10-K, 10-Q, 8-K, etc.
    filing_url VARCHAR(500),
    
    -- Status
    is_restated BOOLEAN DEFAULT FALSE,
    restatement_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, period_type, fiscal_year, fiscal_quarter)
);

-- Income statements
CREATE TABLE IF NOT EXISTS income_statements (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    
    -- Revenue
    total_revenue DECIMAL(20,2),
    cost_of_revenue DECIMAL(20,2),
    gross_profit DECIMAL(20,2),
    
    -- Operating expenses
    research_development DECIMAL(20,2),
    sales_marketing DECIMAL(20,2),
    general_administrative DECIMAL(20,2),
    total_operating_expenses DECIMAL(20,2),
    
    -- Operating income
    operating_income DECIMAL(20,2),
    operating_margin DECIMAL(8,4),
    
    -- Non-operating items
    interest_income DECIMAL(20,2),
    interest_expense DECIMAL(20,2),
    other_income DECIMAL(20,2),
    
    -- Pre-tax income
    income_before_tax DECIMAL(20,2),
    income_tax_expense DECIMAL(20,2),
    
    -- Net income
    net_income DECIMAL(20,2),
    net_income_margin DECIMAL(8,4),
    
    -- Per share data
    basic_shares_outstanding BIGINT,
    diluted_shares_outstanding BIGINT,
    basic_eps DECIMAL(10,4),
    diluted_eps DECIMAL(10,4),
    
    -- Additional items
    ebitda DECIMAL(20,2),
    depreciation_amortization DECIMAL(20,2),
    stock_compensation DECIMAL(20,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(financial_period_id)
);

-- Balance sheets
CREATE TABLE IF NOT EXISTS balance_sheets (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    
    -- Current assets
    cash_and_equivalents DECIMAL(20,2),
    short_term_investments DECIMAL(20,2),
    accounts_receivable DECIMAL(20,2),
    inventory DECIMAL(20,2),
    prepaid_expenses DECIMAL(20,2),
    other_current_assets DECIMAL(20,2),
    total_current_assets DECIMAL(20,2),
    
    -- Non-current assets
    property_plant_equipment DECIMAL(20,2),
    goodwill DECIMAL(20,2),
    intangible_assets DECIMAL(20,2),
    long_term_investments DECIMAL(20,2),
    other_non_current_assets DECIMAL(20,2),
    total_non_current_assets DECIMAL(20,2),
    
    -- Total assets
    total_assets DECIMAL(20,2),
    
    -- Current liabilities
    accounts_payable DECIMAL(20,2),
    short_term_debt DECIMAL(20,2),
    accrued_liabilities DECIMAL(20,2),
    deferred_revenue DECIMAL(20,2),
    other_current_liabilities DECIMAL(20,2),
    total_current_liabilities DECIMAL(20,2),
    
    -- Non-current liabilities
    long_term_debt DECIMAL(20,2),
    deferred_tax_liabilities DECIMAL(20,2),
    other_non_current_liabilities DECIMAL(20,2),
    total_non_current_liabilities DECIMAL(20,2),
    
    -- Total liabilities
    total_liabilities DECIMAL(20,2),
    
    -- Shareholders' equity
    common_stock DECIMAL(20,2),
    retained_earnings DECIMAL(20,2),
    accumulated_other_income DECIMAL(20,2),
    treasury_stock DECIMAL(20,2),
    total_shareholders_equity DECIMAL(20,2),
    
    -- Totals
    total_liabilities_equity DECIMAL(20,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(financial_period_id)
);

-- Cash flow statements
CREATE TABLE IF NOT EXISTS cash_flow_statements (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    
    -- Operating activities
    net_income DECIMAL(20,2),
    depreciation_amortization DECIMAL(20,2),
    stock_compensation DECIMAL(20,2),
    deferred_tax DECIMAL(20,2),
    working_capital_changes DECIMAL(20,2),
    other_operating_activities DECIMAL(20,2),
    net_cash_from_operations DECIMAL(20,2),
    
    -- Investing activities
    capital_expenditures DECIMAL(20,2),
    acquisitions DECIMAL(20,2),
    investments_purchased DECIMAL(20,2),
    investments_sold DECIMAL(20,2),
    other_investing_activities DECIMAL(20,2),
    net_cash_from_investing DECIMAL(20,2),
    
    -- Financing activities
    debt_issued DECIMAL(20,2),
    debt_repaid DECIMAL(20,2),
    equity_issued DECIMAL(20,2),
    equity_repurchased DECIMAL(20,2),
    dividends_paid DECIMAL(20,2),
    other_financing_activities DECIMAL(20,2),
    net_cash_from_financing DECIMAL(20,2),
    
    -- Net change in cash
    net_change_in_cash DECIMAL(20,2),
    cash_beginning_period DECIMAL(20,2),
    cash_end_period DECIMAL(20,2),
    
    -- Free cash flow
    free_cash_flow DECIMAL(20,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(financial_period_id)
);

-- Financial ratio definitions
CREATE TABLE IF NOT EXISTS ratio_definitions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- PROFITABILITY, LIQUIDITY, LEVERAGE, EFFICIENCY, VALUATION
    description TEXT,
    formula TEXT,
    interpretation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Financial ratios
CREATE TABLE IF NOT EXISTS financial_ratios (
    id BIGSERIAL PRIMARY KEY,
    financial_period_id INTEGER NOT NULL REFERENCES financial_periods(id) ON DELETE CASCADE,
    
    -- Profitability ratios
    gross_margin DECIMAL(8,4),
    operating_margin DECIMAL(8,4),
    net_margin DECIMAL(8,4),
    return_on_assets DECIMAL(8,4),
    return_on_equity DECIMAL(8,4),
    return_on_invested_capital DECIMAL(8,4),
    
    -- Liquidity ratios
    current_ratio DECIMAL(8,4),
    quick_ratio DECIMAL(8,4),
    cash_ratio DECIMAL(8,4),
    
    -- Leverage ratios
    debt_to_equity DECIMAL(8,4),
    debt_to_assets DECIMAL(8,4),
    interest_coverage DECIMAL(8,4),
    debt_service_coverage DECIMAL(8,4),
    
    -- Efficiency ratios
    asset_turnover DECIMAL(8,4),
    inventory_turnover DECIMAL(8,4),
    receivables_turnover DECIMAL(8,4),
    payables_turnover DECIMAL(8,4),
    
    -- Valuation ratios (calculated with market data)
    price_to_earnings DECIMAL(8,4),
    price_to_book DECIMAL(8,4),
    price_to_sales DECIMAL(8,4),
    price_to_cash_flow DECIMAL(8,4),
    enterprise_value_revenue DECIMAL(8,4),
    enterprise_value_ebitda DECIMAL(8,4),
    
    -- Growth rates (year-over-year)
    revenue_growth DECIMAL(8,4),
    earnings_growth DECIMAL(8,4),
    book_value_growth DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(financial_period_id)
);

-- Analyst estimates
CREATE TABLE IF NOT EXISTS analyst_estimates (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Estimate details
    estimate_type VARCHAR(50) NOT NULL, -- EPS, REVENUE, EBITDA, etc.
    period_type VARCHAR(20) NOT NULL, -- QUARTERLY, ANNUAL
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER,
    
    -- Estimate statistics
    mean_estimate DECIMAL(15,4),
    median_estimate DECIMAL(15,4),
    high_estimate DECIMAL(15,4),
    low_estimate DECIMAL(15,4),
    standard_deviation DECIMAL(15,4),
    
    -- Analyst counts
    number_of_estimates INTEGER,
    number_of_revisions_up INTEGER,
    number_of_revisions_down INTEGER,
    
    -- Dates
    estimate_date DATE NOT NULL,
    last_updated TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, estimate_type, period_type, fiscal_year, fiscal_quarter, estimate_date)
);

-- Company guidance
CREATE TABLE IF NOT EXISTS company_guidance (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Guidance details
    guidance_type VARCHAR(50) NOT NULL, -- REVENUE, EPS, MARGIN, etc.
    period_type VARCHAR(20) NOT NULL, -- QUARTERLY, ANNUAL
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER,
    
    -- Guidance ranges
    low_guidance DECIMAL(15,4),
    high_guidance DECIMAL(15,4),
    midpoint_guidance DECIMAL(15,4),
    
    -- Guidance metadata
    guidance_date DATE NOT NULL,
    guidance_source VARCHAR(100), -- EARNINGS_CALL, PRESS_RELEASE, etc.
    confidence_level VARCHAR(20), -- HIGH, MEDIUM, LOW
    
    -- Status
    is_current BOOLEAN DEFAULT TRUE,
    withdrawal_date DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for financial data
CREATE INDEX IF NOT EXISTS idx_financial_periods_company ON financial_periods(company_id);
CREATE INDEX IF NOT EXISTS idx_financial_periods_year_quarter ON financial_periods(fiscal_year, fiscal_quarter);

CREATE INDEX IF NOT EXISTS idx_income_statements_period ON income_statements(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_balance_sheets_period ON balance_sheets(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_cash_flow_statements_period ON cash_flow_statements(financial_period_id);
CREATE INDEX IF NOT EXISTS idx_financial_ratios_period ON financial_ratios(financial_period_id);

CREATE INDEX IF NOT EXISTS idx_analyst_estimates_company ON analyst_estimates(company_id);
CREATE INDEX IF NOT EXISTS idx_analyst_estimates_type_period ON analyst_estimates(estimate_type, period_type, fiscal_year);

CREATE INDEX IF NOT EXISTS idx_company_guidance_company ON company_guidance(company_id);
CREATE INDEX IF NOT EXISTS idx_company_guidance_current ON company_guidance(is_current);