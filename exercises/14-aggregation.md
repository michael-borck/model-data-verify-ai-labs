# Lab 14: Aggregation and grouping

Chapter: [Aggregation and Grouping](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/14-aggregation-and-grouping.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=14
```

The check verifies monthly revenue, average order value, average line value,
customer totals, counts, `HAVING` and the zero-row `COALESCE` case.

## Do it by hand

1. Compute shipped revenue by month:

   ```sql
   SELECT to_char(ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
          sum(oi.quantity * oi.unit_price_cents) AS revenue_cents
   FROM orders o
   JOIN order_items oi ON oi.order_id = o.order_id
   WHERE o.status = 'shipped'
   GROUP BY month
   ORDER BY month;
   ```

2. Compute average order value and average line value. Explain why they differ.

3. Count orders, order items and distinct customers in one query.

4. Find customers whose shipped revenue is above 10,000. Use `HAVING`.

5. Rewrite a conditional sum with `FILTER`:

   ```sql
   SELECT sum(oi.quantity * oi.unit_price_cents)
            FILTER (WHERE o.status = 'shipped') AS shipped_revenue,
          sum(oi.quantity * oi.unit_price_cents)
            FILTER (WHERE o.status = 'pending') AS pending_revenue
   FROM orders o
   JOIN order_items oi ON oi.order_id = o.order_id;
   ```

6. Add a cancelled order and a pending order. Recompute the totals. Which change,
   and which should not?

## Then break it

1. Group by customer name instead of id. Add a second customer with the same name
   in a scratch copy. What happens to the totals?
2. Remove `COALESCE` from Barbara's revenue. What does the query return?
3. Change `COUNT(DISTINCT o.order_id)` to `COUNT(*)` after a join. What changes?
4. Average the monthly averages. Compare with the weighted average order value.

## Reset

```bash
make reset
```

The check uses the case data and creates no tables.
