#!/bin/bash
# Setup Polyport - run this after docker compose up

set -e

cd "$(dirname "$0")/.."

echo "=== Polyport Setup ==="

# Wait for API to be healthy
echo "Waiting for API to be healthy..."
timeout=60
while [ $timeout -gt 0 ]; do
  if docker compose exec polyport-api wget -q --spider http://localhost:3001/health 2>/dev/null; then
    echo "API is healthy!"
    break
  fi
  sleep 2
  timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
  echo "ERROR: API did not become healthy in time"
  exit 1
fi

# Push database schema
echo "Pushing database schema..."
docker compose exec polyport-api /app/packages/db/node_modules/.bin/prisma db push --schema=/app/packages/db/prisma/schema.prisma

# Seed database
echo "Seeding database..."
./scripts/seed.sh

echo ""
echo "=== Setup Complete ==="
echo "Web UI: https://tictac232434.duckdns.org/polyport"
echo "API:    https://tictac232434.duckdns.org/polyport/api"
