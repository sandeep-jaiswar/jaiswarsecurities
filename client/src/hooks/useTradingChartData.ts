import { useQuery } from "react-query";
import { apiClient } from "@/lib/api";

export function useTradingChartData(symbol: string, timeframe: string) {
  const { data, isLoading } = useQuery(
    ["trading-chart", symbol, timeframe],
    () => apiClient.get(`/api/trading/chart/${symbol}?timeframe=${timeframe}`),
    {
      refetchInterval: 5000,
    }
  );

  return {
    tradingChartData: data,
    isLoading,
  };
}
