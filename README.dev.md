# Development Guide

## Hot Reload Development Environment

DJaaS includes a development setup with automatic code reloading using [Air](https://github.com/air-verse/air).

### Quick Start

**Start dev environment with hot reload:**
```bash
make.bat dev-up
```

This will:
- Start PostgreSQL database
- Start API server with Air hot reload
- Watch for Go file changes and auto-rebuild
- Mount source code as a volume

**Stop dev environment:**
```bash
make.bat dev-down
```

### How It Works

1. **Air** watches your Go files for changes
2. When you save a file, Air automatically:
   - Rebuilds the Go binary
   - Restarts the server
   - Shows build errors in real-time

3. **Volume Mounting** - Your local code is mounted into the container:
   - Edit files locally with your IDE
   - Changes are instantly picked up by Air
   - No need to rebuild the container

### What Gets Watched

Air watches these files (configured in `.air.toml`):
- All `.go` files in the project
- Excludes: `tmp/`, `vendor/`, `testdata/`, `migrations/`, `scripts/`, `public/`, `docker/`
- Excludes: `*_test.go` files

### Development Workflow

1. **Start the dev environment:**
   ```bash
   make.bat dev-up
   ```

2. **Edit your code** - Any changes to Go files will trigger a rebuild

3. **View logs in real-time:**
   ```bash
   docker logs -f djaas-api-dev
   ```

4. **Test your changes:**
   ```bash
   curl http://localhost:8080/api/v1/joke
   ```

5. **Stop when done:**
   ```bash
   make.bat dev-down
   ```

### Files

- **`.air.toml`** - Air configuration
- **`docker-compose.dev.yml`** - Dev environment docker-compose
- **`docker/Dockerfile.dev`** - Dev Dockerfile with Air installed

### Differences: Dev vs Production

| Feature | Development (`dev-up`) | Production (`docker-up`) |
|---------|------------------------|--------------------------|
| Hot Reload | ✅ Yes (Air) | ❌ No |
| Code Mounting | ✅ Volume mount | ❌ Copied into image |
| Image Size | Larger (includes Go toolchain) | Smaller (Alpine runtime) |
| Build Speed | Instant (Air) | Slower (full rebuild) |
| Database | Separate dev volume | Separate prod volume |

### Troubleshooting

**Air not rebuilding on Windows (Docker Desktop):**

File system notifications don't work properly with Docker Desktop on Windows. The `.air.toml` is already configured with polling enabled:
```toml
poll = true
poll_interval = 1000  # Check for changes every second
```

If hot reload still doesn't work:
1. Verify Air is running: `docker logs -f djaas-api-dev`
2. Make a change and save a `.go` file
3. Wait 1-2 seconds for the poll interval
4. Check logs for rebuild messages

**Air not rebuilding (general):**
- Check that you saved the file
- Look for build errors in logs: `docker logs djaas-api-dev`
- Verify the file isn't in an excluded directory

**Port already in use:**
```bash
# Stop all containers first
make.bat dev-down
make.bat docker-down

# Then start dev environment
make.bat dev-up
```

**Database issues:**
```bash
# Reset dev database
make.bat dev-down
docker volume rm djaas_postgres_data_dev
make.bat dev-up

# Re-run migrations
docker-compose -f docker-compose.dev.yml exec postgres psql -U djaas -d djaas -f /migrations/000001_init.up.sql
```

### Tips

1. **Keep dev environment running** - Leave `dev-up` running while you code
2. **Multiple terminals** - Run `dev-up` in one terminal, keep another free for commands
3. **Fast iteration** - Edit → Save → Air rebuilds → Test (seconds!)
4. **Frontend changes** - HTML/CSS/JS changes are instant (no rebuild needed)

### Example Session

```bash
# Terminal 1: Start dev environment
C:\...\djaas> make.bat dev-up
Starting development environment with hot reload...
[+] Building...
[+] Running 2/2
✔ Container djaas-postgres-dev  Started
✔ Container djaas-api-dev       Started

# Edit internal/handler/joke.go in your IDE
# Save the file

# Air automatically rebuilds:
# building...
# running...
# server starting addr=:8080

# Terminal 2: Test your changes
C:\...\djaas> curl http://localhost:8080/api/v1/joke
{"id":42,"setup":"...","punchline":"..."}

# When done:
C:\...\djaas> make.bat dev-down
```

Happy coding! 🚀
