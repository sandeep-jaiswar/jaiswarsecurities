import axios from "axios"

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:3000"

export const apiClient = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  timeout: 10000,
  headers: {
    "Content-Type": "application/json",
  },
})

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // Add auth token if available
    const token = localStorage.getItem("auth_token")
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
apiClient.interceptors.response.use(
  (response) => {
    return response.data
  },
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access
      localStorage.removeItem("auth_token")
      window.location.href = "/login"
    }
    return Promise.reject(error)
  }
)

// API endpoints
export const api = {
  // Market data
  getSymbols: (params?: Record<string, unknown>) => apiClient.get("/symbols", { params }),
  getSymbol: (symbol: string) => apiClient.get(`/symbols/${symbol}`),
  getOHLCV: (symbol: string, params?: Record<string, unknown>) => apiClient.get(`/symbols/${symbol}/ohlcv`, { params }),
  getIndicators: (symbol: string, params?: Record<string, unknown>) =>
    apiClient.get(`/symbols/${symbol}/indicators`, { params }),

  // Analytics
  getMarketOverview: () => apiClient.get("/analytics/market-overview"),

  // Screening
  getScreens: () => apiClient.get("/screens"),
  runScreen: (screenId: string, params?: Record<string, unknown>) => apiClient.post(`/screens/${screenId}/run`, params),

  // Backtesting
  getStrategies: () => apiClient.get("/strategies"),
  getBacktests: (params?: Record<string, unknown>) => apiClient.get("/backtests", { params }),
  getBacktest: (id: string) => apiClient.get(`/backtests/${id}`),
  getBacktestTrades: (id: string) => apiClient.get(`/backtests/${id}/trades`),
  getEquityCurve: (id: string) => apiClient.get(`/backtests/${id}/equity-curve`),

  // Watchlists
  getWatchlists: () => apiClient.get("/watchlists"),
  getWatchlistSymbols: (id: string) => apiClient.get(`/watchlists/${id}/symbols`),

  // News
  getNews: (params?: Record<string, unknown>) => apiClient.get("/news", { params }),

  // Alerts
  getAlerts: () => apiClient.get("/alerts"),
  createAlert: (data: Record<string, unknown>) => apiClient.post("/alerts", data),
}
