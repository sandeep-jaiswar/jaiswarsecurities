"use client"

export function PriceActionHeatmap() {
  // const heatmapData = [
  //   { time: "9:30", price: 150.25, volume: "high", color: "bg-market-up" },
  //   { time: "10:00", price: 150.45, volume: "medium", color: "bg-market-up" },
  //   { time: "10:30", price: 150.12, volume: "low", color: "bg-market-down" },
  //   { time: "11:00", price: 150.67, volume: "high", color: "bg-market-up" },
  // ]

  return (
    <div className="border border-terminal-border bg-terminal-panel p-2">
      <h4 className="mb-2 text-xs font-bold text-terminal-accent">Price Action Heatmap</h4>

      <div className="grid grid-cols-8 gap-1">
        {Array.from({ length: 64 }, (_, i) => (
          <div
            key={i}
            className={`h-4 w-4 ${
              Math.random() > 0.5
                ? Math.random() > 0.7
                  ? "bg-market-up"
                  : "bg-market-up opacity-50"
                : Math.random() > 0.7
                ? "bg-market-down"
                : "bg-market-down opacity-50"
            }`}
          />
        ))}
      </div>
    </div>
  )
}
