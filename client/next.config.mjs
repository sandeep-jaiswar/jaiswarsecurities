const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:3000";

const nextConfig = {
  reactStrictMode: true,
  env: {
    API_BASE_URL: apiBaseUrl,
    WS_URL: process.env.NEXT_PUBLIC_WS_URL || "ws://localhost:3000",
  },
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${apiBaseUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
