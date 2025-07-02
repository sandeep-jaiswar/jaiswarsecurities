import { createClient } from "@clickhouse/client";
import axios from "axios";
import { Kafka } from "kafkajs";
import Redis from "redis";
import winston from "winston";
import { NextResponse } from "next/server";

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});

const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL,
  username: process.env.CLICKHOUSE_USER,
  password: process.env.CLICKHOUSE_PASSWORD,
  database: process.env.CLICKHOUSE_DATABASE,
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 1,
  },
});

const kafka = new Kafka({
  clientId: "data-ingestion-service",
  brokers: process.env.KAFKA_BROKERS.split(","),
});

const producer = kafka.producer();
const redis = Redis.createClient({
  url: process.env.REDIS_URL,
});

redis.on("error", (err) => {
    logger.error("Redis connection error:", err)
});

async function connectRedis() {
    if (!redis.isOpen) {
        await redis.connect();
    }
}

export async function ingestSymbols(symbols: any[]) {
    try {
        const values = symbols.map((symbol) => ({
            id: Date.now() + Math.random(),
            company_id: symbol.company_id || 0,
            symbol: symbol.symbol,
            name: symbol.name,
            is_active: 1,
        }));

        await clickhouse.insert({
            table: "securities",
            values: values,
        });

        logger.info(`Ingested ${symbols.length} symbols`);

        await producer.connect();
        await producer.send({
            topic: "symbols-ingested",
            messages: [
                {
                    key: "symbols",
                    value: JSON.stringify({
                        count: symbols.length,
                        timestamp: new Date(),
                    }),
                },
            ],
        });

        return NextResponse.json({ message: "Symbols ingestion started", count: symbols.length });
    } catch (error) {
        logger.error("Error in ingestSymbols:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    } finally {
        await producer.disconnect();
    }
}

export async function ingestOHLCV(symbol: string, startDate: string, endDate: string) {
    try {
        const securityResult = await clickhouse.query({
            query: "SELECT id FROM securities WHERE symbol = {symbol:String}",
            query_params: { symbol },
        });

        const securities: any = await securityResult.json();
        if (securities.data.length === 0) {
            throw new Error(`Symbol ${symbol} not found`);
        }
        const securityId = securities.data[0].id;

        const data = await fetchOHLCVData(symbol, startDate, endDate);

        const values = data.map((record: any) => ({
            id: Date.now() + Math.random(),
            security_id: securityId,
            trade_date: record.date,
            open_price: record.open,
            high_price: record.high,
            low_price: record.low,
            close_price: record.close,
            adjusted_close: record.adjusted_close,
            volume: record.volume,
        }));

        await clickhouse.insert({
            table: "ohlcv_daily",
            values: values,
        });

        logger.info(`Ingested ${data.length} OHLCV records for ${symbol}`);
        
        await producer.connect();
        await producer.send({
            topic: "ohlcv-ingested",
            messages: [
                {
                    key: symbol,
                    value: JSON.stringify({
                        symbol,
                        securityId,
                        recordCount: data.length,
                        startDate,
                        endDate,
                        timestamp: new Date(),
                    }),
                },
            ],
        });

        return NextResponse.json({
            message: "OHLCV ingestion started",
            symbol,
            startDate,
            endDate,
        });
    } catch (error) {
        logger.error(`Error ingesting OHLCV for ${symbol}:`, error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    } finally {
        await producer.disconnect();
    }
}

async function fetchOHLCVData(symbol: string, startDate: string, endDate: string) {
    await connectRedis();
    const cacheKey = `ohlcv:${symbol}:${startDate}:${endDate}`;
    const cachedData = await redis.get(cacheKey);

    if (cachedData) {
        logger.info(`Using cached data for ${symbol}`);
        return JSON.parse(cachedData);
    }

    try {
        const response = await axios.get("https://www.alphavantage.co/query", {
            params: {
                function: "TIME_SERIES_DAILY_ADJUSTED",
                symbol: symbol,
                apikey: process.env.ALPHA_VANTAGE_API_KEY,
                outputsize: "full",
            },
            timeout: 30000,
        });

        const timeSeries = response.data["Time Series (Daily)"];
        if (!timeSeries) {
            throw new Error(`No data received for ${symbol}`);
        }

        const data = Object.entries(timeSeries)
            .filter(([date]) => date >= startDate && date <= endDate)
            .map(([date, values]: [string, any]) => ({
                date,
                open: parseFloat(values["1. open"]),
                high: parseFloat(values["2. high"]),
                low: parseFloat(values["3. low"]),
                close: parseFloat(values["4. close"]),
                adjusted_close: parseFloat(values["5. adjusted close"]),
                volume: parseInt(values["6. volume"]),
            }))
            .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

        await redis.setEx(cacheKey, 3600, JSON.stringify(data));

        return data;
    } catch (error) {
        logger.error(`Error fetching data for ${symbol}:`, error);
        throw error;
    }
}
