from clickhouse_connect import get_client
import uuid
from datetime import datetime

client = get_client(host='localhost', port=8123, username='default', password='')

def create_tables():
    # SECTORS
    client.command("""
    CREATE TABLE IF NOT EXISTS sectors (
        id UUID,
        name LowCardinality(String),
        code LowCardinality(String),
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (code)
    """)

    # INDUSTRIES
    client.command("""
    CREATE TABLE IF NOT EXISTS industries (
        id UUID,
        name LowCardinality(String),
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (id)
    """)

    # EXCHANGES
    client.command("""
    CREATE TABLE IF NOT EXISTS exchanges (
        id UUID,
        name LowCardinality(String),
        code LowCardinality(String),
        country LowCardinality(String),
        timezone String,
        mic_code String,
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (code)
    """)

    # COMPANIES
    client.command("""
    CREATE TABLE IF NOT EXISTS companies (
        id UUID,
        name String,
        sector_id UUID,
        industry_id UUID,
        business_description String,
        employee_count UInt32,
        website String,
        country LowCardinality(String),
        founded_year Nullable(UInt16),
        headquarters_city String,
        headquarters_state String,
        headquarters_country String,
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (id)
    """)

    # SECURITIES
    client.command("""
    CREATE TABLE IF NOT EXISTS securities (
        id UUID,
        symbol String,
        name String,
        company_id UUID,
        exchange_id UUID,
        isin String,
        cusip String,
        figi String,
        asset_type LowCardinality(String),
        currency LowCardinality(String),
        country LowCardinality(String),
        is_active UInt8,
        listing_date Date,
        delisting_date Nullable(Date),
        shares_outstanding UInt64,
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (symbol)
    """)

    # OHLCV DAILY
    client.command("""
    CREATE TABLE IF NOT EXISTS ohlcv_daily (
        security_id UUID,
        trade_date Date,
        open_price Float32,
        high_price Float32,
        low_price Float32,
        close_price Float32,
        adjusted_close Float32,
        volume UInt64,
        dividend Nullable(Float32),
        split_factor Nullable(Float32),
        currency LowCardinality(String),
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    PARTITION BY toYYYYMM(trade_date)
    ORDER BY (security_id, trade_date)
    """)

    # TECHNICAL INDICATORS
    client.command("""
    CREATE TABLE IF NOT EXISTS technical_indicators (
        security_id UUID,
        trade_date Date,
        sma_20 Float32,
        sma_50 Float32,
        sma_200 Float32,
        ema_12 Float32,
        ema_26 Float32,
        rsi_14 Float32,
        macd Float32,
        macd_signal Float32,
        macd_histogram Float32,
        bb_upper Float32,
        bb_middle Float32,
        bb_lower Float32,
        stochastic_k Nullable(Float32),
        stochastic_d Nullable(Float32),
        atr_14 Nullable(Float32),
        adx_14 Nullable(Float32),
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    PARTITION BY toYYYYMM(trade_date)
    ORDER BY (security_id, trade_date)
    """)

    # TRADING STATISTICS
    client.command("""
    CREATE TABLE IF NOT EXISTS trading_statistics (
        security_id UUID,
        trade_date Date,
        previous_close Float32,
        price_change Float32,
        price_change_percent Float32,
        volume_ratio Float32,
        market_cap Float64,
        turnover Float64,
        avg_volume_10d UInt64,
        beta Nullable(Float32),
        volatility_30d Nullable(Float32),
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    PARTITION BY toYYYYMM(trade_date)
    ORDER BY (security_id, trade_date)
    """)

    # FINANCIAL PERIODS
    client.command("""
    CREATE TABLE IF NOT EXISTS financial_periods (
        id UUID,
        company_id UUID,
        fiscal_year UInt16,
        period_type LowCardinality(String),
        period_start Date,
        period_end Date,
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY (company_id, fiscal_year)
    """)

    # FINANCIAL RATIOS
    client.command("""
    CREATE TABLE IF NOT EXISTS financial_ratios (
        financial_period_id UUID,
        price_to_earnings Float32,
        price_to_book Float32,
        price_to_sales Float32,
        return_on_equity Float32,
        return_on_assets Float32,
        debt_to_equity Float32,
        current_ratio Float32,
        gross_margin Float32,
        operating_margin Float32,
        net_margin Float32,
        ebitda Float32,
        eps_basic Float32,
        eps_diluted Float32,
        dividend_per_share Float32,
        book_value_per_share Float32,
        free_cash_flow Float32,
        created_at DateTime DEFAULT now(),
        updated_at DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(updated_at)
    ORDER BY financial_period_id
    """)


def now():
    return datetime.utcnow().isoformat()

# ========== INSERT METHODS ==========

def insert_sector(id, name, code):
    now = datetime.utcnow()
    client.insert("sectors", [[id, name, code, now, now]],
                  column_names=["id", "name", "code", "created_at", "updated_at"])

def insert_industry(id, name):
    now = datetime.utcnow()
    client.insert("industries", [[id, name, now, now]],
                  column_names=["id", "name", "created_at", "updated_at"])

def insert_exchange(id, name, code, country, timezone, mic_code):
    now = datetime.utcnow()
    client.insert("exchanges", [[id, name, code, country, timezone, mic_code, now, now]],
                  column_names=["id", "name", "code", "country", "timezone", "mic_code", "created_at", "updated_at"])

def insert_company(data):
    now = datetime.utcnow()
    row = [
        data["id"], data["name"], data["sector_id"], data["industry_id"], data["business_description"],
        data["employee_count"], data["website"], data["country"], data.get("founded_year"),
        data["headquarters_city"], data["headquarters_state"], data["headquarters_country"],
        now, now
    ]
    columns = [
        "id", "name", "sector_id", "industry_id", "business_description", "employee_count",
        "website", "country", "founded_year", "headquarters_city", "headquarters_state",
        "headquarters_country", "created_at", "updated_at"
    ]
    client.insert("companies", [row], column_names=columns)

def insert_security(data):
    now = datetime.utcnow()
    row = [
        data["id"], data["symbol"], data["name"], data["company_id"], data["exchange_id"],
        data["isin"], data["cusip"], data["figi"], data["asset_type"],
        data["currency"], data["country"], data["is_active"], data["listing_date"],
        data.get("delisting_date"), data["shares_outstanding"], now, now
    ]
    columns = [
        "id", "symbol", "name", "company_id", "exchange_id", "isin", "cusip", "figi",
        "asset_type", "currency", "country", "is_active", "listing_date", "delisting_date",
        "shares_outstanding", "created_at", "updated_at"
    ]
    client.insert("securities", [row], column_names=columns)

def insert_ohlcv(data):
    now = datetime.utcnow()
    row = [
        data["security_id"], data["trade_date"], data["open_price"], data["high_price"],
        data["low_price"], data["close_price"], data["adjusted_close"], data["volume"],
        data.get("dividend"), data.get("split_factor"), data["currency"], now, now
    ]
    client.insert("ohlcv_daily", [row], column_names=[
        "security_id", "trade_date", "open_price", "high_price", "low_price", "close_price",
        "adjusted_close", "volume", "dividend", "split_factor", "currency", "created_at", "updated_at"
    ])

def insert_technical_indicators(data):
    now = datetime.utcnow()
    row = [
        data["security_id"], data["trade_date"], data["sma_20"], data["sma_50"], data["sma_200"],
        data["ema_12"], data["ema_26"], data["rsi_14"], data["macd"], data["macd_signal"], data["macd_histogram"],
        data["bb_upper"], data["bb_middle"], data["bb_lower"], data.get("stochastic_k"), data.get("stochastic_d"),
        data.get("atr_14"), data.get("adx_14"), now, now
    ]
    client.insert("technical_indicators", [row], column_names=[
        "security_id", "trade_date", "sma_20", "sma_50", "sma_200", "ema_12", "ema_26", "rsi_14",
        "macd", "macd_signal", "macd_histogram", "bb_upper", "bb_middle", "bb_lower",
        "stochastic_k", "stochastic_d", "atr_14", "adx_14", "created_at", "updated_at"
    ])

def insert_trading_statistics(data):
    now = datetime.utcnow()
    row = [
        data["security_id"], data["trade_date"], data["previous_close"], data["price_change"],
        data["price_change_percent"], data["volume_ratio"], data["market_cap"], data["turnover"],
        data["avg_volume_10d"], data.get("beta"), data.get("volatility_30d"), now, now
    ]
    client.insert("trading_statistics", [row], column_names=[
        "security_id", "trade_date", "previous_close", "price_change", "price_change_percent",
        "volume_ratio", "market_cap", "turnover", "avg_volume_10d", "beta", "volatility_30d",
        "created_at", "updated_at"
    ])

def insert_financial_period(data):
    now = datetime.utcnow()
    row = [
        data["id"], data["company_id"], data["fiscal_year"], data["period_type"],
        data["period_start"], data["period_end"], now, now
    ]
    client.insert("financial_periods", [row], column_names=[
        "id", "company_id", "fiscal_year", "period_type", "period_start", "period_end",
        "created_at", "updated_at"
    ])

def insert_financial_ratios(data):
    now = datetime.utcnow()
    row = [
        data["financial_period_id"], data["price_to_earnings"], data["price_to_book"],
        data["price_to_sales"], data["return_on_equity"], data["return_on_assets"],
        data["debt_to_equity"], data["current_ratio"], data["gross_margin"], data["operating_margin"],
        data["net_margin"], data["ebitda"], data["eps_basic"], data["eps_diluted"],
        data["dividend_per_share"], data["book_value_per_share"], data["free_cash_flow"],
        now, now
    ]
    client.insert("financial_ratios", [row], column_names=[
        "financial_period_id", "price_to_earnings", "price_to_book", "price_to_sales",
        "return_on_equity", "return_on_assets", "debt_to_equity", "current_ratio",
        "gross_margin", "operating_margin", "net_margin", "ebitda", "eps_basic",
        "eps_diluted", "dividend_per_share", "book_value_per_share", "free_cash_flow",
        "created_at", "updated_at"
    ])
# ========== GET METHODS ==========

def get_sectors():
    return client.query("SELECT * FROM sectors ORDER BY name").result_rows

def get_industries():
    return client.query("SELECT * FROM industries ORDER BY name").result_rows

def get_exchanges():
    return client.query("SELECT * FROM exchanges ORDER BY name").result_rows

def get_companies(limit=100):
    return client.query(f"SELECT * FROM companies ORDER BY created_at DESC LIMIT {limit}").result_rows

def get_securities(limit=100):
    return client.query(f"SELECT * FROM securities ORDER BY listing_date DESC LIMIT {limit}").result_rows

def get_ohlcv(security_id, start_date, end_date):
    return client.query(f"""
        SELECT * FROM ohlcv_daily
        WHERE security_id = '{security_id}'
        AND trade_date BETWEEN '{start_date}' AND '{end_date}'
        ORDER BY trade_date
    """).result_rows

def get_technical_indicators(security_id, start_date, end_date):
    return client.query(f"""
        SELECT * FROM technical_indicators
        WHERE security_id = '{security_id}'
        AND trade_date BETWEEN '{start_date}' AND '{end_date}'
        ORDER BY trade_date
    """).result_rows

def get_trading_statistics(security_id, start_date, end_date):
    return client.query(f"""
        SELECT * FROM trading_statistics
        WHERE security_id = '{security_id}'
        AND trade_date BETWEEN '{start_date}' AND '{end_date}'
        ORDER BY trade_date
    """).result_rows

def get_financial_periods(company_id):
    return client.query(f"""
        SELECT * FROM financial_periods
        WHERE company_id = '{company_id}'
        ORDER BY fiscal_year DESC
    """).result_rows

def get_financial_ratios(financial_period_id):
    return client.query(f"""
        SELECT * FROM financial_ratios
        WHERE financial_period_id = '{financial_period_id}'
    """).result_rows
    
def get_security_id_by_symbol(symbol: str) -> str:
    result = client.query(f"SELECT id FROM securities WHERE symbol = '{symbol}' LIMIT 1").result_rows
    print(f"Query result for symbol '{symbol}': {result}")
    return str(result[0][0]) if result else None

def get_company_id_by_symbol(symbol: str) -> str:
    result = client.query(f"""
        SELECT company_id FROM securities
        WHERE symbol = '{symbol}' LIMIT 1
    """).result_rows
    return str(result[0][0]) if result else None

def get_sector_id_by_name(name: str) -> str:
    result = client.query(f"SELECT id FROM sectors WHERE name = '{name}' LIMIT 1").result_rows
    return str(result[0][0]) if result else None

def get_industry_id_by_name(name: str) -> str:
    result = client.query(f"SELECT id FROM industries WHERE name = '{name}' LIMIT 1").result_rows
    return str(result[0][0]) if result else None
