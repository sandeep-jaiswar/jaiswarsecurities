package main

import (
	"context"
	"fmt"

	"go.uber.org/fx"
)

type Greeter struct {
	Message string
}

func NewGreeter(lc fx.Lifecycle) *Greeter {
	g := &Greeter{Message: "Uber Fx Lifecycle!"}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			fmt.Println("Starting application...")
			return nil
		},
		OnStop: func(ctx context.Context) error {
			fmt.Println("Stopping application...")
			return nil
		},
	})

	return g
}

func Run(g *Greeter) {
	fmt.Println(g.Message)
}

func main() {
	app := fx.New(
		fx.Provide(NewGreeter),
		fx.Invoke(Run),
	)

	app.Run()
}
