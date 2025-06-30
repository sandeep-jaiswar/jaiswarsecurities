'use client'

import { useState } from 'react'
import { MagnifyingGlassIcon, Cog6ToothIcon, BellIcon } from '@heroicons/react/24/outline'
import { useTerminalStore } from '@/store/terminalStore'

export function TerminalHeader() {
  const [searchQuery, setSearchQuery] = useState('')
  const { setActiveSymbol, setActivePanel } = useTerminalStore()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      setActiveSymbol(searchQuery.toUpperCase())
      setActivePanel('chart')
    }
  }

  return (
    <header className="bg-terminal-panel border-b border-terminal-border px-4 py-2">
      <div className="flex items-center justify-between">
        {/* Logo and Title */}
        <div className="flex items-center space-x-4">
          <div className="text-terminal-accent font-bold text-xl">
            STOCK TERMINAL
          </div>
          <div className="text-terminal-muted text-sm">
            Professional Trading Platform
          </div>
        </div>

        {/* Search Bar */}
        <form onSubmit={handleSearch} className="flex-1 max-w-md mx-8">
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-terminal-muted" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Enter symbol (e.g., AAPL, MSFT)..."
              className="w-full bg-terminal-bg border border-terminal-border rounded px-10 py-2 text-sm focus:outline-none focus:border-terminal-accent"
            />
          </div>
        </form>

        {/* Action Buttons */}
        <div className="flex items-center space-x-4">
          <button className="p-2 hover:bg-terminal-border rounded">
            <BellIcon className="h-5 w-5" />
          </button>
          <button className="p-2 hover:bg-terminal-border rounded">
            <Cog6ToothIcon className="h-5 w-5" />
          </button>
          <div className="text-sm">
            <div className="text-terminal-accent">LIVE</div>
            <div className="text-xs text-terminal-muted">Real-time</div>
          </div>
        </div>
      </div>
    </header>
  )
}