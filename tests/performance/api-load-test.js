import { check, sleep } from "k6"
import http from "k6/http"
import { Rate } from "k6/metrics"

// Custom metrics
export const errorRate = new Rate("errors")

// Test configuration
export const options = {
  stages: [
    { duration: "2m", target: 10 }, // Ramp up to 10 users
    { duration: "5m", target: 10 }, // Stay at 10 users
    { duration: "2m", target: 20 }, // Ramp up to 20 users
    { duration: "5m", target: 20 }, // Stay at 20 users
    { duration: "2m", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
    http_req_failed: ["rate<0.1"], // Error rate must be below 10%
    errors: ["rate<0.1"], // Custom error rate must be below 10%
  },
}

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000"

export default function () {
  // Test health endpoint
  let response = http.get(`${BASE_URL}/health`)
  check(response, {
    "health check status is 200": (r) => r.status === 200,
    "health check response time < 200ms": (r) => r.timings.duration < 200,
  }) || errorRate.add(1)

  sleep(1)

  // Test market overview
  response = http.get(`${BASE_URL}/api/analytics/market-overview`)
  check(response, {
    "market overview status is 200": (r) => r.status === 200,
    "market overview response time < 1000ms": (r) => r.timings.duration < 1000,
    "market overview has data": (r) => {
      try {
        const data = JSON.parse(r.body)
        return data && typeof data === "object"
      } catch {
        return false
      }
    },
  }) || errorRate.add(1)

  sleep(1)

  // Test symbols endpoint
  response = http.get(`${BASE_URL}/api/market/symbols?limit=10`)
  check(response, {
    "symbols status is 200": (r) => r.status === 200,
    "symbols response time < 1000ms": (r) => r.timings.duration < 1000,
    "symbols returns array": (r) => {
      try {
        const data = JSON.parse(r.body)
        return Array.isArray(data.data)
      } catch {
        return false
      }
    },
  }) || errorRate.add(1)

  sleep(1)

  // Test quote endpoint
  response = http.get(`${BASE_URL}/api/market/symbols/AAPL/quote`)
  check(response, {
    "quote status is 200 or 404": (r) => r.status === 200 || r.status === 404,
    "quote response time < 1000ms": (r) => r.timings.duration < 1000,
  }) || errorRate.add(1)

  sleep(2)
}

export function handleSummary(data) {
  return {
    "performance-summary.json": JSON.stringify(data, null, 2),
    stdout: `
    ========================================
    Performance Test Summary
    ========================================
    
    Total Requests: ${data.metrics.http_reqs.count}
    Failed Requests: ${data.metrics.http_req_failed.count}
    Average Response Time: ${data.metrics.http_req_duration.avg.toFixed(2)}ms
    95th Percentile: ${data.metrics.http_req_duration["p(95)"].toFixed(2)}ms
    
    Error Rate: ${(data.metrics.http_req_failed.rate * 100).toFixed(2)}%
    
    ========================================
    `,
  }
}
