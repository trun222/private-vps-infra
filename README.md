# Private VPS Infrastructure

Infrastructure scaffolding for a Hetzner VPS with observability stack.

## Quick Start

```bash
# Clone and run setup
git clone <repo-url> && cd private-vps-infra
./setup.sh
```

This creates the following structure at `~/srv/`:

```
~/srv/
├── infra/
│   ├── compose.yaml          # Main Docker Compose
│   ├── .env                   # Environment variables (from template)
│   ├── Caddyfile              # Reverse proxy config
│   ├── caddy/                 # Caddy data/config volumes
│   ├── observability/
│   │   ├── prometheus/
│   │   │   ├── prometheus.yml
│   │   │   └── rules/
│   │   │       └── core-alerts.yml
│   │   ├── loki/
│   │   │   └── config.yaml
│   │   ├── alloy/
│   │   │   └── config.alloy
│   │   └── grafana/
│   │       └── provisioning/
│   │           └── datasources/
│   │               └── datasources.yaml
│   └── scripts/
│       ├── backup.sh
│       ├── restore.sh
│       └── update.sh
├── apps/                      # Your applications go here
├── data/
│   └── observability/
│       ├── grafana/
│       ├── prometheus/
│       └── loki/
└── backups/
    └── observability/
```

## After Setup

1. **Edit environment variables:**
   ```bash
   nano ~/srv/infra/.env
   ```
   - Set `TS_AUTHKEY` (Tailscale auth key)
   - Set `GRAFANA_ADMIN_PASSWORD`
   - Update `CADDY_ACME_EMAIL`

2. **Update Caddyfile** with your domain:
   ```bash
   nano ~/srv/infra/Caddyfile
   ```

3. **Start the stack:**
   ```bash
   cd ~/srv/infra
   docker compose up -d
   ```

4. **Access Grafana** at `https://grafana.dev.internal` (via Tailscale)

## Services

| Service | Purpose | Port |
|---------|---------|------|
| Caddy | Reverse proxy, HTTPS | 80, 443 |
| Tailscale | Mesh VPN | host network |
| Grafana | Dashboards | internal:3000 |
| Prometheus | Metrics | internal:9090 |
| Loki | Logs | internal:3100 |
| Alloy | Log collector | internal:12345 |
| Node Exporter | Host metrics | internal:9100 |
| cAdvisor | Container metrics | internal:8080 |

## Adding Apps

Create app directories under `~/srv/apps/<app-name>/` with their own `compose.yaml`.

To enable metrics scraping, add labels:
```yaml
labels:
  prometheus.scrape: "true"
  prometheus.port: "3001"
  app: "myapp"
  env: "dev"
  service: "api"
```

To enable log enrichment, add labels:
```yaml
labels:
  com.builtwithwisdom.app: "myapp"
  com.builtwithwisdom.env: "dev"
  com.builtwithwisdom.service: "api"
```

## Networks

- **edge**: Public-facing services (Caddy)
- **internal**: Private services (observability, apps)

Apps should join the `internal` network:
```yaml
networks:
  internal:
    external: true
    name: internal
```
