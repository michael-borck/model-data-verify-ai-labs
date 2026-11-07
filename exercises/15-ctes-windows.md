# Lab 15: CTEs, windows and readable SQL

Chapter: [CTEs, Windows and Readable SQL](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/15-ctes-windows-and-readable-sql.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=15
```

The check verifies:

- top customer by shipped revenue in each month
- the running revenue total
- the previous month with `LAG`
- the customer ranking with `RANK`

## Do it by hand

1. Write the order totals CTE:

   ```sql
   WITH order_totals AS (
     SELECT o.order_id,
            o.customer_id,
            to_char(o.ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
            sum(oi.quantity * oi.unit_price_cents) AS total_cents
     FROM orders o
     JOIN order_items oi ON oi.order_id = o.order_id
     WHERE o.status = 'shipped'
     GROUP BY o.order_id, o.customer_id, month
   )
   SELECT * FROM order_totals ORDER BY order_id;
   ```

   Check the row count and the grain before adding the next step.

2. Add `monthly_customer` and rank with `ROW_NUMBER`:

   ```sql
   WITH order_totals AS (...),
   monthly_customer AS (
     SELECT month, customer_id, sum(total_cents) AS revenue_cents
     FROM order_totals
     GROUP BY month, customer_id
   ),
   ranked AS (
     SELECT month, customer_id, revenue_cents,
            row_number() OVER (
              PARTITION BY month
              ORDER BY revenue_cents DESC, customer_id
            ) AS rn
     FROM monthly_customer
   )
   SELECT * FROM ranked WHERE rn = 1 ORDER BY month;
   ```

3. Add a running total with `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

4. Add `LAG` to show the previous month.

5. Rank all customers with `RANK()`. Compare with `ROW_NUMBER()` and
   `DENSE_RANK()`.

## Then break it

1. Remove the `customer_id` tie-breaker from the monthly ranking. Run the query
   twice. Does the result change?
2. Add a second customer with the same monthly revenue in a scratch copy. Compare
   the three ranking functions.
3. Change the running total to the default frame. What happens if two months have
   the same revenue?
4. Put `ORDER BY` inside a CTE without `LIMIT` and select from it. Does the outer
   query preserve the order?
5. Use `SELECT *` through each CTE. How hard is the result to audit?

## Reset

```bash
make reset
```

The check uses the case data and creates no tables.
