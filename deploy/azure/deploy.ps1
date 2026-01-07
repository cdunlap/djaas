# Azure DJaaS Deployment Script (PowerShell)
# This script deploys DJaaS to Azure Container Apps with PostgreSQL and Key Vault

param(
    [string]$ResourceGroup = "djaas-rg",
    [string]$Location = "eastus",
    [string]$PostgresAdminPassword = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$AcrName = "djaasacr$timestamp"
$PostgresServer = "djaas-db-$timestamp"
$PostgresAdminUser = "djaasadmin"
$DbName = "djaas"
$KeyVaultName = "djaas-kv-$timestamp"
$ContainerAppName = "djaas-api"
$ContainerAppEnv = "djaas-env"

Write-Host "========================================" -ForegroundColor Green
Write-Host "DJaaS Azure Deployment (PowerShell)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check if Azure CLI is installed
try {
    az --version | Out-Null
} catch {
    Write-Host "Error: Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    az account show | Out-Null
} catch {
    Write-Host "Not logged in. Opening Azure login..." -ForegroundColor Yellow
    az login
}

# Generate strong password if not provided
if ([string]::IsNullOrEmpty($PostgresAdminPassword)) {
    $PostgresAdminPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 25 | ForEach-Object {[char]$_})
    Write-Host "Generated secure database password" -ForegroundColor Green
}

# Create Resource Group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create `
  --name $ResourceGroup `
  --location $Location `
  --output table

# Create Azure Container Registry
Write-Host "Creating Azure Container Registry..." -ForegroundColor Yellow
az acr create `
  --resource-group $ResourceGroup `
  --name $AcrName `
  --sku Basic `
  --admin-enabled true `
  --output table

# Get ACR credentials
Write-Host "Getting ACR credentials..." -ForegroundColor Yellow
$AcrUsername = az acr credential show --name $AcrName --query "username" -o tsv
$AcrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv
$AcrLoginServer = az acr show --name $AcrName --query "loginServer" -o tsv

# Build and push Docker image
Write-Host "Building and pushing Docker image..." -ForegroundColor Yellow
Write-Host "Logging into ACR..." -ForegroundColor Yellow
$AcrPassword | docker login $AcrLoginServer --username $AcrUsername --password-stdin

Write-Host "Building image..." -ForegroundColor Yellow
docker build -t "$AcrLoginServer/djaas:latest" -f docker/Dockerfile .

Write-Host "Pushing image to ACR..." -ForegroundColor Yellow
docker push "$AcrLoginServer/djaas:latest"

# Create Azure Database for PostgreSQL
Write-Host "Creating Azure Database for PostgreSQL..." -ForegroundColor Yellow
az postgres flexible-server create `
  --resource-group $ResourceGroup `
  --name $PostgresServer `
  --location $Location `
  --admin-user $PostgresAdminUser `
  --admin-password $PostgresAdminPassword `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --storage-size 32 `
  --version 16 `
  --public-access 0.0.0.0-255.255.255.255 `
  --output table

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
az postgres flexible-server db create `
  --resource-group $ResourceGroup `
  --server-name $PostgresServer `
  --database-name $DbName `
  --output table

# Enable pg_trgm extension
Write-Host "Enabling pg_trgm extension..." -ForegroundColor Yellow
az postgres flexible-server parameter set `
  --resource-group $ResourceGroup `
  --server-name $PostgresServer `
  --name azure.extensions `
  --value pg_trgm `
  --output table

# Create Key Vault
Write-Host "Creating Azure Key Vault..." -ForegroundColor Yellow
az keyvault create `
  --resource-group $ResourceGroup `
  --name $KeyVaultName `
  --location $Location `
  --output table

# Store secrets in Key Vault
Write-Host "Storing secrets in Key Vault..." -ForegroundColor Yellow
az keyvault secret set `
  --vault-name $KeyVaultName `
  --name "db-password" `
  --value $PostgresAdminPassword `
  --output table

az keyvault secret set `
  --vault-name $KeyVaultName `
  --name "acr-username" `
  --value $AcrUsername `
  --output table

az keyvault secret set `
  --vault-name $KeyVaultName `
  --name "acr-password" `
  --value $AcrPassword `
  --output table

# Create Container Apps Environment
Write-Host "Creating Container Apps Environment..." -ForegroundColor Yellow
az containerapp env create `
  --resource-group $ResourceGroup `
  --name $ContainerAppEnv `
  --location $Location `
  --output table

# Get PostgreSQL FQDN
$PostgresFqdn = az postgres flexible-server show `
  --resource-group $ResourceGroup `
  --name $PostgresServer `
  --query "fullyQualifiedDomainName" -o tsv

# Deploy Container App
Write-Host "Deploying Container App..." -ForegroundColor Yellow
az containerapp create `
  --resource-group $ResourceGroup `
  --name $ContainerAppName `
  --environment $ContainerAppEnv `
  --image "$AcrLoginServer/djaas:latest" `
  --registry-server $AcrLoginServer `
  --registry-username $AcrUsername `
  --registry-password $AcrPassword `
  --target-port 8080 `
  --ingress external `
  --min-replicas 1 `
  --max-replicas 3 `
  --cpu 0.5 `
  --memory 1Gi `
  --env-vars "PORT=8080" "ENV=production" "LOG_LEVEL=info" "DB_HOST=$PostgresFqdn" "DB_PORT=5432" "DB_USER=$PostgresAdminUser" "DB_PASSWORD=$PostgresAdminPassword" "DB_NAME=$DbName" "DB_SSLMODE=require" "DB_MAX_CONNECTIONS=25" "DB_MAX_IDLE_CONNECTIONS=5" "RATE_LIMIT_REQUESTS=100" "RATE_LIMIT_WINDOW=1m" `
  --output table

# Get Container App URL
$AppUrl = az containerapp show `
  --resource-group $ResourceGroup `
  --name $ContainerAppName `
  --query "properties.configuration.ingress.fqdn" -o tsv

# Run migrations (requires psql - PostgreSQL client)
Write-Host "Running database migrations..." -ForegroundColor Yellow
Write-Host "Note: This requires psql (PostgreSQL client) to be installed" -ForegroundColor Yellow
Write-Host "Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow

$env:PGPASSWORD = $PostgresAdminPassword

try {
    # Run migrations
    Get-ChildItem -Path "migrations" -Filter "*.up.sql" | Sort-Object Name | ForEach-Object {
        Write-Host "Running migration: $($_.Name)" -ForegroundColor Yellow
        psql -h $PostgresFqdn -U $PostgresAdminUser -d $DbName -f $_.FullName
    }

    # Seed database
    Write-Host "Seeding database..." -ForegroundColor Yellow
    if (Test-Path "scripts/seed.sql") {
        psql -h $PostgresFqdn -U $PostgresAdminUser -d $DbName -f "scripts/seed.sql"
    }
    if (Test-Path "scripts/seed_tags.sql") {
        psql -h $PostgresFqdn -U $PostgresAdminUser -d $DbName -f "scripts/seed_tags.sql"
    }
} catch {
    Write-Host "Note: psql not found. You can run migrations manually:" -ForegroundColor Yellow
    Write-Host "  psql -h $PostgresFqdn -U $PostgresAdminUser -d $DbName -f migrations/000001_init.up.sql" -ForegroundColor Yellow
}

Remove-Item env:PGPASSWORD

# Deployment complete
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Application URL: https://$AppUrl" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Green
Write-Host "Database Server: $PostgresFqdn" -ForegroundColor Green
Write-Host "Key Vault: $KeyVaultName" -ForegroundColor Green
Write-Host ""
Write-Host "Test the deployment:" -ForegroundColor Yellow
Write-Host "  curl https://$AppUrl/health"
Write-Host "  curl https://$AppUrl/api/v1/joke"
Write-Host ""
Write-Host "Database Password (save this securely):" -ForegroundColor Yellow
Write-Host "  $PostgresAdminPassword"
Write-Host ""
Write-Host "View logs:" -ForegroundColor Yellow
Write-Host "  az containerapp logs show --resource-group $ResourceGroup --name $ContainerAppName --follow"
Write-Host ""
Write-Host "Clean up resources:" -ForegroundColor Yellow
Write-Host "  az group delete --name $ResourceGroup --yes --no-wait"
