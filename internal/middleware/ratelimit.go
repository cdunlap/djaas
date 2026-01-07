package middleware

import (
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// IPRateLimiter manages rate limiters for different IPs
type IPRateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
}

// NewIPRateLimiter creates a new IP rate limiter
func NewIPRateLimiter(requests int, window time.Duration) *IPRateLimiter {
	r := rate.Every(window / time.Duration(requests))
	return &IPRateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     r,
		burst:    requests,
	}
}

// GetLimiter returns the rate limiter for the given IP
func (i *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
	i.mu.Lock()
	defer i.mu.Unlock()

	limiter, exists := i.limiters[ip]
	if !exists {
		limiter = rate.NewLimiter(i.rate, i.burst)
		i.limiters[ip] = limiter
	}

	return limiter
}

// RateLimit creates a rate limiting middleware
func RateLimit(requests int, window time.Duration) func(http.Handler) http.Handler {
	limiter := NewIPRateLimiter(requests, window)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := getIP(r)
			rateLimiter := limiter.GetLimiter(ip)

			if !rateLimiter.Allow() {
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", requests))
				w.Header().Set("X-RateLimit-Window", window.String())
				w.Header().Set("Retry-After", "60")
				w.WriteHeader(http.StatusTooManyRequests)
				w.Write([]byte(`{"error":"rate_limit_exceeded","message":"Too many requests, please try again later"}`))
				return
			}

			// Add rate limit headers to successful requests
			w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", requests))
			w.Header().Set("X-RateLimit-Window", window.String())

			next.ServeHTTP(w, r)
		})
	}
}

// getIP extracts the real IP address from the request
func getIP(r *http.Request) string {
	// Check X-Forwarded-For header (for requests behind a proxy)
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		// X-Forwarded-For can contain multiple IPs, take the first one
		ips := parseForwardedFor(forwarded)
		if len(ips) > 0 {
			return ips[0]
		}
	}

	// Check X-Real-IP header
	realIP := r.Header.Get("X-Real-IP")
	if realIP != "" {
		return realIP
	}

	// Fall back to RemoteAddr
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return ip
}

// parseForwardedFor parses the X-Forwarded-For header
func parseForwardedFor(header string) []string {
	var ips []string
	for i := 0; i < len(header); {
		// Skip spaces
		for i < len(header) && header[i] == ' ' {
			i++
		}
		// Find the end of the IP
		start := i
		for i < len(header) && header[i] != ',' {
			i++
		}
		if start < i {
			ips = append(ips, header[start:i])
		}
		// Skip the comma
		if i < len(header) && header[i] == ',' {
			i++
		}
	}
	return ips
}
