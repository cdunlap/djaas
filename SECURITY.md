# Security Guidelines

## Secrets Management

### Local Development (Docker Compose)

**NEVER commit credentials to version control!**

1. **Copy the example environment file:**
   ```bash
   cp .env.docker.example .env.docker
   ```

2. **Update `.env.docker` with your credentials:**
   - Change `POSTGRES_PASSWORD` to a strong password
   - Change `DB_PASSWORD` to match
   - `.env.docker` is gitignored and will NOT be committed

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

The `docker-compose.yml` file references `.env.docker` using `env_file`, keeping credentials out of version control.

### Production Deployment

**NEVER use the development credentials in production!**

#### AWS Deployment

Use AWS Secrets Manager or Parameter Store:

```bash
# Store database password in Secrets Manager
aws secretsmanager create-secret \
  --name djaas/db-password \
  --secret-string "YOUR_STRONG_PASSWORD"

# ECS Task Definition
{
  "secrets": [
    {
      "name": "DB_PASSWORD",
      "valueFrom": "arn:aws:secretsmanager:region:account:secret:djaas/db-password"
    }
  ]
}
```

#### Google Cloud Deployment

Use Secret Manager:

```bash
# Create secret
echo -n "YOUR_STRONG_PASSWORD" | gcloud secrets create db-password --data-file=-

# Cloud Run deployment
gcloud run deploy djaas \
  --image gcr.io/project/djaas:latest \
  --set-secrets DB_PASSWORD=db-password:latest
```

#### Azure Deployment

Use Azure Key Vault:

```bash
# Create secret
az keyvault secret set \
  --vault-name djaas-vault \
  --name db-password \
  --value "YOUR_STRONG_PASSWORD"

# Container Apps deployment
az containerapp create \
  --name djaas \
  --secrets db-password=keyvaultref:https://djaas-vault.vault.azure.net/secrets/db-password
```

#### Kubernetes

Use Kubernetes Secrets:

```bash
# Create secret
kubectl create secret generic djaas-db \
  --from-literal=password=YOUR_STRONG_PASSWORD

# Deployment manifest
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: djaas-db
        key: password
```

## Security Checklist

### Before Deploying to Production

- [ ] All passwords changed from defaults
- [ ] Database password is strong (20+ characters, mixed case, numbers, symbols)
- [ ] Secrets stored in proper secret management system (NOT in code/config)
- [ ] `.env.docker` and `.env` files are gitignored
- [ ] `DB_SSLMODE=require` in production
- [ ] `ENV=production` to enable rate limiting
- [ ] HTTPS/TLS enabled (handled by load balancer)
- [ ] Database not publicly accessible (private subnet)
- [ ] Security groups/firewall rules properly configured
- [ ] Regular dependency updates scheduled

### Environment-Specific Settings

| Setting | Development | Production |
|---------|------------|------------|
| `DB_PASSWORD` | From `.env.docker` | From secrets manager |
| `DB_SSLMODE` | `disable` | `require` |
| `ENV` | `development` | `production` |
| `LOG_LEVEL` | `debug` or `info` | `info` or `warn` |
| Rate Limiting | Disabled | Enabled |

## Common Security Mistakes to Avoid

1. ❌ Committing `.env.docker` or `.env` files
2. ❌ Using development passwords in production
3. ❌ Hardcoding credentials in docker-compose.yml
4. ❌ Exposing database ports publicly
5. ❌ Running containers as root (already handled in Dockerfile)
6. ❌ Using `sslmode=disable` in production
7. ❌ Storing secrets in environment variables in CI/CD logs

## Rotating Credentials

### Development

```bash
# 1. Update .env.docker with new password
# 2. Restart services
docker-compose down
docker-compose up -d
```

### Production

1. Create new secret in secret manager
2. Update application configuration to use new secret
3. Deploy new version
4. Verify application works
5. Update database password
6. Delete old secret

## Reporting Security Issues

If you discover a security vulnerability, please email security@yourcompany.com instead of creating a public issue.
