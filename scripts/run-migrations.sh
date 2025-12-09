#!/bin/bash
set -e

# =============================================================================
# Haven Database Migration Script
# =============================================================================
# Runs Prisma migrations against Cloud SQL using Cloud SQL Proxy
#
# Prerequisites:
#   1. Cloud SQL Proxy running: cloud_sql_proxy -instances=PROJECT:REGION:haven-db=tcp:5432
#   2. Database password from Secret Manager or when you created the instance
#
# Usage:
#   ./scripts/run-migrations.sh <db-password>
# =============================================================================

if [ -z "$1" ]; then
    echo "Usage: $0 <database-password>"
    echo ""
    echo "Get your password from Secret Manager:"
    echo "  gcloud secrets versions access latest --secret=db-url"
    echo ""
    echo "Or reset it:"
    echo "  gcloud sql users set-password haven --instance=haven-db --password=<new-password>"
    exit 1
fi

DB_PASSWORD="$1"
export DATABASE_URL="postgresql://haven:${DB_PASSWORD}@localhost:5432/haven"

echo "Running database migrations..."
cd apps/api
npx prisma migrate deploy

echo ""
echo "Seeding demo data..."
npx prisma db seed

echo ""
echo "✅ Migrations complete! Your database is ready."
echo ""
echo "Demo accounts:"
echo "  demo@haven.app / Demo123!"
echo "  manager@haven.app / Manager123!"
echo "  admin@haven.app / Admin123!"
