import { useQuery } from "react-query";
import { apiClient } from "@/lib/api";

export function useMarketOverviewData() {
  const { data, isLoading } = useQuery(
    "market-overview",
    () => apiClient.get("/analytics/market-overview"),
    {
      refetchInterval: 5000,
    }
  );

  // For now, returning mock indices as the API does not provide them
  const majorIndices = [
    { symbol: "SPY", name: "S&P 500" },
    { symbol: "QQQ", name: "NASDAQ" },
    { symbol: "DIA", name: "DOW" },
    { symbol: "IWM", name: "Russell 2000" },
  ];

  return {
    marketOverviewData: data,
    majorIndices,
    isLoading,
  };
}
