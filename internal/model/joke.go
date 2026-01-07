package model

import "time"

// Joke represents a dad joke
type Joke struct {
	ID        int32     `json:"id"`
	Setup     string    `json:"setup"`
	Punchline string    `json:"punchline"`
	Category  *string   `json:"category,omitempty"`
	Tags      []string  `json:"tags"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
}

// HealthResponse represents a health check response
type HealthResponse struct {
	Status    string `json:"status"`
	Database  string `json:"database"`
	Timestamp string `json:"timestamp"`
}
