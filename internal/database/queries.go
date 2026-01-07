package database

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Joke represents a dad joke
type Joke struct {
	ID         int32     `json:"id"`
	Setup      string    `json:"setup"`
	Punchline  string    `json:"punchline"`
	Category   *string   `json:"category,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

// Queries provides database query methods
type Queries struct {
	pool *pgxpool.Pool
}

// New creates a new Queries instance
func New(pool *pgxpool.Pool) *Queries {
	return &Queries{pool: pool}
}

// GetRandomJoke retrieves a random joke from the database
func (q *Queries) GetRandomJoke(ctx context.Context) (*Joke, error) {
	query := `
		SELECT id, setup, punchline, category, created_at, updated_at
		FROM jokes
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// SearchJokes searches for jokes containing the query string
func (q *Queries) SearchJokes(ctx context.Context, searchQuery string) (*Joke, error) {
	query := `
		SELECT id, setup, punchline, category, created_at, updated_at
		FROM jokes
		WHERE setup ILIKE '%' || $1 || '%'
		   OR punchline ILIKE '%' || $1 || '%'
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, searchQuery).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetJokeByCategory retrieves a random joke from a specific category
func (q *Queries) GetJokeByCategory(ctx context.Context, category string) (*Joke, error) {
	query := `
		SELECT id, setup, punchline, category, created_at, updated_at
		FROM jokes
		WHERE category = $1
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, category).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetJokeByCategoryAndSearch retrieves a random joke from a specific category matching the search query
func (q *Queries) GetJokeByCategoryAndSearch(ctx context.Context, category string, searchQuery string) (*Joke, error) {
	query := `
		SELECT id, setup, punchline, category, created_at, updated_at
		FROM jokes
		WHERE category = $1
		  AND (setup ILIKE '%' || $2 || '%' OR punchline ILIKE '%' || $2 || '%')
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, category, searchQuery).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetTagsForJoke retrieves all tags for a specific joke
func (q *Queries) GetTagsForJoke(ctx context.Context, jokeID int32) ([]string, error) {
	query := `
		SELECT t.name
		FROM tags t
		INNER JOIN joke_tags jt ON t.id = jt.tag_id
		WHERE jt.joke_id = $1
		ORDER BY t.name
	`

	rows, err := q.pool.Query(ctx, query, jokeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tags []string
	for rows.Next() {
		var tag string
		if err := rows.Scan(&tag); err != nil {
			return nil, err
		}
		tags = append(tags, tag)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Return empty slice instead of nil if no tags found
	if tags == nil {
		tags = []string{}
	}

	return tags, nil
}

// GetJokeByTags retrieves a random joke matching any of the provided tags (OR logic)
func (q *Queries) GetJokeByTags(ctx context.Context, tags []string) (*Joke, error) {
	query := `
		SELECT DISTINCT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
		FROM jokes j
		INNER JOIN joke_tags jt ON j.id = jt.joke_id
		INNER JOIN tags t ON jt.tag_id = t.id
		WHERE t.name = ANY($1::text[])
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, tags).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetJokeByTagsAndCategory retrieves a random joke matching tags and category
func (q *Queries) GetJokeByTagsAndCategory(ctx context.Context, tags []string, category string) (*Joke, error) {
	query := `
		SELECT DISTINCT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
		FROM jokes j
		INNER JOIN joke_tags jt ON j.id = jt.joke_id
		INNER JOIN tags t ON jt.tag_id = t.id
		WHERE t.name = ANY($1::text[])
		  AND j.category = $2
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, tags, category).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetJokeByTagsAndSearch retrieves a random joke matching tags and search query
func (q *Queries) GetJokeByTagsAndSearch(ctx context.Context, tags []string, searchQuery string) (*Joke, error) {
	query := `
		SELECT DISTINCT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
		FROM jokes j
		INNER JOIN joke_tags jt ON j.id = jt.joke_id
		INNER JOIN tags t ON jt.tag_id = t.id
		WHERE t.name = ANY($1::text[])
		  AND (j.setup ILIKE '%' || $2 || '%' OR j.punchline ILIKE '%' || $2 || '%')
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, tags, searchQuery).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}

// GetJokeByAllFilters retrieves a random joke matching tags, category, and search query
func (q *Queries) GetJokeByAllFilters(ctx context.Context, tags []string, category string, searchQuery string) (*Joke, error) {
	query := `
		SELECT DISTINCT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
		FROM jokes j
		INNER JOIN joke_tags jt ON j.id = jt.joke_id
		INNER JOIN tags t ON jt.tag_id = t.id
		WHERE t.name = ANY($1::text[])
		  AND j.category = $2
		  AND (j.setup ILIKE '%' || $3 || '%' OR j.punchline ILIKE '%' || $3 || '%')
		ORDER BY RANDOM()
		LIMIT 1
	`

	var joke Joke
	err := q.pool.QueryRow(ctx, query, tags, category, searchQuery).Scan(
		&joke.ID,
		&joke.Setup,
		&joke.Punchline,
		&joke.Category,
		&joke.CreatedAt,
		&joke.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &joke, nil
}
