# Haven Home Manager - GCP Deployment Guide

This guide covers deploying Haven to Google Cloud Platform using Cloud Run, Cloud SQL, and Cloud Storage.

## Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and authenticated
- Docker installed locally (for building images)

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐
│   Cloud Run     │     │   Cloud Run     │
│   (Web App)     │────▶│   (API)         │
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
            ┌───────────┐ ┌───────────┐ ┌───────────┐
            │ Cloud SQL │ │   Cloud   │ │  Redis    │
            │ (Postgres)│ │  Storage  │ │  (Memorystore)│
            └───────────┘ └───────────┘ └───────────┘
```

## GCP Services Required

| Service | Purpose |
|---------|---------|
| Cloud Run | Hosting API and Web containers |
| Cloud SQL | PostgreSQL database |
| Cloud Storage | File uploads (GCS) |
| Memorystore | Redis for caching/WebSocket |
| Secret Manager | Storing sensitive credentials |
| Cloud Build | CI/CD (optional) |

## Environment Variables

### API Service (`apps/api`)

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host/db` |
| `JWT_SECRET` | Secret for JWT signing | `openssl rand -base64 32` |
| `JWT_EXPIRES_IN` | Access token expiration | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiration | `7d` |
| `GCP_PROJECT_ID` | GCP project ID | `my-haven-project` |
| `GCS_BUCKET_NAME` | Cloud Storage bucket | `haven-uploads` |
| `REDIS_URL` | Memorystore Redis URL | `redis://10.0.0.3:6379` |
| `STRIPE_SECRET_KEY` | Stripe API key | `sk_live_...` |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret | `whsec_...` |

### Web Service (`apps/web`)

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | API base URL | `https://api.haven.example.com` |

## IAM Roles Required

### Cloud Run Service Account

Create a dedicated service account for the API service:

```bash
# Create service account
gcloud iam service-accounts create haven-api \
  --display-name="Haven API Service Account"

# Get the service account email
SA_EMAIL="haven-api@${PROJECT_ID}.iam.gserviceaccount.com"
```

Required roles:

| Role | Purpose |
|------|---------|
| `roles/cloudsql.client` | Connect to Cloud SQL |
| `roles/storage.objectAdmin` | Upload/download files from GCS |
| `roles/secretmanager.secretAccessor` | Access secrets |
| `roles/logging.logWriter` | Write logs to Cloud Logging |

```bash
# Grant roles to service account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.logWriter"
```

## Step-by-Step Deployment

### 1. Set up GCP Project

```bash
# Set project
export PROJECT_ID="your-project-id"
export REGION="us-central1"

gcloud config set project ${PROJECT_ID}
gcloud config set run/region ${REGION}

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  redis.googleapis.com
```

### 2. Create Cloud SQL Instance

```bash
# Create PostgreSQL instance
gcloud sql instances create haven-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=${REGION} \
  --storage-type=SSD \
  --storage-size=10GB

# Create database
gcloud sql databases create haven --instance=haven-db

# Create user
gcloud sql users create haven \
  --instance=haven-db \
  --password="$(openssl rand -base64 24)"
```

### 3. Create Cloud Storage Bucket

```bash
# Create bucket for file uploads
gsutil mb -l ${REGION} gs://${PROJECT_ID}-haven-uploads

# Set CORS policy for signed URLs
cat > cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
EOF

gsutil cors set cors.json gs://${PROJECT_ID}-haven-uploads
```

### 4. Store Secrets

```bash
# Store JWT secret
echo -n "$(openssl rand -base64 32)" | \
  gcloud secrets create jwt-secret --data-file=-

# Store database password
echo -n "your-db-password" | \
  gcloud secrets create db-password --data-file=-

# Store Stripe keys
echo -n "sk_live_..." | \
  gcloud secrets create stripe-secret-key --data-file=-
```

### 5. Build and Push Docker Images

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build and push API image
docker build -t gcr.io/${PROJECT_ID}/haven-api:latest -f apps/api/Dockerfile .
docker push gcr.io/${PROJECT_ID}/haven-api:latest

# Build and push Web image
docker build -t gcr.io/${PROJECT_ID}/haven-web:latest \
  --build-arg NEXT_PUBLIC_API_URL=https://api.haven.example.com \
  -f apps/web/Dockerfile .
docker push gcr.io/${PROJECT_ID}/haven-web:latest
```

### 6. Deploy to Cloud Run

```bash
# Deploy API
gcloud run deploy haven-api \
  --image=gcr.io/${PROJECT_ID}/haven-api:latest \
  --platform=managed \
  --region=${REGION} \
  --service-account=${SA_EMAIL} \
  --add-cloudsql-instances=${PROJECT_ID}:${REGION}:haven-db \
  --set-env-vars="NODE_ENV=production" \
  --set-env-vars="GCP_PROJECT_ID=${PROJECT_ID}" \
  --set-env-vars="GCS_BUCKET_NAME=${PROJECT_ID}-haven-uploads" \
  --set-secrets="JWT_SECRET=jwt-secret:latest" \
  --set-secrets="DATABASE_URL=db-connection-string:latest" \
  --set-secrets="STRIPE_SECRET_KEY=stripe-secret-key:latest" \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=10

# Deploy Web
gcloud run deploy haven-web \
  --image=gcr.io/${PROJECT_ID}/haven-web:latest \
  --platform=managed \
  --region=${REGION} \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=5
```

### 7. Set up Custom Domain (Optional)

```bash
# Map custom domain to API
gcloud run domain-mappings create \
  --service=haven-api \
  --domain=api.haven.example.com \
  --region=${REGION}

# Map custom domain to Web
gcloud run domain-mappings create \
  --service=haven-web \
  --domain=haven.example.com \
  --region=${REGION}
```

## Local Development with Docker

For local development, use the provided `docker-compose.yml`:

```bash
# Start Postgres and Redis only
docker-compose up -d postgres redis

# Run API locally
cd apps/api
cp .env.example .env.local
# Edit .env.local with your settings
pnpm dev

# Run Web locally (in another terminal)
cd apps/web
pnpm dev
```

## CI/CD with Cloud Build (Optional)

Create `cloudbuild.yaml` in the repository root:

```yaml
steps:
  # Build API
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/haven-api:$COMMIT_SHA', '-f', 'apps/api/Dockerfile', '.']

  # Build Web
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/haven-web:$COMMIT_SHA'
      - '--build-arg'
      - 'NEXT_PUBLIC_API_URL=https://api.haven.example.com'
      - '-f'
      - 'apps/web/Dockerfile'
      - '.'

  # Push images
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/haven-api:$COMMIT_SHA']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/haven-web:$COMMIT_SHA']

  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - 'haven-api'
      - '--image'
      - 'gcr.io/$PROJECT_ID/haven-api:$COMMIT_SHA'
      - '--region'
      - 'us-central1'
      - '--platform'
      - 'managed'

images:
  - 'gcr.io/$PROJECT_ID/haven-api:$COMMIT_SHA'
  - 'gcr.io/$PROJECT_ID/haven-web:$COMMIT_SHA'
```

## Troubleshooting

### Database Connection Issues

1. Verify Cloud SQL instance is running
2. Check service account has `cloudsql.client` role
3. Ensure Cloud SQL Admin API is enabled
4. Check connection string format: `postgresql://user:pass@/db?host=/cloudsql/PROJECT:REGION:INSTANCE`

### File Upload Issues

1. Verify GCS bucket exists and is in correct region
2. Check service account has `storage.objectAdmin` role
3. Verify CORS settings on the bucket
4. Check `GCS_BUCKET_NAME` environment variable

### Signed URL Errors

1. Ensure service account can sign URLs (needs `iam.serviceAccounts.signBlob` permission)
2. Check token/key expiration settings

## Cost Optimization

- Use Cloud Run minimum instances = 0 for dev/staging
- Consider reserved capacity for production
- Use Cloud SQL db-f1-micro for development
- Set storage lifecycle policies on GCS bucket
- Use Memorystore Basic tier for development
