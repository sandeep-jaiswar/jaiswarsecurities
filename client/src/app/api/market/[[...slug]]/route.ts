import { NextRequest, NextResponse } from "next/server";
import { getSymbols, getQuote, getChartData, getMovers, getSectors, getIndices, getFundamentals } from "@/lib/market";

async function handleGetSymbols(req: NextRequest) {
    const { search, sector, exchange, limit, offset } = Object.fromEntries(req.nextUrl.searchParams);
    return getSymbols(search, sector, exchange, limit, offset);
}

async function handleGetQuote(req: NextRequest, symbol: string) {
    return getQuote(symbol);
}

async function handleGetChartData(req: NextRequest, symbol: string) {
    const { period, interval } = Object.fromEntries(req.nextUrl.searchParams);
    return getChartData(symbol, period, interval);
}

async function handleGetMovers(req: NextRequest) {
    const { type, limit } = Object.fromEntries(req.nextUrl.searchParams);
    return getMovers(type, limit);
}

async function handleGetSectors(req: NextRequest) {
    return getSectors();
}

async function handleGetIndices(req: NextRequest) {
    return getIndices();
}

async function handleGetFundamentals(req: NextRequest, symbol: string) {
    return getFundamentals(symbol);
}

export async function GET(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/market/', '').split('/');

    if (slug.length === 1) {
        const endpoint = slug[0];
        switch (endpoint) {
            case 'symbols':
                return handleGetSymbols(req);
            case 'movers':
                return handleGetMovers(req);
            case 'sectors':
                return handleGetSectors(req);
            case 'indices':
                return handleGetIndices(req);
            default:
                return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
        }
    } else if (slug.length === 2) {
        const [symbol, endpoint] = slug;
        switch (endpoint) {
            case 'quote':
                return handleGetQuote(req, symbol);
            case 'chart':
                return handleGetChartData(req, symbol);
            case 'fundamentals':
                return handleGetFundamentals(req, symbol);
            default:
                return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
        }
    }

    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}
