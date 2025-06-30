/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Bloomberg Terminal Colors
        terminal: {
          bg: '#000000',
          panel: '#1a1a1a',
          border: '#333333',
          text: '#ffffff',
          accent: '#ff6600',
          success: '#00ff00',
          danger: '#ff0000',
          warning: '#ffff00',
          info: '#00ffff',
          muted: '#888888',
        },
        // Market Colors
        market: {
          up: '#00ff00',
          down: '#ff0000',
          neutral: '#ffffff',
          volume: '#0066cc',
        },
        // Chart Colors
        chart: {
          grid: '#333333',
          axis: '#666666',
          candle: {
            up: '#00ff00',
            down: '#ff0000',
            wick: '#ffffff',
          },
          volume: '#0066cc',
          ma: {
            short: '#ffff00',
            medium: '#ff6600',
            long: '#ff00ff',
          },
          indicator: {
            rsi: '#00ffff',
            macd: '#ff6600',
            bb: '#ffff00',
          },
        },
      },
      fontFamily: {
        mono: ['Consolas', 'Monaco', 'Courier New', 'monospace'],
        terminal: ['Courier New', 'monospace'],
      },
      fontSize: {
        'xs': '0.75rem',
        'sm': '0.875rem',
        'base': '1rem',
        'lg': '1.125rem',
        'xl': '1.25rem',
        '2xl': '1.5rem',
        '3xl': '1.875rem',
        '4xl': '2.25rem',
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      animation: {
        'pulse-fast': 'pulse 1s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'blink': 'blink 1s step-end infinite',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
      },
      keyframes: {
        blink: {
          '0%, 50%': { opacity: '1' },
          '51%, 100%': { opacity: '0' },
        },
        slideUp: {
          '0%': { transform: 'translateY(100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      backdropBlur: {
        xs: '2px',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}