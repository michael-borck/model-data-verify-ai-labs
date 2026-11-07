# Lab 07: Backfills and idempotence

Chapter: [Backfills and Idempotence](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/07-backfills-and-idempotence.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=07
```

The check creates 1,000 rows, processes them in batches of 100, and then runs the
same batch again. The second run must change zero rows.

## Do it by hand

1. Create the table:

   ```sql
   DROP TABLE IF EXISTS lab_backfill;
   CREATE TABLE lab_backfill (
     id integer PRIMARY KEY,
     payload text NOT NULL,
     processed_at timestamptz
   );
   INSERT INTO lab_backfill (id, payload)
   SELECT g, 'row ' || g FROM generate_series(1, 1000) AS g;
   ```

2. Run one batch:

   ```sql
   WITH batch AS (
     SELECT id FROM lab_backfill
     WHERE processed_at IS NULL
     ORDER BY id
     LIMIT 100
   )
   UPDATE lab_backfill b
   SET processed_at = now()
   FROM batch
   WHERE b.id = batch.id;
   ```

3. Check how many rows are left:

   ```sql
   SELECT count(*) FROM lab_backfill WHERE processed_at IS NULL;
   ```

4. Repeat until the batch updates zero rows. How many passes did it take?

5. Run the batch again. What is the row count now? Why?

## Add progress

Create a checkpoint table and record the last id after each batch:

```sql
CREATE TABLE backfill_progress (
  name text PRIMARY KEY,
  last_id integer NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

Stop halfway. Restart from the recorded id. Does the predicate still protect you
if the checkpoint is stale?

## Then break it

1. Change the predicate to `WHERE true` and run the batch twice. What happens to
   `processed_at`?
2. Create a `legacy_orders` table with duplicate keys. Write an idempotent upsert
   into `orders`. Run it twice. Are there duplicates?
3. Write a backfill that adds to a value instead of setting it. Run it twice. Why
   is it not idempotent?

## Reset

```bash
make reset
```

The check drops its own table. Reset only if you created case data you want to
undo.
