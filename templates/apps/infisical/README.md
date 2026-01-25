# Infisical - Self-Hosted Secrets Manager

Infisical is an open-source secrets management platform for storing, syncing, and managing environment variables across your infrastructure.

## Architecture

```
                                    ┌─────────────────┐
                                    │     Caddy       │
                                    │  (HTTPS/TLS)    │
                                    └────────┬────────┘
                                             │
                                             ▼
┌─────────────────┐              ┌─────────────────────┐
│  infisical-redis│◄────────────►│     infisical       │
│  (Redis 7)      │              │  (Port 8080)        │
└─────────────────┘              └──────────┬──────────┘
                                            │
                                            ▼
                                 ┌─────────────────────┐
                                 │      postgres       │
                                 │  (Shared Cluster)   │
                                 └─────────────────────┘
```

## URLs

| Service | URL |
|---------|-----|
| Infisical Web UI | https://secrets.scalor.app |

## Quick Start

### 1. Ensure Prerequisites

Make sure the shared PostgreSQL cluster is running:
```bash
cd ~/srv/apps/postgres
docker compose ps
```

If not running:
```bash
docker compose up -d
```

### 2. Generate Security Keys

**CRITICAL**: Generate these keys ONCE and back them up securely. Losing these keys means losing access to all stored secrets!

```bash
# Generate encryption key (32-byte hex)
echo "ENCRYPTION_KEY=$(openssl rand -hex 16)"

# Generate auth secret (random base64 string)
echo "AUTH_SECRET=$(openssl rand -base64 32)"
```

### 3. Configure Environment

Edit `~/srv/apps/infisical/.env`:

```bash
nano ~/srv/apps/infisical/.env
```

Update these values:
- `ENCRYPTION_KEY` - Paste the generated encryption key
- `AUTH_SECRET` - Paste the generated auth secret
- `DB_CONNECTION_URI` - Update password to match `INFISICAL_PASS` from `~/srv/apps/postgres/.env`

### 4. Start Infisical

```bash
cd ~/srv/apps/infisical
docker compose up -d
```

### 5. Verify Startup

Check container status:
```bash
docker compose ps
```

Check logs:
```bash
docker logs infisical --tail 50
```

### 6. Initial Setup

1. Open https://secrets.scalor.app
2. Create your first admin account
3. Create an organization
4. Start adding projects and secrets

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ENCRYPTION_KEY` | 32-byte hex key for encrypting secrets at rest | Yes |
| `AUTH_SECRET` | JWT signing secret for authentication | Yes |
| `DB_CONNECTION_URI` | PostgreSQL connection string | Yes |
| `REDIS_URL` | Redis connection string | Yes |
| `SITE_URL` | Public URL for Infisical | Yes |
| `SMTP_*` | SMTP settings for email notifications | No |
| `TELEMETRY_ENABLED` | Enable/disable telemetry | No |

### Database

Infisical uses the shared PostgreSQL cluster:
- Database: `infisical`
- User: `infisical`
- Password: Set in `~/srv/apps/postgres/.env` as `INFISICAL_PASS`

## Operations

### View Logs

```bash
# Infisical app logs
docker logs infisical --tail 100 -f

# Redis logs
docker logs infisical-redis --tail 50
```

### Restart Services

```bash
cd ~/srv/apps/infisical

# Restart all
docker compose restart

# Restart specific service
docker compose restart infisical
```

### Stop Services

```bash
docker compose down
```

### Update Infisical

```bash
cd ~/srv/apps/infisical

# Pull latest image
docker compose pull

# Recreate with new image
docker compose up -d
```

## Backup

### Critical Data to Backup

1. **Encryption Key** - `ENCRYPTION_KEY` from `.env` (MOST CRITICAL)
2. **Auth Secret** - `AUTH_SECRET` from `.env`
3. **PostgreSQL Database** - `infisical` database

### Backup Database

```bash
# From VPS
docker exec postgres pg_dump -U infisical infisical > ~/srv/backups/infisical/infisical-$(date +%Y%m%d).sql

# Or via backup script
~/srv/infra/scripts/backup.sh infisical
```

### Restore Database

```bash
# Stop Infisical first
cd ~/srv/apps/infisical && docker compose down

# Restore
docker exec -i postgres psql -U infisical infisical < ~/srv/backups/infisical/infisical-YYYYMMDD.sql

# Restart
docker compose up -d
```

## Troubleshooting

### Container Won't Start

1. Check logs: `docker logs infisical`
2. Verify PostgreSQL is running and accessible
3. Verify Redis is healthy: `docker logs infisical-redis`
4. Check environment variables are set correctly

### Can't Connect to Database

1. Verify PostgreSQL password matches:
   - `INFISICAL_PASS` in `~/srv/apps/postgres/.env`
   - Password in `DB_CONNECTION_URI` in `~/srv/apps/infisical/.env`
2. Ensure database exists: `docker exec postgres psql -U postgres -c "\l" | grep infisical`

### 502 Bad Gateway

1. Check if container is running: `docker ps | grep infisical`
2. Check Caddy can reach the container (same network)
3. Verify Infisical is listening on port 8080

### Lost Encryption Key

**There is no recovery if you lose the encryption key**. All encrypted secrets will be permanently inaccessible. You would need to:
1. Start fresh with a new database
2. Re-enter all secrets

This is why backing up the `.env` file (especially `ENCRYPTION_KEY`) is critical.

## Security Considerations

1. **Backup encryption keys** to a secure location (password manager, hardware key, etc.)
2. **Use strong passwords** for the database user
3. **Enable SMTP** to receive security alerts
4. **Review access logs** regularly in Infisical dashboard
5. **Enable 2FA** for all users via Infisical settings

## Integration

### CLI Usage

Install the Infisical CLI:
```bash
# macOS
brew install infisical/get-cli/infisical

# Linux
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt-get install infisical
```

Login and pull secrets:
```bash
# Login
infisical login --domain https://secrets.scalor.app

# Pull secrets to .env file
infisical export --env=production > .env
```

### Docker Integration

Use Infisical in Docker Compose:
```yaml
services:
  myapp:
    image: myapp:latest
    environment:
      - INFISICAL_TOKEN=${INFISICAL_TOKEN}
    # Or use infisical CLI in entrypoint to inject secrets
```

## Files

| Path | Description |
|------|-------------|
| `~/srv/apps/infisical/compose.yaml` | Docker Compose configuration |
| `~/srv/apps/infisical/.env` | Environment variables (contains secrets!) |
| `~/srv/data/infisical/redis/` | Redis persistence data |
