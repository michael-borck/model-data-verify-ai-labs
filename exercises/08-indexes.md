# Lab 08: Indexes and query plans

Chapter: [Indexes and Query Plans](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/08-indexes-and-query-plans.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=08
```

The check builds a 100,000-row table, shows a sequential scan, adds a composite
index, and requires the plan to change to an index or bitmap plan.

## Do it by hand

1. Look at the query shape:

   ```sql
   SELECT order_id, ordered_at, status
   FROM orders
   WHERE customer_id = 1
     AND ordered_at >= '2026-03-01 00:00+08'
   ORDER BY ordered_at DESC;
   ```

2. Run `EXPLAIN (ANALYZE, BUFFERS)` on the seed table. The plan may be a
   sequential scan because the table is tiny. That is allowed.

3. Create the composite index:

   ```sql
   CREATE INDEX orders_customer_ordered_at_idx
   ON orders (customer_id, ordered_at);
   ```

4. Run `ANALYZE orders` and the same `EXPLAIN` again.

5. Drop the composite index and try single-column indexes:

   ```sql
   CREATE INDEX orders_customer_idx ON orders (customer_id);
   CREATE INDEX orders_ordered_at_idx ON orders (ordered_at);
   ```

   Compare the plans. Which index does the planner choose? Why?

6. Create a partial index for overdue invoices:

   ```sql
   CREATE INDEX invoices_overdue_idx
   ON invoices (due_at)
   WHERE paid_at IS NULL;
   ```

   Run the overdue query with `EXPLAIN`. Does the planner use the partial index?

7. Add an index on `order_items.product_id`. Test a join to products and a delete
   of an unused product.

8. Find unused indexes:

   ```sql
   SELECT relname, indexrelname, idx_scan
   FROM pg_stat_user_indexes
   ORDER BY idx_scan, pg_relation_size(indexrelid) DESC;
   ```

## Then break it

Write the wrong index suggestion an AI might give: an index on every column, or
an index with the range column first. Run `EXPLAIN` and write the check that would
catch it.

## Reset

```bash
make reset
```

The check drops its own table. Reset if you changed the case schema.
