package service

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"github.com/cdunlap/djaas/internal/database"
	"github.com/cdunlap/djaas/internal/model"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var (
	ErrNoJokesFound = errors.New("no jokes found")
	ErrInvalidInput = errors.New("invalid input")
)

// JokeService provides business logic for jokes
type JokeService struct {
	queries *database.Queries
	logger  *slog.Logger
}

// NewJokeService creates a new JokeService
func NewJokeService(queries *database.Queries, logger *slog.Logger) *JokeService {
	return &JokeService{
		queries: queries,
		logger:  logger,
	}
}

// GetRandomJoke retrieves a random joke
func (s *JokeService) GetRandomJoke(ctx context.Context) (*model.Joke, error) {
	joke, err := s.queries.GetRandomJoke(ctx)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found in database")
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get random joke", "error", err)
		return nil, fmt.Errorf("failed to get random joke: %w", err)
	}

	tags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		// Continue with empty tags rather than failing
		tags = []string{}
	}

	return s.buildJokeWithTags(joke, tags), nil
}

// SearchJokes searches for jokes containing the query string
func (s *JokeService) SearchJokes(ctx context.Context, query string) (*model.Joke, error) {
	if query == "" {
		return nil, ErrInvalidInput
	}

	joke, err := s.queries.SearchJokes(ctx, toPgText(query))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching search query", "query", query)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to search jokes", "error", err, "query", query)
		return nil, fmt.Errorf("failed to search jokes: %w", err)
	}

	tags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		tags = []string{}
	}

	return s.buildJokeWithTags(joke, tags), nil
}

// GetJokeByCategory retrieves a random joke from a specific category
func (s *JokeService) GetJokeByCategory(ctx context.Context, category string) (*model.Joke, error) {
	if category == "" {
		return nil, ErrInvalidInput
	}

	joke, err := s.queries.GetJokeByCategory(ctx, toPgText(category))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found in category", "category", category)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by category", "error", err, "category", category)
		return nil, fmt.Errorf("failed to get joke by category: %w", err)
	}

	tags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		tags = []string{}
	}

	return s.buildJokeWithTags(joke, tags), nil
}

// GetJokeByCategoryAndSearch retrieves a random joke from a specific category matching the search query
func (s *JokeService) GetJokeByCategoryAndSearch(ctx context.Context, category, query string) (*model.Joke, error) {
	if category == "" || query == "" {
		return nil, ErrInvalidInput
	}

	params := database.GetJokeByCategoryAndSearchParams{
		Category: toPgText(category),
		Column2:  toPgText(query),
	}

	joke, err := s.queries.GetJokeByCategoryAndSearch(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching category and search",
				"category", category, "query", query)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by category and search",
			"error", err, "category", category, "query", query)
		return nil, fmt.Errorf("failed to get joke by category and search: %w", err)
	}

	tags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		tags = []string{}
	}

	return s.buildJokeWithTags(joke, tags), nil
}

// buildJokeWithTags builds a model.Joke with tags included
func (s *JokeService) buildJokeWithTags(dbJoke database.Joke, tags []string) *model.Joke {
	// Convert pgtype.Text to *string
	var category *string
	if dbJoke.Category.Valid {
		category = &dbJoke.Category.String
	}

	return &model.Joke{
		ID:        dbJoke.ID,
		Setup:     dbJoke.Setup,
		Punchline: dbJoke.Punchline,
		Category:  category,
		Tags:      tags,
		CreatedAt: dbJoke.CreatedAt.Time,
		UpdatedAt: dbJoke.UpdatedAt.Time,
	}
}

// Helper functions to convert Go types to pgtype

func toPgText(s string) pgtype.Text {
	return pgtype.Text{
		String: s,
		Valid:  true,
	}
}

// GetJokeByTags retrieves a random joke matching any of the provided tags
func (s *JokeService) GetJokeByTags(ctx context.Context, tags []string) (*model.Joke, error) {
	if len(tags) == 0 {
		return nil, ErrInvalidInput
	}

	joke, err := s.queries.GetJokeByTags(ctx, tags)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching tags", "tags", tags)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by tags", "error", err, "tags", tags)
		return nil, fmt.Errorf("failed to get joke by tags: %w", err)
	}

	joketags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		joketags = []string{}
	}

	return s.buildJokeWithTags(joke, joketags), nil
}

// GetJokeByTagsAndCategory retrieves a random joke matching tags and category
func (s *JokeService) GetJokeByTagsAndCategory(ctx context.Context, tags []string, category string) (*model.Joke, error) {
	if len(tags) == 0 || category == "" {
		return nil, ErrInvalidInput
	}

	params := database.GetJokeByTagsAndCategoryParams{
		Column1:  tags,
		Category: toPgText(category),
	}

	joke, err := s.queries.GetJokeByTagsAndCategory(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching tags and category", "tags", tags, "category", category)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by tags and category", "error", err, "tags", tags, "category", category)
		return nil, fmt.Errorf("failed to get joke by tags and category: %w", err)
	}

	joketags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		joketags = []string{}
	}

	return s.buildJokeWithTags(joke, joketags), nil
}

// GetJokeByTagsAndSearch retrieves a random joke matching tags and search query
func (s *JokeService) GetJokeByTagsAndSearch(ctx context.Context, tags []string, searchQuery string) (*model.Joke, error) {
	if len(tags) == 0 || searchQuery == "" {
		return nil, ErrInvalidInput
	}

	params := database.GetJokeByTagsAndSearchParams{
		Column1: tags,
		Column2: toPgText(searchQuery),
	}

	joke, err := s.queries.GetJokeByTagsAndSearch(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching tags and search", "tags", tags, "search", searchQuery)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by tags and search", "error", err, "tags", tags, "search", searchQuery)
		return nil, fmt.Errorf("failed to get joke by tags and search: %w", err)
	}

	joketags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		joketags = []string{}
	}

	return s.buildJokeWithTags(joke, joketags), nil
}

// GetJokeByAllFilters retrieves a random joke matching tags, category, and search query
func (s *JokeService) GetJokeByAllFilters(ctx context.Context, tags []string, category string, searchQuery string) (*model.Joke, error) {
	if len(tags) == 0 || category == "" || searchQuery == "" {
		return nil, ErrInvalidInput
	}

	params := database.GetJokeByAllFiltersParams{
		Column1:  tags,
		Category: toPgText(category),
		Column3:  toPgText(searchQuery),
	}

	joke, err := s.queries.GetJokeByAllFilters(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			s.logger.Warn("no jokes found matching all filters", "tags", tags, "category", category, "search", searchQuery)
			return nil, ErrNoJokesFound
		}
		s.logger.Error("failed to get joke by all filters", "error", err, "tags", tags, "category", category, "search", searchQuery)
		return nil, fmt.Errorf("failed to get joke by all filters: %w", err)
	}

	joketags, err := s.queries.GetTagsForJoke(ctx, joke.ID)
	if err != nil {
		s.logger.Error("failed to get tags for joke", "error", err, "joke_id", joke.ID)
		joketags = []string{}
	}

	return s.buildJokeWithTags(joke, joketags), nil
}

// GetAllTags retrieves all available tags
func (s *JokeService) GetAllTags(ctx context.Context) ([]string, error) {
	tags, err := s.queries.GetAllTags(ctx)
	if err != nil {
		s.logger.Error("failed to get all tags", "error", err)
		return nil, fmt.Errorf("failed to get all tags: %w", err)
	}

	return tags, nil
}
