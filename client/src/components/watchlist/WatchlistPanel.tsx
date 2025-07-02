"use client"

import { PlusIcon } from "@heroicons/react/24/outline"
import { useState } from "react"
import { useQuery } from "react-query"
import { api } from "@/lib/api"
import { useTerminalStore } from "@/store/terminalStore"
import { formatPercent, formatPrice, getChangeColor } from "@/utils/formatters"

// --- Type Definitions ---
interface SymbolData {
  symbol: string
  name: string
  price: number
  change: number
  changePercent: number
}

interface Watchlist {
  id: string
  name: string
  symbols: string[]
}

export function WatchlistPanel() {
  const { watchlists, setActiveSymbol } = useTerminalStore() as {
    watchlists: Watchlist[]
    setActiveSymbol: (symbol: string) => void
  }

  const [activeWatchlist, setActiveWatchlist] = useState(0)

  const symbols = watchlists[activeWatchlist]?.symbols || []

  const { data: symbolsData, isLoading } = useQuery<(SymbolData | null)[]>(
    ["watchlist-data", symbols],
    async () => {
      return await Promise.all(
        symbols.map(async (symbol) => {
          try {
            const res = await api.getSymbol(symbol)
            return {
              symbol,
              name: "Company Name",
              price: 150.25 + Math.random() * 50, // mock price
              change: (Math.random() - 0.5) * 10,
              changePercent: 0, // calculated below
            } as SymbolData
          } catch {
            return null
          }
        })
      )
    },
    {
      enabled: symbols.length > 0,
      refetchInterval: 5000,
      select: (data) =>
        data.map((d) => {
          if (!d) return null
          return {
            ...d,
            changePercent: (d.change / d.price) * 100,
          }
        }),
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

              return (
                <div
                  key={data.symbol}
                  onClick={() => handleSymbolClick(data.symbol)}
                  className="cursor-pointer rounded p-2 text-xs hover:bg-terminal-border"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="font-medium text-terminal-text">{data.symbol}</div>
                      <div className="truncate text-xs text-terminal-muted">
                        {data.name ?? "Company Name"}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono">{formatPrice(data.price)}</div>
                      <div className={`text-xs ${getChangeColor(data.change)}`}>
                        {formatPercent(data.changePercent)}
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
        <button className="flex w-full items-center justify-center space-x-2 rounded p-2 text-xs text-terminal-muted hover:bg-terminal-border hover:text-terminal-accent">
          <PlusIcon className="h-4 w-4" />
          <span>Add Symbol</span>
        </button>
      </div>
    </div>
  )
}
