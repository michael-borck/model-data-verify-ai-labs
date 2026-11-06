# Lab 01: Model before query

Chapter: [Model Before Query](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/01-model-before-query.qmd)

## Start

```bash
./start.sh
```

Or, from this folder:

```bash
make up
make psql
```

## Tasks

1. List the tables and their columns:

   ```sql
   \d
   \d customers
   \d orders
   \d order_items
   ```

2. Try each invalid insert from the chapter. Record which constraint rejects it.

   ```sql
   INSERT INTO customers (name, email) VALUES ('Duplicate Ada', 'ada@example.com');
   INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
   VALUES (1, 2, -1, 3000);
   INSERT INTO invoices (order_id, issued_at, due_at, total_cents)
   VALUES (5, '2026-05-01', '2026-04-01', 1000);
   ```

3. Add a `support_tickets` table. A ticket belongs to a customer, has an opened
   time, an optional closed time, a priority (`low`, `normal`, `high`) and a
   subject. Decide what happens when a customer is deleted.

4. Add a `refunds` table. Decide whether a refund belongs to a payment or an
   invoice, and whether one invoice can have more than one refund.

5. Break your own schema. Try to insert a row that should be impossible. If it is
   accepted, add the constraint that rejects it.

## Check

```bash
make check LAB=01
```

The check confirms the seed counts, the key constraints and the known revenue.
It also tries several invalid writes and fails if any of them is accepted.

## Reset

```bash
make reset
```

The seed scripts run only when the database volume is first created. Reset after
changing the seed or after a destructive exercise.
