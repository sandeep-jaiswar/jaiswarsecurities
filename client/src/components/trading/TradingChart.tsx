'use client'

import { useEffect, useRef } from 'react'
import { useQuery } from 'react-query'
import { apiClient } from '@/lib/api'

interface TradingChartProps {
  symbol: string
  timeframe: string
}

export function TradingChart({ symbol, timeframe }: TradingChartProps) {
  const chartRef = useRef<HTMLDivElement>(null)

  const { data: chartData, isLoading } = useQuery(
    ['trading-chart', symbol, timeframe],
    () => apiClient.get(`/api/trading/chart/${symbol}?timeframe=${timeframe}`),
    {
      refetchInterval: 5000,
    }
  )

  return (
    <div className="bg-terminal-panel border border-terminal-border h-96">
      {/* Chart Header */}
      <div className="border-b border-terminal-border p-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h3 className="text-sm font-bold text-terminal-accent">
              {symbol} - Candlestick Pattern Recognition
            </h3>
            <div className="text-xs text-terminal-muted">
              Period: -0.63% Pre-market
            </div>
          </div>
          <div className="flex items-center space-x-4 text-xs">
            <span className="text-market-up">Entry: Long 150.67</span>
            <span className="text-market-up">Exit: +1.92% (Bullish)</span>
            <span className="text-market-down">Entry: Short 184.15</span>
          </div>
        </div>
      </div>

      {/* Chart Container */}
      <div className="relative h-full">
        <div ref={chartRef} className="absolute inset-0 p-4">
          {isLoading ? (
            <div className="flex items-center justify-center h-full">
              <div className="loading-spinner"></div>
            </div>
          ) : (
            <div className="h-full flex items-center justify-center">
              <div className="text-center">
                <div className="text-4xl text-terminal-muted mb-4">📈</div>
                <div className="text-terminal-muted">
                  Advanced Trading Chart for {symbol}
                </div>
                <div className="text-xs text-terminal-muted mt-2">
                  Candlestick patterns, trendlines, and technical analysis
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Chart Annotations */}
        <div className="absolute top-4 right-4 space-y-1 text-xs">
          <div className="bg-black bg-opacity-75 p-2 rounded">
            <div className="text-terminal-accent">Latest News</div>
            <div className="text-terminal-muted">Automated Trendlines</div>
          </div>
          <div className="bg-black bg-opacity-75 p-2 rounded">
            <div className="text-terminal-accent">Price Action Heatmaps</div>
            <div className="text-terminal-muted">Buy & Sell Signals</div>
          </div>
          <div className="bg-black bg-opacity-75 p-2 rounded">
            <div className="text-terminal-accent">Analyst Rating Changes</div>
          </div>
        </div>
      </div>
    </div>
  )
}