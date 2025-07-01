import { create } from "zustand"
import { devtools } from "zustand/middleware"

interface TerminalState {
  // Active selections
  activeSymbol: string
  activePanel: "chart" | "screener" | "news" | "orderbook" | "portfolio"

  // UI state
  sidebarCollapsed: boolean
  rightPanelCollapsed: boolean

  // Market data
  marketStatus: "open" | "closed" | "pre-market" | "after-hours"
  connectionStatus: "connected" | "disconnected" | "connecting"

  // Watchlists
  watchlists: Array<{
    id: string
    name: string
    symbols: string[]
  }>

  // Actions
  setActiveSymbol: (symbol: string) => void
  setActivePanel: (panel: TerminalState["activePanel"]) => void
  setSidebarCollapsed: (collapsed: boolean) => void
  setRightPanelCollapsed: (collapsed: boolean) => void
  setMarketStatus: (status: TerminalState["marketStatus"]) => void
  setConnectionStatus: (status: TerminalState["connectionStatus"]) => void
  addToWatchlist: (listId: string, symbol: string) => void
  removeFromWatchlist: (listId: string, symbol: string) => void
}

export const useTerminalStore = create<TerminalState>()(
  devtools(
    (set) => ({
      // Initial state
      activeSymbol: "AAPL",
      activePanel: "chart",
      sidebarCollapsed: false,
      rightPanelCollapsed: false,
      marketStatus: "open",
      connectionStatus: "connected",
      watchlists: [
        {
          id: "default",
          name: "My Watchlist",
          symbols: ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA"],
        },
        {
          id: "tech",
          name: "Tech Giants",
          symbols: ["AAPL", "MSFT", "GOOGL", "META", "NFLX"],
        },
      ],

      // Actions
      setActiveSymbol: (symbol) => set({ activeSymbol: symbol }, false, "setActiveSymbol"),

      setActivePanel: (panel) => set({ activePanel: panel }, false, "setActivePanel"),

      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }, false, "setSidebarCollapsed"),

      setRightPanelCollapsed: (collapsed) => set({ rightPanelCollapsed: collapsed }, false, "setRightPanelCollapsed"),

      setMarketStatus: (status) => set({ marketStatus: status }, false, "setMarketStatus"),

      setConnectionStatus: (status) => set({ connectionStatus: status }, false, "setConnectionStatus"),

      addToWatchlist: (listId, symbol) =>
        set(
          (state) => ({
            watchlists: state.watchlists.map((list) =>
              list.id === listId ? { ...list, symbols: [...list.symbols, symbol] } : list
            ),
          }),
          false,
          "addToWatchlist"
        ),

      removeFromWatchlist: (listId, symbol) =>
        set(
          (state) => ({
            watchlists: state.watchlists.map((list) =>
              list.id === listId ? { ...list, symbols: list.symbols.filter((s) => s !== symbol) } : list
            ),
          }),
          false,
          "removeFromWatchlist"
        ),
    }),
    {
      name: "terminal-store",
    }
  )
)
