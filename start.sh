#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif podman compose version >/dev/null 2>&1; then
  COMPOSE=(podman compose)
else
  echo "Docker Compose or Podman Compose is required." >&2
  echo "Install Docker Desktop or Podman, then run this script again." >&2
  exit 1
fi

echo "Starting the lab database..."
"${COMPOSE[@]}" up -d --wait

echo "Opening psql. Type \\q to leave."
exec "${COMPOSE[@]}" exec postgres \
  psql -U "${POSTGRES_USER:-mdvai}" -d "${POSTGRES_DB:-model_data_verify_ai}"
