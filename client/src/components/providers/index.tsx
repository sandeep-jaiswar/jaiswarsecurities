"use client"

import { useState, type PropsWithChildren } from "react"
import { QueryClient, QueryClientProvider } from "react-query"
import { ReactQueryDevtools } from "react-query/devtools"

interface CustomError extends Error {
  response?: { status?: number }
}

export function Providers({ children }: PropsWithChildren) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 5 * 60 * 1000, // 5 minutes
            cacheTime: 10 * 60 * 1000, // 10 minutes
            refetchOnWindowFocus: false,
            retry: (failureCount, error: unknown) => {
              const customError = error as CustomError
              if (customError?.response?.status === 404) return false
              return failureCount < 3
            },
          },
        },
      })
  )

  return (
    <>
      <QueryClientProvider client={queryClient}>
        <>{children}</>
        {process.env.NODE_ENV === "development" && <ReactQueryDevtools initialIsOpen={false} />}
      </QueryClientProvider>
    </>
  )
}
