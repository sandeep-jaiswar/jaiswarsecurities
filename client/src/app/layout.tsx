import type { Metadata, Viewport } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { Toaster } from "react-hot-toast"
import { Providers } from "@/components/providers"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Stock Terminal - Bloomberg-style Trading Platform",
  description: "Professional stock screening and trading terminal",
  keywords: "stocks, trading, terminal, bloomberg, finance, market data",
  authors: [{ name: "Stock Terminal Team" }],
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-terminal-bg text-terminal-text antialiased`}>
        <Providers>{children}</Providers>
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: "#1a1a1a",
              color: "#ffffff",
              border: "1px solid #333333",
            },
            success: {
              iconTheme: {
                primary: "#00ff00",
                secondary: "#000000",
              },
            },
            error: {
              iconTheme: {
                primary: "#ff0000",
                secondary: "#000000",
              },
            },
          }}
        />
      </body>
    </html>
  )
}
