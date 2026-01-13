package middleware

import (
	"net/http"
	"os"
)

// SimpleAuth checks for a valid API token in the X-API-Token header
func SimpleAuth() func(http.Handler) http.Handler {
	// Get the API token from environment variable
	apiToken := os.Getenv("API_TOKEN")
	if apiToken == "" {
		apiToken = "default-secret-token" // Fallback for development
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := r.Header.Get("X-API-Token")

			if token == "" {
				http.Error(w, `{"error":"Missing X-API-Token header"}`, http.StatusUnauthorized)
				return
			}

			if token != apiToken {
				http.Error(w, `{"error":"Invalid API token"}`, http.StatusUnauthorized)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
