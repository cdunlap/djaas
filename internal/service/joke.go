package service

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"github.com/cdunlap/djaas/internal/database"
	"github.com/cdunlap/djaas/internal/model"
	"github.com/jackc/pgx/v5"
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

	joke, err := s.queries.SearchJokes(ctx, query)
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

	joke, err := s.queries.GetJokeByCategory(ctx, category)
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

	joke, err := s.queries.GetJokeByCategoryAndSearch(ctx, category, query)
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
func (s *JokeService) buildJokeWithTags(dbJoke *database.Joke, tags []string) *model.Joke {
	return &model.Joke{
		ID:        dbJoke.ID,
		Setup:     dbJoke.Setup,
		Punchline: dbJoke.Punchline,
		Category:  dbJoke.Category,
		Tags:      tags,
		CreatedAt: dbJoke.CreatedAt,
		UpdatedAt: dbJoke.UpdatedAt,
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

	joke, err := s.queries.GetJokeByTagsAndCategory(ctx, tags, category)
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

	joke, err := s.queries.GetJokeByTagsAndSearch(ctx, tags, searchQuery)
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

	joke, err := s.queries.GetJokeByAllFilters(ctx, tags, category, searchQuery)
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
