@echo off
setlocal

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="test" goto test
if "%1"=="clean" goto clean
if "%1"=="docker-build" goto docker-build
if "%1"=="docker-up" goto docker-up
if "%1"=="docker-down" goto docker-down
if "%1"=="migrate-up" goto migrate-up
if "%1"=="migrate-down" goto migrate-down
if "%1"=="seed" goto seed
if "%1"=="deps" goto deps
if "%1"=="tidy" goto tidy

echo Unknown command: %1
goto help

:help
echo Available commands:
echo   make.bat build         - Build the Go binary
echo   make.bat run           - Run the application locally
echo   make.bat test          - Run tests
echo   make.bat clean         - Clean build artifacts
echo   make.bat docker-build  - Build Docker image
echo   make.bat docker-up     - Start docker-compose services
echo   make.bat docker-down   - Stop docker-compose services
echo   make.bat migrate-up    - Run database migrations up
echo   make.bat migrate-down  - Run database migrations down
echo   make.bat seed          - Seed database with jokes
echo   make.bat deps          - Download dependencies
echo   make.bat tidy          - Tidy go.mod
goto end

:build
echo Building application...
if not exist bin mkdir bin
go build -o bin\api.exe cmd\api\main.go
goto end

:run
echo Running application...
go run cmd\api\main.go
goto end

:test
echo Running tests...
go test -v ./...
goto end

:clean
echo Cleaning...
if exist bin rmdir /s /q bin
go clean
goto end

:docker-build
echo Building Docker image...
docker build -f docker\Dockerfile -t djaas:latest .
goto end

:docker-up
echo Starting docker-compose services...
docker-compose up -d
goto end

:docker-down
echo Stopping docker-compose services...
docker-compose down
goto end

:migrate-up
echo Running migrations up...
where migrate >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: golang-migrate is not installed. Install it with:
    echo   go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
    goto end
)
migrate -path migrations -database "postgresql://djaas:djaas_dev@localhost:5432/djaas?sslmode=disable" up
goto end

:migrate-down
echo Running migrations down...
where migrate >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: golang-migrate is not installed
    goto end
)
migrate -path migrations -database "postgresql://djaas:djaas_dev@localhost:5432/djaas?sslmode=disable" down
goto end

:seed
echo Seeding database...
where psql >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: psql is not installed. You can also use Docker:
    echo   docker-compose exec postgres psql -U djaas -d djaas -f /scripts/seed.sql
    goto end
)
psql -h localhost -U djaas -d djaas -f scripts\seed.sql
goto end

:deps
echo Downloading dependencies...
go mod download
goto end

:tidy
echo Tidying go.mod...
go mod tidy
goto end

:end
endlocal
