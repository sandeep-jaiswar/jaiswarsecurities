'use client'

import { ReactNode } from 'react'
import { TerminalHeader } from './TerminalHeader'
import { TerminalSidebar } from './TerminalSidebar'
import { TerminalFooter } from './TerminalFooter'

interface TerminalLayoutProps {
  children: ReactNode
}

export function TerminalLayout({ children }: TerminalLayoutProps) {
  return (
    <div className="min-h-screen bg-terminal-bg text-terminal-text">
      {children}
    </div>
  )
}