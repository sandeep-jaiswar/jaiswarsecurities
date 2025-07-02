import { NextRequest, NextResponse } from "next/server";
import { ingestSymbols, ingestOHLCV } from "@/lib/data-ingestion";

export async function POST(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/ingest/', '').split('/');
    const body = await req.json();

    if (slug.length === 1 && slug[0] === 'symbols') {
        const { symbols } = body;
        return ingestSymbols(symbols);
    }

    if (slug.length === 1 && slug[0] === 'ohlcv') {
        const { symbol, startDate, endDate } = body;
        return ingestOHLCV(symbol, startDate, endDate);
    }

    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}
