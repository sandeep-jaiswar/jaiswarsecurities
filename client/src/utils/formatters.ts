export function formatNumber(value: number, decimals: number = 2): string {
  if (value === null || value === undefined || isNaN(value)) {
    return "--"
  }

  if (Math.abs(value) >= 1e9) {
    return (value / 1e9).toFixed(decimals) + "B"
  } else if (Math.abs(value) >= 1e6) {
    return (value / 1e6).toFixed(decimals) + "M"
  } else if (Math.abs(value) >= 1e3) {
    return (value / 1e3).toFixed(decimals) + "K"
  }

  return value.toFixed(decimals)
}

export function formatPercent(value: number, decimals: number = 2): string {
  if (value === null || value === undefined || isNaN(value)) {
    return "--"
  }

  const sign = value >= 0 ? "+" : ""
  return `${sign}${value.toFixed(decimals)}%`
}

export function formatPrice(value: number, decimals: number = 2): string {
  if (value === null || value === undefined || isNaN(value)) {
    return "--"
  }

  return `$${value.toFixed(decimals)}`
}

export function formatVolume(value: number): string {
  if (value === null || value === undefined || isNaN(value)) {
    return "--"
  }

  if (value >= 1e9) {
    return (value / 1e9).toFixed(1) + "B"
  } else if (value >= 1e6) {
    return (value / 1e6).toFixed(1) + "M"
  } else if (value >= 1e3) {
    return (value / 1e3).toFixed(1) + "K"
  }

  return value.toString()
}

export function formatMarketCap(value: number): string {
  if (value === null || value === undefined || isNaN(value)) {
    return "--"
  }

  if (value >= 1e12) {
    return (value / 1e12).toFixed(1) + "T"
  } else if (value >= 1e9) {
    return (value / 1e9).toFixed(1) + "B"
  } else if (value >= 1e6) {
    return (value / 1e6).toFixed(1) + "M"
  }

  return formatNumber(value)
}

export function formatTime(timestamp: string | number | Date): string {
  const date = new Date(timestamp)
  return date.toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  })
}

export function formatDate(timestamp: string | number | Date): string {
  const date = new Date(timestamp)
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

export function getChangeColor(value: number): string {
  if (value > 0) return "text-market-up"
  if (value < 0) return "text-market-down"
  return "text-market-neutral"
}

export function getChangeIcon(value: number): string {
  if (value > 0) return "▲"
  if (value < 0) return "▼"
  return "●"
}
