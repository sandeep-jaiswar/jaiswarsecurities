"use client"

import { useQuery } from "react-query"
import { apiClient } from "@/lib/api"
import { formatNumber, formatPercent } from "@/utils/formatters"

interface MarketData {
  symbol: string
  price: number
  change: number
  changePercent: number
  volume: number
}

export function MarketOverview() {
  const { data: marketData, isLoading } = useQuery(
    "market-overview",
    () => apiClient.get("/analytics/market-overview"),
    {
      refetchInterval: 5000, // Refresh every 5 seconds
    }
  )

  const majorIndices = [
    { symbol: "SPY", name: "S&P 500" },
    { symbol: "QQQ", name: "NASDAQ" },
    { symbol: "DIA", name: "DOW" },
    { symbol: "IWM", name: "Russell 2000" },
  ]

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="loading-spinner"></div>
      </div>
    )
  }

  return (
    <div className="flex h-full items-center justify-between px-4">
      {/* Market Status */}
      <div className="flex items-center space-x-6">
        <div className="flex items-center space-x-2">
          <div className="h-2 w-2 animate-pulse rounded-full bg-market-up"></div>
          <span className="text-sm font-medium">MARKET OPEN</span>
        </div>
        <div className="text-xs text-terminal-muted">
          {new Date().toLocaleString("en-US", {
            timeZone: "America/New_York",
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
          })}{" "}
          EST
        </div>
      </div>

      {/* Major Indices */}
      <div className="flex items-center space-x-8">
        {majorIndices.map((index) => (
          <div key={index.symbol} className="text-center">
            <div className="text-xs text-terminal-muted">{index.name}</div>
            <div className="flex items-center space-x-2">
              <span className="font-mono text-sm">450.25</span>
              <span className="text-xs text-market-up">+1.25%</span>
            </div>
          </div>
        ))}
      </div>

      {/* Market Stats */}
      <div className="flex items-center space-x-6 text-xs">
        <div>
          <span className="text-terminal-muted">Volume: </span>
          <span className="font-mono">2.5B</span>
        </div>
        <div>
          <span className="text-terminal-muted">Adv/Dec: </span>
          <span className="text-market-up">1,250</span>
          <span className="text-terminal-muted">/</span>
          <span className="text-market-down">850</span>
        </div>
        <div>
          <span className="text-terminal-muted">VIX: </span>
          <span className="font-mono">18.45</span>
        </div>
      </div>
    </div>
  )
}
