# Google Cloud DJaaS Deployment Script (PowerShell)
# Deploys DJaaS to Cloud Run with Cloud SQL PostgreSQL

param(
    [string]$ProjectId = "",
    [string]$Region = "us-central1",
    [string]$ServiceName = "djaas-api",
    [string]$DbInstanceName = "djaas-db",
    [string]$DbName = "djaas",
    [string]$DbUser = "djaas",
    [string]$DbPassword = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Green
Write-Host "DJaaS Google Cloud Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check if gcloud is installed
try {
    gcloud --version | Out-Null
} catch {
    Write-Host "Error: Google Cloud SDK is not installed" -ForegroundColor Red
    Write-Host "Install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "Checking Google Cloud login status..." -ForegroundColor Yellow
$activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if ([string]::IsNullOrEmpty($activeAccount)) {
    Write-Host "Not logged in. Opening Google Cloud login..." -ForegroundColor Yellow
    gcloud auth login
}

# Get or set project ID
if ([string]::IsNullOrEmpty($ProjectId)) {
    Write-Host "Available projects:" -ForegroundColor Yellow
    gcloud projects list --format="table(projectId,name)"
    Write-Host ""
    $ProjectId = Read-Host "Enter your Project ID"
}

# Set project
Write-Host "Setting project to: $ProjectId" -ForegroundColor Yellow
gcloud config set project $ProjectId

# Generate strong password if not provided
if ([string]::IsNullOrEmpty($DbPassword)) {
    $DbPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 25 | ForEach-Object {[char]$_})
    Write-Host "Generated secure database password" -ForegroundColor Green
}

# Enable required APIs
Write-Host "Enabling required Google Cloud APIs (this may take a few minutes)..." -ForegroundColor Yellow
gcloud services enable `
    cloudrun.googleapis.com `
    sqladmin.googleapis.com `
    secretmanager.googleapis.com `
    artifactregistry.googleapis.com `
    cloudbuild.googleapis.com

# Create Artifact Registry repository
Write-Host "Creating Artifact Registry repository..." -ForegroundColor Yellow
$repoExists = gcloud artifacts repositories describe djaas --location=$Region 2>$null
if ($LASTEXITCODE -ne 0) {
    gcloud artifacts repositories create djaas `
        --repository-format=docker `
        --location=$Region `
        --description="DJaaS container images"
} else {
    Write-Host "Artifact Registry repository already exists" -ForegroundColor Blue
}

# Configure Docker to use Artifact Registry
Write-Host "Configuring Docker authentication..." -ForegroundColor Yellow
gcloud auth configure-docker "$Region-docker.pkg.dev" --quiet

# Build and push Docker image
Write-Host "Building and pushing Docker image..." -ForegroundColor Yellow
$ImageUrl = "$Region-docker.pkg.dev/$ProjectId/djaas/${ServiceName}:latest"
docker build -t $ImageUrl -f docker/Dockerfile .
docker push $ImageUrl

# Create Cloud SQL instance
Write-Host "Creating Cloud SQL PostgreSQL instance (this takes 5-10 minutes)..." -ForegroundColor Yellow
$instanceExists = gcloud sql instances describe $DbInstanceName 2>$null
if ($LASTEXITCODE -ne 0) {
    gcloud sql instances create $DbInstanceName `
        --database-version=POSTGRES_16 `
        --tier=db-f1-micro `
        --region=$Region `
        --root-password=$DbPassword `
        --storage-type=HDD `
        --storage-size=10GB `
        --storage-auto-increase `
        --backup-start-time=03:00 `
        --maintenance-window-day=SUN `
        --maintenance-window-hour=04

    Write-Host "Cloud SQL instance created" -ForegroundColor Green
} else {
    Write-Host "Cloud SQL instance already exists" -ForegroundColor Blue
}

# Get instance connection name
$ConnectionName = gcloud sql instances describe $DbInstanceName --format="value(connectionName)"
Write-Host "Connection name: $ConnectionName" -ForegroundColor Green

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
$dbExists = gcloud sql databases describe $DbName --instance=$DbInstanceName 2>$null
if ($LASTEXITCODE -ne 0) {
    gcloud sql databases create $DbName --instance=$DbInstanceName
} else {
    Write-Host "Database already exists" -ForegroundColor Blue
}

# Create database user
Write-Host "Creating database user..." -ForegroundColor Yellow
$userList = gcloud sql users list --instance=$DbInstanceName --format="value(name)"
if ($userList -notcontains $DbUser) {
    gcloud sql users create $DbUser `
        --instance=$DbInstanceName `
        --password=$DbPassword
} else {
    Write-Host "Database user already exists" -ForegroundColor Blue
}

# Store secrets in Secret Manager
Write-Host "Storing secrets in Secret Manager..." -ForegroundColor Yellow

# Database password
$secretExists = gcloud secrets describe db-password 2>$null
if ($LASTEXITCODE -ne 0) {
    $DbPassword | gcloud secrets create db-password --data-file=-
} else {
    $DbPassword | gcloud secrets versions add db-password --data-file=-
}

Write-Host "Secrets stored in Secret Manager" -ForegroundColor Green

# Get project number for service account
$ProjectNumber = gcloud projects describe $ProjectId --format="value(projectNumber)"
$ServiceAccount = "$ProjectNumber-compute@developer.gserviceaccount.com"

# Grant Cloud Run service account access to secrets
Write-Host "Granting service account access to secrets..." -ForegroundColor Yellow
gcloud secrets add-iam-policy-binding db-password `
    --member="serviceAccount:$ServiceAccount" `
    --role="roles/secretmanager.secretAccessor" `
    --quiet

# Grant Cloud Run service account access to Cloud SQL
Write-Host "Granting service account Cloud SQL client role..." -ForegroundColor Yellow
gcloud projects add-iam-policy-binding $ProjectId `
    --member="serviceAccount:$ServiceAccount" `
    --role="roles/cloudsql.client" `
    --quiet

# Deploy to Cloud Run
Write-Host "Deploying to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy $ServiceName `
    --image=$ImageUrl `
    --platform=managed `
    --region=$Region `
    --allow-unauthenticated `
    --set-cloudsql-instances=$ConnectionName `
    --min-instances=0 `
    --max-instances=3 `
    --cpu=1 `
    --memory=512Mi `
    --timeout=300 `
    --set-env-vars="PORT=8080,ENV=production,LOG_LEVEL=info,DB_HOST=/cloudsql/$ConnectionName,DB_PORT=5432,DB_USER=$DbUser,DB_NAME=$DbName,DB_SSLMODE=disable,DB_MAX_CONNECTIONS=25,DB_MAX_IDLE_CONNECTIONS=5,RATE_LIMIT_REQUESTS=100,RATE_LIMIT_WINDOW=1m" `
    --set-secrets="DB_PASSWORD=db-password:latest"

# Get service URL
$ServiceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"

Write-Host "Cloud Run service deployed" -ForegroundColor Green

# Run migrations using Cloud SQL Proxy
Write-Host "Running database migrations..." -ForegroundColor Yellow
Write-Host "Setting up Cloud SQL connection..." -ForegroundColor Yellow

# Check for Cloud SQL Proxy
$proxyPath = "cloud-sql-proxy"
if (!(Get-Command cloud-sql-proxy -ErrorAction SilentlyContinue)) {
    Write-Host "Downloading Cloud SQL Proxy..." -ForegroundColor Yellow
    $proxyUrl = "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.x64.exe"
    $proxyPath = "$env:TEMP\cloud-sql-proxy.exe"
    Invoke-WebRequest -Uri $proxyUrl -OutFile $proxyPath
}

# Start Cloud SQL Proxy in background
Write-Host "Starting Cloud SQL Proxy..." -ForegroundColor Yellow
$proxyJob = Start-Job -ScriptBlock {
    param($proxyPath, $connectionName)
    & $proxyPath $connectionName --port=5433
} -ArgumentList $proxyPath, $ConnectionName

# Wait for proxy to be ready
Start-Sleep -Seconds 5

# Set password environment variable
$env:PGPASSWORD = $DbPassword

# Run migrations
Write-Host "Applying migrations..." -ForegroundColor Yellow
try {
    Get-ChildItem -Path "migrations" -Filter "*.up.sql" | Sort-Object Name | ForEach-Object {
        Write-Host "Running migration: $($_.Name)" -ForegroundColor Yellow
        psql -h localhost -p 5433 -U $DbUser -d $DbName -f $_.FullName 2>$null
    }

    # Seed database
    Write-Host "Seeding database..." -ForegroundColor Yellow
    if (Test-Path "scripts/seed.sql") {
        psql -h localhost -p 5433 -U $DbUser -d $DbName -f "scripts/seed.sql" 2>$null
    }
    if (Test-Path "scripts/seed_tags.sql") {
        psql -h localhost -p 5433 -U $DbUser -d $DbName -f "scripts/seed_tags.sql" 2>$null
    }
} catch {
    Write-Host "Note: psql not found. You can run migrations manually:" -ForegroundColor Yellow
    Write-Host "  Install PostgreSQL client from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
}

# Clean up
Remove-Item env:PGPASSWORD
Stop-Job $proxyJob -ErrorAction SilentlyContinue
Remove-Job $proxyJob -Force -ErrorAction SilentlyContinue

# Deployment complete
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Application URL: $ServiceUrl" -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Green
Write-Host "Region: $Region" -ForegroundColor Green
Write-Host "Cloud SQL Instance: $DbInstanceName" -ForegroundColor Green
Write-Host "Connection Name: $ConnectionName" -ForegroundColor Green
Write-Host ""
Write-Host "Test the deployment:" -ForegroundColor Yellow
Write-Host "  curl $ServiceUrl/health"
Write-Host "  curl $ServiceUrl/api/v1/joke"
Write-Host ""
Write-Host "Database Password (save this securely):" -ForegroundColor Yellow
Write-Host "  $DbPassword"
Write-Host ""
Write-Host "View logs:" -ForegroundColor Yellow
Write-Host "  gcloud run logs read --service=$ServiceName --region=$Region --limit=50"
Write-Host ""
Write-Host "View in console:" -ForegroundColor Yellow
Write-Host "  https://console.cloud.google.com/run?project=$ProjectId"
Write-Host ""
Write-Host "Clean up resources:" -ForegroundColor Yellow
Write-Host "  gcloud sql instances delete $DbInstanceName --quiet"
Write-Host "  gcloud run services delete $ServiceName --region=$Region --quiet"
Write-Host "  gcloud artifacts repositories delete djaas --location=$Region --quiet"
Write-Host ""
Write-Host "Free Tier Info:" -ForegroundColor Blue
Write-Host "  Cloud Run: 2M requests/month, 360K GB-seconds/month FREE"
Write-Host "  Artifact Registry: 0.5 GB storage FREE"
Write-Host "  Secret Manager: 6 active secret versions FREE"
Write-Host "  Cloud SQL: First 30 days FREE, then ~`$10/month for db-f1-micro"
