package handler

import (
	"log/slog"

	"github.com/yourusername/djaas/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Handler holds dependencies for HTTP handlers
type Handler struct {
	jokeService *service.JokeService
	logger      *slog.Logger
	dbPool      *pgxpool.Pool
}

// New creates a new Handler
func New(jokeService *service.JokeService, logger *slog.Logger, dbPool *pgxpool.Pool) *Handler {
	return &Handler{
		jokeService: jokeService,
		logger:      logger,
		dbPool:      dbPool,
	}
}
