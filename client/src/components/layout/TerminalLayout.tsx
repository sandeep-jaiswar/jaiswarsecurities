"use client"

import type { ReactNode } from "react"

interface TerminalLayoutProps {
  children: ReactNode;
}

export function TerminalLayout({ children }: TerminalLayoutProps) {
  return <div className="min-h-screen bg-terminal-bg text-terminal-text">{children}</div>
}
