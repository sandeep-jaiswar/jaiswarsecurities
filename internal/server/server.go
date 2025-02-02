package server

import (
	"context"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Params defines the dependencies for the server
type Params struct {
	fx.In
	Logger *zap.Logger
}

// Server wraps an HTTP server and router
type Server struct {
	router *mux.Router
	server *http.Server
	logger *zap.Logger
}

// NewMuxRouter provides a new mux router
func NewMuxRouter() *mux.Router {
	return mux.NewRouter()
}

// NewServer creates a new HTTP server with dependency injection
func NewServer(p Params, router *mux.Router) *Server {
	s := &Server{
		router: router,
		server: &http.Server{
			Addr:         ":8080", // Change port if necessary
			Handler:      router,
			ReadTimeout:  10 * time.Second,
			WriteTimeout: 10 * time.Second,
			IdleTimeout:  60 * time.Second,
		},
		logger: p.Logger,
	}

	return s
}

// StartServer runs the HTTP server
func (s *Server) StartServer(lc fx.Lifecycle) {
	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			s.logger.Info("Starting HTTP server on port 8080...")

			go func() {
				if err := s.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					s.logger.Fatal("Server error:", zap.Error(err))
				}
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			s.logger.Info("Shutting down HTTP server...")
			return s.server.Shutdown(ctx)
		},
	})
}

// Module defines the server module for fx
var Module = fx.Module("server",
	fx.Provide(NewMuxRouter), // Provides the router
	fx.Provide(NewServer),    // Provides the HTTP server
	fx.Invoke((*Server).StartServer), // Starts the server using lifecycle hooks
)
