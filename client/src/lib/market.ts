import { createClient } from "@clickhouse/client";
import { NextResponse } from "next/server";
import winston from "winston";

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: winston.format.json(),
  transports: [new winston.transports.Console()],
});

const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || "http://localhost:8123",
  username: process.env.CLICKHOUSE_USER || "stockuser",
  password: process.env.CLICKHOUSE_PASSWORD || "stockpass123",
  database: process.env.CLICKHOUSE_DATABASE || "stockdb",
});

export async function getSymbols(search: string, sector: string, exchange: string, limit: string = '100', offset: string = '0') {
    try {
        let query = `
      SELECT 
        s.id,
        s.symbol,
        s.name,
        c.name as company_name,
        sec.name as sector_name,
        ind.name as industry_name,
        e.name as exchange_name,
        s.is_active,
        s.listing_date,
        s.shares_outstanding
      FROM securities s
      LEFT JOIN companies c ON s.company_id = c.id
      LEFT JOIN sectors sec ON c.sector_id = sec.id
      LEFT JOIN industries ind ON c.industry_id = ind.id
      LEFT JOIN exchanges e ON s.exchange_id = e.id
      WHERE s.is_active = 1
    `;

        const queryParams: any = {};

        if (search) {
            query += ` AND (s.symbol ILIKE {search:String} OR s.name ILIKE {search:String} OR c.name ILIKE {search:String})`;
            queryParams.search = `%${search}%`;
        }

        if (sector) {
            query += ` AND sec.code = {sector:String}`;
            queryParams.sector = sector;
        }

        if (exchange) {
            query += ` AND e.code = {exchange:String}`;
            queryParams.exchange = exchange;
        }

        query += ` ORDER BY s.symbol LIMIT {limit:UInt32} OFFSET {offset:UInt32}`;
        queryParams.limit = parseInt(limit);
        queryParams.offset = parseInt(offset);

        const result = await clickhouse.query({
            query,
            query_params: queryParams,
        });

        const data = await result.json();
        return NextResponse.json({
            data: data.data,
            pagination: {
                limit: parseInt(limit),
                offset: parseInt(offset),
                total: data.data.length,
            },
        });
    } catch (error) {
        logger.error("Error fetching symbols:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getQuote(symbol: string) {
    try {
        const result = await clickhouse.query({
            query: `
        SELECT 
          s.symbol,
          s.name,
          o.open_price,
          o.high_price,
          o.low_price,
          o.close_price,
          o.adjusted_close,
          o.volume,
          o.trade_date,
          ts.previous_close,
          ts.price_change,
          ts.price_change_percent,
          ts.volume_ratio,
          ts.market_cap
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE s.symbol = {symbol:String}
        ORDER BY o.trade_date DESC
        LIMIT 1
      `,
            query_params: { symbol: symbol.toUpperCase() },
        });

        const data = await result.json();
        if (data.data.length === 0) {
            return NextResponse.json({ error: "Symbol not found" }, { status: 404 });
        }

        return NextResponse.json(data.data[0]);
    } catch (error) {
        logger.error("Error fetching quote:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getChartData(symbol: string, period: string = '1M', interval: string = '1d') {
    try {
        const endDate = new Date();
        const startDate = new Date();

        switch (period) {
            case "1D":
                startDate.setDate(endDate.getDate() - 1);
                break;
            case "5D":
                startDate.setDate(endDate.getDate() - 5);
                break;
            case "1M":
                startDate.setMonth(endDate.getMonth() - 1);
                break;
            case "3M":
                startDate.setMonth(endDate.getMonth() - 3);
                break;
            case "6M":
                startDate.setMonth(endDate.getMonth() - 6);
                break;
            case "1Y":
                startDate.setFullYear(endDate.getFullYear() - 1);
                break;
            case "2Y":
                startDate.setFullYear(endDate.getFullYear() - 2);
                break;
            case "5Y":
                startDate.setFullYear(endDate.getFullYear() - 5);
                break;
        }

        const result = await clickhouse.query({
            query: `
        SELECT 
          o.trade_date,
          o.open_price,
          o.high_price,
          o.low_price,
          o.close_price,
          o.volume,
          ti.sma_20,
          ti.sma_50,
          ti.sma_200,
          ti.ema_12,
          ti.ema_26,
          ti.rsi_14,
          ti.macd,
          ti.macd_signal,
          ti.bb_upper,
          ti.bb_middle,
          ti.bb_lower
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        LEFT JOIN technical_indicators ti ON s.id = ti.security_id AND o.trade_date = ti.trade_date
        WHERE s.symbol = {symbol:String}
          AND o.trade_date >= {startDate:Date}
          AND o.trade_date <= {endDate:Date}
        ORDER BY o.trade_date ASC
      `,
            query_params: {
                symbol: symbol.toUpperCase(),
                startDate: startDate.toISOString().split("T")[0],
                endDate: endDate.toISOString().split("T")[0],
            },
        });

        const data = await result.json();
        return NextResponse.json({
            symbol: symbol.toUpperCase(),
            period,
            interval,
            data: data.data,
        });
    } catch (error) {
        logger.error("Error fetching chart data:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getMovers(type: string = 'gainers', limit: string = '20') {
    try {
        let orderBy = "";
        switch (type) {
            case "gainers":
                orderBy = "ts.price_change_percent DESC";
                break;
            case "losers":
                orderBy = "ts.price_change_percent ASC";
                break;
            case "active":
                orderBy = "o.volume DESC";
                break;
        }

        const result = await clickhouse.query({
            query: `
        SELECT 
          s.symbol,
          s.name,
          o.close_price,
          o.volume,
          ts.price_change,
          ts.price_change_percent,
          ts.market_cap
        FROM securities s
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
          AND ts.price_change_percent IS NOT NULL
        ORDER BY ${orderBy}
        LIMIT {limit:UInt32}
      `,
            query_params: { limit: parseInt(limit) },
        });

        const data = await result.json();
        return NextResponse.json({
            type,
            data: data.data,
        });
    } catch (error) {
        logger.error("Error fetching movers:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getSectors() {
    try {
        const result = await clickhouse.query({
            query: `
        SELECT 
          sec.name as sector_name,
          sec.code as sector_code,
          COUNT(DISTINCT s.id) as stock_count,
          AVG(ts.price_change_percent) as avg_change_percent,
          SUM(o.volume) as total_volume,
          SUM(ts.market_cap) as total_market_cap
        FROM sectors sec
        JOIN companies c ON sec.id = c.sector_id
        JOIN securities s ON c.id = s.company_id
        JOIN ohlcv_daily o ON s.id = o.security_id
        JOIN trading_statistics ts ON s.id = ts.security_id AND o.trade_date = ts.trade_date
        WHERE o.trade_date = (SELECT MAX(trade_date) FROM ohlcv_daily)
          AND s.is_active = 1
        GROUP BY sec.name, sec.code
        ORDER BY avg_change_percent DESC
      `,
        });

        const data = await result.json();
        return NextResponse.json(data.data);
    } catch (error) {
        logger.error("Error fetching sector performance:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getIndices() {
    try {
        // Mock data for major indices
        const indices = [
            {
                symbol: "SPY",
                name: "SPDR S&P 500 ETF",
                price: 450.25,
                change: 2.15,
                changePercent: 0.48,
                volume: 45000000,
            },
            {
                symbol: "QQQ",
                name: "Invesco QQQ Trust",
                price: 385.5,
                change: 3.2,
                changePercent: 0.84,
                volume: 32000000,
            },
            {
                symbol: "DIA",
                name: "SPDR Dow Jones Industrial Average ETF",
                price: 340.75,
                change: 1.85,
                changePercent: 0.55,
                volume: 15000000,
            },
            {
                symbol: "IWM",
                name: "iShares Russell 2000 ETF",
                price: 195.3,
                change: -0.85,
                changePercent: -0.43,
                volume: 28000000,
            },
        ];

        return NextResponse.json(indices);
    } catch (error) {
        logger.error("Error fetching indices:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getFundamentals(symbol: string) {
    try {
        const result = await clickhouse.query({
            query: `
        SELECT 
          c.name as company_name,
          c.business_description,
          c.employee_count,
          c.website,
          sec.name as sector_name,
          ind.name as industry_name,
          s.shares_outstanding,
          s.shares_float,
          fr.price_to_earnings,
          fr.price_to_book,
          fr.price_to_sales,
          fr.return_on_equity,
          fr.return_on_assets,
          fr.debt_to_equity,
          fr.current_ratio,
          fr.gross_margin,
          fr.operating_margin,
          fr.net_margin
        FROM securities s
        JOIN companies c ON s.company_id = c.id
        LEFT JOIN sectors sec ON c.sector_id = sec.id
        LEFT JOIN industries ind ON c.industry_id = ind.id
        LEFT JOIN financial_periods fp ON c.id = fp.company_id
        LEFT JOIN financial_ratios fr ON fp.id = fr.financial_period_id
        WHERE s.symbol = {symbol:String}
          AND fp.period_type = 'annual'
        ORDER BY fp.fiscal_year DESC
        LIMIT 1
      `,
            query_params: { symbol: symbol.toUpperCase() },
        });

        const data = await result.json();
        if (data.data.length === 0) {
            return NextResponse.json({ error: "Symbol not found" }, { status: 404 });
        }

        return NextResponse.json(data.data[0]);
    } catch (error) {
        logger.error("Error fetching fundamentals:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
