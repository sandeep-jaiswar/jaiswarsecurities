'use client'

import { useState } from 'react'
import { useQuery } from 'react-query'
import { api } from '@/lib/api'
import { useTerminalStore } from '@/store/terminalStore'
import { formatPrice, formatPercent, getChangeColor } from '@/utils/formatters'
import { PlusIcon, XMarkIcon } from '@heroicons/react/24/outline'

export function WatchlistPanel() {
  const { watchlists, setActiveSymbol } = useTerminalStore()
  const [activeWatchlist, setActiveWatchlist] = useState(0)

  const { data: symbolsData, isLoading } = useQuery(
    ['watchlist-data', watchlists[activeWatchlist]?.symbols],
    () => {
      const symbols = watchlists[activeWatchlist]?.symbols || []
      return Promise.all(
        symbols.map(symbol => api.getSymbol(symbol).catch(() => null))
      )
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
    <div className="h-full flex flex-col">
      {/* Watchlist Tabs */}
      <div className="border-b border-terminal-border">
        <div className="flex">
          {watchlists.map((list, index) => (
            <button
              key={list.id}
              onClick={() => setActiveWatchlist(index)}
              className={`px-3 py-2 text-xs font-medium border-b-2 ${
                index === activeWatchlist
                  ? 'border-terminal-accent text-terminal-accent'
                  : 'border-transparent text-terminal-muted hover:text-terminal-text'
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
          <div className="flex items-center justify-center h-32">
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
                  className="p-2 hover:bg-terminal-border cursor-pointer rounded text-xs"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="font-medium text-terminal-text">{symbol}</div>
                      <div className="text-terminal-muted text-xs truncate">
                        // TODO:// Fix type error
                        {/* {data?.name ?? 'Company Name'} */}
                        {'Company Name'}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono">{formatPrice(price)}</div>
                      <div className={`text-xs ${getChangeColor(change)}`}>
                        {formatPercent(changePercent)}
                      </div>
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
        <button className="w-full flex items-center justify-center space-x-2 p-2 text-xs text-terminal-muted hover:text-terminal-accent hover:bg-terminal-border rounded">
          <PlusIcon className="h-4 w-4" />
          <span>Add Symbol</span>
        </button>
      </div>
    </div>
  )
}