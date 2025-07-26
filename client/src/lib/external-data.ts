import axios from "axios";
import Redis from "redis";
import winston from "winston";

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

export async function fetchOHLCVData(symbol: string, startDate: string, endDate: string) {
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
