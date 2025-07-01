"use client"

import { useEffect, useRef } from "react"
import { useQuery } from "react-query"
import { api } from "@/lib/api"

interface ChartPanelProps {
  symbol: string
}

export function ChartPanel({ symbol }: ChartPanelProps) {
  const chartContainerRef = useRef<HTMLDivElement>(null)

  const { data: ohlcvData, isLoading } = useQuery(["ohlcv", symbol], () => api.getOHLCV(symbol, { limit: 100 }), {
    enabled: !!symbol,
    refetchInterval: 10000,
  })

  const { data: indicatorsData } = useQuery(["indicators", symbol], () => api.getIndicators(symbol, { limit: 100 }), {
    enabled: !!symbol,
    refetchInterval: 10000,
  })

  useEffect(() => {
    if (!chartContainerRef.current || !ohlcvData) return

    // Here you would integrate with a charting library like TradingView, Lightweight Charts, etc.
    // For now, we'll show a placeholder
  }, [ohlcvData, indicatorsData])

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="text-center">
          <div className="loading-spinner mx-auto mb-4"></div>
          <div className="text-terminal-muted">Loading chart data for {symbol}...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col">
      {/* Chart Header */}
      <div className="border-b border-terminal-border p-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-terminal-accent">{symbol}</h2>
            <div className="text-sm text-terminal-muted">Real-time Chart</div>
          </div>
          <div className="flex items-center space-x-4 text-sm">
            <div>
              <span className="text-terminal-muted">Price: </span>
              <span className="font-mono text-market-up">$150.25</span>
            </div>
            <div>
              <span className="text-terminal-muted">Change: </span>
              <span className="font-mono text-market-up">+2.45 (+1.65%)</span>
            </div>
            <div>
              <span className="text-terminal-muted">Volume: </span>
              <span className="font-mono">2.5M</span>
            </div>
          </div>
        </div>
      </div>

      {/* Chart Container */}
      <div className="relative flex-1">
        <div ref={chartContainerRef} className="absolute inset-0 bg-terminal-bg">
          {/* Placeholder Chart */}
          <div className="flex h-full items-center justify-center">
            <div className="text-center">
              <div className="mb-4 text-6xl text-terminal-muted">📈</div>
              <div className="text-terminal-muted">Chart for {symbol} will be displayed here</div>
              <div className="mt-2 text-xs text-terminal-muted">
                Integration with TradingView or Lightweight Charts coming soon
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Chart Controls */}
      <div className="border-t border-terminal-border p-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            {["1D", "5D", "1M", "3M", "6M", "1Y", "5Y"].map((period) => (
              <button
                key={period}
                className="rounded bg-terminal-border px-3 py-1 text-xs hover:bg-terminal-accent hover:text-terminal-bg"
              >
                {period}
              </button>
            ))}
          </div>
          <div className="flex items-center space-x-2">
            <button className="rounded bg-terminal-border px-3 py-1 text-xs hover:bg-terminal-accent hover:text-terminal-bg">
              Indicators
            </button>
            <button className="rounded bg-terminal-border px-3 py-1 text-xs hover:bg-terminal-accent hover:text-terminal-bg">
              Drawing Tools
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
