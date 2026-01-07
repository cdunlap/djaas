# DJaaS - Dad Joke as a Service

A production-ready REST API for serving dad jokes, built with Go and deployable to any cloud platform via Docker.

## Features

- **Random Jokes**: Get a random dad joke on demand
- **Search**: Search for jokes containing specific keywords
- **Categories**: Filter jokes by category (general, food, animals, science, technology, sports, dad)
- **Tags**: Filter jokes by tags for more granular searching (wordplay, puns, clever, etc.)
- **Combined Filtering**: Mix and match tags, categories, and search queries
- **Rate Limiting**: Built-in per-IP rate limiting to prevent abuse
- **Health Checks**: Health endpoint for monitoring and load balancers
- **Cloud-Ready**: Containerized for deployment to AWS, GCP, Azure, or Kubernetes
- **Production-Grade**: Structured logging, graceful shutdown, panic recovery

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [Go 1.22+](https://golang.org/dl/) (for local development)
- [PostgreSQL 16](https://www.postgresql.org/download/) (for local development without Docker)

### Running with Docker Compose (Recommended)

1. Clone the repository:
```bash
git clone <repository-url>
cd djaas
```

2. Start the services:
```bash
docker-compose up -d
```

3. Run database migrations:
```bash
# Install golang-migrate if you haven't already
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run migrations
make migrate-up
```

4. Seed the database with jokes:
```bash
make seed
```

5. Seed the tags (run after seeding jokes):
```bash
docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed_tags.sql
```

6. Test the API:
```bash
# Get a random joke
curl http://localhost:8080/api/v1/joke

# Search for jokes
curl http://localhost:8080/api/v1/joke?search=dog

# Filter by category
curl http://localhost:8080/api/v1/joke?category=food

# Filter by tags
curl "http://localhost:8080/api/v1/joke?tags=wordplay"

# Combine tags and category
curl "http://localhost:8080/api/v1/joke?tags=puns&category=science"

# Health check
curl http://localhost:8080/health
```

### Running Locally (Without Docker)

1. Install dependencies:
```bash
make deps
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

3. Start PostgreSQL and create the database:
```bash
createdb djaas
```

4. Run migrations and seed data:
```bash
make migrate-up
make seed
```

5. Run the application:
```bash
make run
```

## API Documentation

### Endpoints

#### Get a Random Joke

```http
GET /api/v1/joke
```

**Response:**
```json
{
  "id": 42,
  "setup": "Why don't scientists trust atoms?",
  "punchline": "Because they make up everything!",
  "category": "science",
  "tags": ["wordplay", "chemistry", "clever", "dad-humor"],
  "created_at": "2026-01-06T10:00:00Z",
  "updated_at": "2026-01-06T10:00:00Z"
}
```

#### Search for Jokes

```http
GET /api/v1/joke?search=dog
```

Searches both setup and punchline for the keyword.

#### Filter by Category

```http
GET /api/v1/joke?category=food
```

Available categories: `general`, `food`, `animals`, `science`, `technology`, `sports`, `dad`

#### Combine Category and Search

```http
GET /api/v1/joke?category=food&search=pizza
```

#### Filter by Tags

```http
GET /api/v1/joke?tags=wordplay
```

Filter by one or more tags (comma-separated). Returns jokes matching ANY of the provided tags (OR logic).

**Multiple tags:**
```http
GET /api/v1/joke?tags=wordplay,puns
```

**Available tags:**
- **Style**: wordplay, puns, dad-humor, one-liner, clever, silly, groan-worthy
- **Science**: science, chemistry, physics, biology, math
- **Food**: food, cooking, pizza, pasta, cheese, fruit
- **Animals**: animals, dogs, cats, birds, fish, bears
- **Technology**: technology, computers, programming
- **Sports**: sports, golf, soccer, basketball
- **Other**: dad, family, meta

#### Combine Tags with Other Filters

```http
# Tags + category
GET /api/v1/joke?tags=puns&category=science

# Tags + search
GET /api/v1/joke?tags=animals&search=dog

# Tags + category + search (all three!)
GET /api/v1/joke?tags=wordplay&category=food&search=cheese
```

#### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-01-06T10:00:00Z"
}
```

### Error Responses

All errors return JSON with the following format:

```json
{
  "error": "error_code",
  "message": "Human-readable error message"
}
```

**Status Codes:**
- `200 OK`: Success
- `400 Bad Request`: Invalid parameters
- `404 Not Found`: No jokes found matching criteria
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Database unavailable

### Rate Limiting

The API implements per-IP rate limiting with the following default limits:
- **10 requests per minute** per IP address
- **Disabled in development mode** (when `ENV=development`)

Rate limit information is included in response headers (production only):
```
X-RateLimit-Limit: 10
X-RateLimit-Window: 1m
Retry-After: 60  (only when rate limit is exceeded)
```

## Configuration

Configuration is done via environment variables. See `.env.example` for all available options.

### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `ENV` | `development` | Environment (development/production) |
| `LOG_LEVEL` | `info` | Log level (debug/info/warn/error) |

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `djaas` | Database user |
| `DB_PASSWORD` | - | Database password |
| `DB_NAME` | `djaas` | Database name |
| `DB_SSLMODE` | `disable` | SSL mode (disable/require) |
| `DB_MAX_CONNECTIONS` | `25` | Maximum connection pool size |
| `DB_MAX_IDLE_CONNECTIONS` | `5` | Maximum idle connections |

### Rate Limiting Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RATE_LIMIT_REQUESTS` | `10` | Number of requests allowed |
| `RATE_LIMIT_WINDOW` | `1m` | Time window (e.g., 1m, 60s) |

## Development

### Project Structure

```
djaas/
├── cmd/api/              # Application entry point
├── internal/
│   ├── config/          # Configuration management
│   ├── database/        # Database connection and queries
│   ├── handler/         # HTTP handlers
│   ├── middleware/      # HTTP middleware
│   ├── model/           # Domain models
│   └── service/         # Business logic
├── migrations/          # Database migrations
├── scripts/             # Utility scripts and seed data
├── docker/              # Docker configuration
└── sqlc/               # SQL query definitions
```

### Available Commands

```bash
make help           # Show all available commands
make build          # Build the Go binary
make run            # Run the application locally
make test           # Run tests
make clean          # Clean build artifacts

make docker-build   # Build Docker image
make docker-up      # Start docker-compose services
make docker-down    # Stop docker-compose services

make migrate-up     # Run database migrations up
make migrate-down   # Run database migrations down
make seed           # Seed database with jokes

make deps           # Download dependencies
make tidy           # Tidy go.mod
```

### Adding New Jokes

1. Edit `scripts/seed.sql` and add your jokes
2. Re-run the seed script:
```bash
make seed
```

Or insert directly via SQL:
```sql
INSERT INTO jokes (setup, punchline, category)
VALUES ('Your setup here', 'Your punchline here', 'general');
```

## Cloud Deployment

The application is cloud-agnostic and can be deployed to any platform that supports Docker containers.

### Automated Deployment Scripts

We provide automated deployment scripts for easy cloud deployment:

#### **Google Cloud Run (Recommended - Best Free Tier)**

**Free Tier Benefits:**
- 2 million requests/month FREE
- 360,000 GB-seconds/month FREE
- $300 credit for 90 days
- Perfect for hobby projects and testing

**Deploy in 15 minutes:**
```powershell
# Windows PowerShell
cd deploy\gcp
.\deploy.ps1

# Linux/macOS/WSL
cd deploy/gcp
./deploy.sh
```

**What you get:**
- Cloud Run serverless deployment
- Cloud SQL PostgreSQL database
- Automatic SSL/HTTPS
- Auto-scaling from 0 to N
- Full monitoring and logging

📖 **See [deploy/gcp/README.md](deploy/gcp/README.md) for detailed instructions**

#### **Azure Container Apps**

**Free Tier Benefits:**
- $200 free credit for 30 days
- Azure for Students: $100 credit annually

**Deploy:**
```powershell
# Windows PowerShell
cd deploy\azure
.\deploy.ps1

# Linux/macOS/WSL
cd deploy/azure
./deploy.sh
```

**What you get:**
- Azure Container Apps deployment
- Azure Database for PostgreSQL
- Azure Key Vault for secrets
- Auto-scaling and load balancing

📖 **See [deploy/azure/README.md](deploy/azure/README.md) for detailed instructions**

### Other Cloud Platforms

#### AWS ECS

```bash
# Build and push to ECR
docker build -f docker/Dockerfile -t djaas:latest .
docker tag djaas:latest <account-id>.dkr.ecr.<region>.amazonaws.com/djaas:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/djaas:latest

# Create RDS PostgreSQL instance
# Create ECS task definition
# Deploy to ECS cluster
```

#### Kubernetes

Example deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: djaas
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: djaas
        image: your-registry/djaas:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
```

## Architecture

### Tech Stack

- **Language**: Go 1.22+
- **HTTP Framework**: chi (lightweight, composable router)
- **Database**: PostgreSQL 16 with pgx driver
- **Migrations**: golang-migrate
- **Rate Limiting**: Token bucket algorithm (in-memory)
- **Logging**: slog (structured logging)

### Key Features

**Rate Limiting**
- In-memory per-IP token bucket implementation
- Configurable requests per time window
- Returns 429 with Retry-After header when exceeded
- For multi-instance deployments, consider Redis-based rate limiting

**Search**
- PostgreSQL full-text search using pg_trgm extension
- Searches both setup and punchline fields
- Case-insensitive matching
- Returns random matching joke

**Error Handling**
- Structured JSON error responses
- Appropriate HTTP status codes
- Internal errors logged but not exposed to clients
- Panic recovery middleware

**Database**
- Connection pooling for performance
- Prepared statements via queries
- Retry logic on startup
- Health check endpoint

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
