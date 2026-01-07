# Google Cloud Run Deployment Guide

Deploy DJaaS to Google Cloud Run with generous **FREE TIER** benefits!

## Why Google Cloud Run?

✅ **Generous Free Tier**:
- 2 million requests/month FREE
- 360,000 GB-seconds/month FREE
- 180,000 vCPU-seconds/month FREE
- No credit card required for free tier

✅ **Serverless**: Auto-scales from 0 to N, pay only for what you use
✅ **Easy to Use**: Deploy with one command
✅ **Fully Managed**: No server maintenance

## Architecture

- **Cloud Run**: Serverless container hosting (FREE tier generous!)
- **Cloud SQL**: Managed PostgreSQL 16 (30-day free trial, then ~$10/month)
- **Artifact Registry**: Private Docker image registry (0.5 GB FREE)
- **Secret Manager**: Secure credentials storage (6 secrets FREE)

## Prerequisites

### 1. Google Cloud Account
- Sign up at https://cloud.google.com/
- **$300 free credit** for 90 days (no credit card initially)
- After trial: Generous always-free tier continues

### 2. Create a Google Cloud Project
```bash
# Via web console: https://console.cloud.google.com/projectcreate
# Or via CLI after installation:
gcloud projects create djaas-PROJECT_ID --name="DJaaS"
```

### 3. Install Google Cloud SDK

**Windows:**
```powershell
# Download installer
https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe

# Or via PowerShell
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe
```

**Linux/macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

### 4. Install Docker Desktop
- Download from https://www.docker.com/products/docker-desktop
- Make sure it's running before deployment

### 5. Install PostgreSQL Client (for migrations)

**Windows:**
```powershell
# Download from PostgreSQL website
https://www.postgresql.org/download/windows/

# Or via Chocolatey
choco install postgresql
```

**Linux:**
```bash
sudo apt-get install postgresql-client  # Debian/Ubuntu
sudo yum install postgresql             # RHEL/CentOS
```

**macOS:**
```bash
brew install postgresql
```

## Quick Start

### Option 1: PowerShell (Windows - Recommended)

```powershell
cd deploy\gcp
.\deploy.ps1
```

### Option 2: Bash (Linux/macOS/WSL)

```bash
cd deploy/gcp
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Prompt for your Google Cloud Project ID
2. Enable required APIs (~2 minutes)
3. Build and push Docker image (~3 minutes)
4. Create Cloud SQL instance (~5-10 minutes)
5. Deploy to Cloud Run (~2 minutes)
6. Run migrations and seed database
7. Output your live URL!

**Total time: ~15 minutes**

## What Gets Created

| Resource | Type | Cost |
|----------|------|------|
| Cloud Run Service | Serverless container | **FREE** (within 2M requests/month) |
| Cloud SQL PostgreSQL | db-f1-micro | 30-day trial, then ~$10/month |
| Artifact Registry | Docker repository | **FREE** (within 0.5 GB) |
| Secret Manager | 1 secret (db password) | **FREE** (within 6 secrets) |

## Environment Variables (Production)

The deployment automatically configures:

| Variable | Value | Notes |
|----------|-------|-------|
| `PORT` | `8080` | Cloud Run port |
| `ENV` | `production` | Enables rate limiting |
| `LOG_LEVEL` | `info` | Production logging |
| `DB_HOST` | `/cloudsql/CONNECTION_NAME` | Unix socket connection |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `djaas` | Database user |
| `DB_PASSWORD` | From Secret Manager | Auto-injected |
| `DB_NAME` | `djaas` | Database name |
| `DB_SSLMODE` | `disable` | Unix socket = no SSL needed |
| `DB_MAX_CONNECTIONS` | `25` | Connection pool size |
| `DB_MAX_IDLE_CONNECTIONS` | `5` | Idle connection limit |
| `RATE_LIMIT_REQUESTS` | `100` | Requests per minute |
| `RATE_LIMIT_WINDOW` | `1m` | Rate limit window |

## Manual Deployment Steps

If you prefer step-by-step manual deployment:

### 1. Login and Set Project

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Enable APIs

```bash
gcloud services enable \
    cloudrun.googleapis.com \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com
```

### 3. Create Artifact Registry Repository

```bash
gcloud artifacts repositories create djaas \
    --repository-format=docker \
    --location=us-central1 \
    --description="DJaaS container images"
```

### 4. Configure Docker Authentication

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### 5. Build and Push Image

```bash
PROJECT_ID=$(gcloud config get-value project)
IMAGE_URL="us-central1-docker.pkg.dev/$PROJECT_ID/djaas/djaas-api:latest"

docker build -t $IMAGE_URL -f docker/Dockerfile .
docker push $IMAGE_URL
```

### 6. Create Cloud SQL Instance

```bash
gcloud sql instances create djaas-db \
    --database-version=POSTGRES_16 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --root-password=CHANGE_ME_STRONG_PASSWORD

# Create database
gcloud sql databases create djaas --instance=djaas-db

# Create user
gcloud sql users create djaas \
    --instance=djaas-db \
    --password=CHANGE_ME_STRONG_PASSWORD
```

### 7. Store Password in Secret Manager

```bash
echo -n "CHANGE_ME_STRONG_PASSWORD" | gcloud secrets create db-password \
    --data-file=- \
    --replication-policy=automatic
```

### 8. Get Connection Name

```bash
CONNECTION_NAME=$(gcloud sql instances describe djaas-db --format="value(connectionName)")
echo "Connection name: $CONNECTION_NAME"
```

### 9. Deploy to Cloud Run

```bash
gcloud run deploy djaas-api \
    --image=$IMAGE_URL \
    --platform=managed \
    --region=us-central1 \
    --allow-unauthenticated \
    --set-cloudsql-instances=$CONNECTION_NAME \
    --min-instances=0 \
    --max-instances=3 \
    --cpu=1 \
    --memory=512Mi \
    --set-env-vars="PORT=8080,ENV=production,LOG_LEVEL=info,DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432,DB_USER=djaas,DB_NAME=djaas,DB_SSLMODE=disable,DB_MAX_CONNECTIONS=25,DB_MAX_IDLE_CONNECTIONS=5,RATE_LIMIT_REQUESTS=100,RATE_LIMIT_WINDOW=1m" \
    --set-secrets="DB_PASSWORD=db-password:latest"
```

### 10. Run Migrations via Cloud SQL Proxy

**Windows:**
```powershell
# Download Cloud SQL Proxy
Invoke-WebRequest -Uri "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.x64.exe" -OutFile cloud-sql-proxy.exe

# Start proxy (in separate terminal)
.\cloud-sql-proxy.exe $CONNECTION_NAME --port=5433

# Run migrations (in another terminal)
$env:PGPASSWORD = "YOUR_PASSWORD"
psql -h localhost -p 5433 -U djaas -d djaas -f ..\..\migrations\000001_init.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ..\..\migrations\000002_add_category.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ..\..\migrations\000003_add_tags.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ..\..\scripts\seed.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ..\..\scripts\seed_tags.sql
```

**Linux/macOS:**
```bash
# Download Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy

# Start proxy in background
./cloud-sql-proxy $CONNECTION_NAME --port=5433 &

# Run migrations
export PGPASSWORD="YOUR_PASSWORD"
psql -h localhost -p 5433 -U djaas -d djaas -f ../../migrations/000001_init.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ../../migrations/000002_add_category.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ../../migrations/000003_add_tags.up.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ../../scripts/seed.sql
psql -h localhost -p 5433 -U djaas -d djaas -f ../../scripts/seed_tags.sql
```

## Testing the Deployment

Get your service URL:

```bash
gcloud run services describe djaas-api \
    --region=us-central1 \
    --format="value(status.url)"
```

Test endpoints:

```bash
SERVICE_URL="https://djaas-api-xxxxx.a.run.app"

# Health check
curl $SERVICE_URL/health

# Get random joke
curl $SERVICE_URL/api/v1/joke

# Search jokes
curl "$SERVICE_URL/api/v1/joke?search=science"

# Filter by category
curl "$SERVICE_URL/api/v1/joke?category=programming"

# Filter by tags
curl "$SERVICE_URL/api/v1/joke?tags=wordplay"

# Multiple tags (OR logic)
curl "$SERVICE_URL/api/v1/joke?tags=wordplay,puns"

# Combined filters
curl "$SERVICE_URL/api/v1/joke?tags=science&category=general&search=atom"
```

## Viewing Logs

### Stream live logs:

```bash
gcloud run logs tail --service=djaas-api --region=us-central1
```

### View recent logs:

```bash
gcloud run logs read --service=djaas-api --region=us-central1 --limit=50
```

### View in web console:

```bash
# Open logs in browser
gcloud run services describe djaas-api --region=us-central1 --format="value(status.url)"
```

Or visit: https://console.cloud.google.com/run

## Updating the Deployment

### Update code and redeploy:

```bash
# Rebuild and push new image
docker build -t $IMAGE_URL -f docker/Dockerfile .
docker push $IMAGE_URL

# Cloud Run auto-deploys on new image push, or force update:
gcloud run services update djaas-api \
    --region=us-central1 \
    --image=$IMAGE_URL
```

### Update environment variables:

```bash
gcloud run services update djaas-api \
    --region=us-central1 \
    --update-env-vars="RATE_LIMIT_REQUESTS=200"
```

### Update secrets:

```bash
echo -n "NEW_PASSWORD" | gcloud secrets versions add db-password --data-file=-

# Cloud Run will use new secret on next deploy
gcloud run services update djaas-api --region=us-central1
```

### Scale instances:

```bash
gcloud run services update djaas-api \
    --region=us-central1 \
    --min-instances=1 \
    --max-instances=10
```

## Database Management

### Connect via Cloud SQL Proxy:

```bash
# Start proxy
cloud-sql-proxy $CONNECTION_NAME --port=5433

# Connect with psql
psql "host=localhost port=5433 dbname=djaas user=djaas"
```

### Backup database:

```bash
# Start proxy
cloud-sql-proxy $CONNECTION_NAME --port=5433 &

# Backup
pg_dump -h localhost -p 5433 -U djaas -d djaas --no-owner --no-privileges -f backup.sql
```

### Restore database:

```bash
psql -h localhost -p 5433 -U djaas -d djaas -f backup.sql
```

### Automated backups (already configured):

Cloud SQL automatically backs up your database daily at 3 AM.

View backups:
```bash
gcloud sql backups list --instance=djaas-db
```

Restore from backup:
```bash
gcloud sql backups restore BACKUP_ID --backup-instance=djaas-db --restore-instance=djaas-db
```

## Cost Management

### Check current usage:

```bash
# Cloud Run requests
gcloud logging read "resource.type=cloud_run_revision" --limit=10

# View billing
gcloud billing accounts list
```

### Stay within FREE tier:

**Cloud Run:**
- 2M requests/month = ~65K requests/day
- 360K GB-seconds/month with 512MB = ~20 hours/day runtime
- **Tip**: Set `--min-instances=0` so it scales to zero when not used

**Artifact Registry:**
- 0.5 GB storage free = ~5-10 Docker images

**Cloud SQL:**
- Use db-f1-micro (smallest instance) = ~$10/month after trial
- **Tip**: Stop instance when not in use to save costs

### Stop Cloud SQL when not needed:

```bash
# Stop instance (saves ~$10/month)
gcloud sql instances patch djaas-db --activation-policy=NEVER

# Start instance when needed
gcloud sql instances patch djaas-db --activation-policy=ALWAYS
```

## Security Best Practices

### 1. Use IAM for Authentication (Remove --allow-unauthenticated)

```bash
gcloud run services update djaas-api \
    --region=us-central1 \
    --no-allow-unauthenticated

# Call with authentication
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL/health
```

### 2. Use VPC Connector for Private Cloud SQL Access

```bash
# Create VPC connector
gcloud compute networks vpc-access connectors create djaas-connector \
    --region=us-central1 \
    --range=10.8.0.0/28

# Update Cloud Run to use connector
gcloud run services update djaas-api \
    --region=us-central1 \
    --vpc-connector=djaas-connector \
    --vpc-egress=private-ranges-only
```

### 3. Rotate Secrets Regularly

```bash
# Add new secret version
echo -n "NEW_PASSWORD" | gcloud secrets versions add db-password --data-file=-

# Update database password
gcloud sql users set-password djaas \
    --instance=djaas-db \
    --password=NEW_PASSWORD

# Redeploy to use new secret
gcloud run services update djaas-api --region=us-central1
```

### 4. Enable Cloud Armor (DDoS Protection)

```bash
# Create security policy
gcloud compute security-policies create djaas-policy \
    --description="DJaaS DDoS protection"

# Add rate limiting rule
gcloud compute security-policies rules create 1000 \
    --security-policy=djaas-policy \
    --expression="true" \
    --action=rate-based-ban \
    --rate-limit-threshold-count=100 \
    --rate-limit-threshold-interval-sec=60
```

## Monitoring and Alerts

### Set up uptime check:

```bash
# Via web console: https://console.cloud.google.com/monitoring/uptime
# Configure uptime check for: https://YOUR_SERVICE_URL/health
```

### Create alert for high error rate:

```bash
# Via web console: https://console.cloud.google.com/monitoring/alerting
# Alert when: Error rate > 5% for 5 minutes
```

### View metrics dashboard:

Visit: https://console.cloud.google.com/run/detail/us-central1/djaas-api/metrics

## Troubleshooting

### Issue: Container fails to start

**Check logs:**
```bash
gcloud run logs read --service=djaas-api --region=us-central1 --limit=100
```

**Common causes:**
- Database connection issues (check Cloud SQL connection name)
- Missing environment variables
- Port mismatch (must listen on PORT env var)

### Issue: Database connection timeout

**Check:**
- Cloud SQL instance is running: `gcloud sql instances describe djaas-db`
- Correct connection name in Cloud Run env vars
- Service account has Cloud SQL Client role

**Fix:**
```bash
# Grant Cloud SQL access
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/cloudsql.client"
```

### Issue: 403 Forbidden

**Cause:** Service requires authentication

**Fix:** Either allow unauthenticated access or include auth token:
```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL/health
```

### Issue: High costs

**Check billing:**
```bash
gcloud billing accounts list
```

**Reduce costs:**
- Stop Cloud SQL when not needed
- Set `--max-instances=1` on Cloud Run
- Delete old container images in Artifact Registry

## Clean Up Resources

### Delete everything:

```bash
# Delete Cloud Run service
gcloud run services delete djaas-api --region=us-central1 --quiet

# Delete Cloud SQL instance
gcloud sql instances delete djaas-db --quiet

# Delete Artifact Registry repository
gcloud artifacts repositories delete djaas --location=us-central1 --quiet

# Delete secrets
gcloud secrets delete db-password --quiet

# Delete entire project (CAREFUL!)
# gcloud projects delete YOUR_PROJECT_ID
```

### Delete only Cloud Run service (keep database):

```bash
gcloud run services delete djaas-api --region=us-central1 --quiet
```

## CI/CD with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]

env:
  PROJECT_ID: your-project-id
  REGION: us-central1
  SERVICE_NAME: djaas-api

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - id: auth
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1

      - name: Configure Docker
        run: gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev

      - name: Build and Push
        run: |
          IMAGE_URL=${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/djaas/${{ env.SERVICE_NAME }}:${{ github.sha }}
          docker build -t $IMAGE_URL -f docker/Dockerfile .
          docker push $IMAGE_URL

      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy ${{ env.SERVICE_NAME }} \
            --image=${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/djaas/${{ env.SERVICE_NAME }}:${{ github.sha }} \
            --region=${{ env.REGION }} \
            --platform=managed
```

## Custom Domain

### Add custom domain:

```bash
# Map domain to Cloud Run
gcloud run domain-mappings create \
    --service=djaas-api \
    --domain=api.yourdomain.com \
    --region=us-central1

# Follow instructions to configure DNS records
```

Visit: https://console.cloud.google.com/run/domains

## Free Tier Limits Summary

| Service | Free Tier | After Free Tier |
|---------|-----------|-----------------|
| **Cloud Run** | 2M requests/month<br>360K GB-seconds/month<br>180K vCPU-seconds/month | $0.00002400/GB-second<br>$0.00001000/vCPU-second |
| **Cloud SQL** | 30-day trial | db-f1-micro: ~$10/month |
| **Artifact Registry** | 0.5 GB storage | $0.10/GB/month |
| **Secret Manager** | 6 secret versions | $0.06/version/month |
| **Cloud Build** | 120 build-minutes/day | $0.003/build-minute |

**Estimated monthly cost after free trial**: ~$10-15/month (mostly Cloud SQL)

## Support and Resources

- Cloud Run Docs: https://cloud.google.com/run/docs
- Cloud SQL Docs: https://cloud.google.com/sql/docs
- Pricing Calculator: https://cloud.google.com/products/calculator
- Community Support: https://stackoverflow.com/questions/tagged/google-cloud-run

## Next Steps

1. ✅ Deploy with the script
2. Test all endpoints
3. Set up custom domain (optional)
4. Configure monitoring and alerts
5. Set up CI/CD with GitHub Actions
6. Consider VPC connector for enhanced security
7. Enable Cloud Armor for DDoS protection

Happy deploying! 🚀
