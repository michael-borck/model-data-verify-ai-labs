# Lab 02: Relationships and constraints

Chapter: [Relationships and Constraints](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/02-relationships-and-constraints.qmd)

## Start

```bash
make reset
make psql
```

## Tasks

1. Find the foreign keys:

   ```sql
   SELECT conrelid::regclass AS table_name,
          conname,
          pg_get_constraintdef(oid) AS definition
   FROM pg_constraint
   WHERE connamespace = 'public'::regnamespace
     AND contype = 'f'
   ORDER BY table_name, conname;
   ```

2. Try each delete:

   ```sql
   DELETE FROM customers WHERE customer_id = 1;
   DELETE FROM products WHERE product_id = 1;
   DELETE FROM orders WHERE order_id = 1;
   DELETE FROM invoices WHERE invoice_id = 1;
   ```

   Record which fail and why. Then explain each result in business terms.

3. Create an order with no invoice, add an item, and delete the order. What
   happens to the item?

4. Add a `support_tickets` table. Choose the delete rule for the customer and for
   an optional assignee. Write named constraints.

5. Add a `refunds` table. Decide whether a refund belongs to a payment or an
   invoice, and whether one invoice can have more than one refund.

6. Write the rule "a payment must not exceed its invoice total." Can a `CHECK`
   constraint enforce it? If not, what would?

## Check

```bash
make check LAB=02
```

The check confirms the foreign keys, the unique constraints, the delete rules and
the cascade that should work.

## Reset

Lab 05 changes the schema. Run `make reset` before repeating labs 01 to 04.
