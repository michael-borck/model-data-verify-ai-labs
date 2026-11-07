#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

POSTGRES_USER="${POSTGRES_USER:-mdvai}"
POSTGRES_DB="${POSTGRES_DB:-model_data_verify_ai}"
RESTORE_DB="mdvai_restore"
DUMP="/tmp/mdvai-harbour.dump"
COMPOSE_CMD="${COMPOSE:-docker compose}"
read -r -a COMPOSE <<< "$COMPOSE_CMD"

psql_db() {
  local db="$1"; shift
  "${COMPOSE[@]}" exec -T postgres psql \
    -U "$POSTGRES_USER" -d "$db" -v ON_ERROR_STOP=1 -At "$@"
}

cleanup() {
  psql_db postgres -c "DROP DATABASE IF EXISTS $RESTORE_DB WITH (FORCE);" >/dev/null 2>&1 || true
  "${COMPOSE[@]}" exec -T postgres rm -f "$DUMP" >/dev/null 2>&1 || true
}
trap cleanup EXIT

check_eq() {
  local label="$1" actual="$2" expected="$3"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $label expected $expected, got $actual"
    exit 1
  fi
  echo "  $label: $actual"
}

echo "Dumping $POSTGRES_DB"
"${COMPOSE[@]}" exec -T postgres pg_dump \
  -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f "$DUMP"

"${COMPOSE[@]}" exec -T postgres test -s "$DUMP"
echo "  dump size: $("${COMPOSE[@]}" exec -T postgres stat -c %s "$DUMP") bytes"

echo "Restoring into a clean database"
psql_db postgres -c "DROP DATABASE IF EXISTS $RESTORE_DB WITH (FORCE);" >/dev/null
psql_db postgres -c "CREATE DATABASE $RESTORE_DB;" >/dev/null

"${COMPOSE[@]}" exec -T postgres pg_restore \
  -U "$POSTGRES_USER" -d "$RESTORE_DB" --exit-on-error "$DUMP"

echo "Verifying the restored data"
check_eq "customers" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM customers;')" "6"
check_eq "products" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM products;')" "6"
check_eq "orders" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM orders;')" "10"
check_eq "order_items" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM order_items;')" "15"
check_eq "invoices" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM invoices;')" "7"
check_eq "payments" "$(psql_db "$RESTORE_DB" -c 'SELECT count(*) FROM payments;')" "5"
check_eq "shipped revenue" "$(psql_db "$RESTORE_DB" -c "SELECT sum(oi.quantity * oi.unit_price_cents) FROM orders o JOIN order_items oi ON oi.order_id = o.order_id WHERE o.status = 'shipped';")" "53600"
check_eq "foreign keys" "$(psql_db "$RESTORE_DB" -c "SELECT count(*) FROM pg_constraint WHERE connamespace = 'public'::regnamespace AND contype = 'f';")" "5"
seq=$(psql_db "$RESTORE_DB" -c "SELECT nextval(pg_get_serial_sequence('customers', 'customer_id'));")
if [ "$seq" -lt 7 ]; then
  echo "FAIL: customer sequence expected at least 7, got $seq"
  exit 1
fi
echo "  customer sequence: $seq (at least 7, no collision)"

echo "09-backup scenario passed"
