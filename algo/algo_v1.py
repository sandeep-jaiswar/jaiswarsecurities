import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

# --- Configuration ---
TICKER = 'AAPL'
START_DATE = '2023-01-01'
END_DATE = '2025-01-01'
INITIAL_CAPITAL = 1000000
SHORT_WINDOW = 50
LONG_WINDOW = 200

# --- Data Acquisition ---
def get_stock_data(ticker, start_date, end_date):
    data = yf.download(ticker, start=start_date, end=end_date, threads=False, auto_adjust=True, interval='1d')
    return data

# --- Moving Average Strategy ---
def generate_signals(data, short_window, long_window):
    signals = pd.DataFrame(index=data.index)
    signals['price'] = data['Close']
    signals['short_mavg'] = data['Close'].rolling(window=short_window, min_periods=1).mean()
    signals['long_mavg'] = data['Close'].rolling(window=long_window, min_periods=1).mean()
    signals['signal'] = 0.0
    signals['signal'][short_window:] = np.where(
        signals['short_mavg'][short_window:] > signals['long_mavg'][short_window:], 1.0, 0.0
    )
    signals['positions'] = signals['signal'].diff()
    return signals

# --- Backtesting Logic with Trade Tracking ---
def backtest_strategy(signals, initial_capital):
    portfolio = pd.DataFrame(index=signals.index)
    portfolio['price'] = signals['price']
    portfolio['signal'] = signals['signal']
    portfolio['positions'] = signals['positions']

    cash = initial_capital
    shares_held = 0
    total_values = []
    trades = []

    for i in range(len(signals)):
        date = signals.index[i]
        price = portfolio['price'].iloc[i]
        position = portfolio['positions'].iloc[i]

        if position == 1.0:  # Buy
            shares_to_buy = cash // price
            cost = shares_to_buy * price
            cash -= cost
            shares_held += shares_to_buy

            trades.append({
                'date': date,
                'action': 'BUY',
                'price': price,
                'shares': shares_to_buy,
                'cash_remaining': cash,
                'total_value': cash + shares_held * price
            })

        elif position == -1.0:  # Sell
            proceeds = shares_held * price
            cash += proceeds

            trades.append({
                'date': date,
                'action': 'SELL',
                'price': price,
                'shares': shares_held,
                'cash_remaining': cash,
                'total_value': cash
            })

            shares_held = 0

        total_value = cash + (shares_held * price)
        total_values.append(total_value)

    portfolio['total'] = total_values
    portfolio['returns'] = portfolio['total'].pct_change()
    trades_df = pd.DataFrame(trades)

    return portfolio, trades_df

# --- Machine Learning Signal Generator ---
def generate_ml_signals(data):
    data['short_mavg'] = data['Close'].rolling(window=SHORT_WINDOW, min_periods=1).mean()
    data['long_mavg'] = data['Close'].rolling(window=LONG_WINDOW, min_periods=1).mean()
    data['price_change'] = data['Close'].pct_change()
    data.dropna(inplace=True)
    data['target'] = np.where(data['Close'].shift(-1) > data['Close'], 1, 0)
    data.dropna(inplace=True)

    features = ['short_mavg', 'long_mavg', 'price_change']
    X = data[features]
    y = data['target']

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = LogisticRegression()
    model.fit(X_train, y_train)

    data['ml_signal_prob'] = model.predict_proba(X)[:, 1]
    data['ml_signal'] = np.where(data['ml_signal_prob'] > 0.55, 1, 0)

    ml_signals_df = pd.DataFrame(index=data.index)
    ml_signals_df['price'] = data['Close']
    ml_signals_df['signal'] = data['ml_signal']
    ml_signals_df['positions'] = ml_signals_df['signal'].diff()

    return ml_signals_df, model, X_test, y_test

# --- Main Execution ---
if __name__ == '__main__':
    stock_data = get_stock_data(TICKER, START_DATE, END_DATE)

    if not stock_data.empty:
        print(f"Downloaded data for {TICKER}")

        # --- Moving Average Strategy ---
        print("\n--- Backtesting Moving Average Strategy ---")
        ma_signals = generate_signals(stock_data.copy(), SHORT_WINDOW, LONG_WINDOW)
        ma_portfolio, ma_trades = backtest_strategy(ma_signals, INITIAL_CAPITAL)

        # Save trades to CSV
        ma_trades.to_csv('ma_trades.csv', index=False)
        print("Saved trade log to 'ma_trades.csv'")

        # Plot MA results
        plt.figure(figsize=(12, 6))
        plt.plot(ma_portfolio['total'], label='Portfolio Value')
        plt.plot(stock_data['Close'] / stock_data['Close'].iloc[0] * INITIAL_CAPITAL, label='Buy and Hold')
        plt.title(f'{TICKER} Moving Average Crossover Backtest')
        plt.xlabel('Date')
        plt.ylabel('Portfolio Value ($)')
        plt.legend()
        plt.grid(True)
        plt.savefig('ma_backtest.png')
        print("Saved plot to 'ma_backtest.png'")

        print(f"Final Portfolio Value (MA): ${ma_portfolio['total'].iloc[-1]:,.2f}")
        total_return_ma = (ma_portfolio['total'].iloc[-1] - INITIAL_CAPITAL) / INITIAL_CAPITAL * 100
        print(f"Total Return (MA): {total_return_ma:.2f}%")

        # --- Machine Learning Strategy ---
        print("\n--- Backtesting Machine Learning Strategy (Example) ---")
        ml_signals, ml_model, X_test, y_test = generate_ml_signals(stock_data.copy())
        ml_portfolio, ml_trades = backtest_strategy(ml_signals, INITIAL_CAPITAL)

        # Save trades to CSV
        ml_trades.to_csv('ml_trades.csv', index=False)
        print("Saved trade log to 'ml_trades.csv'")

        # Evaluate model
        ml_predictions = ml_model.predict(X_test)
        accuracy = accuracy_score(y_test, ml_predictions)
        print(f"Machine Learning Model Accuracy (on test set): {accuracy:.2f}")

        # Plot ML results
        plt.figure(figsize=(12, 6))
        plt.plot(ml_portfolio['total'], label='ML Portfolio Value')
        plt.plot(stock_data['Close'] / stock_data['Close'].iloc[0] * INITIAL_CAPITAL, label='Buy and Hold')
        plt.title(f'{TICKER} Machine Learning Strategy Backtest (Example)')
        plt.xlabel('Date')
        plt.ylabel('Portfolio Value ($)')
        plt.legend()
        plt.grid(True)
        plt.savefig('ml_backtest.png')
        print("Saved plot to 'ml_backtest.png'")

        print(f"Final Portfolio Value (ML): ${ml_portfolio['total'].iloc[-1]:,.2f}")
        total_return_ml = (ml_portfolio['total'].iloc[-1] - INITIAL_CAPITAL) / INITIAL_CAPITAL * 100
        print(f"Total Return (ML): {total_return_ml:.2f}%")

    else:
        print(f"Could not download data for {TICKER}. Please check the ticker symbol and date range.")
