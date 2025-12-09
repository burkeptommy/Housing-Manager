#!/bin/bash
set -e

# =============================================================================
# Haven GCP Deployment Script
# =============================================================================
# This script deploys Haven to Google Cloud Platform
#
# Prerequisites:
#   1. gcloud CLI installed: https://cloud.google.com/sdk/docs/install
#   2. Docker installed: https://docs.docker.com/get-docker/
#   3. Logged into gcloud: gcloud auth login
#
# Usage:
#   ./scripts/deploy-gcp.sh <project-id> [region]
#
# Example:
#   ./scripts/deploy-gcp.sh my-haven-project us-central1
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 <project-id> [region]"
    log_info "Example: $0 my-haven-project us-central1"
    exit 1
fi

export PROJECT_ID="$1"
export REGION="${2:-us-central1}"

log_info "Deploying Haven to GCP"
log_info "Project: ${PROJECT_ID}"
log_info "Region: ${REGION}"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."
command -v gcloud >/dev/null 2>&1 || { log_error "gcloud CLI not installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { log_error "Docker not installed"; exit 1; }
log_success "Prerequisites OK"

# Set project
log_info "Setting GCP project..."
gcloud config set project ${PROJECT_ID}

# =============================================================================
# Step 1: Enable APIs
# =============================================================================
log_info "Enabling required GCP APIs (this may take a minute)..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  cloudscheduler.googleapis.com \
  --quiet
log_success "APIs enabled"

# =============================================================================
# Step 2: Create Cloud SQL Instance
# =============================================================================
log_info "Checking for existing Cloud SQL instance..."
if gcloud sql instances describe haven-db --quiet 2>/dev/null; then
    log_warn "Cloud SQL instance 'haven-db' already exists, skipping creation"
else
    log_info "Creating Cloud SQL PostgreSQL instance (this takes 5-10 minutes)..."
    gcloud sql instances create haven-db \
      --database-version=POSTGRES_15 \
      --tier=db-f1-micro \
      --region=${REGION} \
      --storage-type=SSD \
      --storage-size=10GB \
      --quiet

    log_info "Creating database..."
    gcloud sql databases create haven --instance=haven-db --quiet

    log_info "Creating database user..."
    DB_PASSWORD=$(openssl rand -base64 24)
    gcloud sql users create haven \
      --instance=haven-db \
      --password="${DB_PASSWORD}" \
      --quiet

    # Store the connection string
    DB_URL="postgresql://haven:${DB_PASSWORD}@/haven?host=/cloudsql/${PROJECT_ID}:${REGION}:haven-db"
    echo -n "${DB_URL}" | gcloud secrets create db-url --data-file=- --quiet 2>/dev/null || \
      echo -n "${DB_URL}" | gcloud secrets versions add db-url --data-file=-

    log_success "Cloud SQL instance created"
fi

# =============================================================================
# Step 3: Create Cloud Storage Bucket
# =============================================================================
BUCKET_NAME="${PROJECT_ID}-haven-uploads"
log_info "Checking for existing GCS bucket..."
if gsutil ls -b gs://${BUCKET_NAME} 2>/dev/null; then
    log_warn "Bucket '${BUCKET_NAME}' already exists, skipping creation"
else
    log_info "Creating Cloud Storage bucket..."
    gsutil mb -l ${REGION} gs://${BUCKET_NAME}

    # Set CORS
    cat > /tmp/cors.json << 'CORSEOF'
[{"origin": ["*"], "method": ["GET", "PUT", "POST"], "responseHeader": ["Content-Type"], "maxAgeSeconds": 3600}]
CORSEOF
    gsutil cors set /tmp/cors.json gs://${BUCKET_NAME}
    rm /tmp/cors.json
    log_success "GCS bucket created"
fi

# =============================================================================
# Step 4: Create Secrets
# =============================================================================
log_info "Setting up secrets..."

# JWT Secret
if gcloud secrets describe jwt-secret --quiet 2>/dev/null; then
    log_warn "Secret 'jwt-secret' already exists"
else
    openssl rand -base64 32 | gcloud secrets create jwt-secret --data-file=- --quiet
    log_success "Created jwt-secret"
fi

# Cron Secret
if gcloud secrets describe cron-secret --quiet 2>/dev/null; then
    log_warn "Secret 'cron-secret' already exists"
else
    openssl rand -hex 32 | gcloud secrets create cron-secret --data-file=- --quiet
    log_success "Created cron-secret"
fi

# Stripe Secret (placeholder - user should update)
if gcloud secrets describe stripe-secret-key --quiet 2>/dev/null; then
    log_warn "Secret 'stripe-secret-key' already exists"
else
    echo -n "sk_test_placeholder_update_me" | gcloud secrets create stripe-secret-key --data-file=- --quiet
    log_warn "Created stripe-secret-key with placeholder - UPDATE THIS with your real Stripe key!"
fi

# =============================================================================
# Step 5: Create Service Account
# =============================================================================
SA_NAME="haven-api"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

log_info "Setting up service account..."
if gcloud iam service-accounts describe ${SA_EMAIL} 2>/dev/null; then
    log_warn "Service account already exists"
else
    gcloud iam service-accounts create ${SA_NAME} \
      --display-name="Haven API Service Account" \
      --quiet
fi

# Grant roles
log_info "Granting IAM roles..."
for role in cloudsql.client storage.objectAdmin secretmanager.secretAccessor logging.logWriter; do
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="roles/${role}" \
      --quiet 2>/dev/null || true
done
log_success "Service account configured"

# =============================================================================
# Step 6: Build and Push Docker Images
# =============================================================================
log_info "Configuring Docker for GCR..."
gcloud auth configure-docker --quiet

log_info "Building API Docker image..."
docker build -t gcr.io/${PROJECT_ID}/haven-api:latest -f apps/api/Dockerfile .
log_info "Pushing API image..."
docker push gcr.io/${PROJECT_ID}/haven-api:latest
log_success "API image pushed"

# =============================================================================
# Step 7: Deploy API to Cloud Run
# =============================================================================
log_info "Deploying API to Cloud Run..."
gcloud run deploy haven-api \
  --image=gcr.io/${PROJECT_ID}/haven-api:latest \
  --platform=managed \
  --region=${REGION} \
  --service-account=${SA_EMAIL} \
  --add-cloudsql-instances=${PROJECT_ID}:${REGION}:haven-db \
  --set-env-vars="NODE_ENV=production,GCP_PROJECT_ID=${PROJECT_ID},GCS_BUCKET_NAME=${BUCKET_NAME}" \
  --set-secrets="JWT_SECRET=jwt-secret:latest,DATABASE_URL=db-url:latest,STRIPE_SECRET_KEY=stripe-secret-key:latest,CRON_SECRET=cron-secret:latest" \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=10 \
  --memory=512Mi \
  --quiet

API_URL=$(gcloud run services describe haven-api --region=${REGION} --format='value(status.url)')
log_success "API deployed at: ${API_URL}"

# =============================================================================
# Step 8: Build and Deploy Web
# =============================================================================
log_info "Building Web Docker image with API URL: ${API_URL}/api"
docker build -t gcr.io/${PROJECT_ID}/haven-web:latest \
  --build-arg NEXT_PUBLIC_API_URL=${API_URL}/api \
  -f apps/web/Dockerfile .
log_info "Pushing Web image..."
docker push gcr.io/${PROJECT_ID}/haven-web:latest

log_info "Deploying Web to Cloud Run..."
gcloud run deploy haven-web \
  --image=gcr.io/${PROJECT_ID}/haven-web:latest \
  --platform=managed \
  --region=${REGION} \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=5 \
  --memory=512Mi \
  --quiet

WEB_URL=$(gcloud run services describe haven-web --region=${REGION} --format='value(status.url)')
log_success "Web deployed at: ${WEB_URL}"

# =============================================================================
# Step 9: Run Database Migrations
# =============================================================================
log_info "Running database migrations..."
log_warn "You need to run migrations manually. Use Cloud SQL Proxy:"
echo ""
echo "  # In a separate terminal, run:"
echo "  cloud_sql_proxy -instances=${PROJECT_ID}:${REGION}:haven-db=tcp:5432"
echo ""
echo "  # Then in another terminal:"
echo "  cd apps/api"
echo "  DATABASE_URL=\"postgresql://haven:<password>@localhost:5432/haven\" npx prisma migrate deploy"
echo "  DATABASE_URL=\"postgresql://haven:<password>@localhost:5432/haven\" npx prisma db seed"
echo ""

# =============================================================================
# Step 10: Set up Cloud Scheduler
# =============================================================================
log_info "Setting up Cloud Scheduler for cron jobs..."

# Create scheduler service account
SCHEDULER_SA="haven-scheduler@${PROJECT_ID}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe ${SCHEDULER_SA} 2>/dev/null; then
    gcloud iam service-accounts create haven-scheduler \
      --display-name="Haven Cloud Scheduler" \
      --quiet
fi

gcloud run services add-iam-policy-binding haven-api \
  --region=${REGION} \
  --member="serviceAccount:${SCHEDULER_SA}" \
  --role="roles/run.invoker" \
  --quiet 2>/dev/null || true

CRON_SECRET=$(gcloud secrets versions access latest --secret=cron-secret)

# Create scheduler job
if gcloud scheduler jobs describe haven-reminder-cron --location=${REGION} 2>/dev/null; then
    log_warn "Scheduler job already exists, updating..."
    gcloud scheduler jobs update http haven-reminder-cron \
      --location=${REGION} \
      --schedule="0 8 * * *" \
      --uri="${API_URL}/api/internal/cron/run-reminder-jobs" \
      --http-method=POST \
      --headers="x-cron-secret=${CRON_SECRET},Content-Type=application/json" \
      --oidc-service-account-email="${SCHEDULER_SA}" \
      --quiet
else
    gcloud scheduler jobs create http haven-reminder-cron \
      --location=${REGION} \
      --schedule="0 8 * * *" \
      --uri="${API_URL}/api/internal/cron/run-reminder-jobs" \
      --http-method=POST \
      --headers="x-cron-secret=${CRON_SECRET},Content-Type=application/json" \
      --oidc-service-account-email="${SCHEDULER_SA}" \
      --time-zone="America/New_York" \
      --description="Runs Haven reminder jobs daily" \
      --quiet
fi
log_success "Cloud Scheduler configured"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "============================================================================="
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo "============================================================================="
echo ""
echo "Your Haven instance is now running at:"
echo ""
echo -e "  ${BLUE}Web App:${NC}  ${WEB_URL}"
echo -e "  ${BLUE}API:${NC}      ${API_URL}"
echo ""
echo "Demo Credentials:"
echo "  Email:    demo@haven.app"
echo "  Password: Demo123!"
echo ""
echo -e "${YELLOW}IMPORTANT: Before users can log in, you must run database migrations!${NC}"
echo ""
echo "Next Steps:"
echo "  1. Install Cloud SQL Proxy: https://cloud.google.com/sql/docs/postgres/sql-proxy"
echo "  2. Run: cloud_sql_proxy -instances=${PROJECT_ID}:${REGION}:haven-db=tcp:5432"
echo "  3. Get your DB password from Secret Manager or reset it"
echo "  4. Run migrations (see commands above)"
echo "  5. Update Stripe secret key: gcloud secrets versions add stripe-secret-key --data-file=-"
echo ""
echo "============================================================================="
