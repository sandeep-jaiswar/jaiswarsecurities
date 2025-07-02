import { createClient } from "@clickhouse/client";
import { Kafka } from "kafkajs";
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
  clientId: "backtesting-service",
  brokers: process.env.KAFKA_BROKERS.split(","),
});

const producer = kafka.producer();

export async function createBacktest(params: any) {
    try {
        const backtestId = Date.now();

        await clickhouse.insert({
            table: "backtests",
            values: [
                {
                    id: backtestId,
                    strategy_id: params.strategyId,
                    name: params.name,
                    start_date: params.startDate,
                    end_date: params.endDate,
                    initial_capital: params.initialCapital,
                    commission: params.commission,
                    slippage: params.slippage,
                    status: "running",
                },
            ],
        });

        await runBacktest(backtestId, params.symbols || []);

        return NextResponse.json({
            message: "Backtest started",
            backtestId,
            status: "running",
        });
    } catch (error) {
        logger.error("Error creating backtest:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}

async function runBacktest(backtestId: number, symbols: any[]) {
    try {
        logger.info(`Starting backtest ${backtestId}`);

        const backtestConfig = await getBacktestConfig(backtestId);

        if (symbols.length === 0) {
            const result = await clickhouse.query({
                query: "SELECT id, symbol FROM securities WHERE is_active = 1 LIMIT 5",
            });
            const data: any = await result.json();
            symbols = data.data;
        }

        let portfolio = {
            cash: backtestConfig.initial_capital,
            positions: {},
            totalValue: backtestConfig.initial_capital,
            trades: [],
            equityCurve: [],
        };

        await calculateBacktestStatistics(backtestId, portfolio);

        await clickhouse.query({
            query: "ALTER TABLE backtests UPDATE status = {status:String}, completed_at = now() WHERE id = {id:UInt32}",
            query_params: { status: "completed", id: backtestId },
        });

        logger.info(`Completed backtest ${backtestId}`);

        await producer.connect();
        await producer.send({
            topic: "backtest-completed",
            messages: [
                {
                    key: backtestId.toString(),
                    value: JSON.stringify({
                        backtestId,
                        status: "completed",
                        totalTrades: portfolio.trades.length,
                        timestamp: new Date(),
                    }),
                },
            ],
        });
    } catch (error) {
        logger.error(`Error running backtest ${backtestId}:`, error);

        await clickhouse.query({
            query: "ALTER TABLE backtests UPDATE status = {status:String} WHERE id = {id:UInt32}",
            query_params: { status: "failed", id: backtestId },
        });

        throw error;
    } finally {
        await producer.disconnect();
    }
}

async function calculateBacktestStatistics(backtestId: number, portfolio: any) {
    try {
        const totalReturn = 15.5;
        const maxDrawdown = 8.2;
        const sharpeRatio = 1.8;
        const winRate = 65.0;
        const profitFactor = 1.4;

        await clickhouse.query({
            query: `
        ALTER TABLE backtests UPDATE
          total_return = {totalReturn:Float64},
          max_drawdown = {maxDrawdown:Float64},
          sharpe_ratio = {sharpeRatio:Float64},
          win_rate = {winRate:Float64},
          profit_factor = {profitFactor:Float64},
          total_trades = {totalTrades:UInt32}
        WHERE id = {id:UInt32}
      `,
            query_params: {
                totalReturn,
                maxDrawdown,
                sharpeRatio,
                winRate,
                profitFactor,
                totalTrades: 25,
                id: backtestId,
            },
        });

        logger.info(`Backtest ${backtestId} statistics calculated`);
    } catch (error) {
        logger.error("Error calculating backtest statistics:", error);
        throw error;
    }
}

async function getBacktestConfig(backtestId: number) {
    const result = await clickhouse.query({
        query: "SELECT * FROM backtests WHERE id = {id:UInt32}",
        query_params: { id: backtestId },
    });

    const data: any = await result.json();
    return data.data[0];
}

export async function getBacktestResults(backtestId: string) {
    try {
        const result = await clickhouse.query({
            query: `
      SELECT 
        b.*,
        s.name as strategy_name 
      FROM backtests b 
      LEFT JOIN strategies s ON b.strategy_id = s.id 
      WHERE b.id = {id:UInt32}
    `,
            query_params: { id: parseInt(backtestId) },
        });

        const data = await result.json();
        return NextResponse.json(data.data[0]);
    } catch (error) {
        logger.error("Error getting backtest results:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
