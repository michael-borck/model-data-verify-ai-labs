# Lab 02: Questions into SQL

Chapter: [Questions into SQL](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/02-questions-into-sql.qmd)

## Start

```bash
make up
make psql
```

## Tasks

Write each query before looking at the chapter. Then compare with the known
answers in `db/known-answers.md`.

1. What was shipped revenue, all time?
2. What was shipped revenue in April 2026?
3. Which product sold the most units?
4. Which invoices are overdue on 30 April 2026?
5. Which customers have never placed an order?

Then write the monthly view:

6. For each month, show the number of shipped orders, the revenue and the average
   order value.

## Traps to test

- Include a cancelled order in revenue. Does the number change? Should it?
- Include a pending order. Does the number change? Should it?
- Replace `paid_at IS NULL` with `paid_at = NULL`. What happens?
- Use `BETWEEN '2026-04-01' AND '2026-04-30'`. Which orders disappear?
- Count order items instead of orders. How does the average change?

## Check

```bash
make check LAB=02
```

The check runs the five known answers and the January average. It fails on the
first mismatch and tells you which one.

## Then break it

Add a new order for Barbara Liskov. Predict the new answers before running the
queries. Update `db/known-answers.md` only after you can explain every change.
