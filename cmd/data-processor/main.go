package main

import (
	"context"

	"go.uber.org/fx"
	"go.uber.org/zap"
	"github.com/sandeep-jaiswar/jaiswarsecurities/internal/logger"
)

type Greeter struct {
	Message string
	Logger  *zap.Logger
}

func NewGreeter(lc fx.Lifecycle, logger *zap.Logger) *Greeter {
	g := &Greeter{Message: "Uber Fx Lifecycle!", Logger: logger}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			logger.Info("Starting application...")
			return nil
		},
		OnStop: func(ctx context.Context) error {
			logger.Info("Stopping application...")
			return nil
		},
	})

	return g
}

func Run(g *Greeter) {
	g.Logger.Info("Application Running", zap.String("message", g.Message))
	g.Logger.Info(g.Message)
}

func main() {
	app := fx.New(
		fx.Provide(logger.NewLogger),
		fx.Provide(NewGreeter),
		fx.Invoke(Run),
	)

	app.Run()
}
