package backtester

import (
	"net/http"

	"github.com/gorilla/mux"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// GreeterHandler provides the API for greeting
func BacktesterHandler(logger *zap.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logger.Info("Handling Backtest Request")
		w.WriteHeader(http.StatusOK)
		if _, err := w.Write([]byte(`{"message": "Hello from Backtest!"}`)); err != nil {
			logger.Error("failed to write response", zap.Error(err))
		}
	}
}

// New constructor function for dependency injection
func New(router *mux.Router, logger *zap.Logger) {
	router.HandleFunc("/backtest", BacktesterHandler(logger)).Methods("GET")
	logger.Info("Registered Backtest Routes")
}

// Module exports the greeter dependencies
var Module = fx.Module("backtester",
	fx.Invoke(New),
)
