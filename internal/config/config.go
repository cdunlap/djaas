package config

import (
	"fmt"
	"log"
	"time"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

type Config struct {
	Server    ServerConfig
	Database  DatabaseConfig
	RateLimit RateLimitConfig
}

type ServerConfig struct {
	Port     string
	Env      string
	LogLevel string
}

type DatabaseConfig struct {
	Host            string
	Port            string
	User            string
	Password        string
	DBName          string
	SSLMode         string
	MaxConnections  int32
	MaxIdleConns    int32
}

type RateLimitConfig struct {
	Requests int
	Window   time.Duration
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists (for local development)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	viper.AutomaticEnv()

	// Set defaults
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("ENV", "development")
	viper.SetDefault("LOG_LEVEL", "info")

	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("DB_PORT", "5432")
	viper.SetDefault("DB_USER", "djaas")
	viper.SetDefault("DB_PASSWORD", "")
	viper.SetDefault("DB_NAME", "djaas")
	viper.SetDefault("DB_SSLMODE", "disable")
	viper.SetDefault("DB_MAX_CONNECTIONS", 25)
	viper.SetDefault("DB_MAX_IDLE_CONNECTIONS", 5)

	viper.SetDefault("RATE_LIMIT_REQUESTS", 10)
	viper.SetDefault("RATE_LIMIT_WINDOW", "1m")

	// Parse rate limit window
	windowStr := viper.GetString("RATE_LIMIT_WINDOW")
	window, err := time.ParseDuration(windowStr)
	if err != nil {
		return nil, fmt.Errorf("invalid RATE_LIMIT_WINDOW: %w", err)
	}

	cfg := &Config{
		Server: ServerConfig{
			Port:     viper.GetString("PORT"),
			Env:      viper.GetString("ENV"),
			LogLevel: viper.GetString("LOG_LEVEL"),
		},
		Database: DatabaseConfig{
			Host:            viper.GetString("DB_HOST"),
			Port:            viper.GetString("DB_PORT"),
			User:            viper.GetString("DB_USER"),
			Password:        viper.GetString("DB_PASSWORD"),
			DBName:          viper.GetString("DB_NAME"),
			SSLMode:         viper.GetString("DB_SSLMODE"),
			MaxConnections:  int32(viper.GetInt("DB_MAX_CONNECTIONS")),
			MaxIdleConns:    int32(viper.GetInt("DB_MAX_IDLE_CONNECTIONS")),
		},
		RateLimit: RateLimitConfig{
			Requests: viper.GetInt("RATE_LIMIT_REQUESTS"),
			Window:   window,
		},
	}

	// Validate required fields
	if err := cfg.Validate(); err != nil {
		return nil, err
	}

	return cfg, nil
}

// Validate checks if the configuration is valid
func (c *Config) Validate() error {
	if c.Database.Host == "" {
		return fmt.Errorf("DB_HOST is required")
	}
	if c.Database.User == "" {
		return fmt.Errorf("DB_USER is required")
	}
	if c.Database.DBName == "" {
		return fmt.Errorf("DB_NAME is required")
	}
	if c.RateLimit.Requests <= 0 {
		return fmt.Errorf("RATE_LIMIT_REQUESTS must be greater than 0")
	}
	if c.RateLimit.Window <= 0 {
		return fmt.Errorf("RATE_LIMIT_WINDOW must be greater than 0")
	}

	return nil
}
