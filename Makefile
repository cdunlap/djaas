.PHONY: help build run test clean docker-build docker-up docker-down migrate-up migrate-down seed sqlc-generate deps tidy

help:
	@echo "Available commands:"
	@echo "  make build         - Build the Go binary"
	@echo "  make run           - Run the application locally"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-up     - Start docker-compose services"
	@echo "  make docker-down   - Stop docker-compose services"
	@echo "  make migrate-up    - Run database migrations up"
	@echo "  make migrate-down  - Run database migrations down"
	@echo "  make seed          - Seed database with jokes"
	@echo "  make sqlc-generate - Generate sqlc code"
	@echo "  make deps          - Download dependencies"
	@echo "  make tidy          - Tidy go.mod"

build:
	@echo "Building application..."
	go build -o bin/api cmd/api/main.go

run:
	@echo "Running application..."
	go run cmd/api/main.go

test:
	@echo "Running tests..."
	go test -v ./...

clean:
	@echo "Cleaning..."
	rm -rf bin/
	go clean

docker-build:
	@echo "Building Docker image..."
	docker build -f docker/Dockerfile -t djaas:latest .

docker-up:
	@echo "Starting docker-compose services..."
	docker-compose up -d

docker-down:
	@echo "Stopping docker-compose services..."
	docker-compose down

migrate-up:
	@echo "Running migrations up..."
	@if command -v migrate >/dev/null 2>&1; then \
		migrate -path migrations -database "postgresql://djaas:djaas_dev@localhost:5432/djaas?sslmode=disable" up; \
	else \
		echo "Error: golang-migrate is not installed. Install it with:"; \
		echo "  go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"; \
	fi

migrate-down:
	@echo "Running migrations down..."
	@if command -v migrate >/dev/null 2>&1; then \
		migrate -path migrations -database "postgresql://djaas:djaas_dev@localhost:5432/djaas?sslmode=disable" down; \
	else \
		echo "Error: golang-migrate is not installed"; \
	fi

seed:
	@echo "Seeding database..."
	@if command -v psql >/dev/null 2>&1; then \
		psql -h localhost -U djaas -d djaas -f scripts/seed.sql; \
	else \
		echo "Error: psql is not installed"; \
	fi

sqlc-generate:
	@echo "Generating sqlc code..."
	@if command -v sqlc >/dev/null 2>&1; then \
		sqlc generate; \
	else \
		echo "Error: sqlc is not installed. Install it with:"; \
		echo "  go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest"; \
	fi

deps:
	@echo "Downloading dependencies..."
	go mod download

tidy:
	@echo "Tidying go.mod..."
	go mod tidy
