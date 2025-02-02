package logger

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"os"
	"time"
)

var log *zap.Logger

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
	fileCore := zapcore.NewCore(zapcore.NewJSONEncoder(encoderConfig), getLogFileWriter("logs/app.log"), zap.InfoLevel)

	// Combine cores
	core := zapcore.NewTee(consoleCore, fileCore)
	log = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zap.ErrorLevel))

	defer log.Sync()
}

// customTimeEncoder formats timestamps
func customTimeEncoder(t time.Time, enc zapcore.PrimitiveArrayEncoder) {
	enc.AppendString(t.Format(time.RFC3339))
}

// getLogFileWriter handles log file writing
func getLogFileWriter(filename string) zapcore.WriteSyncer {
	file, _ := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	return zapcore.AddSync(file)
}

// GetLogger returns the global logger instance
func NewLogger() *zap.Logger {
	if log == nil {
		InitLogger()
	}
	return log
}