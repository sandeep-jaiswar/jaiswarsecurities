-- ClickHouse Financial Data Tables
-- Comprehensive fundamental analysis data

USE stockdb;

-- Financial Periods table
CREATE TABLE IF NOT EXISTS financial_periods (
    id UInt32,
    company_id UInt32,
    period_type String,
    fiscal_year UInt32,
    fiscal_quarter UInt8,
    period_start_date Date,
    period_end_date Date,
    report_date Date,
    filing_type String,
    filing_url String,
    is_restated UInt8 DEFAULT 0,
    restatement_date Date,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (company_id, fiscal_year, fiscal_quarter)
SETTINGS index_granularity = 8192;

-- Income Statements table
CREATE TABLE IF NOT EXISTS income_statements (
    id UInt64,
    financial_period_id UInt32,
    total_revenue Decimal(20, 2),
    cost_of_revenue Decimal(20, 2),
    gross_profit Decimal(20, 2),
    research_development Decimal(20, 2),
    sales_marketing Decimal(20, 2),
    general_administrative Decimal(20, 2),
    total_operating_expenses Decimal(20, 2),
    operating_income Decimal(20, 2),
    operating_margin Decimal(8, 4),
    interest_income Decimal(20, 2),
    interest_expense Decimal(20, 2),
    other_income Decimal(20, 2),
    income_before_tax Decimal(20, 2),
    income_tax_expense Decimal(20, 2),
    net_income Decimal(20, 2),
    net_income_margin Decimal(8, 4),
    basic_shares_outstanding UInt64,
    diluted_shares_outstanding UInt64,
    basic_eps Decimal(10, 4),
    diluted_eps Decimal(10, 4),
    ebitda Decimal(20, 2),
    depreciation_amortization Decimal(20, 2),
    stock_compensation Decimal(20, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY financial_period_id
SETTINGS index_granularity = 8192;

-- Balance Sheets table
CREATE TABLE IF NOT EXISTS balance_sheets (
    id UInt64,
    financial_period_id UInt32,
    cash_and_equivalents Decimal(20, 2),
    short_term_investments Decimal(20, 2),
    accounts_receivable Decimal(20, 2),
    inventory Decimal(20, 2),
    prepaid_expenses Decimal(20, 2),
    other_current_assets Decimal(20, 2),
    total_current_assets Decimal(20, 2),
    property_plant_equipment Decimal(20, 2),
    goodwill Decimal(20, 2),
    intangible_assets Decimal(20, 2),
    long_term_investments Decimal(20, 2),
    other_non_current_assets Decimal(20, 2),
    total_non_current_assets Decimal(20, 2),
    total_assets Decimal(20, 2),
    accounts_payable Decimal(20, 2),
    short_term_debt Decimal(20, 2),
    accrued_liabilities Decimal(20, 2),
    deferred_revenue Decimal(20, 2),
    other_current_liabilities Decimal(20, 2),
    total_current_liabilities Decimal(20, 2),
    long_term_debt Decimal(20, 2),
    deferred_tax_liabilities Decimal(20, 2),
    other_non_current_liabilities Decimal(20, 2),
    total_non_current_liabilities Decimal(20, 2),
    total_liabilities Decimal(20, 2),
    common_stock Decimal(20, 2),
    retained_earnings Decimal(20, 2),
    accumulated_other_income Decimal(20, 2),
    treasury_stock Decimal(20, 2),
    total_shareholders_equity Decimal(20, 2),
    total_liabilities_equity Decimal(20, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY financial_period_id
SETTINGS index_granularity = 8192;

-- Cash Flow Statements table
CREATE TABLE IF NOT EXISTS cash_flow_statements (
    id UInt64,
    financial_period_id UInt32,
    net_income Decimal(20, 2),
    depreciation_amortization Decimal(20, 2),
    stock_compensation Decimal(20, 2),
    deferred_tax Decimal(20, 2),
    working_capital_changes Decimal(20, 2),
    other_operating_activities Decimal(20, 2),
    net_cash_from_operations Decimal(20, 2),
    capital_expenditures Decimal(20, 2),
    acquisitions Decimal(20, 2),
    investments_purchased Decimal(20, 2),
    investments_sold Decimal(20, 2),
    other_investing_activities Decimal(20, 2),
    net_cash_from_investing Decimal(20, 2),
    debt_issued Decimal(20, 2),
    debt_repaid Decimal(20, 2),
    equity_issued Decimal(20, 2),
    equity_repurchased Decimal(20, 2),
    dividends_paid Decimal(20, 2),
    other_financing_activities Decimal(20, 2),
    net_cash_from_financing Decimal(20, 2),
    net_change_in_cash Decimal(20, 2),
    cash_beginning_period Decimal(20, 2),
    cash_end_period Decimal(20, 2),
    free_cash_flow Decimal(20, 2),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY financial_period_id
SETTINGS index_granularity = 8192;

-- Financial Ratios table
CREATE TABLE IF NOT EXISTS financial_ratios (
    id UInt64,
    financial_period_id UInt32,
    gross_margin Decimal(8, 4),
    operating_margin Decimal(8, 4),
    net_margin Decimal(8, 4),
    return_on_assets Decimal(8, 4),
    return_on_equity Decimal(8, 4),
    return_on_invested_capital Decimal(8, 4),
    current_ratio Decimal(8, 4),
    quick_ratio Decimal(8, 4),
    cash_ratio Decimal(8, 4),
    debt_to_equity Decimal(8, 4),
    debt_to_assets Decimal(8, 4),
    interest_coverage Decimal(8, 4),
    debt_service_coverage Decimal(8, 4),
    asset_turnover Decimal(8, 4),
    inventory_turnover Decimal(8, 4),
    receivables_turnover Decimal(8, 4),
    payables_turnover Decimal(8, 4),
    price_to_earnings Decimal(8, 4),
    price_to_book Decimal(8, 4),
    price_to_sales Decimal(8, 4),
    price_to_cash_flow Decimal(8, 4),
    enterprise_value_revenue Decimal(8, 4),
    enterprise_value_ebitda Decimal(8, 4),
    revenue_growth Decimal(8, 4),
    earnings_growth Decimal(8, 4),
    book_value_growth Decimal(8, 4),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY financial_period_id
SETTINGS index_granularity = 8192;

-- Ratio Definitions table
CREATE TABLE IF NOT EXISTS ratio_definitions (
    id UInt32,
    code String,
    name String,
    category String,
    description String,
    formula String,
    interpretation String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Analyst Estimates table
CREATE TABLE IF NOT EXISTS analyst_estimates (
    id UInt64,
    company_id UInt32,
    estimate_type String,
    period_type String,
    fiscal_year UInt32,
    fiscal_quarter UInt8,
    mean_estimate Decimal(15, 4),
    median_estimate Decimal(15, 4),
    high_estimate Decimal(15, 4),
    low_estimate Decimal(15, 4),
    standard_deviation Decimal(15, 4),
    number_of_estimates UInt32,
    number_of_revisions_up UInt32,
    number_of_revisions_down UInt32,
    estimate_date Date,
    last_updated DateTime,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(estimate_date)
ORDER BY (company_id, estimate_type, fiscal_year, fiscal_quarter)
SETTINGS index_granularity = 8192;

-- Company Guidance table
CREATE TABLE IF NOT EXISTS company_guidance (
    id UInt64,
    company_id UInt32,
    guidance_type String,
    period_type String,
    fiscal_year UInt32,
    fiscal_quarter UInt8,
    low_guidance Decimal(15, 4),
    high_guidance Decimal(15, 4),
    midpoint_guidance Decimal(15, 4),
    guidance_date Date,
    guidance_source String,
    confidence_level String,
    is_current UInt8 DEFAULT 1,
    withdrawal_date Date,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(guidance_date)
ORDER BY (company_id, guidance_date)
SETTINGS index_granularity = 8192;