"use client"

import { useEffect, useState } from "react"
import { useQuery } from "react-query"
import { AnalystPanel } from "@/components/trading/AnalystPanel"
import { BacktestPanel } from "@/components/trading/BacktestPanel"
import { MarketScanner } from "@/components/trading/MarketScanner"
import { NewsPanel } from "@/components/trading/NewsPanel"
import { PriceActionHeatmap } from "@/components/trading/PriceActionHeatmap"
import { StrategyTester } from "@/components/trading/StrategyTester"
import { TradingChart } from "@/components/trading/TradingChart"
import { TradingToolbar } from "@/components/trading/TradingToolbar"
import { apiClient } from "@/lib/api"
import { useTerminalStore } from "@/store/terminalStore"

export default function TradingPage() {
  const { activeSymbol, setActiveSymbol } = useTerminalStore()
  const [selectedTimeframe, setSelectedTimeframe] = useState("Daily")
  const [activeTab, setActiveTab] = useState("Strategy Tester")

  return (
    <div className="min-h-screen bg-black font-mono text-terminal-text">
      {/* Top Toolbar */}
      <TradingToolbar
        activeSymbol={activeSymbol}
        onSymbolChange={setActiveSymbol}
        timeframe={selectedTimeframe}
        onTimeframeChange={setSelectedTimeframe}
      />

      {/* Main Trading Interface */}
      <div className="grid h-[calc(100vh-60px)] grid-cols-12 gap-1 p-1">
        {/* Left Sidebar - Symbol Info & Tools */}
        <div className="col-span-2 space-y-1">
          <div className="h-64 border border-terminal-border bg-terminal-panel">
            <div className="border-b border-terminal-border p-2">
              <h3 className="text-xs font-bold text-terminal-accent">AAPL</h3>
              <div className="text-xs text-terminal-muted">Apple Inc., Daily, Nasdaq</div>
            </div>
            <div className="space-y-1 p-2 text-xs">
              <div className="flex justify-between">
                <span className="text-terminal-muted">Last:</span>
                <span className="text-market-up">185.52</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Change:</span>
                <span className="text-market-up">+1.84%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Volume:</span>
                <span>45.2M</span>
              </div>
              <div className="flex justify-between">
                <span className="text-terminal-muted">Avg Vol:</span>
                <span>52.1M</span>
              </div>
            </div>
          </div>

          <MarketScanner />
        </div>

        {/* Main Chart Area */}
        <div className="col-span-6 space-y-1">
          <TradingChart symbol={activeSymbol} timeframe={selectedTimeframe} />

          <div className="h-64">
            <div className="flex border-b border-terminal-border bg-terminal-panel">
              {["Strategy Tester", "Market Scanner", "What's Happening Now", "Custom Indicator Editor"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`border-r border-terminal-border px-3 py-1 text-xs ${
                    activeTab === tab ? "bg-terminal-accent text-black" : "text-terminal-muted hover:text-terminal-text"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            <div className="h-full border border-t-0 border-terminal-border bg-terminal-panel">
              {activeTab === "Strategy Tester" && <StrategyTester />}
              {activeTab === "Market Scanner" && <MarketScanner />}
              {activeTab === "What's Happening Now" && <NewsPanel symbol={activeSymbol} />}
            </div>
          </div>
        </div>

        {/* Right Panels */}
        <div className="col-span-4 space-y-1">
          <NewsPanel symbol={activeSymbol} />
          <AnalystPanel symbol={activeSymbol} />
          <BacktestPanel />
        </div>
      </div>

      {/* Bottom Panel - Backtesting Results */}
      <div className="h-80 border-t border-terminal-border bg-terminal-panel">
        <BacktestPanel />
      </div>
    </div>
  )
}
