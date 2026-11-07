# Lab 11: Privacy, retention and injection

Chapter: [Privacy, Retention and Injection](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/11-privacy-retention-and-injection.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=11
```

The check creates ticket rows, an unsafe search function and a safe one. It shows
the injection returning every row, the safe version returning none, and a
retention job deleting the old rows and recording the count.

## Do it by hand

1. Create the table and rows:

   ```sql
   CREATE TABLE lab_tickets (
     ticket_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
     email text NOT NULL,
     body text NOT NULL,
     closed_at timestamptz
   );
   INSERT INTO lab_tickets (email, body, closed_at) VALUES
     ('ada@example.com', 'Refund request', '2025-12-01'),
     ('grace@example.com', 'Delivery delay', '2025-12-15'),
     ('alan@example.com', 'Refund request', '2026-04-01'),
     ('edsger@example.com', 'Password reset', '2026-04-10'),
     ('barbara@example.com', 'Refund request', NULL);
   ```

2. Create the unsafe function from the chapter and run the payload:

   ```sql
   SELECT lab_search_unsafe(''' OR true --');
   ```

   It returns every row. Then create the safe function with `USING` and run the
   same payload. It returns zero.

3. Write a retention job for closed tickets older than 90 days. Use a fixed cutoff
   so the result is repeatable. Record the deleted count in a log table.

4. Insert a synthetic marker row, run the job, and search for the marker in the
   table and the log.

5. List every copy of a customer email in the system. Does the deletion reach the
   logs, the prompt history and any search index?

## Then break it

1. Remove the `USING` clause from the safe function and replace it with string
   concatenation. Run the payload again.
2. Change the retention job to `DELETE` without a cutoff. What happens to the open
   tickets?
3. Add a `deleted_at` column instead of deleting. Is the row still in the table?
   Is it still in a backup?

## Reset

```bash
make reset
```

The check drops its own functions and tables.
