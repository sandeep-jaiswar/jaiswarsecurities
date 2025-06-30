'use client'

import { useQuery } from 'react-query'
import { apiClient } from '@/lib/api'

interface AnalystPanelProps {
  symbol: string
}

export function AnalystPanel({ symbol }: AnalystPanelProps) {
  const { data: analystData, isLoading } = useQuery(
    ['analyst-estimates', symbol],
    () => apiClient.get(`/api/trading/analyst-estimates/${symbol}`),
    {
      refetchInterval: 60000,
    }
  )

  const mockData = {
    reports: [
      { period: '2w4 4wk', rank: '13wk', growth: '6mo', rating: '1yr' },
      { period: 'Ranked "Buy"', rank: '5', growth: '1', rating: '4' },
      { period: 'Ranked "Hold"', rank: '6', growth: '1', rating: '17' },
      { period: 'Ranked "Sell"', rank: '1', growth: '1', rating: '3' },
    ],
    estimates: [
      { metric: 'Windbush', value: 'buy' },
      { metric: 'JP Morgan', value: 'buy' },
      { metric: 'Deutsche', value: 'buy' },
    ]
  }

  return (
    <div className="bg-terminal-panel border border-terminal-border h-48">
      <div className="border-b border-terminal-border p-2">
        <h3 className="text-xs font-bold text-terminal-accent">Analyst Estimates, {symbol}</h3>
      </div>
      
      <div className="p-2">
        <div className="grid grid-cols-4 gap-1 text-xs mb-4">
          <div className="text-terminal-muted">Reports within...</div>
          <div className="text-terminal-muted">2w4 4wk</div>
          <div className="text-terminal-muted">13wk 6mo</div>
          <div className="text-terminal-muted">1yr</div>
        </div>

        <div className="space-y-1 text-xs">
          {mockData.reports.slice(1).map((report, index) => (
            <div key={index} className="grid grid-cols-4 gap-1">
              <div className="text-terminal-text">{report.period}</div>
              <div className="text-terminal-text">{report.rank}</div>
              <div className="text-terminal-text">{report.growth}</div>
              <div className="text-terminal-text">{report.rating}</div>
            </div>
          ))}
        </div>

        <div className="mt-4 space-y-1 text-xs">
          <div className="text-terminal-muted">Recent Estimates:</div>
          {mockData.estimates.map((estimate, index) => (
            <div key={index} className="flex justify-between">
              <span className="text-terminal-text">{estimate.metric}</span>
              <span className="text-market-up">{estimate.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}