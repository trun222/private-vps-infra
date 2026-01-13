#!/usr/bin/env bash
set -euo pipefail

#############################################
# VPS Infrastructure Setup Script
#
# Creates the ~/srv directory structure and
# copies all configuration files into place.
#############################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRV_DIR="${HOME}/srv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#############################################
# Create directory structure
#############################################
create_directories() {
    log_info "Creating directory structure at ${SRV_DIR}..."

    # Core infra directories
    mkdir -p "${SRV_DIR}/infra/observability/prometheus/rules"
    mkdir -p "${SRV_DIR}/infra/observability/loki"
    mkdir -p "${SRV_DIR}/infra/observability/alloy"
    mkdir -p "${SRV_DIR}/infra/observability/grafana/provisioning/datasources"
    mkdir -p "${SRV_DIR}/infra/scripts"
    mkdir -p "${SRV_DIR}/infra/caddy/data"
    mkdir -p "${SRV_DIR}/infra/caddy/config"

    # Apps directory (empty, apps added later)
    mkdir -p "${SRV_DIR}/apps"

    # Data directories for observability
    mkdir -p "${SRV_DIR}/data/observability/grafana"
    mkdir -p "${SRV_DIR}/data/observability/prometheus"
    mkdir -p "${SRV_DIR}/data/observability/loki"

    # Backups directories
    mkdir -p "${SRV_DIR}/backups/observability"

    log_info "Directory structure created."
}

#############################################
# Copy configuration files
#############################################
copy_configs() {
    log_info "Copying configuration files..."

    # Main infra files
    cp "${SCRIPT_DIR}/templates/infra/compose.yaml" "${SRV_DIR}/infra/compose.yaml"
    cp "${SCRIPT_DIR}/templates/infra/Caddyfile" "${SRV_DIR}/infra/Caddyfile"

    # .env from template (only if .env doesn't exist)
    if [[ ! -f "${SRV_DIR}/infra/.env" ]]; then
        cp "${SCRIPT_DIR}/templates/infra/.env.template" "${SRV_DIR}/infra/.env"
        log_warn ".env created from template - edit it with your actual values!"
    else
        log_info ".env already exists, skipping (won't overwrite)."
    fi

    # Observability configs
    cp "${SCRIPT_DIR}/templates/infra/observability/prometheus/prometheus.yml" \
       "${SRV_DIR}/infra/observability/prometheus/prometheus.yml"
    cp "${SCRIPT_DIR}/templates/infra/observability/prometheus/rules/core-alerts.yml" \
       "${SRV_DIR}/infra/observability/prometheus/rules/core-alerts.yml"
    cp "${SCRIPT_DIR}/templates/infra/observability/loki/config.yaml" \
       "${SRV_DIR}/infra/observability/loki/config.yaml"
    cp "${SCRIPT_DIR}/templates/infra/observability/alloy/config.alloy" \
       "${SRV_DIR}/infra/observability/alloy/config.alloy"
    cp "${SCRIPT_DIR}/templates/infra/observability/grafana/provisioning/datasources/datasources.yaml" \
       "${SRV_DIR}/infra/observability/grafana/provisioning/datasources/datasources.yaml"

    # Scripts
    cp "${SCRIPT_DIR}/templates/scripts/backup.sh" "${SRV_DIR}/infra/scripts/backup.sh"
    cp "${SCRIPT_DIR}/templates/scripts/restore.sh" "${SRV_DIR}/infra/scripts/restore.sh"
    cp "${SCRIPT_DIR}/templates/scripts/update.sh" "${SRV_DIR}/infra/scripts/update.sh"
    chmod +x "${SRV_DIR}/infra/scripts/"*.sh

    log_info "Configuration files copied."
}

#############################################
# Set permissions
#############################################
set_permissions() {
    log_info "Setting permissions..."

    # Container UID mappings:
    # - Grafana runs as UID 472
    # - Prometheus runs as UID 65534 (nobody)
    # - Loki runs as UID 10001
    chown -R 472:472 "${SRV_DIR}/data/observability/grafana"
    chown -R 65534:65534 "${SRV_DIR}/data/observability/prometheus"
    chown -R 10001:10001 "${SRV_DIR}/data/observability/loki"

    # Ensure directories are writable
    chmod -R 755 "${SRV_DIR}/data"
    chmod -R 755 "${SRV_DIR}/backups"

    # Protect .env file
    chmod 600 "${SRV_DIR}/infra/.env"

    log_info "Permissions set."
}

#############################################
# Print next steps
#############################################
print_next_steps() {
    echo ""
    log_info "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit ${SRV_DIR}/infra/.env with your actual values"
    echo "     - Set TS_AUTHKEY (Tailscale auth key)"
    echo "     - Set GRAFANA_ADMIN_PASSWORD"
    echo "     - Update CADDY_ACME_EMAIL"
    echo ""
    echo "  2. Update ${SRV_DIR}/infra/Caddyfile"
    echo "     - Replace 'tictac232434.duckdns.org' with your domain"
    echo "     - Update email in global block"
    echo ""
    echo "  3. Start the infrastructure:"
    echo "     cd ${SRV_DIR}/infra && docker compose up -d"
    echo ""
    echo "  4. Access Grafana at https://grafana.dev.internal (via Tailscale)"
    echo ""
}

#############################################
# Main
#############################################
main() {
    echo "============================================"
    echo "  VPS Infrastructure Setup"
    echo "============================================"
    echo ""

    # Check if already set up
    if [[ -d "${SRV_DIR}/infra" ]]; then
        log_warn "Directory ${SRV_DIR}/infra already exists."
        read -p "Continue and overwrite configs? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted."
            exit 0
        fi
    fi

    create_directories
    copy_configs
    set_permissions
    print_next_steps
}

main "$@"
