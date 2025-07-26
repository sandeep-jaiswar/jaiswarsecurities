import { NextRequest, NextResponse } from "next/server";
import { ingestSymbols, ingestOHLCV } from "@/lib/data-ingestion";

async function handleIngestSymbols(req: NextRequest) {
    const body = await req.json();
    const { symbols } = body;
    return ingestSymbols(symbols);
}

async function handleIngestOHLCV(req: NextRequest) {
    const body = await req.json();
    const { symbol, startDate, endDate } = body;
    return ingestOHLCV(symbol, startDate, endDate);
}

export async function POST(req: NextRequest) {
    const slug = req.nextUrl.pathname.replace('/api/ingest/', '').split('/');

    if (slug.length === 1) {
        const endpoint = slug[0];
        switch (endpoint) {
            case 'symbols':
                return handleIngestSymbols(req);
            case 'ohlcv':
                return handleIngestOHLCV(req);
            default:
                return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
        }
    }

    return NextResponse.json({ error: "Endpoint not found" }, { status: 404 });
}
