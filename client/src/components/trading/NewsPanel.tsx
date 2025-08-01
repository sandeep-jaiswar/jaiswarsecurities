"use client"

import { useQuery } from "react-query"
import { apiClient } from "@/lib/api"

interface NewsPanelProps {
  symbol: string
}

export function NewsPanel({ symbol }: NewsPanelProps) {
  useQuery(["trading-news", symbol], () => apiClient.get(`/api/trading/news/${symbol}`), {
    refetchInterval: 30000,
  })

  const mockNews = [
    {
      id: 1,
      title:
        "Ananya Gairola — Mark Zuckerberg Finally Ties Apple's Vision Pro and Says Meta 3 Is The Better Product, Period",
      time: "Yesterday, 01:16 NY",
      source: "Benzinga",
    },
    {
      id: 2,
      title:
        "Ananya Gairola — Former Apple Engineer Sent To Prison For Stealing Trade Secrets, Apple Recommends Teaching Math In Prison",
      time: "2 days ago",
      source: "Benzinga",
    },
    {
      id: 3,
      title: "Ananya Gairola — Apple's Seasonality for AAPL (43 years)",
      time: "3 days ago",
      source: "Benzinga",
    },
  ]

  return (
    <div className="h-64 border border-terminal-border bg-terminal-panel">
      <div className="border-b border-terminal-border p-2">
        <h3 className="text-xs font-bold text-terminal-accent">Latest News</h3>
      </div>

      <div className="h-full space-y-2 overflow-y-auto p-2">
        {mockNews.map((news) => (
          <div key={news.id} className="border-b border-terminal-border pb-2">
            <div className="mb-1 text-xs leading-tight text-terminal-text">{news.title}</div>
            <div className="flex justify-between text-xs text-terminal-muted">
              <span>{news.time}</span>
              <span>{news.source}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
