import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Providers } from '@/components/providers'
import { Toaster } from 'react-hot-toast'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Stock Terminal - Bloomberg-style Trading Platform',
  description: 'Professional stock screening and trading terminal',
  keywords: 'stocks, trading, terminal, bloomberg, finance, market data',
  authors: [{ name: 'Stock Terminal Team' }],
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-terminal-bg text-terminal-text antialiased`}>
        <Providers>
          {children}
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              style: {
                background: '#1a1a1a',
                color: '#ffffff',
                border: '1px solid #333333',
              },
              success: {
                iconTheme: {
                  primary: '#00ff00',
                  secondary: '#000000',
                },
              },
              error: {
                iconTheme: {
                  primary: '#ff0000',
                  secondary: '#000000',
                },
              },
            }}
          />
        </Providers>
      </body>
    </html>
  )
}