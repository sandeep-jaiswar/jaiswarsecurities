'use client'

import { TerminalLayout } from '@/components/layout/TerminalLayout'
import { MarketOverview } from '@/components/dashboard/MarketOverview'
import { WatchlistPanel } from '@/components/watchlist/WatchlistPanel'
import { ChartPanel } from '@/components/charts/ChartPanel'
import { NewsPanel } from '@/components/news/NewsPanel'
import { OrderBookPanel } from '@/components/trading/OrderBookPanel'
import { ScreenerPanel } from '@/components/screener/ScreenerPanel'
import { useTerminalStore } from '@/store/terminalStore'

export default function HomePage() {
  const { activeSymbol, activePanel } = useTerminalStore()

  const renderMainPanel = () => {
    switch (activePanel) {
      case 'chart':
        return <ChartPanel symbol={activeSymbol} />
      case 'screener':
        return <ScreenerPanel />
      case 'news':
        return <NewsPanel symbol={activeSymbol} />
      case 'orderbook':
        return <OrderBookPanel symbol={activeSymbol} />
      default:
        return <ChartPanel symbol={activeSymbol} />
    }
  }

  return (
    <TerminalLayout>
      <div className="terminal-grid">
        {/* Header */}
        <div className="terminal-header">
          <MarketOverview />
        </div>

        {/* Left Sidebar */}
        <div className="terminal-sidebar">
          <WatchlistPanel />
        </div>

        {/* Main Content */}
        <div className="terminal-main">
          {renderMainPanel()}
        </div>

        {/* Right Panel */}
        <div className="terminal-rightpanel">
          <NewsPanel symbol={activeSymbol} />
        </div>

        {/* Footer */}
        <div className="terminal-footer">
          <div className="flex items-center justify-between p-2 text-xs">
            <div className="flex items-center space-x-4">
              <span className="status-online">● LIVE</span>
              <span>Market: OPEN</span>
              <span>Delay: Real-time</span>
            </div>
            <div className="flex items-center space-x-4">
              <span>API: Connected</span>
              <span>Data: {new Date().toLocaleTimeString()}</span>
            </div>
          </div>
        </div>
      </div>
    </TerminalLayout>
  )
}