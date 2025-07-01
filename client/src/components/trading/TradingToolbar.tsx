"use client"

import { ChartBarIcon, CogIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline"
import { useState } from "react"

interface TradingToolbarProps {
  activeSymbol: string
  onSymbolChange: (symbol: string) => void
  timeframe: string
  onTimeframeChange: (timeframe: string) => void
}

export function TradingToolbar({ timeframe, onTimeframeChange }: TradingToolbarProps) {
  const [searchQuery, setSearchQuery] = useState("")

  const timeframes = ["1m", "5m", "15m", "1h", "4h", "Daily", "Weekly", "Monthly"]
  const tools = [
    "Auto Fib",
    "Trends",
    "Indicators",
    "Candle Patterns",
    "Chart Patterns",
    "Heatmaps",
    "Other data",
    "Alerts&book",
    "Visual Scripts",
  ]

  return (
    <div className="border-b border-terminal-border bg-terminal-panel p-2">
      <div className="flex items-center justify-between">
        {/* Left - Symbol and Tools */}
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Symbol..."
              className="w-20 rounded border border-terminal-border bg-terminal-bg px-2 py-1 text-xs"
            />
            <MagnifyingGlassIcon className="h-4 w-4 text-terminal-muted" />
          </div>

          <div className="flex items-center space-x-1">
            {tools.map((tool) => (
              <button
                key={tool}
                className="rounded bg-terminal-border px-2 py-1 text-xs hover:bg-terminal-accent hover:text-black"
              >
                {tool}
              </button>
            ))}
          </div>
        </div>

        {/* Right - Timeframes and Controls */}
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-1">
            {timeframes.map((tf) => (
              <button
                key={tf}
                onClick={() => onTimeframeChange(tf)}
                className={`rounded px-2 py-1 text-xs ${
                  timeframe === tf
                    ? "bg-terminal-accent text-black"
                    : "bg-terminal-border hover:bg-terminal-accent hover:text-black"
                }`}
              >
                {tf}
              </button>
            ))}
          </div>

          <div className="flex items-center space-x-2">
            <ChartBarIcon className="h-4 w-4 text-terminal-muted" />
            <CogIcon className="h-4 w-4 text-terminal-muted" />
          </div>
        </div>
      </div>
    </div>
  )
}
