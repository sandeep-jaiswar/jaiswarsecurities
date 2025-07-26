import { NextRequest, NextResponse } from 'next/server';

const rateLimitMap = new Map();

export async function middleware(req: NextRequest) {
  const ip = req.ip ?? '127.0.0.1';
  const limit = 100; // 100 requests per hour
  const windowMs = 60 * 60 * 1000; // 1 hour

  const record = rateLimitMap.get(ip);
  const now = Date.now();

  if (record && now - record.timestamp < windowMs) {
    if (record.count >= limit) {
      return new NextResponse(JSON.stringify({ error: 'Too many requests' }), {
        status: 429,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }
    rateLimitMap.set(ip, { ...record, count: record.count + 1 });
  } else {
    rateLimitMap.set(ip, { timestamp: now, count: 1 });
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
