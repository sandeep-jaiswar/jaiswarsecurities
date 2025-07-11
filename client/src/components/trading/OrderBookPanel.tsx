"use client"

import { formatPrice, formatVolume } from "@/utils/formatters"

interface OrderBookPanelProps {
  symbol: string
}

export function OrderBookPanel({ symbol }: OrderBookPanelProps) {
  // Mock order book data
  const mockOrderBook = {
    bids: [
      { price: 150.24, size: 1500, orders: 12 },
      { price: 150.23, size: 2300, orders: 18 },
      { price: 150.22, size: 1800, orders: 15 },
      { price: 150.21, size: 3200, orders: 25 },
      { price: 150.2, size: 2100, orders: 16 },
    ],
    asks: [
      { price: 150.25, size: 1200, orders: 10 },
      { price: 150.26, size: 1900, orders: 14 },
      { price: 150.27, size: 2500, orders: 20 },
      { price: 150.28, size: 1700, orders: 13 },
      { price: 150.29, size: 2800, orders: 22 },
    ],
  }

  // Add checks for empty arrays
  if (!mockOrderBook.asks.length || !mockOrderBook.bids.length) {
    return (
      <div className="flex h-full flex-col items-center justify-center text-terminal-muted">
        No order book data available for {symbol}
      </div>
    )
  }

  // Destructure the first elements after the length check
  const firstAsk = mockOrderBook.asks[0]
  const firstBid = mockOrderBook.bids[0]

  const spread = firstAsk!.price - firstBid!.price
  const midPrice = (firstAsk!.price + firstBid!.price) / 2

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="border-b border-terminal-border p-3">
        <div className="flex items-center justify-between">
          <h3 className="font-medium text-terminal-accent">Order Book - {symbol}</h3>
          <div className="text-xs text-terminal-muted">Spread: {formatPrice(spread)}</div>
        </div>
      </div>

      {/* Order Book */}
      <div className="flex-1 overflow-y-auto">
        <div className="grid h-full grid-cols-2">
          {/* Bids */}
          <div className="border-r border-terminal-border">
            <div className="bg-terminal-border p-2 text-center text-xs font-medium">BIDS</div>
            <div className="space-y-1 p-2">
              {mockOrderBook.bids.map((bid, index) => (
                <div key={index} className="grid grid-cols-3 gap-2 text-xs">
                  <div className="font-mono text-market-up">{formatPrice(bid.price)}</div>
                  <div className="text-right font-mono">{formatVolume(bid.size)}</div>
                  <div className="text-right font-mono text-terminal-muted">{bid.orders}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Asks */}
          <div>
            <div className="bg-terminal-border p-2 text-center text-xs font-medium">ASKS</div>
            <div className="space-y-1 p-2">
              {mockOrderBook.asks.map((ask, index) => (
                <div key={index} className="grid grid-cols-3 gap-2 text-xs">
                  <div className="font-mono text-market-down">{formatPrice(ask.price)}</div>
                  <div className="text-right font-mono">{formatVolume(ask.size)}</div>
                  <div className="text-right font-mono text-terminal-muted">{ask.orders}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Market Info */}
      <div className="border-t border-terminal-border p-3">
        <div className="grid grid-cols-2 gap-4 text-xs">
          <div>
            <span className="text-terminal-muted">Mid Price: </span>
            <span className="font-mono">{formatPrice(midPrice)}</span>
          </div>
          <div>
            <span className="text-terminal-muted">Total Vol: </span>
            <span className="font-mono">15.2K</span>
          </div>
        </div>
      </div>
    </div>
  )
}
