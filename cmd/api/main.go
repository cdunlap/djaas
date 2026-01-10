package main

import (
	"context"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/cdunlap/djaas/internal/config"
	"github.com/cdunlap/djaas/internal/database"
	"github.com/cdunlap/djaas/internal/handler"
	"github.com/cdunlap/djaas/internal/middleware"
	"github.com/cdunlap/djaas/internal/service"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize logger
	var logger *slog.Logger
	logLevel := slog.LevelInfo
	switch cfg.Server.LogLevel {
	case "debug":
		logLevel = slog.LevelDebug
	case "warn":
		logLevel = slog.LevelWarn
	case "error":
		logLevel = slog.LevelError
	}

	opts := &slog.HandlerOptions{
		Level: logLevel,
	}

	if cfg.Server.Env == "production" {
		logger = slog.New(slog.NewJSONHandler(os.Stdout, opts))
	} else {
		logger = slog.New(slog.NewTextHandler(os.Stdout, opts))
	}

	slog.SetDefault(logger)

	logger.Info("starting dad joke service",
		"env", cfg.Server.Env,
		"port", cfg.Server.Port,
	)

	// Connect to database with retry logic
	var dbPool *pgxpool.Pool
	maxRetries := 5
	for i := 0; i < maxRetries; i++ {
		dbCfg := database.Config{
			Host:            cfg.Database.Host,
			Port:            cfg.Database.Port,
			User:            cfg.Database.User,
			Password:        cfg.Database.Password,
			DBName:          cfg.Database.DBName,
			SSLMode:         cfg.Database.SSLMode,
			MaxConnections:  cfg.Database.MaxConnections,
			MaxIdleConns:    cfg.Database.MaxIdleConns,
		}

		dbPool, err = database.Connect(dbCfg, logger)
		if err == nil {
			break
		}

		logger.Warn("failed to connect to database, retrying",
			"attempt", i+1,
			"max_retries", maxRetries,
			"error", err,
		)
		time.Sleep(time.Duration(i+1) * time.Second)
	}

	if err != nil {
		logger.Error("failed to connect to database after retries", "error", err)
		os.Exit(1)
	}
	defer database.Close(dbPool)

	// Initialize database queries
	queries := database.New(dbPool)

	// Initialize services
	jokeService := service.NewJokeService(queries, logger)

	// Initialize handlers
	h := handler.New(jokeService, logger, dbPool)

	// Set up router
	r := chi.NewRouter()

	// Apply middleware
	r.Use(middleware.Recovery(logger))
	r.Use(middleware.Logger(logger))

	// Only apply rate limiting in non-development environments
	if cfg.Server.Env != "development" {
		r.Use(middleware.RateLimit(cfg.RateLimit.Requests, cfg.RateLimit.Window))
		logger.Info("rate limiting enabled", "requests", cfg.RateLimit.Requests, "window", cfg.RateLimit.Window)
	} else {
		logger.Info("rate limiting disabled (development mode)")
	}

	// Register routes
	r.Get("/health", h.HandleHealth)
	r.Route("/api/v1", func(r chi.Router) {
		r.Get("/joke", h.HandleGetJoke)
		r.Get("/tags", h.HandleGetTags)
	})

	// Serve static files from public directory
	fileServer := http.FileServer(http.Dir("public"))
	r.Get("/*", func(w http.ResponseWriter, r *http.Request) {
		fileServer.ServeHTTP(w, r)
	})

	// Create HTTP server
	server := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	serverErrors := make(chan error, 1)
	go func() {
		logger.Info("server starting", "addr", server.Addr)
		serverErrors <- server.ListenAndServe()
	}()

	// Listen for shutdown signals
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	// Block until we receive a signal or server error
	select {
	case err := <-serverErrors:
		logger.Error("server error", "error", err)
		os.Exit(1)
	case sig := <-shutdown:
		logger.Info("shutdown signal received", "signal", sig)

		// Give outstanding requests 30 seconds to complete
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			logger.Error("graceful shutdown failed", "error", err)
			if err := server.Close(); err != nil {
				logger.Error("server close failed", "error", err)
			}
		}

		logger.Info("server stopped")
	}
}
