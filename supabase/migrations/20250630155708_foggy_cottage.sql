-- ClickHouse User System Tables
-- Complete user management and authentication

USE stockdb;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UInt64,
    username String,
    email String,
    password_hash String,
    salt String,
    first_name String,
    last_name String,
    display_name String,
    is_active UInt8 DEFAULT 1,
    is_verified UInt8 DEFAULT 0,
    is_locked UInt8 DEFAULT 0,
    failed_login_attempts UInt32 DEFAULT 0,
    last_login_at DateTime,
    password_changed_at DateTime DEFAULT now(),
    email_verification_token String,
    email_verified_at DateTime,
    password_reset_token String,
    password_reset_expires_at DateTime,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id UInt32,
    name String,
    description String,
    is_system_role UInt8 DEFAULT 0,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id UInt32,
    name String,
    description String,
    resource String,
    action String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY id
SETTINGS index_granularity = 8192;

-- Role Permissions table
CREATE TABLE IF NOT EXISTS role_permissions (
    id UInt32,
    role_id UInt32,
    permission_id UInt32,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (role_id, permission_id)
SETTINGS index_granularity = 8192;

-- User Roles table
CREATE TABLE IF NOT EXISTS user_roles (
    id UInt64,
    user_id UInt64,
    role_id UInt32,
    assigned_by UInt64,
    assigned_at DateTime DEFAULT now(),
    expires_at DateTime
) ENGINE = MergeTree()
ORDER BY (user_id, role_id)
SETTINGS index_granularity = 8192;

-- User Profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UInt64,
    user_id UInt64,
    phone String,
    timezone String DEFAULT 'UTC',
    language String DEFAULT 'en',
    country_id UInt32,
    company String,
    job_title String,
    industry String,
    experience_level String,
    trading_experience String,
    risk_tolerance String,
    investment_goals Array(String),
    avatar_url String,
    bio String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY user_id
SETTINGS index_granularity = 8192;

-- User Sessions table
CREATE TABLE IF NOT EXISTS user_sessions (
    id UInt64,
    user_id UInt64,
    session_token String,
    refresh_token String,
    ip_address String,
    user_agent String,
    device_type String,
    browser String,
    os String,
    created_at DateTime DEFAULT now(),
    last_activity_at DateTime DEFAULT now(),
    expires_at DateTime,
    is_active UInt8 DEFAULT 1,
    logout_at DateTime
) ENGINE = MergeTree()
ORDER BY (user_id, created_at)
SETTINGS index_granularity = 8192;

-- User Preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UInt64,
    user_id UInt64,
    theme String DEFAULT 'light',
    chart_type String DEFAULT 'candlestick',
    default_time_frame String DEFAULT '1D',
    email_notifications UInt8 DEFAULT 1,
    push_notifications UInt8 DEFAULT 1,
    sms_notifications UInt8 DEFAULT 0,
    alert_frequency String DEFAULT 'IMMEDIATE',
    max_alerts_per_day UInt32 DEFAULT 50,
    default_currency String DEFAULT 'USD',
    price_display_format String DEFAULT 'DECIMAL',
    profile_visibility String DEFAULT 'PRIVATE',
    share_watchlists UInt8 DEFAULT 0,
    share_performance UInt8 DEFAULT 0,
    custom_settings String, -- JSON as String
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY user_id
SETTINGS index_granularity = 8192;

-- User Activity table
CREATE TABLE IF NOT EXISTS user_activity (
    id UInt64,
    user_id UInt64,
    activity_type String,
    activity_data String, -- JSON as String
    session_id UInt64,
    ip_address String,
    created_at DateTime DEFAULT now(),
    duration_seconds UInt32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (user_id, created_at)
SETTINGS index_granularity = 8192;

-- User API Keys table
CREATE TABLE IF NOT EXISTS user_api_keys (
    id UInt64,
    user_id UInt64,
    key_name String,
    api_key String,
    api_secret String,
    permissions Array(String),
    rate_limit_per_minute UInt32 DEFAULT 60,
    is_active UInt8 DEFAULT 1,
    last_used_at DateTime,
    created_at DateTime DEFAULT now(),
    expires_at DateTime
) ENGINE = MergeTree()
ORDER BY (user_id, api_key)
SETTINGS index_granularity = 8192;

-- Audit Logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UInt64,
    event_type String,
    resource_type String,
    resource_id String,
    user_id UInt64,
    username String,
    ip_address String,
    user_agent String,
    request_method String,
    request_url String,
    old_values String, -- JSON as String
    new_values String, -- JSON as String
    additional_data String, -- JSON as String
    success UInt8 DEFAULT 1,
    error_message String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (created_at, user_id)
SETTINGS index_granularity = 8192;