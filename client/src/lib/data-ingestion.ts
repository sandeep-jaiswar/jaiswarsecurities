import { createClient } from "@clickhouse/client";
import { Kafka } from "kafkajs";
import winston from "winston";
import { NextResponse } from "next/server";
import { fetchOHLCVData } from "./external-data"; // Import from the new file

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

// Encapsulate ClickHouse insertion for securities
async function insertSecuritiesToDb(values: any[]) {
    await clickhouse.insert({
        table: "securities",
        values: values,
    });
}

// Encapsulate Kafka publishing for symbols ingested event
async function publishSymbolsIngestedEvent(symbolsCount: number) {
    await producer.connect();
    await producer.send({
        topic: "symbols-ingested",
        messages: [
            {
                key: "symbols",
                value: JSON.stringify({
                    count: symbolsCount,
                    timestamp: new Date(),
                }),
            },
        ],
    });
    await producer.disconnect();
}

// Encapsulate ClickHouse insertion for OHLCV data
async function insertOHLCVToDb(values: any[]) {
    await clickhouse.insert({
        table: "ohlcv_daily",
        values: values,
    });
}

// Encapsulate Kafka publishing for OHLCV ingested event
async function publishOHLCVIngestedEvent(symbol: string, securityId: any, recordCount: number, startDate: string, endDate: string) {
    await producer.connect();
    await producer.send({
        topic: "ohlcv-ingested",
        messages: [
            {
                key: symbol,
                value: JSON.stringify({
                    symbol,
                    securityId,
                    recordCount,
                    startDate,
                    endDate,
                    timestamp: new Date(),
                }),
            },
        ],
    });
    await producer.disconnect();
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

        await insertSecuritiesToDb(values);

        logger.info(`Ingested ${symbols.length} symbols`);

        await publishSymbolsIngestedEvent(symbols.length);

        return NextResponse.json({ message: "Symbols ingestion started", count: symbols.length });
    } catch (error) {
        logger.error("Error in ingestSymbols:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
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

        await insertOHLCVToDb(values);

        logger.info(`Ingested ${data.length} OHLCV records for ${symbol}`);
        
        await publishOHLCVIngestedEvent(symbol, securityId, data.length, startDate, endDate);

        return NextResponse.json({
            message: "OHLCV ingestion started",
            symbol,
            startDate,
            endDate,
        });
    } catch (error) {
        logger.error(`Error ingesting OHLCV for ${symbol}:`, error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
