'use client'

import { useState } from 'react'
import { MagnifyingGlassIcon, ChartBarIcon, CogIcon } from '@heroicons/react/24/outline'

interface TradingToolbarProps {
  activeSymbol: string
  onSymbolChange: (symbol: string) => void
  timeframe: string
  onTimeframeChange: (timeframe: string) => void
}

export function TradingToolbar({ 
  activeSymbol, 
  onSymbolChange, 
  timeframe, 
  onTimeframeChange 
}: TradingToolbarProps) {
  const [searchQuery, setSearchQuery] = useState('')

  const timeframes = ['1m', '5m', '15m', '1h', '4h', 'Daily', 'Weekly', 'Monthly']
  const tools = ['Auto Fib', 'Trends', 'Indicators', 'Candle Patterns', 'Chart Patterns', 'Heatmaps', 'Other data', 'Alerts&book', 'Visual Scripts']

  return (
    <div className="bg-terminal-panel border-b border-terminal-border p-2">
      <div className="flex items-center justify-between">
        {/* Left - Symbol and Tools */}
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Symbol..."
              className="bg-terminal-bg border border-terminal-border rounded px-2 py-1 text-xs w-20"
            />
            <MagnifyingGlassIcon className="h-4 w-4 text-terminal-muted" />
          </div>

          <div className="flex items-center space-x-1">
            {tools.map((tool) => (
              <button
                key={tool}
                className="px-2 py-1 text-xs bg-terminal-border hover:bg-terminal-accent hover:text-black rounded"
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
                className={`px-2 py-1 text-xs rounded ${
                  timeframe === tf
                    ? 'bg-terminal-accent text-black'
                    : 'bg-terminal-border hover:bg-terminal-accent hover:text-black'
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