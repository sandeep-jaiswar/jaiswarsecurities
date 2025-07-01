"use client"

import { useQuery } from "react-query"
import { apiClient } from "@/lib/api"

export function BacktestPanel() {
  const { data: backtestData, isLoading } = useQuery(
    "backtest-performance",
    () => apiClient.get("/api/trading/backtest-performance"),
    {
      refetchInterval: 10000,
    }
  )

  const mockData = {
    strategy: "Keltner Channel Buy X Up, Sell Y Down",
    performance: {
      totalReturn: "+44.49%",
      annualReturn: "+104.2%",
      maxDrawdown: "-41.5%",
      sharpeRatio: "1.39%",
      winRate: "75%",
      profitFactor: "2.02%",
    },
    positions: [
      { symbol: "AAPL.O", change: "+2K 4h", status: "buy" },
      { symbol: "Wagner Susan", change: "Oct Ex.(n)", status: "buy" },
      { symbol: "Roth Russell D", change: "Oct Ex.(n)", status: "buy" },
    ],
  }

  return (
    <div className="h-full border border-terminal-border bg-terminal-panel">
      <div className="border-b border-terminal-border p-2">
        <h3 className="text-xs font-bold text-terminal-accent">Backtesting & Strategy Performance</h3>
      </div>

      <div className="grid h-full grid-cols-3 gap-4 p-4">
        {/* Strategy Performance */}
        <div className="space-y-4">
          <div>
            <h4 className="mb-2 text-xs font-bold text-terminal-accent">{mockData.strategy}</h4>
            <div className="space-y-1 text-xs">
              <div className="flex justify-between">
                <span className="text-terminal-muted">Total Return:</span>
                <span className="text-market-up">{mockData.performance.totalReturn}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Annual Return:</span>
                <span className="text-market-up">{mockData.performance.annualReturn}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Max Drawdown:</span>
                <span className="text-market-down">{mockData.performance.maxDrawdown}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Sharpe Ratio:</span>
                <span className="text-terminal-text">{mockData.performance.sharpeRatio}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Win Rate:</span>
                <span className="text-market-up">{mockData.performance.winRate}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Profit Factor:</span>
                <span className="text-market-up">{mockData.performance.profitFactor}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Equity Curve Chart */}
        <div className="border border-terminal-border">
          <div className="border-b border-terminal-border p-2">
            <h4 className="text-xs font-bold text-terminal-accent">Equity Curve</h4>
          </div>
          <div className="flex h-32 items-center justify-center">
            <div className="text-xs text-terminal-muted">Performance Chart</div>
          </div>
        </div>

        {/* Insider Ownership */}
        <div>
          <div className="border-b border-terminal-border p-2">
            <h4 className="text-xs font-bold text-terminal-accent">Insider ownership diagram</h4>
          </div>
          <div className="space-y-1 p-2 text-xs">
            {mockData.positions.map((position, index) => (
              <div key={index} className="flex justify-between">
                <span className="text-terminal-text">{position.symbol}</span>
                <span className="text-terminal-muted">{position.change}</span>
                <span className="text-market-up">{position.status}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
