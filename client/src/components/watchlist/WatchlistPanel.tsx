"use client"

import { PlusIcon } from "@heroicons/react/24/outline"
import { useState } from "react"
import { useQuery } from "react-query"
import { api } from "@/lib/api"
import { useTerminalStore } from "@/store/terminalStore"
import { formatPercent, formatPrice, getChangeColor } from "@/utils/formatters"

export function WatchlistPanel() {
  const { watchlists, setActiveSymbol } = useTerminalStore()
  const [activeWatchlist, setActiveWatchlist] = useState(0)

  const { data: symbolsData, isLoading } = useQuery(
    ["watchlist-data", watchlists[activeWatchlist]?.symbols],
    () => {
      const symbols = watchlists[activeWatchlist]?.symbols || []
      return Promise.all(symbols.map((symbol) => api.getSymbol(symbol).catch(() => null)))
    },
    {
      enabled: watchlists[activeWatchlist]?.symbols?.length > 0,
      refetchInterval: 5000,
    }
  )

  const handleSymbolClick = (symbol: string) => {
    setActiveSymbol(symbol)
  }

  return (
    <div className="flex h-full flex-col">
      {/* Watchlist Tabs */}
      <div className="border-b border-terminal-border">
        <div className="flex">
          {watchlists.map((list, index) => (
            <button
              key={list.id}
              onClick={() => setActiveWatchlist(index)}
              className={`border-b-2 px-3 py-2 text-xs font-medium ${
                index === activeWatchlist
                  ? "border-terminal-accent text-terminal-accent"
                  : "border-transparent text-terminal-muted hover:text-terminal-text"
              }`}
            >
              {list.name}
            </button>
          ))}
        </div>
      </div>

      {/* Watchlist Content */}
      <div className="flex-1 overflow-y-auto">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="loading-spinner"></div>
          </div>
        ) : (
          <div className="space-y-1 p-2">
            {symbolsData?.map((data, index) => {
              if (!data) return null

              const symbol = watchlists[activeWatchlist].symbols[index]
              const price = 150.25 + Math.random() * 50 // Mock data
              const change = (Math.random() - 0.5) * 10
              const changePercent = (change / price) * 100

              return (
                <div
                  key={symbol}
                  onClick={() => handleSymbolClick(symbol)}
                  className="cursor-pointer rounded p-2 text-xs hover:bg-terminal-border"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="font-medium text-terminal-text">{symbol}</div>
                      <div className="truncate text-xs text-terminal-muted">
                        // TODO:// Fix type error
                        {/* {data?.name ?? 'Company Name'} */}
                        {"Company Name"}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono">{formatPrice(price)}</div>
                      <div className={`text-xs ${getChangeColor(change)}`}>{formatPercent(changePercent)}</div>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* Add Symbol */}
      <div className="border-t border-terminal-border p-2">
        <button className="flex w-full items-center justify-center space-x-2 rounded p-2 text-xs text-terminal-muted hover:bg-terminal-border hover:text-terminal-accent">
          <PlusIcon className="h-4 w-4" />
          <span>Add Symbol</span>
        </button>
      </div>
    </div>
  )
}
