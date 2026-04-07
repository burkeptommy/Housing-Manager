#!/bin/bash
# ============================================================================
# Haven Supabase backup
# ============================================================================
#
# Dumps the entire haven-dev Supabase database to a local SQL file you can
# restore from with `psql -f <file>`. Reads the database password from the
# PGPASSWORD environment variable so it never appears on the command line
# or in shell history.
#
# USAGE
# -----
#   1. Get your database password from
#      https://supabase.com/dashboard/project/jsucwnkntdrxhysojgri/settings/database
#      (Connection info → Database password → Reveal/Reset)
#
#   2. From this terminal, run:
#        export PGPASSWORD='paste-your-db-password-here'
#        ./scripts/backup-supabase.sh
#
#   3. The script writes three files into ./backups/ :
#        haven-pre-reset-TS-full.sql        — schema + data, restorable to a fresh project
#        haven-pre-reset-TS-public-data.sql — data-only for the public schema (greppable)
#        haven-pre-reset-TS-auth-data.sql   — data-only for the auth schema (auth.users, etc.)
#
#   4. After it's done:
#        unset PGPASSWORD
#
# WHAT IT BACKS UP
# ----------------
# • public schema (all tables, including catalog tables)
# • auth schema (auth.users, identities, refresh_tokens, sessions)
# • storage schema (object metadata for ALL buckets — file blobs are not
#   included, see the storage backup note below)
#
# WHAT IT DOES NOT BACK UP
# ------------------------
# • Storage object file blobs (the actual PDFs / images / avatars in the
#   buckets). The metadata is captured but the binary contents stay in
#   Supabase's S3-backed object store. To back those up too, take a managed
#   backup from Project Settings → Database → Backups → "Take backup now",
#   which is the only way to get a Supabase-managed point-in-time snapshot
#   that includes storage blobs.
# • Edge function source — already in git, no action needed.
# • Edge function secrets — set per-environment, treat as recoverable from
#   1Password / wherever you store them.
#
# ============================================================================

set -euo pipefail

PROJECT_REF="jsucwnkntdrxhysojgri"
DB_HOST="db.${PROJECT_REF}.supabase.co"
DB_USER="postgres"
DB_NAME="postgres"
DB_PORT="5432"
PG_DUMP="/opt/homebrew/Cellar/postgresql@16/16.11/bin/pg_dump"

if [ -z "${PGPASSWORD:-}" ]; then
    echo "ERROR: PGPASSWORD is not set. See the comment block at the top of this script." >&2
    exit 1
fi

if [ ! -x "$PG_DUMP" ]; then
    echo "ERROR: pg_dump not found at $PG_DUMP" >&2
    exit 1
fi

mkdir -p backups
TS=$(date +%Y%m%d-%H%M%S)
BASE="backups/haven-pre-reset-${TS}"

CONN_ARGS=(
    -h "$DB_HOST"
    -p "$DB_PORT"
    -U "$DB_USER"
    -d "$DB_NAME"
)

echo "→ Backup 1/3: full dump (schema + data, public + auth + storage)"
"$PG_DUMP" "${CONN_ARGS[@]}" \
    --schema=public \
    --schema=auth \
    --schema=storage \
    --no-owner \
    --no-acl \
    --file="${BASE}-full.sql"

echo "→ Backup 2/3: public schema data only (greppable, fast restore)"
"$PG_DUMP" "${CONN_ARGS[@]}" \
    --schema=public \
    --data-only \
    --no-owner \
    --no-acl \
    --file="${BASE}-public-data.sql"

echo "→ Backup 3/3: auth schema data only (auth.users + sessions + identities)"
"$PG_DUMP" "${CONN_ARGS[@]}" \
    --schema=auth \
    --data-only \
    --no-owner \
    --no-acl \
    --file="${BASE}-auth-data.sql"

echo
echo "Done. Files written to ./backups/ :"
ls -lh "${BASE}-full.sql" "${BASE}-public-data.sql" "${BASE}-auth-data.sql"

echo
echo "Quick row count check (from the public-data.sql file):"
echo -n "  COPY statements (one per table with rows): "
grep -c "^COPY public\." "${BASE}-public-data.sql" || echo "0"

echo
echo "Now also take a managed backup from the dashboard:"
echo "  https://supabase.com/dashboard/project/${PROJECT_REF}/database/backups"
echo "  → 'Take backup now' (this captures storage object blobs too)"
echo
echo "When you're done, clear the password from your shell:"
echo "  unset PGPASSWORD"
