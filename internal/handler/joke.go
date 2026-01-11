package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/cdunlap/djaas/internal/model"
	"github.com/cdunlap/djaas/internal/service"
)

// HandleGetJoke handles GET /api/v1/joke requests
// @Summary Get a random joke
// @Description Retrieve a random joke with optional filtering by search query, category, and tags
// @Tags Jokes
// @Accept json
// @Produce json
// @Param search query string false "Search query to filter jokes"
// @Param category query string false "Category filter (e.g., 'general', 'food', 'science')"
// @Param tags query string false "Comma-separated list of tags (e.g., 'wordplay,puns')"
// @Success 200 {object} model.Joke
// @Failure 404 {object} model.ErrorResponse "No jokes found"
// @Failure 500 {object} model.ErrorResponse "Internal server error"
// @Router /joke [get]
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

// HandleGetTags returns all available tags
// @Summary Get all tags
// @Description Retrieve a list of all available tags
// @Tags Tags
// @Accept json
// @Produce json
// @Success 200 {object} map[string][]string "List of tags"
// @Failure 500 {object} model.ErrorResponse "Internal server error"
// @Router /tags [get]
func (h *Handler) HandleGetTags(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	tags, err := h.jokeService.GetAllTags(ctx)
	if err != nil {
		h.logger.Error("failed to get tags", "error", err)
		h.writeErrorJSON(w, http.StatusInternalServerError, "internal_error", "Failed to retrieve tags")
		return
	}

	h.writeJSON(w, http.StatusOK, map[string][]string{
		"tags": tags,
	})
}

// CreateJokeRequest represents the request body for creating a joke
type CreateJokeRequest struct {
	Setup     string   `json:"setup"`
	Punchline string   `json:"punchline"`
	Category  *string  `json:"category,omitempty"`
	Tags      []string `json:"tags,omitempty"`
}

// HandleCreateJoke handles POST /api/v1/joke requests
// @Summary Create a new joke
// @Description Add a new joke to the database with optional category and tags
// @Tags Jokes
// @Accept json
// @Produce json
// @Param joke body CreateJokeRequest true "Joke to create"
// @Success 201 {object} model.Joke "Created joke"
// @Failure 400 {object} model.ErrorResponse "Invalid request"
// @Failure 500 {object} model.ErrorResponse "Internal server error"
// @Router /joke [post]
func (h *Handler) HandleCreateJoke(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req CreateJokeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorJSON(w, http.StatusBadRequest, "invalid_json", "Invalid JSON request body")
		return
	}

	// Validate required fields
	if req.Setup == "" || req.Punchline == "" {
		h.writeErrorJSON(w, http.StatusBadRequest, "missing_fields", "Setup and punchline are required")
		return
	}

	// Create the joke
	joke, err := h.jokeService.CreateJoke(ctx, req.Setup, req.Punchline, req.Category, req.Tags)
	if err != nil {
		h.handleError(w, err)
		return
	}

	h.writeJSON(w, http.StatusCreated, joke)
}
