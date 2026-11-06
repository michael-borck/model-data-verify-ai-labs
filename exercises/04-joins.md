# Lab 04: Joins and the grain

Chapter: [Joins and the Grain](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/04-joins-and-the-grain.qmd)

## Start

```bash
make reset
make psql
```

## Tasks

1. Count the rows before and after the join:

   ```sql
   SELECT count(*) AS orders FROM orders;
   SELECT count(*) AS items FROM order_items;
   SELECT count(*) AS joined_rows,
          count(DISTINCT o.order_id) AS orders
   FROM orders o
   JOIN order_items oi ON oi.order_id = o.order_id;
   ```

   Explain all three numbers.

2. Run the correct revenue query. It returns 53,600.

3. Run the fan-out query: join orders, order items and invoices, then sum the
   invoice total. It returns 90,800. Explain why.

4. Find the customer with no orders. Then rewrite the query as an inner join and
   explain who disappears.

5. Add a second item to order 1. Predict the new revenue and invoice total before
   running anything. Which one changes?

6. Write a query that returns one row per order with its item count and item
   total. Use a CTE or `GROUP BY`. Check that the grain is one row per order.

7. Check the uniqueness of the invoice side:

   ```sql
   SELECT order_id, count(*)
   FROM invoices
   GROUP BY order_id
   HAVING count(*) > 1;
   ```

   No rows means the join cannot fan out on the invoice side.

## Check

```bash
make check LAB=04
```

The check confirms the row counts, the correct revenue, the deliberate fan-out,
the top product and the customer with no orders.

## Reset

Lab 05 changes the schema. Run `make reset` before repeating labs 01 to 04.
