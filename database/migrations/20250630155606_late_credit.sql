-- ClickHouse News and Events Tables
-- Comprehensive news and corporate events data

USE stockdb;

-- News Categories table
CREATE TABLE IF NOT EXISTS news_categories (
    id UInt32,
    code String,
    name String,
    parent_category_id UInt32,
    description String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- News Sources table
CREATE TABLE IF NOT EXISTS news_sources (
    id UInt32,
    code String,
    name String,
    website String,
    description String,
    credibility_score Decimal(3, 2),
    bias_score Decimal(3, 2),
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- News Articles table (partitioned by month)
CREATE TABLE IF NOT EXISTS news_articles (
    id UInt64,
    title String,
    summary String,
    content String,
    url String,
    news_source_id UInt32,
    author String,
    news_category_id UInt32,
    tags Array(String),
    published_at DateTime,
    updated_at DateTime,
    word_count UInt32,
    reading_time_minutes UInt32,
    language String DEFAULT 'en',
    view_count UInt32 DEFAULT 0,
    share_count UInt32 DEFAULT 0,
    comment_count UInt32 DEFAULT 0,
    is_duplicate UInt8 DEFAULT 0,
    duplicate_of UInt64,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(published_at)
ORDER BY (published_at, id)
SETTINGS index_granularity = 8192;

-- Company News table
CREATE TABLE IF NOT EXISTS company_news (
    id UInt64,
    company_id UInt32,
    news_article_id UInt64,
    relevance_score Decimal(3, 2),
    mention_type String,
    mention_context String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (company_id, news_article_id)
SETTINGS index_granularity = 8192;

-- News Sentiment table (partitioned by date)
CREATE TABLE IF NOT EXISTS news_sentiment (
    id UInt64,
    news_article_id UInt64,
    company_id UInt32,
    overall_sentiment Decimal(3, 2),
    sentiment_label String,
    confidence_score Decimal(3, 2),
    positive_score Decimal(3, 2),
    negative_score Decimal(3, 2),
    neutral_score Decimal(3, 2),
    analysis_model String,
    analysis_date DateTime DEFAULT now(),
    key_phrases Array(String),
    named_entities String, -- JSON as String
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(analysis_date)
ORDER BY (news_article_id, company_id)
SETTINGS index_granularity = 8192;

-- Event Types table
CREATE TABLE IF NOT EXISTS event_types (
    id UInt32,
    code String,
    name String,
    category String,
    description String,
    impact_level String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Corporate Events table
CREATE TABLE IF NOT EXISTS corporate_events (
    id UInt64,
    company_id UInt32,
    event_type_id UInt32,
    event_name String,
    description String,
    announcement_date Date,
    event_date Date,
    ex_date Date,
    record_date Date,
    payment_date Date,
    event_data String, -- JSON as String
    expected_impact String,
    actual_impact String,
    impact_magnitude Decimal(8, 4),
    status String DEFAULT 'SCHEDULED',
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (company_id, event_date)
SETTINGS index_granularity = 8192;

-- Earnings Calls table
CREATE TABLE IF NOT EXISTS earnings_calls (
    id UInt64,
    company_id UInt32,
    financial_period_id UInt32,
    call_date DateTime,
    call_duration_minutes UInt32,
    participants String, -- JSON as String
    transcript String,
    key_topics Array(String),
    management_tone String,
    question_count UInt32,
    guidance_updates String, -- JSON as String
    forward_looking_statements Array(String),
    pre_call_price Decimal(15, 4),
    post_call_price Decimal(15, 4),
    price_impact_percent Decimal(8, 4),
    volume_impact Decimal(8, 4),
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(call_date)
ORDER BY (company_id, call_date)
SETTINGS index_granularity = 8192;

-- Economic Indicators table
CREATE TABLE IF NOT EXISTS economic_indicators (
    id UInt32,
    code String,
    name String,
    description String,
    category String,
    frequency String,
    unit String,
    source String,
    country_id UInt32,
    is_active UInt8 DEFAULT 1,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Economic Events table
CREATE TABLE IF NOT EXISTS economic_events (
    id UInt64,
    economic_indicator_id UInt32,
    event_name String,
    release_date DateTime,
    period_start Date,
    period_end Date,
    actual_value Decimal(20, 4),
    forecast_value Decimal(20, 4),
    previous_value Decimal(20, 4),
    importance_level String,
    market_impact String,
    surprise_factor Decimal(8, 4),
    revision_flag UInt8 DEFAULT 0,
    preliminary_flag UInt8 DEFAULT 0,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(release_date)
ORDER BY (release_date, economic_indicator_id)
SETTINGS index_granularity = 8192;