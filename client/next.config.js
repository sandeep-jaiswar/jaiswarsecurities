/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  output: 'standalone',
  experimental: {
    appDir: true,
  },
  env: {
    API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000',
    WS_URL: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3000',
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000'}/api/:path*`,
      },
    ];
  },
}

module.exports = nextConfig