#!/bin/sh
set -e

# Note: Database migrations should be run separately before deployment
# using: pnpm db:migrate (from local machine or CI/CD)

# If Infisical credentials are provided, use infisical run to inject secrets
if [ -n "$INFISICAL_MACHINE_IDENTITY_CLIENT_ID" ] && [ -n "$INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET" ]; then
  echo "Authenticating with Infisical (Universal Auth)..."

  # Login with Universal Auth Machine Identity and capture the token
  INFISICAL_TOKEN=$(infisical login \
    --method=universal-auth \
    --client-id="$INFISICAL_MACHINE_IDENTITY_CLIENT_ID" \
    --client-secret="$INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET" \
    --domain="${INFISICAL_API_URL:-https://secrets.scalor.app}" \
    --plain 2>/dev/null)

  if [ -z "$INFISICAL_TOKEN" ]; then
    echo "Failed to get Infisical token, starting without secret injection..."
    exec node dist/main.js
  fi

  echo "Starting API with Infisical secret injection (env: $INFISICAL_ENV)..."
  export INFISICAL_TOKEN
  exec infisical run \
    --domain "${INFISICAL_API_URL:-https://secrets.scalor.app}" \
    --projectId "$INFISICAL_PROJECT_ID" \
    --env "${INFISICAL_ENV:-dev}" \
    --token "$INFISICAL_TOKEN" \
    --recursive \
    -- node dist/main.js
else
  echo "Starting API without Infisical (using environment variables)..."
  exec node dist/main.js
fi
