#!/bin/bash
set -e

# Google Cloud DJaaS Deployment Script
# Deploys DJaaS to Cloud Run with Cloud SQL PostgreSQL

# Configuration - UPDATE THESE VALUES
PROJECT_ID=""  # Your GCP project ID (will prompt if empty)
REGION="us-central1"
SERVICE_NAME="djaas-api"
DB_INSTANCE_NAME="djaas-db"
DB_NAME="djaas"
DB_USER="djaas"
DB_PASSWORD=""  # Will be generated if empty

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DJaaS Google Cloud Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: Google Cloud SDK is not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}Checking Google Cloud login status...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}Not logged in. Opening Google Cloud login...${NC}"
    gcloud auth login
fi

# Get or set project ID
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}Available projects:${NC}"
    gcloud projects list --format="table(projectId,name)"
    echo ""
    read -p "Enter your Project ID: " PROJECT_ID
fi

# Set project
echo -e "${YELLOW}Setting project to: $PROJECT_ID${NC}"
gcloud config set project "$PROJECT_ID"

# Generate strong password if not provided
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo -e "${GREEN}Generated secure database password${NC}"
fi

# Enable required APIs
echo -e "${YELLOW}Enabling required Google Cloud APIs (this may take a few minutes)...${NC}"
gcloud services enable \
    cloudrun.googleapis.com \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com

# Create Artifact Registry repository
echo -e "${YELLOW}Creating Artifact Registry repository...${NC}"
if ! gcloud artifacts repositories describe djaas --location="$REGION" &>/dev/null; then
    gcloud artifacts repositories create djaas \
        --repository-format=docker \
        --location="$REGION" \
        --description="DJaaS container images"
else
    echo -e "${BLUE}Artifact Registry repository already exists${NC}"
fi

# Configure Docker to use Artifact Registry
echo -e "${YELLOW}Configuring Docker authentication...${NC}"
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# Build and push Docker image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/djaas/$SERVICE_NAME:latest"
docker build -t "$IMAGE_URL" -f docker/Dockerfile .
docker push "$IMAGE_URL"

# Create Cloud SQL instance
echo -e "${YELLOW}Creating Cloud SQL PostgreSQL instance (this takes 5-10 minutes)...${NC}"
if ! gcloud sql instances describe "$DB_INSTANCE_NAME" &>/dev/null; then
    gcloud sql instances create "$DB_INSTANCE_NAME" \
        --database-version=POSTGRES_16 \
        --tier=db-f1-micro \
        --region="$REGION" \
        --root-password="$DB_PASSWORD" \
        --storage-type=HDD \
        --storage-size=10GB \
        --storage-auto-increase \
        --backup-start-time=03:00 \
        --maintenance-window-day=SUN \
        --maintenance-window-hour=04

    echo -e "${GREEN}Cloud SQL instance created${NC}"
else
    echo -e "${BLUE}Cloud SQL instance already exists${NC}"
fi

# Get instance connection name
CONNECTION_NAME=$(gcloud sql instances describe "$DB_INSTANCE_NAME" --format="value(connectionName)")
echo -e "${GREEN}Connection name: $CONNECTION_NAME${NC}"

# Create database
echo -e "${YELLOW}Creating database...${NC}"
if ! gcloud sql databases describe "$DB_NAME" --instance="$DB_INSTANCE_NAME" &>/dev/null; then
    gcloud sql databases create "$DB_NAME" \
        --instance="$DB_INSTANCE_NAME"
else
    echo -e "${BLUE}Database already exists${NC}"
fi

# Create database user
echo -e "${YELLOW}Creating database user...${NC}"
if ! gcloud sql users list --instance="$DB_INSTANCE_NAME" --format="value(name)" | grep -q "^$DB_USER$"; then
    gcloud sql users create "$DB_USER" \
        --instance="$DB_INSTANCE_NAME" \
        --password="$DB_PASSWORD"
else
    echo -e "${BLUE}Database user already exists${NC}"
fi

# Store secrets in Secret Manager
echo -e "${YELLOW}Storing secrets in Secret Manager...${NC}"

# Database password
if ! gcloud secrets describe db-password &>/dev/null; then
    echo -n "$DB_PASSWORD" | gcloud secrets create db-password \
        --data-file=- \
        --replication-policy=automatic
else
    echo -n "$DB_PASSWORD" | gcloud secrets versions add db-password \
        --data-file=-
fi

echo -e "${GREEN}Secrets stored in Secret Manager${NC}"

# Get project number for service account
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
SERVICE_ACCOUNT="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

# Grant Cloud Run service account access to secrets
echo -e "${YELLOW}Granting service account access to secrets...${NC}"
gcloud secrets add-iam-policy-binding db-password \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --quiet

# Grant Cloud Run service account access to Cloud SQL
echo -e "${YELLOW}Granting service account Cloud SQL client role...${NC}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/cloudsql.client" \
    --quiet

# Deploy to Cloud Run
echo -e "${YELLOW}Deploying to Cloud Run...${NC}"
gcloud run deploy "$SERVICE_NAME" \
    --image="$IMAGE_URL" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated \
    --set-cloudsql-instances="$CONNECTION_NAME" \
    --min-instances=0 \
    --max-instances=3 \
    --cpu=1 \
    --memory=512Mi \
    --timeout=300 \
    --set-env-vars="PORT=8080,ENV=production,LOG_LEVEL=info,DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432,DB_USER=$DB_USER,DB_NAME=$DB_NAME,DB_SSLMODE=disable,DB_MAX_CONNECTIONS=25,DB_MAX_IDLE_CONNECTIONS=5,RATE_LIMIT_REQUESTS=100,RATE_LIMIT_WINDOW=1m" \
    --set-secrets="DB_PASSWORD=db-password:latest"

# Get service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")

echo -e "${GREEN}Cloud Run service deployed${NC}"

# Run migrations using Cloud SQL Proxy
echo -e "${YELLOW}Running database migrations...${NC}"
echo -e "${YELLOW}Setting up Cloud SQL connection...${NC}"

# Install Cloud SQL Proxy if not present
if ! command -v cloud-sql-proxy &> /dev/null; then
    echo -e "${YELLOW}Downloading Cloud SQL Proxy...${NC}"
    curl -o /tmp/cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.linux.amd64
    chmod +x /tmp/cloud-sql-proxy
    PROXY_CMD="/tmp/cloud-sql-proxy"
else
    PROXY_CMD="cloud-sql-proxy"
fi

# Start Cloud SQL Proxy in background
echo -e "${YELLOW}Starting Cloud SQL Proxy...${NC}"
$PROXY_CMD "$CONNECTION_NAME" --port=5433 &
PROXY_PID=$!

# Wait for proxy to be ready
sleep 5

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

# Run migrations
echo -e "${YELLOW}Applying migrations...${NC}"
for migration in migrations/*.up.sql; do
    if [ -f "$migration" ]; then
        echo -e "${YELLOW}Running migration: $migration${NC}"
        psql -h localhost -p 5433 -U "$DB_USER" -d "$DB_NAME" -f "$migration" || true
    fi
done

# Seed database
echo -e "${YELLOW}Seeding database...${NC}"
if [ -f "scripts/seed.sql" ]; then
    psql -h localhost -p 5433 -U "$DB_USER" -d "$DB_NAME" -f "scripts/seed.sql" || true
fi

if [ -f "scripts/seed_tags.sql" ]; then
    psql -h localhost -p 5433 -U "$DB_USER" -d "$DB_NAME" -f "scripts/seed_tags.sql" || true
fi

# Clean up
unset PGPASSWORD
kill $PROXY_PID 2>/dev/null || true

# Deployment complete
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Application URL:${NC} $SERVICE_URL"
echo -e "${GREEN}Project ID:${NC} $PROJECT_ID"
echo -e "${GREEN}Region:${NC} $REGION"
echo -e "${GREEN}Cloud SQL Instance:${NC} $DB_INSTANCE_NAME"
echo -e "${GREEN}Connection Name:${NC} $CONNECTION_NAME"
echo ""
echo -e "${YELLOW}Test the deployment:${NC}"
echo "  curl $SERVICE_URL/health"
echo "  curl $SERVICE_URL/api/v1/joke"
echo ""
echo -e "${YELLOW}Database Password (save this securely):${NC}"
echo "  $DB_PASSWORD"
echo ""
echo -e "${YELLOW}View logs:${NC}"
echo "  gcloud run logs read --service=$SERVICE_NAME --region=$REGION --limit=50"
echo ""
echo -e "${YELLOW}View in console:${NC}"
echo "  https://console.cloud.google.com/run?project=$PROJECT_ID"
echo ""
echo -e "${YELLOW}Clean up resources:${NC}"
echo "  gcloud sql instances delete $DB_INSTANCE_NAME --quiet"
echo "  gcloud run services delete $SERVICE_NAME --region=$REGION --quiet"
echo "  gcloud artifacts repositories delete djaas --location=$REGION --quiet"
echo ""
echo -e "${BLUE}Free Tier Info:${NC}"
echo "  Cloud Run: 2M requests/month, 360K GB-seconds/month FREE"
echo "  Artifact Registry: 0.5 GB storage FREE"
echo "  Secret Manager: 6 active secret versions FREE"
echo "  Cloud SQL: First 30 days FREE, then ~\$10/month for db-f1-micro"
