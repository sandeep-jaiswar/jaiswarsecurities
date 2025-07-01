"use client"

import { useQuery } from "react-query"
import { apiClient } from "@/lib/api"

export function MarketScanner() {
  useQuery("market-scanner", () => apiClient.get("/api/trading/market-scanner"), {
    refetchInterval: 5000,
  })

  const mockData = [
    { symbol: "AAPL", change: "+2.45%", volume: "45.2M", signal: "BUY" },
    { symbol: "MSFT", change: "+1.23%", volume: "32.1M", signal: "BUY" },
    { symbol: "GOOGL", change: "-0.87%", volume: "28.5M", signal: "HOLD" },
    { symbol: "TSLA", change: "+3.21%", volume: "67.8M", signal: "BUY" },
  ]

  return (
    <div className="h-48 border border-terminal-border bg-terminal-panel">
      <div className="border-b border-terminal-border p-2">
        <h3 className="text-xs font-bold text-terminal-accent">Market Scanner</h3>
      </div>

      <div className="p-2">
        <div className="mb-2 grid grid-cols-4 gap-1 text-xs text-terminal-muted">
          <div>Symbol</div>
          <div>Change</div>
          <div>Volume</div>
          <div>Signal</div>
        </div>

        <div className="space-y-1">
          {mockData.map((item, index) => (
            <div key={index} className="grid grid-cols-4 gap-1 text-xs">
              <div className="text-terminal-accent">{item.symbol}</div>
              <div className={item.change.startsWith("+") ? "text-market-up" : "text-market-down"}>{item.change}</div>
              <div className="text-terminal-text">{item.volume}</div>
              <div
                className={`text-${
                  item.signal === "BUY" ? "market-up" : item.signal === "SELL" ? "market-down" : "terminal-muted"
                }`}
              >
                {item.signal}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
