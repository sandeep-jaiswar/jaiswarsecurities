"use client"

import { BellIcon, Cog6ToothIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline"
import { useState } from "react"
import { useTerminalStore } from "@/store/terminalStore"

export function TerminalHeader() {
  const [searchQuery, setSearchQuery] = useState("")
  const { setActiveSymbol, setActivePanel } = useTerminalStore()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      setActiveSymbol(searchQuery.toUpperCase())
      setActivePanel("chart")
    }
  }

  return (
    <header className="border-b border-terminal-border bg-terminal-panel px-4 py-2">
      <div className="flex items-center justify-between">
        {/* Logo and Title */}
        <div className="flex items-center space-x-4">
          <div className="text-xl font-bold text-terminal-accent">STOCK TERMINAL</div>
          <div className="text-sm text-terminal-muted">Professional Trading Platform</div>
        </div>

        {/* Search Bar */}
        <form onSubmit={handleSearch} className="mx-8 max-w-md flex-1">
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 transform text-terminal-muted" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Enter symbol (e.g., AAPL, MSFT)..."
              className="w-full rounded border border-terminal-border bg-terminal-bg px-10 py-2 text-sm focus:border-terminal-accent focus:outline-none"
            />
          </div>
        </form>

        {/* Action Buttons */}
        <div className="flex items-center space-x-4">
          <button className="rounded p-2 hover:bg-terminal-border">
            <BellIcon className="h-5 w-5" />
          </button>
          <button className="rounded p-2 hover:bg-terminal-border">
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
