#!/usr/bin/env bash
set -euo pipefail

############################################
# PostgreSQL Restore Script
#
# Restores a database from a backup file.
############################################

BACKUP_DIR="/srv/data/postgres/backups"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 <backup_file> [database_name]"
    echo ""
    echo "Arguments:"
    echo "  backup_file    Path to .sql.gz backup file"
    echo "  database_name  Target database (optional, inferred from filename)"
    echo ""
    echo "Examples:"
    echo "  $0 ${BACKUP_DIR}/polyport_dev_20260113_120000.sql.gz"
    echo "  $0 ${BACKUP_DIR}/polyport_dev_20260113_120000.sql.gz polyport_dev"
    echo ""
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/*.sql.gz 2>/dev/null || echo "  No backups found"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

BACKUP_FILE="$1"
DATABASE="${2:-}"

# Validate backup file
if [[ ! -f "${BACKUP_FILE}" ]]; then
    log_error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Infer database name from filename if not provided
if [[ -z "${DATABASE}" ]]; then
    # Extract database name from filename like "polyport_dev_20260113_120000.sql.gz"
    FILENAME=$(basename "${BACKUP_FILE}")
    DATABASE=$(echo "${FILENAME}" | sed 's/_[0-9]\{8\}_[0-9]\{6\}\.sql\.gz$//')

    if [[ -z "${DATABASE}" || "${DATABASE}" == "${FILENAME}" ]]; then
        log_error "Could not infer database name from filename. Please provide it as second argument."
        exit 1
    fi
fi

log_warn "This will restore database: ${DATABASE}"
log_warn "From backup: ${BACKUP_FILE}"
log_warn ""
read -p "This may OVERWRITE existing data. Continue? (yes/no) " -r
echo

if [[ ! "${REPLY}" == "yes" ]]; then
    log_info "Aborted."
    exit 0
fi

# Check if database exists
DB_EXISTS=$(docker exec postgres psql -U postgres -t -c "SELECT 1 FROM pg_database WHERE datname = '${DATABASE}';" | tr -d ' ')

if [[ "${DB_EXISTS}" == "1" ]]; then
    log_info "Database ${DATABASE} exists. Dropping and recreating..."

    # Terminate connections
    docker exec postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DATABASE}' AND pid <> pg_backend_pid();" || true

    # Drop database
    docker exec postgres dropdb -U postgres "${DATABASE}" || true
fi

# Create database
log_info "Creating database ${DATABASE}..."
docker exec postgres createdb -U postgres "${DATABASE}"

# Restore
log_info "Restoring from backup..."
gunzip -c "${BACKUP_FILE}" | docker exec -i postgres psql -U postgres "${DATABASE}"

log_info "Restore complete!"
log_info "Database ${DATABASE} has been restored from ${BACKUP_FILE}"
