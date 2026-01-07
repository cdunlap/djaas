package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/yourusername/djaas/internal/model"
	"github.com/yourusername/djaas/internal/service"
)

// HandleGetJoke handles GET /api/v1/joke requests
// Supports query parameters:
//   - search: search for jokes containing this string
//   - category: filter by category
//   - tags: comma-separated list of tags (e.g., "wordplay,puns")
func (h *Handler) HandleGetJoke(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Parse query parameters
	searchQuery := r.URL.Query().Get("search")
	category := r.URL.Query().Get("category")
	tagsParam := r.URL.Query().Get("tags")

	// Parse tags (comma-separated)
	var tags []string
	if tagsParam != "" {
		rawTags := strings.Split(tagsParam, ",")
		for _, tag := range rawTags {
			trimmed := strings.TrimSpace(tag)
			if trimmed != "" {
				tags = append(tags, trimmed)
			}
		}
	}

	var joke *model.Joke
	var err error

	// Route to appropriate service method based on query param combinations
	switch {
	case len(tags) > 0 && category != "" && searchQuery != "":
		// All three filters
		joke, err = h.jokeService.GetJokeByAllFilters(ctx, tags, category, searchQuery)
	case len(tags) > 0 && category != "":
		// Tags + category
		joke, err = h.jokeService.GetJokeByTagsAndCategory(ctx, tags, category)
	case len(tags) > 0 && searchQuery != "":
		// Tags + search
		joke, err = h.jokeService.GetJokeByTagsAndSearch(ctx, tags, searchQuery)
	case len(tags) > 0:
		// Tags only
		joke, err = h.jokeService.GetJokeByTags(ctx, tags)
	case category != "" && searchQuery != "":
		// Category + search (existing)
		joke, err = h.jokeService.GetJokeByCategoryAndSearch(ctx, category, searchQuery)
	case category != "":
		// Category only (existing)
		joke, err = h.jokeService.GetJokeByCategory(ctx, category)
	case searchQuery != "":
		// Search only (existing)
		joke, err = h.jokeService.SearchJokes(ctx, searchQuery)
	default:
		// Random (existing)
		joke, err = h.jokeService.GetRandomJoke(ctx)
	}

	if err != nil {
		h.handleError(w, err)
		return
	}

	h.writeJSON(w, http.StatusOK, joke)
}

// handleError handles service errors and sends appropriate HTTP responses
func (h *Handler) handleError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrNoJokesFound):
		h.writeErrorJSON(w, http.StatusNotFound, "not_found", "No jokes found matching your criteria")
	case errors.Is(err, service.ErrInvalidInput):
		h.writeErrorJSON(w, http.StatusBadRequest, "invalid_input", "Invalid search query, category, or tags")
	default:
		h.logger.Error("internal server error", "error", err)
		h.writeErrorJSON(w, http.StatusInternalServerError, "internal_error", "An internal error occurred")
	}
}

// writeJSON writes a JSON response
func (h *Handler) writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		h.logger.Error("failed to encode JSON response", "error", err)
	}
}

// writeErrorJSON writes an error JSON response
func (h *Handler) writeErrorJSON(w http.ResponseWriter, status int, error string, message string) {
	errorResponse := model.ErrorResponse{
		Error:   error,
		Message: message,
	}
	h.writeJSON(w, status, errorResponse)
}
