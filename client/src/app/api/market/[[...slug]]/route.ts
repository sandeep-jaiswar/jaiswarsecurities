import { NextRequest, NextResponse } from "next/server";
import { getSymbols, getQuote, getChartData, getMovers, getSectors, getIndices, getFundamentals } from "@/lib/market";

export async function GET(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/market/', '').split('/');
    const symbol = slug[0];

    if (slug.length === 1 && slug[0] === 'symbols') {
        const { search, sector, exchange, limit, offset } = Object.fromEntries(req.nextUrl.searchParams);
        return getSymbols(search, sector, exchange, limit, offset);
    }

    if (slug.length === 2 && slug[1] === 'quote') {
        return getQuote(symbol);
    }

    if (slug.length === 2 && slug[1] === 'chart') {
        const { period, interval } = Object.fromEntries(req.nextUrl.searchParams);
        return getChartData(symbol, period, interval);
    }
    
    if (slug.length === 1 && slug[0] === 'movers') {
        const { type, limit } = Object.fromEntries(req.nextUrl.searchParams);
        return getMovers(type, limit);
    }

    if (slug.length === 1 && slug[0] === 'sectors') {
        return getSectors();
    }

    if (slug.length === 1 && slug[0] === 'indices') {
        return getIndices();
    }

    if (slug.length === 2 && slug[1] === 'fundamentals') {
        return getFundamentals(symbol);
    }

    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}
