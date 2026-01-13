#!/usr/bin/env bash
set -euo pipefail

############################################
# PostgreSQL Backup Script
#
# Creates timestamped dumps of all databases.
# Run via cron for automated backups.
############################################

BACKUP_DIR="/srv/data/postgres/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=7

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

log_info "Starting PostgreSQL backup at ${TIMESTAMP}..."

# Get list of databases (excluding templates)
DATABASES=$(docker exec postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';" | tr -d ' ')

# Backup each database
for DB in ${DATABASES}; do
    if [[ -n "${DB}" ]]; then
        BACKUP_FILE="${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql.gz"
        log_info "Backing up database: ${DB}..."

        if docker exec postgres pg_dump -U postgres "${DB}" | gzip > "${BACKUP_FILE}"; then
            log_info "  -> ${BACKUP_FILE}"
        else
            log_error "  Failed to backup ${DB}"
        fi
    fi
done

# Also create a full cluster backup (all databases)
FULL_BACKUP="${BACKUP_DIR}/full_cluster_${TIMESTAMP}.sql.gz"
log_info "Creating full cluster backup..."
if docker exec postgres pg_dumpall -U postgres | gzip > "${FULL_BACKUP}"; then
    log_info "  -> ${FULL_BACKUP}"
else
    log_error "  Failed to create full cluster backup"
fi

# Cleanup old backups
log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete

# List current backups
log_info "Current backups:"
ls -lh "${BACKUP_DIR}"/*.sql.gz 2>/dev/null || echo "  No backups found"

log_info "Backup complete!"
