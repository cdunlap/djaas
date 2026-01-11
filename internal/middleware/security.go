package middleware

import (
	"net/http"
	"strings"
)

// SecurityHeaders adds security headers to all responses
func SecurityHeaders() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Prevent browsers from interpreting files as something other than declared by content type
			w.Header().Set("X-Content-Type-Options", "nosniff")

			// Enable browser XSS protection
			w.Header().Set("X-XSS-Protection", "1; mode=block")

			// Prevent clickjacking attacks
			w.Header().Set("X-Frame-Options", "DENY")

			// Force HTTPS connections
			w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")

			// Control what features and APIs can be used in the browser
			w.Header().Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

			// Referrer policy
			w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

			// Content Security Policy - relaxed for Swagger UI
			if strings.HasPrefix(r.URL.Path, "/swagger/") {
				// Swagger UI requires inline scripts and styles
				w.Header().Set("Content-Security-Policy",
					"default-src 'self'; "+
					"script-src 'self' 'unsafe-inline'; "+
					"style-src 'self' 'unsafe-inline'; "+
					"img-src 'self' data:; "+
					"font-src 'self'; "+
					"connect-src 'self'; "+
					"frame-ancestors 'none'; "+
					"base-uri 'self'; "+
					"form-action 'self'")
			} else {
				// Strict CSP for application routes
				w.Header().Set("Content-Security-Policy",
					"default-src 'self'; "+
					"script-src 'self'; "+
					"style-src 'self' 'unsafe-inline'; "+
					"img-src 'self' data:; "+
					"font-src 'self'; "+
					"connect-src 'self'; "+
					"frame-ancestors 'none'; "+
					"base-uri 'self'; "+
					"form-action 'self'")
			}

			next.ServeHTTP(w, r)
		})
	}
}
