#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

COMPOSE="${COMPOSE:-docker compose}"
PSQL=($COMPOSE exec -T postgres psql \
  -U "${POSTGRES_USER:-mdvai}" \
  -d "${POSTGRES_DB:-model_data_verify_ai}" \
  -v ON_ERROR_STOP=1 -At)

psql() { "${PSQL[@]}" "$@"; }

psql -c "DROP TABLE IF EXISTS lab_ledger;
         CREATE TABLE lab_ledger (id int primary key, amount int not null);
         INSERT INTO lab_ledger VALUES (1, 100);" >/dev/null

echo "Lost update, two sessions, no row lock"
psql -c "BEGIN;
         SELECT amount FROM lab_ledger WHERE id = 1;
         SELECT pg_sleep(2);
         UPDATE lab_ledger SET amount = 70 WHERE id = 1;
         COMMIT;" >/tmp/mdvai-session-a.out &
a=$!
sleep 0.5
psql -c "BEGIN;
         SELECT amount FROM lab_ledger WHERE id = 1;
         UPDATE lab_ledger SET amount = 50 WHERE id = 1;
         COMMIT;" >/tmp/mdvai-session-b.out
wait "$a"

final=$(psql -c "SELECT amount FROM lab_ledger WHERE id = 1;")
echo "  final amount: $final (expected 70; the -50 update was lost)"
if [ "$final" != "70" ]; then
  echo "FAIL: expected 70"
  exit 1
fi

psql -c "UPDATE lab_ledger SET amount = 100 WHERE id = 1;" >/dev/null

echo "Lost update, two sessions, SELECT ... FOR UPDATE"
psql -c "BEGIN;
         SELECT amount FROM lab_ledger WHERE id = 1 FOR UPDATE;
         SELECT pg_sleep(2);
         UPDATE lab_ledger SET amount = amount - 30 WHERE id = 1;
         COMMIT;" >/tmp/mdvai-session-c.out &
c=$!
sleep 0.5
psql -c "BEGIN;
         SELECT amount FROM lab_ledger WHERE id = 1 FOR UPDATE;
         UPDATE lab_ledger SET amount = amount - 50 WHERE id = 1;
         COMMIT;" >/tmp/mdvai-session-d.out
wait "$c"

final=$(psql -c "SELECT amount FROM lab_ledger WHERE id = 1;")
echo "  final amount: $final (expected 20; the second session waited for the lock)"
if [ "$final" != "20" ]; then
  echo "FAIL: expected 20"
  exit 1
fi

psql -c "DROP TABLE lab_ledger;" >/dev/null
echo "05-transaction scenario passed"
