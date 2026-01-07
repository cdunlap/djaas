#!/bin/bash
set -e

# Azure DJaaS Deployment Script
# This script deploys DJaaS to Azure Container Apps with PostgreSQL and Key Vault

# Configuration - UPDATE THESE VALUES
RESOURCE_GROUP="djaas-rg"
LOCATION="eastus"
ACR_NAME="djaasacr$(date +%s)"  # Must be globally unique
POSTGRES_SERVER="djaas-db-$(date +%s)"
POSTGRES_ADMIN_USER="djaasadmin"
POSTGRES_ADMIN_PASSWORD=""  # Will be generated if empty
DB_NAME="djaas"
KEY_VAULT_NAME="djaas-kv-$(date +%s)"
CONTAINER_APP_NAME="djaas-api"
CONTAINER_APP_ENV="djaas-env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DJaaS Azure Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Opening Azure login...${NC}"
    az login
fi

# Generate strong password if not provided
if [ -z "$POSTGRES_ADMIN_PASSWORD" ]; then
    POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo -e "${GREEN}Generated secure database password${NC}"
fi

# Create Resource Group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# Create Azure Container Registry
echo -e "${YELLOW}Creating Azure Container Registry...${NC}"
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --output table

# Get ACR credentials
echo -e "${YELLOW}Getting ACR credentials...${NC}"
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query "loginServer" -o tsv)

# Build and push Docker image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
echo -e "${YELLOW}Logging into ACR...${NC}"
echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" --username "$ACR_USERNAME" --password-stdin

echo -e "${YELLOW}Building image...${NC}"
docker build -t "$ACR_LOGIN_SERVER/djaas:latest" -f docker/Dockerfile .

echo -e "${YELLOW}Pushing image to ACR...${NC}"
docker push "$ACR_LOGIN_SERVER/djaas:latest"

# Create Azure Database for PostgreSQL
echo -e "${YELLOW}Creating Azure Database for PostgreSQL...${NC}"
az postgres flexible-server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_SERVER" \
  --location "$LOCATION" \
  --admin-user "$POSTGRES_ADMIN_USER" \
  --admin-password "$POSTGRES_ADMIN_PASSWORD" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --public-access 0.0.0.0-255.255.255.255 \
  --output table

# Create database
echo -e "${YELLOW}Creating database...${NC}"
az postgres flexible-server db create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$POSTGRES_SERVER" \
  --database-name "$DB_NAME" \
  --output table

# Enable pg_trgm extension (needed for full-text search)
echo -e "${YELLOW}Enabling pg_trgm extension...${NC}"
az postgres flexible-server parameter set \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$POSTGRES_SERVER" \
  --name azure.extensions \
  --value pg_trgm \
  --output table

# Create Key Vault
echo -e "${YELLOW}Creating Azure Key Vault...${NC}"
az keyvault create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$KEY_VAULT_NAME" \
  --location "$LOCATION" \
  --output table

# Store secrets in Key Vault
echo -e "${YELLOW}Storing secrets in Key Vault...${NC}"
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "db-password" \
  --value "$POSTGRES_ADMIN_PASSWORD" \
  --output table

az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "acr-username" \
  --value "$ACR_USERNAME" \
  --output table

az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "acr-password" \
  --value "$ACR_PASSWORD" \
  --output table

# Create Container Apps Environment
echo -e "${YELLOW}Creating Container Apps Environment...${NC}"
az containerapp env create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_ENV" \
  --location "$LOCATION" \
  --output table

# Get PostgreSQL FQDN
POSTGRES_FQDN=$(az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_SERVER" \
  --query "fullyQualifiedDomainName" -o tsv)

# Deploy Container App
echo -e "${YELLOW}Deploying Container App...${NC}"
az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  --environment "$CONTAINER_APP_ENV" \
  --image "$ACR_LOGIN_SERVER/djaas:latest" \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars \
    PORT=8080 \
    ENV=production \
    LOG_LEVEL=info \
    DB_HOST="$POSTGRES_FQDN" \
    DB_PORT=5432 \
    DB_USER="$POSTGRES_ADMIN_USER" \
    DB_PASSWORD="$POSTGRES_ADMIN_PASSWORD" \
    DB_NAME="$DB_NAME" \
    DB_SSLMODE=require \
    DB_MAX_CONNECTIONS=25 \
    DB_MAX_IDLE_CONNECTIONS=5 \
    RATE_LIMIT_REQUESTS=100 \
    RATE_LIMIT_WINDOW=1m \
  --output table

# Get Container App URL
APP_URL=$(az containerapp show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  --query "properties.configuration.ingress.fqdn" -o tsv)

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
echo "Connecting to PostgreSQL to run migrations..."

# Export connection string for psql
export PGPASSWORD="$POSTGRES_ADMIN_PASSWORD"

# Run migrations
for migration in migrations/*.up.sql; do
    if [ -f "$migration" ]; then
        echo -e "${YELLOW}Running migration: $migration${NC}"
        psql -h "$POSTGRES_FQDN" \
             -U "$POSTGRES_ADMIN_USER" \
             -d "$DB_NAME" \
             -f "$migration"
    fi
done

# Seed database
echo -e "${YELLOW}Seeding database...${NC}"
if [ -f "scripts/seed.sql" ]; then
    psql -h "$POSTGRES_FQDN" \
         -U "$POSTGRES_ADMIN_USER" \
         -d "$DB_NAME" \
         -f "scripts/seed.sql"
fi

if [ -f "scripts/seed_tags.sql" ]; then
    psql -h "$POSTGRES_FQDN" \
         -U "$POSTGRES_ADMIN_USER" \
         -d "$DB_NAME" \
         -f "scripts/seed_tags.sql"
fi

unset PGPASSWORD

# Deployment complete
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Application URL:${NC} https://$APP_URL"
echo -e "${GREEN}Resource Group:${NC} $RESOURCE_GROUP"
echo -e "${GREEN}Database Server:${NC} $POSTGRES_FQDN"
echo -e "${GREEN}Key Vault:${NC} $KEY_VAULT_NAME"
echo ""
echo -e "${YELLOW}Test the deployment:${NC}"
echo "  curl https://$APP_URL/health"
echo "  curl https://$APP_URL/api/v1/joke"
echo ""
echo -e "${YELLOW}Database Password (save this securely):${NC}"
echo "  $POSTGRES_ADMIN_PASSWORD"
echo ""
echo -e "${YELLOW}View logs:${NC}"
echo "  az containerapp logs show --resource-group $RESOURCE_GROUP --name $CONTAINER_APP_NAME --follow"
echo ""
echo -e "${YELLOW}Clean up resources:${NC}"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
