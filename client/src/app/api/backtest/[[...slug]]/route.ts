import { NextRequest, NextResponse } from "next/server";
import { createBacktest, getBacktestResults } from "@/lib/backtesting";

async function handleCreateBacktest(req: NextRequest) {
    const body = await req.json();
    const { strategyId, name, startDate, endDate, initialCapital, symbols } = body;
    return createBacktest({ strategyId, name, startDate, endDate, initialCapital, commission: process.env.BACKTEST_COMMISSION, slippage: 0.001, symbols });
}

async function handleGetBacktestResults(id: string) {
    return getBacktestResults(id);
}

export async function POST(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/backtest/', '').split('/');
    if (slug.length === 1 && slug[0] === 'backtest') {
        return handleCreateBacktest(req);
    }
    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}

export async function GET(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/backtest/', '').split('/');
    if (slug.length === 2 && slug[0] === 'backtest') {
        const id = slug[1];
        return handleGetBacktestResults(id);
    }
    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}
