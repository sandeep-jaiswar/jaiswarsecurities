import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# --- Configuration ---
TICKER = 'AAPL'
START_DATE = '2023-05-05'
END_DATE = '2025-05-05'
INITIAL_CAPITAL = 1000000.0
SHORT_WINDOW = 50
LONG_WINDOW = 200
STOP_LOSS_PCT = 0.02
TAKE_PROFIT_PCT = 0.04
COMMISSION_PER_TRADE = 1.0
SLIPPAGE_PCT = 0.0005

# --- Data Acquisition ---
def get_stock_data(ticker, start_date, end_date):
    print(f"Downloading data for {ticker} from {start_date} to {end_date}...")
    data = yf.download(ticker, start=start_date, end=end_date, 
                      auto_adjust=True, interval='1d')
    print(f"Downloaded {len(data)} rows of data")
    
    # Calculate ATR
    print("Calculating ATR...")
    high_low = data['High'] - data['Low']
    high_close = np.abs(data['High'] - data['Close'].shift())
    low_close = np.abs(data['Low'] - data['Close'].shift())
    true_range = pd.concat([high_low, high_close, low_close], axis=1).max(axis=1)
    data['ATR'] = true_range.rolling(window=14).mean().fillna(0.0)
    
    return data

# --- Strategy 1: MA Crossover ---
def ma_crossover_strategy(data, short_window, long_window):
    print("Running MA Crossover strategy...")
    short_ma = data['Close'].rolling(window=short_window, min_periods=1).mean()
    long_ma = data['Close'].rolling(window=long_window, min_periods=1).mean()
    result = np.sign(short_ma - long_ma).astype(int)
    result = result.squeeze()
    print(f"MA Crossover result: Type={type(result)}, Shape={result.shape}, Dim={result.ndim}")
    return result

# --- Strategy 2: Support/Resistance ---
def support_resistance_strategy(data, window=20):
    print("Running Support/Resistance strategy...")
    close_prices = data['Close']
    rolling_max = close_prices.rolling(window=window, min_periods=1).max()
    rolling_min = close_prices.rolling(window=window, min_periods=1).min()

    support_threshold = rolling_min * 1.01
    resistance_threshold = rolling_max * 0.99

    # Initialize signals array
    signals = np.zeros(len(close_prices), dtype=int)
    
    # Get numpy arrays for comparison
    close_arr = close_prices.values
    support_arr = support_threshold.values
    resistance_arr = resistance_threshold.values
    
    # Simple loop implementation
    for i in range(len(close_arr)):
        if close_arr[i] <= support_arr[i]:
            signals[i] = 1
        elif close_arr[i] >= resistance_arr[i]:
            signals[i] = -1
    
    result = pd.Series(signals, index=data.index)
    print(f"Support/Resistance result: Type={type(result)}, Shape={result.shape}, Dim={result.ndim}")
    return result

# --- Strategy 3: Volume Spike ---
def volume_strategy(data, volume_window=20):
    print("Running Volume Spike strategy...")
    avg_volume = data['Volume'].rolling(window=volume_window, min_periods=1).mean()
    spike = (data['Volume'] > 1.5 * avg_volume).astype(int)
    price_direction = np.sign(data['Close'].diff().fillna(0)).astype(int)
    # Ensure both are Series before multiplication
    if isinstance(spike, pd.DataFrame):
        spike = spike.squeeze()
    if isinstance(price_direction, pd.DataFrame):
        price_direction = price_direction.squeeze()
        
    result = spike * price_direction
    result = pd.Series(result, index=data.index)
    
    print(f"Volume Spike result: Type={type(result)}, Shape={result.shape}, Dim={result.ndim}")
    return result

# --- Strategy 4: Momentum ---
def momentum_strategy(data, momentum_window=5):
    print("Running Momentum strategy...")
    momentum = data['Close'].diff(periods=momentum_window).fillna(0)
    result = np.sign(momentum).astype(int)
    print(f"Momentum result: Type={type(result)}, Shape={result.shape}, Dim={result.ndim}")
    return result

# --- Strategy Voting Engine ---
def generate_signals(data, short_window=50, long_window=200):
    print("Generating signals...")
    signals = pd.DataFrame(index=data.index)
    signals['price'] = data['Close']
    signals['ATR'] = data['ATR']

    # Build strategies with debugging
    strategies = {}
    
    print("\n--- Running MA Crossover strategy ---")
    ma_result = ma_crossover_strategy(data, short_window, long_window)
    strategies["ma"] = ma_result
    
    print("\n--- Running Support/Resistance strategy ---")
    sr_result = support_resistance_strategy(data)
    strategies["sr"] = sr_result
    
    print("\n--- Running Volume Spike strategy ---")
    volume_result = volume_strategy(data)
    strategies["volume"] = volume_result
    
    print("\n--- Running Momentum strategy ---")
    momentum_result = momentum_strategy(data)
    strategies["momentum"] = momentum_result
    
    # Create strategy_signals DataFrame
    print("\nCreating strategy_signals DataFrame...")
    strategy_signals = pd.DataFrame(index=data.index)
    
    print("Adding MA signals...")
    strategy_signals['ma'] = ma_result
    print("MA signals added successfully!")
    
    print("Adding Support/Resistance signals...")
    strategy_signals['sr'] = sr_result
    print("Support/Resistance signals added successfully!")
    
    print("Adding Volume Spike signals...")
    strategy_signals['volume'] = volume_result
    print("Volume Spike signals added successfully!")
    
    print("Adding Momentum signals...")
    strategy_signals['momentum'] = momentum_result
    print("Momentum signals added successfully!")
    
    print(f"Strategy_signals shape: {strategy_signals.shape}")

    def vote_signals(row):
        votes = row.values
        buy_votes = np.sum(votes == 1)
        sell_votes = np.sum(votes == -1)
        total_votes = len(votes)

        # Mandatory conditions
        if row['sr'] == 1 and row['volume'] == 1:
            return 1
        if row['sr'] == -1 and row['volume'] == -1:
            return -1

        # Majority vote
        if buy_votes / total_votes >= 0.55:
            return 1
        elif sell_votes / total_votes >= 0.55:
            return -1
        return 0

    print("Applying voting logic...")
    signals['signal'] = strategy_signals.apply(vote_signals, axis=1)
    signals['positions'] = signals['signal'].diff().fillna(0)
    print("Signal generation complete!")
    return signals

# --- Backtesting ---
def backtest_strategy(signals, initial_capital):
    print("Starting backtest...")
    state = {
        'cash': float(initial_capital),
        'shares': 0.0,
        'total': float(initial_capital),
        'entry_price': None
    }
    
    trades = []
    portfolio_values = []
    
    for i, (date, row) in enumerate(signals.iterrows()):
        price = float(row['price'])
        atr = float(row['ATR'])
        position_change = int(row['positions'])
        
        # Execute trades
        if position_change == 1 and state['cash'] > 0:  # Buy
            risk_capital = state['cash'] * 0.01
            position_size = risk_capital / (1.5 * atr) if atr > 0 else 0
            
            shares_to_buy = position_size
            cost = shares_to_buy * price * (1 + SLIPPAGE_PCT)
            commission = COMMISSION_PER_TRADE
            
            if cost + commission <= state['cash']:
                state['cash'] -= (cost + commission)
                state['shares'] += shares_to_buy
                state['entry_price'] = price
                
                trades.append({
                    'date': date, 
                    'action': 'BUY', 
                    'price': price,
                    'shares': shares_to_buy, 
                    'value': cost
                })
        
        elif position_change == -1 and state['shares'] > 0:  # Sell
            proceeds = state['shares'] * price * (1 - SLIPPAGE_PCT)
            commission = COMMISSION_PER_TRADE
            state['cash'] += (proceeds - commission)
            
            trades.append({
                'date': date, 
                'action': 'SELL', 
                'price': price,
                'shares': state['shares'], 
                'value': proceeds
            })
            
            state['shares'] = 0.0
            state['entry_price'] = None
        
        # Update portfolio value
        portfolio_value = state['cash'] + state['shares'] * price
        portfolio_values.append(portfolio_value)
    
    signals['total'] = portfolio_values
    signals['returns'] = signals['total'].pct_change()
    print("Backtest complete!")
    return signals, pd.DataFrame(trades)

# --- Main Execution ---
if __name__ == '__main__':
    print("Starting program...")
    stock_data = get_stock_data(TICKER, START_DATE, END_DATE)
    
    if not stock_data.empty:
        print(f"\nData acquired for {TICKER}, generating signals...")
        signals = generate_signals(stock_data.copy(), SHORT_WINDOW, LONG_WINDOW)
        
        print("\nRunning backtest...")
        portfolio, trades = backtest_strategy(signals, INITIAL_CAPITAL)
        
        # Performance metrics
        cumulative_return = (portfolio['total'].iloc[-1] / INITIAL_CAPITAL - 1) * 100
        sharpe_ratio = (portfolio['returns'].mean() / portfolio['returns'].std()) * np.sqrt(252)
        max_drawdown = (portfolio['total'].cummax() - portfolio['total']).max() / portfolio['total'].cummax().max()
        
        print("\n--- Performance Report ---")
        print(f"Initial Capital: ${INITIAL_CAPITAL:,.2f}")
        print(f"Final Portfolio Value: ${portfolio['total'].iloc[-1]:,.2f}")
        print(f"Cumulative Return: {cumulative_return:.2f}%")
        print(f"Sharpe Ratio: {sharpe_ratio:.2f}")
        print(f"Max Drawdown: {max_drawdown*100:.2f}%")
        print(f"Total Trades: {len(trades)}")
        
        # Save results
        trades.to_csv('trading_log.csv', index=False)
        portfolio[['total', 'returns']].to_csv('portfolio.csv')
        print("Results saved to CSV files")
        
        # Plotting
        print("Generating performance chart...")
        plt.figure(figsize=(14, 7))
        plt.plot(portfolio['total'], label='Strategy')
        plt.plot(stock_data['Close'] / stock_data['Close'].iloc[0] * INITIAL_CAPITAL, 
                label='Buy & Hold', alpha=0.7)
        plt.title(f'{TICKER} Trading Strategy Performance')
        plt.xlabel('Date')
        plt.ylabel('Portfolio Value ($)')
        plt.legend()
        plt.grid(True)
        plt.savefig('strategy_performance.png')
        plt.show()
        print("Chart saved as 'strategy_performance.png'")
    else:
        print("Data download failed. Check ticker and date range.")