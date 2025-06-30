/*
  # News and Events Tables
  
  1. News and Media
    - news_articles: News articles and press releases
    - news_sources: News source metadata
    - news_categories: News categorization
    - news_sentiment: Sentiment analysis
  
  2. Corporate Events
    - corporate_events: Earnings, dividends, splits, etc.
    - event_types: Event type definitions
    - earnings_calls: Earnings call transcripts
  
  3. Economic Events
    - economic_events: Economic indicators and events
    - economic_indicators: Economic data points
*/

-- News sources
CREATE TABLE IF NOT EXISTS news_sources (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    website VARCHAR(255),
    description TEXT,
    credibility_score DECIMAL(3,2), -- 0.00 to 1.00
    bias_score DECIMAL(3,2), -- -1.00 (left) to 1.00 (right)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- News categories
CREATE TABLE IF NOT EXISTS news_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    parent_category_id INTEGER REFERENCES news_categories(id),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- News articles
CREATE TABLE IF NOT EXISTS news_articles (
    id BIGSERIAL PRIMARY KEY,
    
    -- Article metadata
    title VARCHAR(500) NOT NULL,
    summary TEXT,
    content TEXT,
    url VARCHAR(1000) UNIQUE,
    
    -- Source information
    news_source_id INTEGER REFERENCES news_sources(id),
    author VARCHAR(200),
    
    -- Categorization
    news_category_id INTEGER REFERENCES news_categories(id),
    tags TEXT[], -- Array of tags
    
    -- Timing
    published_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ,
    
    -- Content analysis
    word_count INTEGER,
    reading_time_minutes INTEGER,
    language VARCHAR(10) DEFAULT 'en',
    
    -- Engagement metrics
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    
    -- Data quality
    is_duplicate BOOLEAN DEFAULT FALSE,
    duplicate_of BIGINT REFERENCES news_articles(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company-news relationships
CREATE TABLE IF NOT EXISTS company_news (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    news_article_id BIGINT NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
    
    -- Relevance
    relevance_score DECIMAL(3,2), -- 0.00 to 1.00
    mention_type VARCHAR(50), -- PRIMARY, SECONDARY, MENTIONED
    mention_context TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, news_article_id)
);

-- News sentiment analysis
CREATE TABLE IF NOT EXISTS news_sentiment (
    id BIGSERIAL PRIMARY KEY,
    news_article_id BIGINT NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES companies(id),
    
    -- Sentiment scores
    overall_sentiment DECIMAL(3,2), -- -1.00 (negative) to 1.00 (positive)
    sentiment_label VARCHAR(20), -- POSITIVE, NEGATIVE, NEUTRAL
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    
    -- Detailed sentiment
    positive_score DECIMAL(3,2),
    negative_score DECIMAL(3,2),
    neutral_score DECIMAL(3,2),
    
    -- Analysis metadata
    analysis_model VARCHAR(100),
    analysis_date TIMESTAMPTZ DEFAULT NOW(),
    
    -- Key phrases and entities
    key_phrases TEXT[],
    named_entities JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(news_article_id, company_id)
);

-- Event types
CREATE TABLE IF NOT EXISTS event_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- EARNINGS, CORPORATE_ACTION, REGULATORY, ECONOMIC
    description TEXT,
    impact_level VARCHAR(20), -- HIGH, MEDIUM, LOW
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Corporate events
CREATE TABLE IF NOT EXISTS corporate_events (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    event_type_id INTEGER REFERENCES event_types(id),
    
    -- Event details
    event_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Timing
    announcement_date DATE,
    event_date DATE NOT NULL,
    ex_date DATE,
    record_date DATE,
    payment_date DATE,
    
    -- Event-specific data
    event_data JSONB, -- Flexible storage for event-specific information
    
    -- Impact assessment
    expected_impact VARCHAR(20), -- POSITIVE, NEGATIVE, NEUTRAL
    actual_impact VARCHAR(20),
    impact_magnitude DECIMAL(8,4), -- Price impact percentage
    
    -- Status
    status VARCHAR(20) DEFAULT 'SCHEDULED', -- SCHEDULED, COMPLETED, CANCELLED, POSTPONED
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Earnings calls
CREATE TABLE IF NOT EXISTS earnings_calls (
    id BIGSERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    financial_period_id INTEGER REFERENCES financial_periods(id),
    
    -- Call details
    call_date TIMESTAMPTZ NOT NULL,
    call_duration_minutes INTEGER,
    
    -- Participants
    participants JSONB, -- Array of {name, title, company} objects
    
    -- Content
    transcript TEXT,
    key_topics TEXT[],
    management_tone VARCHAR(20), -- OPTIMISTIC, CAUTIOUS, NEUTRAL, PESSIMISTIC
    
    -- Q&A analysis
    question_count INTEGER,
    guidance_updates JSONB,
    forward_looking_statements TEXT[],
    
    -- Market reaction
    pre_call_price DECIMAL(15,4),
    post_call_price DECIMAL(15,4),
    price_impact_percent DECIMAL(8,4),
    volume_impact DECIMAL(8,4),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Economic indicators
CREATE TABLE IF NOT EXISTS economic_indicators (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- GDP, INFLATION, EMPLOYMENT, INTEREST_RATES, etc.
    frequency VARCHAR(20), -- DAILY, WEEKLY, MONTHLY, QUARTERLY, ANNUAL
    unit VARCHAR(50),
    source VARCHAR(100),
    country_id INTEGER REFERENCES countries(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Economic events/data
CREATE TABLE IF NOT EXISTS economic_events (
    id BIGSERIAL PRIMARY KEY,
    economic_indicator_id INTEGER REFERENCES economic_indicators(id),
    
    -- Event details
    event_name VARCHAR(200) NOT NULL,
    release_date TIMESTAMPTZ NOT NULL,
    period_start DATE,
    period_end DATE,
    
    -- Values
    actual_value DECIMAL(20,4),
    forecast_value DECIMAL(20,4),
    previous_value DECIMAL(20,4),
    
    -- Impact assessment
    importance_level VARCHAR(20), -- HIGH, MEDIUM, LOW
    market_impact VARCHAR(20), -- POSITIVE, NEGATIVE, NEUTRAL
    surprise_factor DECIMAL(8,4), -- (actual - forecast) / |forecast| * 100
    
    -- Additional data
    revision_flag BOOLEAN DEFAULT FALSE,
    preliminary_flag BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for news and events
CREATE INDEX IF NOT EXISTS idx_news_articles_published ON news_articles(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_articles_source ON news_articles(news_source_id);
CREATE INDEX IF NOT EXISTS idx_news_articles_category ON news_articles(news_category_id);

CREATE INDEX IF NOT EXISTS idx_company_news_company ON company_news(company_id);
CREATE INDEX IF NOT EXISTS idx_company_news_article ON company_news(news_article_id);
CREATE INDEX IF NOT EXISTS idx_company_news_relevance ON company_news(relevance_score DESC);

CREATE INDEX IF NOT EXISTS idx_news_sentiment_article ON news_sentiment(news_article_id);
CREATE INDEX IF NOT EXISTS idx_news_sentiment_company ON news_sentiment(company_id);
CREATE INDEX IF NOT EXISTS idx_news_sentiment_score ON news_sentiment(overall_sentiment);

CREATE INDEX IF NOT EXISTS idx_corporate_events_company ON corporate_events(company_id);
CREATE INDEX IF NOT EXISTS idx_corporate_events_date ON corporate_events(event_date);
CREATE INDEX IF NOT EXISTS idx_corporate_events_type ON corporate_events(event_type_id);

CREATE INDEX IF NOT EXISTS idx_earnings_calls_company ON earnings_calls(company_id);
CREATE INDEX IF NOT EXISTS idx_earnings_calls_date ON earnings_calls(call_date DESC);

CREATE INDEX IF NOT EXISTS idx_economic_events_indicator ON economic_events(economic_indicator_id);
CREATE INDEX IF NOT EXISTS idx_economic_events_release_date ON economic_events(release_date DESC);