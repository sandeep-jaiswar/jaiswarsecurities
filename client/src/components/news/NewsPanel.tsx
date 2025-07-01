"use client"

import { useQuery } from "react-query"
import { api } from "@/lib/api"
import { formatTime } from "@/utils/formatters"

interface NewsPanelProps {
  symbol?: string
}

export function NewsPanel({ symbol }: NewsPanelProps) {
  const { data: newsData, isLoading } = useQuery(["news", symbol], () => api.getNews({ symbol, limit: 20 }), {
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  // Mock news data for demonstration
  const mockNews = [
    {
      id: 1,
      title: `${symbol || "Market"} Reaches New Highs Amid Strong Earnings`,
      summary: "Strong quarterly results drive investor confidence...",
      source: "Reuters",
      publishedAt: new Date().toISOString(),
      sentiment: "positive",
    },
    {
      id: 2,
      title: "Federal Reserve Signals Potential Rate Changes",
      summary: "Central bank officials hint at policy adjustments...",
      source: "Bloomberg",
      publishedAt: new Date(Date.now() - 3600000).toISOString(),
      sentiment: "neutral",
    },
    {
      id: 3,
      title: "Tech Sector Shows Resilience Despite Headwinds",
      summary: "Technology companies continue to outperform...",
      source: "CNBC",
      publishedAt: new Date(Date.now() - 7200000).toISOString(),
      sentiment: "positive",
    },
  ]

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case "positive":
        return "text-market-up"
      case "negative":
        return "text-market-down"
      default:
        return "text-terminal-muted"
    }
  }

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="border-b border-terminal-border p-3">
        <h3 className="font-medium text-terminal-accent">{symbol ? `${symbol} News` : "Market News"}</h3>
      </div>

      {/* News List */}
      <div className="flex-1 overflow-y-auto">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="loading-spinner"></div>
          </div>
        ) : (
          <div className="space-y-1">
            {mockNews.map((article) => (
              <div
                key={article.id}
                className="cursor-pointer border-b border-terminal-border p-3 hover:bg-terminal-border"
              >
                <div className="mb-2 flex items-start justify-between">
                  <div className="text-xs text-terminal-muted">{article.source}</div>
                  <div className="flex items-center space-x-2">
                    <div
                      className={`h-2 w-2 rounded-full ${
                        article.sentiment === "positive"
                          ? "bg-market-up"
                          : article.sentiment === "negative"
                          ? "bg-market-down"
                          : "bg-terminal-muted"
                      }`}
                    ></div>
                    <div className="text-xs text-terminal-muted">{formatTime(article.publishedAt)}</div>
                  </div>
                </div>
                <h4 className="mb-1 line-clamp-2 text-sm font-medium text-terminal-text">{article.title}</h4>
                <p className="line-clamp-2 text-xs text-terminal-muted">{article.summary}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="border-t border-terminal-border p-2">
        <div className="text-center text-xs text-terminal-muted">News updates every 30 seconds</div>
      </div>
    </div>
  )
}
