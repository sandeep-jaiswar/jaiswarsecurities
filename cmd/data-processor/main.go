package main

import (
	"github.com/sandeep-jaiswar/jaiswarsecurities/internal/logger"
	"github.com/sandeep-jaiswar/jaiswarsecurities/internal/server"
	"github.com/sandeep-jaiswar/jaiswarsecurities/pkg/greeter"
	"go.uber.org/fx"
)

func main() {
	app := fx.New(
		logger.Module,
		server.Module,
		greeter.Module,
	)

	app.Run()
}
