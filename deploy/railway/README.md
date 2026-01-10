# Railway Deployment Guide

Deploy DJaaS to Railway in **5 minutes** with zero CLI setup!

## Why Railway?

✅ **$5 free credit per month** (enough for small apps)
✅ **No credit card required** to start
✅ **Web UI only** - no CLI installation needed
✅ **Free PostgreSQL** database included
✅ **Automatic HTTPS** with custom domains
✅ **Auto-deploy** on git push

## Cost

- **Free**: $5 credit/month (covers ~550 hours of runtime)
- **Usage-based pricing**: Only pay for what you use
- **Estimate**: Small app with DB = ~$3-5/month

## Prerequisites

Make sure you have:
- ✅ Pushed your code to GitHub
- ✅ A `Dockerfile` at the root of your repo (already included)

## Quick Start

### Step 1: Sign Up for Railway

1. Go to https://railway.app
2. Click "Login" (top right)
3. Sign in with GitHub
4. **No credit card required!**

### Step 2: Create New Project

1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Select your `djaas` repository
4. Railway will detect the Dockerfile automatically (at the root of the repo)

### Step 3: Add PostgreSQL Database

1. In your project, click "+ New"
2. Select "Database"
3. Choose "PostgreSQL"
4. Railway creates and connects it automatically

### Step 4: Configure Environment Variables

Railway auto-configures most variables, but you need to add these:

1. Click on your `djaas` service
2. Go to "Variables" tab
3. Click "New Variable" and add each of these:

```
PORT=8080
ENV=production
LOG_LEVEL=info
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=1m
```

**Database variables** (Railway auto-injects these, so you need to map them):

Railway provides `DATABASE_URL`, but we need individual variables. Add these **RAW Editor** mode:

```bash
PORT=8080
ENV=production
LOG_LEVEL=info
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=1m

# Map Railway's auto-injected Postgres vars
DB_HOST=${{Postgres.PGHOST}}
DB_PORT=${{Postgres.PGPORT}}
DB_USER=${{Postgres.PGUSER}}
DB_PASSWORD=${{Postgres.PGPASSWORD}}
DB_NAME=${{Postgres.PGDATABASE}}
DB_SSLMODE=disable
DB_MAX_CONNECTIONS=25
DB_MAX_IDLE_CONNECTIONS=5
```

### Step 5: Run Migrations

Railway doesn't automatically run migrations, so we need to do it manually once.

**Option A: Using Railway CLI (Easiest)**

Install Railway CLI:
```bash
# Windows (PowerShell)
iwr https://railway.app/install.ps1 | iex

# macOS/Linux
curl -fsSL https://railway.app/install.sh | sh
```

Run migrations:
```bash
# Login
railway login

# Link to your project
railway link

# Connect to database and run migrations
railway run psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f migrations/000001_init.up.sql
railway run psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f migrations/000002_add_category.up.sql
railway run psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f migrations/000003_add_tags.up.sql
railway run psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f scripts/seed.sql
railway run psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f scripts/seed_tags.sql
```

**Option B: Using Railway Web Terminal**

1. In Railway dashboard, click on your Postgres service
2. Click "Connect" tab
3. Click "Connect to Postgres" (opens web terminal)
4. Copy/paste the SQL from migration files:
   - Copy contents of `migrations/000001_init.up.sql` and paste
   - Copy contents of `migrations/000002_add_category.up.sql` and paste
   - Copy contents of `migrations/000003_add_tags.up.sql` and paste
   - Copy contents of `scripts/seed.sql` and paste
   - Copy contents of `scripts/seed_tags.sql` and paste

**Option C: Using TablePlus/pgAdmin**

1. In Railway dashboard, click your Postgres service
2. Click "Connect"
3. Copy the connection details
4. Connect with your favorite PostgreSQL client
5. Run the migration files manually

### Step 6: Deploy!

Railway automatically deploys when you push to GitHub. Or:

1. Click "Deploy" in the Railway dashboard
2. Wait ~2-3 minutes for build
3. Your app will be live!

### Step 7: Get Your URL

1. Click on your service in Railway
2. Go to "Settings" tab
3. Scroll to "Domains"
4. Click "Generate Domain"
5. You'll get a URL like: `https://djaas-production.up.railway.app`

## Testing Your Deployment

```bash
# Replace with your Railway URL
URL="https://your-app.up.railway.app"

# Health check
curl $URL/health

# Get random joke
curl $URL/api/v1/joke

# Search
curl "$URL/api/v1/joke?search=science"

# Filter by tags
curl "$URL/api/v1/joke?tags=wordplay"

# Combined filters
curl "$URL/api/v1/joke?tags=puns&category=food&search=cheese"
```

## Custom Domain (Optional)

1. In your service, go to "Settings" > "Domains"
2. Click "Add Custom Domain"
3. Enter your domain (e.g., `api.yourdomain.com`)
4. Add the CNAME record to your DNS:
   ```
   CNAME api.yourdomain.com -> your-app.up.railway.app
   ```
5. Railway auto-provisions SSL certificate

## Auto-Deploy on Git Push

Railway automatically deploys when you push to your GitHub repo's main branch.

To disable auto-deploy:
1. Go to "Settings"
2. Under "Service Settings" > "Deploy Triggers"
3. Toggle off "Automatic Deploys"

## Environment-Specific Settings

Railway sets `RAILWAY_ENVIRONMENT` automatically:

- `production` - main branch
- `staging` - develop branch (if configured)

## Viewing Logs

1. Click on your service
2. Go to "Deployments" tab
3. Click on the latest deployment
4. View live logs

Or use Railway CLI:
```bash
railway logs
```

## Monitoring

Railway provides built-in metrics:

1. Click on your service
2. Go to "Metrics" tab
3. View:
   - CPU usage
   - Memory usage
   - Network traffic
   - Request count

## Cost Management

### Check Current Usage

1. Click on your project
2. Go to "Usage" tab
3. See current month's usage and cost

### Set Budget Alerts

1. Go to "Settings"
2. Set usage limits
3. Get notified when approaching limit

### Optimize Costs

**Tips to stay within free tier:**
- Use smallest Postgres plan (starts at $5/month)
- Set `MIN_INSTANCES=0` to scale to zero when idle
- Monitor usage regularly

## Troubleshooting

### App Won't Start

**Check logs:**
1. Go to "Deployments"
2. Click latest deployment
3. View build and runtime logs

**Common issues:**
- Database not connected (check env vars)
- Port mismatch (must use PORT env var)
- Missing migrations (run migrations manually)

### Database Connection Issues

**Check database is running:**
1. Click on Postgres service
2. Should show "Active"

**Verify environment variables:**
1. Click on your app service
2. Go to "Variables"
3. Ensure all DB_* variables are set correctly

**Test database connection:**
```bash
railway run psql
# Should connect to database
\dt  # List tables
```

### Migrations Failed

Railway doesn't run migrations automatically. See Step 5 above to run them manually.

### High Costs

**Check what's using resources:**
1. Go to "Usage" tab
2. See breakdown by service
3. Optimize:
   - Reduce Postgres size
   - Scale to zero when idle
   - Review deployed services

## Updating Your App

### Option 1: Git Push (Automatic)

```bash
# Make changes locally
git add .
git commit -m "Update feature"
git push

# Railway auto-deploys
```

### Option 2: Manual Deploy

1. Push changes to GitHub
2. In Railway dashboard, click "Deploy"
3. Select the commit to deploy

### Rolling Back

1. Go to "Deployments"
2. Find previous working deployment
3. Click "⋯" menu
4. Select "Redeploy"

## Database Backups

Railway doesn't auto-backup on free tier.

**Manual backup:**

Using Railway CLI:
```bash
railway run pg_dump > backup.sql
```

Using web terminal:
1. Connect to Postgres
2. Run: `pg_dump > /tmp/backup.sql`
3. Download backup file

**Automated backups:**
- Upgrade to Railway Pro ($20/month)
- Automatic daily backups included

## Scaling

### Horizontal Scaling

Railway doesn't support multiple instances on free tier.

**To scale:**
1. Upgrade to Pro plan
2. Set replicas in service settings
3. Railway handles load balancing

### Vertical Scaling

Adjust resources:
1. Go to service "Settings"
2. Under "Resources"
3. Adjust CPU/Memory limits

## CI/CD Integration

Railway works great with GitHub Actions:

```yaml
name: Deploy to Railway
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Railway
        run: |
          railway up --service djaas
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

Get token:
1. Railway dashboard > Settings > Tokens
2. Create new token
3. Add to GitHub Secrets as `RAILWAY_TOKEN`

## Support

- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway
- Status: https://status.railway.app

## Comparison: Railway vs Other Platforms

| Feature | Railway | Render | Fly.io | Google Cloud |
|---------|---------|--------|--------|--------------|
| **Free Tier** | $5 credit/month | 750 hours/month | 3 VMs free | $300 credit |
| **Setup Time** | 5 minutes | 10 minutes | 15 minutes | 30+ minutes |
| **CLI Required** | No | No | Yes | Yes |
| **Auto HTTPS** | ✅ | ✅ | ✅ | ✅ |
| **PostgreSQL** | $5/month | $7/month | Pay per use | ~$10/month |
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

## Next Steps

1. ✅ Deploy to Railway (5 minutes)
2. Run migrations
3. Test your live API
4. Set up custom domain (optional)
5. Enable auto-deploy on git push
6. Monitor usage and costs

Happy deploying! 🚀
