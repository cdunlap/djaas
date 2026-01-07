# Windows Quick Start Guide

This guide helps you get the Dad Joke as a Service app running on Windows.

## Option 1: Using Docker (Recommended for Windows)

This is the easiest way to run the application on Windows.

### Prerequisites
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)

### Steps

1. **Start Docker Desktop** (make sure it's running)

2. **Start the services:**
   ```cmd
   docker-compose up -d
   ```

3. **Run migrations:**
   ```cmd
   docker-compose exec postgres sh -c "cd /migrations && psql -U djaas -d djaas -f 000001_create_jokes_table.up.sql && psql -U djaas -d djaas -f 000002_add_indexes.up.sql && psql -U djaas -d djaas -f 000003_add_tags.up.sql"
   ```

4. **Seed the database with jokes:**
   ```cmd
   docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed.sql
   ```

5. **Seed the tags:**
   ```cmd
   docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed_tags.sql
   ```

6. **Test the API:**
   ```cmd
   curl http://localhost:8080/api/v1/joke
   ```

   Or open in your browser: http://localhost:8080/api/v1/joke

7. **View logs:**
   ```cmd
   docker-compose logs -f api
   ```

8. **Stop services when done:**
   ```cmd
   docker-compose down
   ```

## Option 2: Using the Batch File Helper

Instead of `make`, use `make.bat`:

```cmd
make.bat help          # Show all commands
make.bat build         # Build the application
make.bat run           # Run the application
make.bat docker-up     # Start Docker services
make.bat docker-down   # Stop Docker services
```

## Common Commands Cheat Sheet

### Docker Commands (No installation needed besides Docker Desktop)

```cmd
# Start everything
docker-compose up -d

# Run migrations (first time only)
docker-compose exec postgres sh -c "cd /migrations && psql -U djaas -d djaas -f 000001_create_jokes_table.up.sql && psql -U djaas -d djaas -f 000002_add_indexes.up.sql && psql -U djaas -d djaas -f 000003_add_tags.up.sql"

# Seed database (first time only)
docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed.sql

# Seed tags (first time only, after seeding jokes)
docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed_tags.sql

# View API logs
docker-compose logs -f api

# View database logs
docker-compose logs -f postgres

# Restart API only
docker-compose restart api

# Rebuild API after code changes
docker-compose up -d --build api

# Stop everything
docker-compose down

# Stop and remove all data (fresh start)
docker-compose down -v
```

### Testing the API

**Using curl (if installed):**
```cmd
# Random joke
curl http://localhost:8080/api/v1/joke

# Search for jokes
curl "http://localhost:8080/api/v1/joke?search=dog"

# Filter by category
curl "http://localhost:8080/api/v1/joke?category=food"

# Filter by tags
curl "http://localhost:8080/api/v1/joke?tags=wordplay"

# Multiple tags (OR logic)
curl "http://localhost:8080/api/v1/joke?tags=wordplay,puns"

# Tags + category
curl "http://localhost:8080/api/v1/joke?tags=puns&category=science"

# Tags + search
curl "http://localhost:8080/api/v1/joke?tags=animals&search=dog"

# All filters combined
curl "http://localhost:8080/api/v1/joke?tags=wordplay&category=food&search=cheese"

# Health check
curl http://localhost:8080/health
```

**Using PowerShell:**
```powershell
# Random joke
Invoke-RestMethod http://localhost:8080/api/v1/joke

# Search for jokes
Invoke-RestMethod "http://localhost:8080/api/v1/joke?search=dog"

# Filter by category
Invoke-RestMethod "http://localhost:8080/api/v1/joke?category=food"

# Filter by tags
Invoke-RestMethod "http://localhost:8080/api/v1/joke?tags=wordplay"

# Multiple tags
Invoke-RestMethod "http://localhost:8080/api/v1/joke?tags=wordplay,puns"

# Tags + category
Invoke-RestMethod "http://localhost:8080/api/v1/joke?tags=puns&category=science"

# Tags + search
Invoke-RestMethod "http://localhost:8080/api/v1/joke?tags=animals&search=dog"

# Health check
Invoke-RestMethod http://localhost:8080/health
```

**Using your browser:**
- Random joke: http://localhost:8080/api/v1/joke
- Search: http://localhost:8080/api/v1/joke?search=pizza
- Category: http://localhost:8080/api/v1/joke?category=science
- Tags: http://localhost:8080/api/v1/joke?tags=wordplay
- Tags + category: http://localhost:8080/api/v1/joke?tags=puns&category=food
- Health: http://localhost:8080/health

**Available tags:**
- **Style**: wordplay, puns, dad-humor, one-liner, clever, silly, groan-worthy
- **Science**: science, chemistry, physics, biology, math
- **Food**: food, cooking, pizza, pasta, cheese, fruit
- **Animals**: animals, dogs, cats, birds, fish, bears
- **Technology**: technology, computers, programming
- **Sports**: sports, golf, soccer, basketball
- **Other**: dad, family, meta

## Troubleshooting

### Port 8080 already in use
If another application is using port 8080, you can change it:

1. Edit `docker-compose.yml` and change `"8080:8080"` to `"3000:8080"` (or any other port)
2. Restart: `docker-compose down && docker-compose up -d`
3. Access at: http://localhost:3000/api/v1/joke

### Port 5432 already in use (PostgreSQL running locally)
If you have PostgreSQL already running on Windows:

1. Edit `docker-compose.yml` and change `"5432:5432"` to `"5433:5432"`
2. Restart: `docker-compose down && docker-compose up -d`

### Docker Desktop not starting
- Make sure WSL 2 is installed and enabled
- Check Docker Desktop settings
- Restart your computer

### Cannot connect to database
1. Check if PostgreSQL container is running:
   ```cmd
   docker-compose ps
   ```

2. Check PostgreSQL logs:
   ```cmd
   docker-compose logs postgres
   ```

3. Wait a few seconds for PostgreSQL to fully start, then try again

### Database is empty (no jokes returned)
Run the seed command again:
```cmd
docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed.sql
```

## Development on Windows

If you want to develop and run the Go code directly on Windows:

### Prerequisites
- [Go 1.22+](https://golang.org/dl/)
- [PostgreSQL 16](https://www.postgresql.org/download/windows/)

### Setup

1. **Install Go** from the link above

2. **Install PostgreSQL** and create database:
   ```cmd
   createdb djaas
   ```

3. **Set environment variables** (create `.env` file):
   ```cmd
   copy .env.example .env
   ```

   Edit `.env` with your database password

4. **Install dependencies:**
   ```cmd
   go mod download
   ```

5. **Install migration tool:**
   ```cmd
   go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
   ```

6. **Run migrations:**
   ```cmd
   migrate -path migrations -database "postgresql://djaas:YOUR_PASSWORD@localhost:5432/djaas?sslmode=disable" up
   ```

7. **Seed database:**
   ```cmd
   psql -U djaas -d djaas -f scripts\seed.sql
   ```

8. **Run the application:**
   ```cmd
   go run cmd\api\main.go
   ```

## Deploying to Cloud from Windows

All the cloud deployment commands in the README work from Windows Command Prompt or PowerShell. Just make sure you have:

- **AWS**: [AWS CLI](https://aws.amazon.com/cli/)
- **GCP**: [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- **Azure**: [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)

## Next Steps

- Check out the main [README.md](README.md) for API documentation
- Explore the code in the `internal/` directory
- Add more jokes to `scripts/seed.sql`
- Customize rate limits in `docker-compose.yml` or `.env`

## Getting Help

If you run into issues:
1. Check the logs: `docker-compose logs -f`
2. Ensure Docker Desktop is running
3. Try stopping and starting fresh: `docker-compose down -v && docker-compose up -d`
