package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/cdunlap/djaas/internal/model"
)

// HandleHealth handles GET /health requests
func (h *Handler) HandleHealth(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	// Check database connectivity
	dbStatus := "connected"
	if err := h.dbPool.Ping(ctx); err != nil {
		h.logger.Error("database health check failed", "error", err)
		dbStatus = "disconnected"
	}

	status := "healthy"
	httpStatus := http.StatusOK

	if dbStatus == "disconnected" {
		status = "unhealthy"
		httpStatus = http.StatusServiceUnavailable
	}

	response := model.HealthResponse{
		Status:    status,
		Database:  dbStatus,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	h.writeJSON(w, httpStatus, response)
}
