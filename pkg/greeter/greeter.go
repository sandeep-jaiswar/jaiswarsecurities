package greeter

import (
	"net/http"

	"github.com/gorilla/mux"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// GreeterHandler provides the API for greeting
func GreeterHandler(logger *zap.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logger.Info("Handling Greet Request")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"message": "Hello from Greeter!"}`))
	}
}

// New constructor function for dependency injection
func New(router *mux.Router, logger *zap.Logger) {
	router.HandleFunc("/greet", GreeterHandler(logger)).Methods("GET")
	logger.Info("Registered Greeter Routes")
}

// Module exports the greeter dependencies
var Module = fx.Module("greeter",
	fx.Invoke(New),
)
