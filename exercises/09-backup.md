# Lab 09: Backups and restore tests

Chapter: [Backups and Restore Tests](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/09-backups-and-restore-tests.qmd)

## Start

```bash
make up
```

## Run the scenario

```bash
make scenario LAB=09
```

The scenario:

1. Dumps the case with `pg_dump -Fc`.
2. Creates a clean `mdvai_restore` database.
3. Restores the dump with `pg_restore --exit-on-error`.
4. Checks the row counts, shipped revenue, foreign keys and customer sequence.
5. Drops the restore database and the dump.

A backup is not proven until the restore passes.

## Do it by hand

1. Dump the database:

   ```bash
   docker compose exec -T postgres pg_dump -U mdvai -d model_data_verify_ai -Fc -f /tmp/harbour.dump
   ```

2. Create a clean database:

   ```bash
   docker compose exec -T postgres createdb -U mdvai harbour_restore
   ```

3. Restore:

   ```bash
   docker compose exec -T postgres pg_restore -U mdvai -d harbour_restore --exit-on-error /tmp/harbour.dump
   ```

4. Verify the restored data:

   ```bash
   docker compose exec -T postgres psql -U mdvai -d harbour_restore -c "SELECT count(*) FROM orders;"
   ```

5. Check the sequence:

   ```sql
   SELECT nextval(pg_get_serial_sequence('customers', 'customer_id'));
   ```

6. Drop the restore database and the dump.

## Then break it

1. Truncate the dump file and try to restore it. What does `pg_restore` report?
2. Restore without the roles or grants. What fails?
3. Time the restore. Compare it with an RTO you choose.
4. Write a shell pipeline that hides a failed `pg_dump` behind a successful
   `gzip`. Add `set -o pipefail` and show the difference.

## Reset

```bash
make reset
```

The scenario uses its own restore database and cleans up.
