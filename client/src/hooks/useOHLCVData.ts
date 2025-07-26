import { useQuery } from "react-query";
import { api } from "@/lib/api";

export function useOHLCVData(symbol: string) {
  const { data: ohlcvData, isLoading: isLoadingOhlcv } = useQuery(
    ["ohlcv", symbol],
    () => api.getOHLCV(symbol, { limit: 100 }),
    {
      enabled: !!symbol,
      refetchInterval: 10000,
    }
  );

  const { data: indicatorsData, isLoading: isLoadingIndicators } = useQuery(
    ["indicators", symbol],
    () => api.getIndicators(symbol, { limit: 100 }),
    {
      enabled: !!symbol,
      refetchInterval: 10000,
    }
  );

  return {
    ohlcvData,
    indicatorsData,
    isLoading: isLoadingOhlcv || isLoadingIndicators,
  };
}
