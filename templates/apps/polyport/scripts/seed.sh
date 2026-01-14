#!/bin/bash
# Seed the Polyport database with initial data

set -e

echo "Seeding Polyport database..."

# Create default workspace
docker compose exec -w /app/packages/db polyport-api node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const ws = await prisma.workspace.upsert({
    where: { id: 'default-workspace' },
    update: {},
    create: {
      id: 'default-workspace',
      name: 'Default Workspace',
      slug: 'default',
      plan: 'FREE',
      status: 'ACTIVE'
    }
  });
  console.log('Workspace created:', ws.id);
}
main().catch(console.error).finally(() => prisma.\$disconnect());
"

echo "Seeding complete!"
