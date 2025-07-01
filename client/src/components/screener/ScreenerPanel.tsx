"use client"

import { useState } from "react"
import { useQuery } from "react-query"
import { api } from "@/lib/api"
import { formatPercent, formatPrice, formatVolume, getChangeColor } from "@/utils/formatters"

export function ScreenerPanel() {
  const [selectedScreen, setSelectedScreen] = useState<string>("")

  useQuery("screens", api.getScreens)

  const { isLoading: isRunning } = useQuery(
    ["screen-results", selectedScreen],
    () => (selectedScreen ? api.runScreen(selectedScreen) : null),
    {
      enabled: !!selectedScreen,
    }
  )

  // Mock screen results
  const mockResults = [
    {
      symbol: "AAPL",
      name: "Apple Inc.",
      price: 150.25,
      change: 2.45,
      changePercent: 1.65,
      volume: 2500000,
      marketCap: 2400000000000,
      pe: 25.4,
      score: 85,
    },
    {
      symbol: "MSFT",
      name: "Microsoft Corporation",
      price: 285.5,
      change: -1.25,
      changePercent: -0.44,
      volume: 1800000,
      marketCap: 2100000000000,
      pe: 28.2,
      score: 78,
    },
    {
      symbol: "GOOGL",
      name: "Alphabet Inc.",
      price: 125.75,
      change: 3.2,
      changePercent: 2.61,
      volume: 3200000,
      marketCap: 1600000000000,
      pe: 22.1,
      score: 92,
    },
  ]

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="border-b border-terminal-border p-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-terminal-accent">Stock Screener</h2>
          <div className="flex items-center space-x-4">
            <select
              value={selectedScreen}
              onChange={(e) => setSelectedScreen(e.target.value)}
              className="rounded border border-terminal-border bg-terminal-bg px-3 py-1 text-sm"
            >
              <option value="">Select Screen</option>
              <option value="high-volume">High Volume Breakout</option>
              <option value="oversold-value">Oversold Value Stocks</option>
              <option value="momentum">Momentum Stocks</option>
              <option value="dividend">Dividend Aristocrats</option>
            </select>
            <button
              onClick={() => selectedScreen && setSelectedScreen(selectedScreen)}
              disabled={!selectedScreen || isRunning}
              className="rounded bg-terminal-accent px-4 py-1 text-sm text-terminal-bg hover:bg-opacity-80 disabled:opacity-50"
            >
              {isRunning ? "Running..." : "Run Screen"}
            </button>
          </div>
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-hidden">
        {isRunning ? (
          <div className="flex h-full items-center justify-center">
            <div className="text-center">
              <div className="loading-spinner mx-auto mb-4"></div>
              <div className="text-terminal-muted">Running screen...</div>
            </div>
          </div>
        ) : selectedScreen ? (
          <div className="h-full overflow-y-auto">
            <table className="data-table w-full">
              <thead>
                <tr>
                  <th>Symbol</th>
                  <th>Name</th>
                  <th>Price</th>
                  <th>Change</th>
                  <th>Volume</th>
                  <th>P/E</th>
                  <th>Score</th>
                </tr>
              </thead>
              <tbody>
                {mockResults.map((stock) => (
                  <tr key={stock.symbol} className="hover:bg-terminal-border">
                    <td className="font-medium text-terminal-accent">{stock.symbol}</td>
                    <td className="text-terminal-text">{stock.name}</td>
                    <td className="font-mono">{formatPrice(stock.price)}</td>
                    <td className={`font-mono ${getChangeColor(stock.change)}`}>
                      {formatPercent(stock.changePercent)}
                    </td>
                    <td className="font-mono">{formatVolume(stock.volume)}</td>
                    <td className="font-mono">{stock.pe}</td>
                    <td className="font-mono text-terminal-accent">{stock.score}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="flex h-full items-center justify-center">
            <div className="text-center">
              <div className="mb-4 text-4xl text-terminal-muted">🔍</div>
              <div className="text-terminal-muted">Select a screen to get started</div>
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="border-t border-terminal-border p-2">
        <div className="flex items-center justify-between text-xs text-terminal-muted">
          <div>{selectedScreen && `Results: ${mockResults.length} stocks found`}</div>
          <div>Last updated: {new Date().toLocaleTimeString()}</div>
        </div>
      </div>
    </div>
  )
}
