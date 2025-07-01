"use client"

import { useState } from "react"

export function StrategyTester() {
  const [selectedStrategy, setSelectedStrategy] = useState("Keltner Channel")

  const strategies = [
    "Keltner Channel Buy X Up, Sell Y Down",
    "Moving Average Crossover",
    "RSI Divergence",
    "Bollinger Band Squeeze",
  ]

  return (
    <div className="h-full p-4">
      <div className="grid h-full grid-cols-2 gap-4">
        {/* Strategy Selection */}
        <div>
          <h4 className="mb-2 text-xs font-bold text-terminal-accent">Strategy Selection</h4>
          <select
            value={selectedStrategy}
            onChange={(e) => setSelectedStrategy(e.target.value)}
            className="w-full rounded border border-terminal-border bg-terminal-bg px-2 py-1 text-xs"
          >
            {strategies.map((strategy) => (
              <option key={strategy} value={strategy}>
                {strategy}
              </option>
            ))}
          </select>

          <div className="mt-4 space-y-2 text-xs">
            <div className="flex justify-between">
              <span className="text-terminal-muted">Period:</span>
              <span className="text-terminal-text">3051 candles</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Data:</span>
              <span className="text-terminal-text">Daily</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Trade by:</span>
              <span className="text-terminal-text">Open</span>
            </div>
          </div>
        </div>

        {/* Performance Metrics */}
        <div>
          <h4 className="mb-2 text-xs font-bold text-terminal-accent">Performance</h4>
          <div className="space-y-1 text-xs">
            <div className="flex justify-between">
              <span className="text-terminal-muted">Net Profit:</span>
              <span className="text-market-up">+44.49%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Gross Profit:</span>
              <span className="text-market-up">+104.2%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Max Drawdown:</span>
              <span className="text-market-down">-41.5%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Profit Factor:</span>
              <span className="text-terminal-text">1.39</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Total Trades:</span>
              <span className="text-terminal-text">43</span>
            </div>
            <div className="flex justify-between">
              <span className="text-terminal-muted">Win Rate:</span>
              <span className="text-market-up">75%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
