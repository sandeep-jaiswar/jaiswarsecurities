package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var log *zap.Logger
var loggerOnce sync.Once

// InitLogger initializes the global logger
func InitLogger() {
	encoderConfig := zapcore.EncoderConfig{
		TimeKey:        "timestamp",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "message",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.CapitalColorLevelEncoder,
		EncodeTime:     customTimeEncoder,
		EncodeDuration: zapcore.StringDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	// Log to console and file
	consoleCore := zapcore.NewCore(zapcore.NewConsoleEncoder(encoderConfig), zapcore.AddSync(os.Stdout), zap.DebugLevel)
	fileWriter, err := getLogFileWriter("logs/app.log")
	if err != nil {
		fmt.Printf("failed to initialize file logging: %v\n", err)
		core := zapcore.NewCore(
			zapcore.NewConsoleEncoder(encoderConfig),
			zapcore.AddSync(os.Stdout),
			zap.DebugLevel,
		)
		log = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zap.ErrorLevel))
		return
	}
	fileCore := zapcore.NewCore(zapcore.NewJSONEncoder(encoderConfig), fileWriter, zap.InfoLevel)

	// Combine cores
	core := zapcore.NewTee(consoleCore, fileCore)
	log = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zap.ErrorLevel))

	defer func() {
		if err := log.Sync(); err != nil {
			fmt.Println("Error while syncing log", err)
		}
	}()
}

// customTimeEncoder formats timestamps
func customTimeEncoder(t time.Time, enc zapcore.PrimitiveArrayEncoder) {
	enc.AppendString(t.Format(time.RFC3339))
}

// getLogFileWriter handles log file writing
func getLogFileWriter(filename string) (zapcore.WriteSyncer, error) {
	dir := filepath.Dir(filename)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log directory: %w", err)
	}

	file, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}
	return zapcore.AddSync(file), nil
}

// GetLogger returns the global logger instance
func NewLogger() *zap.Logger {
	loggerOnce.Do(func() {
		InitLogger()
	})
	return log
}