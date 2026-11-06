# Lab 05: Transactions and isolation

Chapter: [Transactions and Isolation](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/05-transactions-and-isolation.qmd)

## Start

```bash
make up
```

This lab needs two sessions. Open two terminals and run this in each:

```bash
make psql
```

## Run the scripted scenario

```bash
make scenario LAB=05
```

The scenario shows two things:

1. Two sessions read the same amount, both update, and one update is lost.
2. With `SELECT ... FOR UPDATE`, the second session waits and the final amount is
   correct.

The scenario uses a scratch table, `lab_ledger`, so it does not touch the case
data.

## Do it by hand

1. Create the ledger:

   ```sql
   DROP TABLE IF EXISTS lab_ledger;
   CREATE TABLE lab_ledger (id int primary key, amount int not null);
   INSERT INTO lab_ledger VALUES (1, 100);
   ```

2. In session A:

   ```sql
   BEGIN;
   SELECT amount FROM lab_ledger WHERE id = 1;
   ```

3. In session B, update and commit:

   ```sql
   UPDATE lab_ledger SET amount = 50 WHERE id = 1;
   ```

4. Back in session A, update from the value you read and commit:

   ```sql
   UPDATE lab_ledger SET amount = 70 WHERE id = 1;
   COMMIT;
   ```

5. Check the final amount. Which update won? Which one was lost?

6. Reset and repeat with `SELECT ... FOR UPDATE` in both sessions. Observe the
   second session waiting.

## Look at the locks

While one session is waiting, open a third session and run:

```sql
SELECT pid, state, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE datname = current_database();

SELECT locktype, relation::regclass, mode, granted
FROM pg_locks
WHERE relation = 'lab_ledger'::regclass;
```

## Isolation levels

In session A:

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT amount FROM lab_ledger WHERE id = 1;
```

In session B, update the amount and commit. In session A, select again and
compare. Then repeat with `REPEATABLE READ` and explain the difference.

## Then break it

Two sessions each insert a payment against the same invoice. Both check the
current total first. Can both payments fit under the invoice total? What lock or
isolation level would stop the write skew?

## Reset

```bash
make reset
```

Lab 06 changes the schema. Run `make reset` before repeating the earlier labs.
