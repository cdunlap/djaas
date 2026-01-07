# Azure Deployment Guide

This guide walks you through deploying DJaaS to Azure using Azure Container Apps, Azure Database for PostgreSQL, and Azure Key Vault.

## Architecture

- **Azure Container Apps**: Serverless container hosting with auto-scaling
- **Azure Database for PostgreSQL Flexible Server**: Managed PostgreSQL 16
- **Azure Container Registry**: Private Docker image registry
- **Azure Key Vault**: Secure secrets management

## Prerequisites

1. **Azure Account**: Sign up at https://azure.microsoft.com/
2. **Azure CLI**: Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
3. **Docker Desktop**: Install from https://www.docker.com/products/docker-desktop
4. **PostgreSQL Client** (for migrations):
   - Linux/macOS: `sudo apt-get install postgresql-client` or `brew install postgresql`
   - Windows: Download from https://www.postgresql.org/download/windows/

## Quick Start

### Option 1: Bash Script (Linux/macOS/WSL)

```bash
cd deploy/azure
chmod +x deploy.sh
./deploy.sh
```

### Option 2: PowerShell Script (Windows)

```powershell
cd deploy\azure
.\deploy.ps1
```

### Option 3: Manual Azure CLI Commands

See the "Manual Deployment Steps" section below.

## What the Deployment Script Does

1. **Creates Resource Group**: Logical container for all Azure resources
2. **Creates Azure Container Registry**: Stores your Docker image privately
3. **Builds and Pushes Docker Image**: Builds from `docker/Dockerfile` and pushes to ACR
4. **Creates PostgreSQL Database**:
   - PostgreSQL 16 Flexible Server
   - Burstable tier (cost-effective for dev/test)
   - Enables `pg_trgm` extension for full-text search
5. **Creates Azure Key Vault**: Stores database password and registry credentials
6. **Creates Container Apps Environment**: Serverless container environment
7. **Deploys Container App**:
   - Auto-scaling (1-3 replicas)
   - 0.5 CPU, 1 GB memory per instance
   - HTTPS enabled automatically
   - Production environment variables
8. **Runs Database Migrations**: Creates tables and indexes
9. **Seeds Database**: Loads 100 jokes with tags

## Configuration

Edit the variables at the top of the deployment script:

```bash
RESOURCE_GROUP="djaas-rg"           # Azure resource group name
LOCATION="eastus"                    # Azure region
```

The script auto-generates unique names for:
- Container Registry (must be globally unique)
- PostgreSQL server (must be globally unique)
- Key Vault (must be globally unique)

## Environment Variables (Production)

The deployment configures these environment variables:

| Variable | Value | Notes |
|----------|-------|-------|
| `PORT` | `8080` | Container port |
| `ENV` | `production` | Enables rate limiting |
| `LOG_LEVEL` | `info` | Production logging |
| `DB_HOST` | PostgreSQL FQDN | Auto-configured |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `djaasadmin` | Database admin user |
| `DB_PASSWORD` | Auto-generated | Stored in Key Vault |
| `DB_NAME` | `djaas` | Database name |
| `DB_SSLMODE` | `require` | **Required** for Azure PostgreSQL |
| `DB_MAX_CONNECTIONS` | `25` | Connection pool size |
| `DB_MAX_IDLE_CONNECTIONS` | `5` | Idle connection limit |
| `RATE_LIMIT_REQUESTS` | `100` | Requests per window |
| `RATE_LIMIT_WINDOW` | `1m` | Rate limit window |

## Cost Estimates (US East, as of 2026)

**Development/Testing:**
- Azure Database for PostgreSQL (Burstable B1ms): ~$12/month
- Azure Container Apps (0.5 vCPU, 1 GB): ~$15/month
- Azure Container Registry (Basic): ~$5/month
- Azure Key Vault: ~$0.03/10,000 operations
- **Total**: ~$35/month

**Production (recommended upgrades):**
- PostgreSQL (General Purpose D2s_v3): ~$100/month
- Container Apps (1 vCPU, 2 GB, 3 replicas): ~$90/month
- Container Registry (Standard): ~$20/month
- **Total**: ~$210/month

> Note: Add ~$1-5/month for bandwidth depending on traffic

## Manual Deployment Steps

If you prefer to run commands manually:

### 1. Login to Azure

```bash
az login
```

### 2. Create Resource Group

```bash
az group create \
  --name djaas-rg \
  --location eastus
```

### 3. Create Container Registry

```bash
az acr create \
  --resource-group djaas-rg \
  --name djaasacr$(date +%s) \
  --sku Basic \
  --admin-enabled true
```

Get credentials:

```bash
ACR_NAME="your-acr-name"
az acr credential show --name $ACR_NAME
```

### 4. Build and Push Image

```bash
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push
docker build -t $ACR_LOGIN_SERVER/djaas:latest -f docker/Dockerfile .
docker push $ACR_LOGIN_SERVER/djaas:latest
```

### 5. Create PostgreSQL Database

```bash
az postgres flexible-server create \
  --resource-group djaas-rg \
  --name djaas-db-$(date +%s) \
  --location eastus \
  --admin-user djaasadmin \
  --admin-password "YourStrongPassword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --public-access 0.0.0.0-255.255.255.255

# Create database
az postgres flexible-server db create \
  --resource-group djaas-rg \
  --server-name your-server-name \
  --database-name djaas

# Enable pg_trgm extension
az postgres flexible-server parameter set \
  --resource-group djaas-rg \
  --server-name your-server-name \
  --name azure.extensions \
  --value pg_trgm
```

### 6. Create Key Vault

```bash
az keyvault create \
  --resource-group djaas-rg \
  --name djaas-kv-$(date +%s) \
  --location eastus

# Store database password
az keyvault secret set \
  --vault-name your-keyvault-name \
  --name db-password \
  --value "YourStrongPassword123!"
```

### 7. Create Container Apps Environment

```bash
az containerapp env create \
  --resource-group djaas-rg \
  --name djaas-env \
  --location eastus
```

### 8. Deploy Container App

```bash
az containerapp create \
  --resource-group djaas-rg \
  --name djaas-api \
  --environment djaas-env \
  --image $ACR_LOGIN_SERVER/djaas:latest \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $(az acr credential show --name $ACR_NAME --query username -o tsv) \
  --registry-password $(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv) \
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
    DB_HOST=your-db-server.postgres.database.azure.com \
    DB_PORT=5432 \
    DB_USER=djaasadmin \
    DB_PASSWORD="YourStrongPassword123!" \
    DB_NAME=djaas \
    DB_SSLMODE=require \
    DB_MAX_CONNECTIONS=25 \
    DB_MAX_IDLE_CONNECTIONS=5 \
    RATE_LIMIT_REQUESTS=100 \
    RATE_LIMIT_WINDOW=1m
```

### 9. Run Migrations

```bash
POSTGRES_FQDN="your-server.postgres.database.azure.com"
export PGPASSWORD="YourStrongPassword123!"

# Run migrations
psql -h $POSTGRES_FQDN -U djaasadmin -d djaas -f ../../migrations/000001_init.up.sql
psql -h $POSTGRES_FQDN -U djaasadmin -d djaas -f ../../migrations/000002_add_category.up.sql
psql -h $POSTGRES_FQDN -U djaasadmin -d djaas -f ../../migrations/000003_add_tags.up.sql

# Seed database
psql -h $POSTGRES_FQDN -U djaasadmin -d djaas -f ../../scripts/seed.sql
psql -h $POSTGRES_FQDN -U djaasadmin -d djaas -f ../../scripts/seed_tags.sql

unset PGPASSWORD
```

## Testing the Deployment

Get your application URL:

```bash
az containerapp show \
  --resource-group djaas-rg \
  --name djaas-api \
  --query "properties.configuration.ingress.fqdn" -o tsv
```

Test endpoints:

```bash
APP_URL="https://your-app-url"

# Health check
curl $APP_URL/health

# Get random joke
curl $APP_URL/api/v1/joke

# Search jokes
curl "$APP_URL/api/v1/joke?search=science"

# Filter by category
curl "$APP_URL/api/v1/joke?category=programming"

# Filter by tags
curl "$APP_URL/api/v1/joke?tags=wordplay,puns"

# Combined filters
curl "$APP_URL/api/v1/joke?tags=science&search=atom"
```

## Viewing Logs

### Stream live logs:

```bash
az containerapp logs show \
  --resource-group djaas-rg \
  --name djaas-api \
  --follow
```

### View recent logs:

```bash
az containerapp logs show \
  --resource-group djaas-rg \
  --name djaas-api \
  --tail 100
```

## Updating the Deployment

### Update code and redeploy:

```bash
# Build and push new image
docker build -t $ACR_LOGIN_SERVER/djaas:latest -f docker/Dockerfile .
docker push $ACR_LOGIN_SERVER/djaas:latest

# Update container app (triggers automatic redeployment)
az containerapp update \
  --resource-group djaas-rg \
  --name djaas-api \
  --image $ACR_LOGIN_SERVER/djaas:latest
```

### Update environment variables:

```bash
az containerapp update \
  --resource-group djaas-rg \
  --name djaas-api \
  --set-env-vars "RATE_LIMIT_REQUESTS=200"
```

### Scale replicas:

```bash
az containerapp update \
  --resource-group djaas-rg \
  --name djaas-api \
  --min-replicas 2 \
  --max-replicas 5
```

## Database Management

### Connect to PostgreSQL:

```bash
psql "host=your-server.postgres.database.azure.com port=5432 dbname=djaas user=djaasadmin sslmode=require"
```

### Backup database:

```bash
pg_dump -h your-server.postgres.database.azure.com \
  -U djaasadmin \
  -d djaas \
  --no-owner \
  --no-privileges \
  -f backup.sql
```

### Restore database:

```bash
psql -h your-server.postgres.database.azure.com \
  -U djaasadmin \
  -d djaas \
  -f backup.sql
```

## Security Best Practices

1. **Use Key Vault References** (instead of inline env vars):
   ```bash
   az containerapp create \
     --secrets db-password=keyvaultref:https://your-vault.vault.azure.net/secrets/db-password
   ```

2. **Restrict Database Access**:
   - Use VNet integration for Container Apps
   - Disable public access to PostgreSQL
   - Use Azure Private Link

3. **Enable Managed Identity**:
   ```bash
   az containerapp identity assign \
     --resource-group djaas-rg \
     --name djaas-api \
     --system-assigned
   ```

4. **Rotate Credentials Regularly**:
   - Update Key Vault secrets
   - Restart container app to pick up new values

## Monitoring

### View metrics in Azure Portal:

1. Navigate to your Container App
2. Select "Metrics" from left menu
3. View: Requests, CPU usage, Memory usage, Response time

### Set up alerts:

```bash
az monitor metrics alert create \
  --name high-error-rate \
  --resource-group djaas-rg \
  --scopes /subscriptions/.../djaas-api \
  --condition "count Requests where ResultCode >= 500 > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Troubleshooting

### Container won't start:

```bash
# Check logs
az containerapp logs show --resource-group djaas-rg --name djaas-api --tail 50

# Check container status
az containerapp show --resource-group djaas-rg --name djaas-api
```

### Database connection issues:

- Verify firewall rules allow Container Apps IP
- Check `DB_SSLMODE=require` is set
- Verify pg_trgm extension is enabled

### Image pull errors:

- Verify ACR credentials are correct
- Ensure Container App has permission to pull from ACR

## Clean Up Resources

### Delete everything:

```bash
az group delete --name djaas-rg --yes --no-wait
```

### Delete specific resources:

```bash
# Delete container app only
az containerapp delete --resource-group djaas-rg --name djaas-api --yes

# Delete database only
az postgres flexible-server delete --resource-group djaas-rg --name your-server --yes
```

## CI/CD Integration

### GitHub Actions example:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and Push
        run: |
          az acr login --name ${{ secrets.ACR_NAME }}
          docker build -t ${{ secrets.ACR_NAME }}.azurecr.io/djaas:${{ github.sha }} .
          docker push ${{ secrets.ACR_NAME }}.azurecr.io/djaas:${{ github.sha }}

      - name: Deploy to Container Apps
        run: |
          az containerapp update \
            --resource-group djaas-rg \
            --name djaas-api \
            --image ${{ secrets.ACR_NAME }}.azurecr.io/djaas:${{ github.sha }}
```

## Support

- Azure Documentation: https://docs.microsoft.com/azure
- Container Apps: https://docs.microsoft.com/azure/container-apps
- PostgreSQL on Azure: https://docs.microsoft.com/azure/postgresql
- Azure CLI Reference: https://docs.microsoft.com/cli/azure

## Next Steps

1. Set up custom domain: https://docs.microsoft.com/azure/container-apps/custom-domains
2. Enable Application Insights: https://docs.microsoft.com/azure/container-apps/observability
3. Configure VNet integration for enhanced security
4. Set up automated backups for PostgreSQL
5. Implement CI/CD pipeline with GitHub Actions or Azure DevOps
