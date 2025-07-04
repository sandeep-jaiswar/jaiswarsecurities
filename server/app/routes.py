from fastapi import APIRouter, Query
from typing import List
import yfinance as yf
import pandas as pd
import pandas_ta as ta
import uuid
from datetime import datetime
from app import db

router = APIRouter()


@router.post("/load/security")
def load_security(symbol: str = Query(..., description="Stock ticker like INFY.NS")):
    ticker = yf.Ticker(symbol)
    info = ticker.info

    security_id = str(uuid.uuid4())
    company_id = str(uuid.uuid4())
    exchange_id = str(uuid.uuid4())

    ipo_date = info.get("ipoDate", "2000-01-01")
    try:
        listing_date = datetime.strptime(ipo_date, "%Y-%m-%d").date()
    except ValueError:
        listing_date = datetime(2000, 1, 1).date()

    db.insert_exchange(
        id=exchange_id,
        name=info.get("exchange", "NSE"),
        code=info.get("exchange", "NSE"),
        country="India",
        timezone="Asia/Kolkata",
        mic_code="XNSE"
    )

    db.insert_company({
        "id": company_id,
        "name": info.get("longName", symbol),
        "sector_id": str(uuid.uuid4()),
        "industry_id": str(uuid.uuid4()),
        "business_description": info.get("longBusinessSummary", ""),
        "employee_count": info.get("fullTimeEmployees", 0),
        "website": info.get("website", ""),
        "country": info.get("country", "India"),
        "founded_year": None,
        "headquarters_city": "",
        "headquarters_state": "",
        "headquarters_country": info.get("country", "India")
    })

    db.insert_security({
        "id": security_id,
        "symbol": symbol,
        "name": info.get("longName", symbol),
        "company_id": company_id,
        "exchange_id": exchange_id,
        "isin": "",
        "cusip": "",
        "figi": "",
        "asset_type": "Equity",
        "currency": info.get("currency", "INR"),
        "country": info.get("country", "India"),
        "is_active": 1,
        "listing_date": listing_date,
        "delisting_date": None,
        "shares_outstanding": info.get("sharesOutstanding", 0)
    })

    return {"status": "success", "action": "security loaded", "symbol": symbol}


@router.post("/load/ohlcv")
def load_ohlcv(symbol: str = Query(...),
               period: str = Query("1y"),
               interval: str = Query("1d")):
    ticker = yf.Ticker(symbol)
    df = ticker.history(period=period, interval=interval)

    if df.empty:
        return {"error": "No data found"}

    security_id = db.get_security_id_by_symbol(symbol)
    if not security_id:
        return {"error": "Security not found. Please load security first."}

    rows = []
    for date, row in df.iterrows():
        rows.append({
            "security_id": security_id,
            "trade_date": date.date(),
            "open_price": float(row["Open"]),
            "high_price": float(row["High"]),
            "low_price": float(row["Low"]),
            "close_price": float(row["Close"]),
            "adjusted_close": float(row.get("Adj Close", row["Close"])),
            "volume": int(row["Volume"]),
            "dividend": None,
            "split_factor": None,
            "currency": "INR"
        })

    for r in rows:
        db.insert_ohlcv(r)

    return {"status": "success", "action": "ohlcv loaded", "symbol": symbol, "count": len(rows)}


@router.post("/load/technical-indicators")
def load_technical_indicators(symbol: str = Query(...)):
    security_id = db.get_security_id_by_symbol(symbol)
    if not security_id:
        return {"error": "Security not found. Please load security first."}
    print(f"Loading technical indicators for {symbol} with security ID {security_id}")
    df = yf.Ticker(symbol).history(period="1y", interval="1d")
    if df.empty:
        return {"error": "No data found"}

    df.ta.sma(length=20, append=True)
    df.ta.sma(length=50, append=True)
    df.ta.sma(length=200, append=True)
    df.ta.ema(length=12, append=True)
    df.ta.ema(length=26, append=True)
    df.ta.rsi(length=14, append=True)
    df.ta.macd(append=True)
    df.ta.bbands(append=True)
    df.ta.stoch(append=True)
    df.ta.atr(length=14, append=True)
    df.ta.adx(length=14, append=True)

    count = 0
    for date, row in df.iterrows():
        if pd.isna(row.get("SMA_20")):
            continue
        db.insert_technical_indicators({
            "security_id": security_id,
            "trade_date": date.date(),
            "sma_20": row["SMA_20"],
            "sma_50": row["SMA_50"],
            "sma_200": row["SMA_200"],
            "ema_12": row["EMA_12"],
            "ema_26": row["EMA_26"],
            "rsi_14": row["RSI_14"],
            "macd": row["MACD_12_26_9"],
            "macd_signal": row["MACDs_12_26_9"],
            "macd_histogram": row["MACDh_12_26_9"],
            "bb_upper": row["BBU_20_2.0"],
            "bb_middle": row["BBM_20_2.0"],
            "bb_lower": row["BBL_20_2.0"],
            "stochastic_k": row.get("STOCHk_14_3_3"),
            "stochastic_d": row.get("STOCHd_14_3_3"),
            "atr_14": row.get("ATR_14", None),
            "adx_14": row.get("ADX_14", None)
        })
        count += 1

    return {"status": "success", "action": "technical indicators loaded", "symbol": symbol, "count": count}


@router.post("/load/trading-statistics")
def load_trading_statistics(symbol: str = Query(...)):
    security_id = db.get_security_id_by_symbol(symbol)
    if not security_id:
        return {"error": "Security not found. Please load security first."}

    ticker = yf.Ticker(symbol)
    df = ticker.history(period="1mo")

    count = 0
    for i in range(1, len(df)):
        row_today = df.iloc[i]
        row_prev = df.iloc[i - 1]
        date = df.index[i].date()

        db.insert_trading_statistics({
            "security_id": security_id,
            "trade_date": date,
            "previous_close": float(row_prev["Close"]),
            "price_change": float(row_today["Close"] - row_prev["Close"]),
            "price_change_percent": float(((row_today["Close"] - row_prev["Close"]) / row_prev["Close"]) * 100),
            "volume_ratio": float(row_today["Volume"] / (df["Volume"].rolling(10).mean().iloc[i] or 1)),
            "market_cap": float(ticker.info.get("marketCap") or 0),
            "turnover": float(row_today["Close"] * row_today["Volume"]),
            "avg_volume_10d": int(df["Volume"].rolling(10).mean().iloc[i] or 0),
            "beta": float(ticker.info.get("beta") or 0),
            "volatility_30d": float(ticker.info.get("52WeekChange") or 0)
        })
        count += 1

    return {"status": "success", "action": "trading statistics loaded", "symbol": symbol, "count": count}


@router.post("/load/financial-periods")
def load_financial_periods(symbol: str = Query(...)):
    company_id = db.get_company_id_by_symbol(symbol)
    if not company_id:
        return {"error": "Company not found"}

    fiscal_year = datetime.now().year
    period_id = str(uuid.uuid4())

    db.insert_financial_period({
        "id": period_id,
        "company_id": company_id,
        "fiscal_year": fiscal_year,
        "period_type": "Annual",
        "period_start": datetime(fiscal_year, 4, 1).date(),
        "period_end": datetime(fiscal_year + 1, 3, 31).date()
    })

    return {"status": "success", "action": "financial period loaded", "symbol": symbol}


@router.post("/load/financial-ratios")
def load_financial_ratios(symbol: str = Query(...)):
    company_id = db.get_company_id_by_symbol(symbol)
    if not company_id:
        return {"error": "Company not found"}

    periods = db.get_financial_periods(company_id)
    if not periods:
        return {"error": "No financial periods found"}

    period_id = str(periods[0][0])
    info = yf.Ticker(symbol).info

    db.insert_financial_ratios({
        "financial_period_id": period_id,
        "price_to_earnings": float(info.get("trailingPE") or 0),
        "price_to_book": float(info.get("priceToBook") or 0),
        "price_to_sales": float(info.get("priceToSalesTrailing12Months") or 0),
        "return_on_equity": float(info.get("returnOnEquity") or 0),
        "return_on_assets": float(info.get("returnOnAssets") or 0),
        "debt_to_equity": float(info.get("debtToEquity") or 0),
        "current_ratio": float(info.get("currentRatio") or 0),
        "gross_margin": float(info.get("grossMargins") or 0),
        "operating_margin": float(info.get("operatingMargins") or 0),
        "net_margin": float(info.get("netMargins") or 0),
        "ebitda": float(info.get("ebitda") or 0),
        "eps_basic": float(info.get("trailingEps") or 0),
        "eps_diluted": float(info.get("trailingEps") or 0),
        "dividend_per_share": float(info.get("dividendRate") or 0),
        "book_value_per_share": float(info.get("bookValue") or 0),
        "free_cash_flow": float(info.get("freeCashflow") or 0)
    })

    return {"status": "success", "action": "financial ratios loaded", "symbol": symbol}
