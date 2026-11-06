\set ON_ERROR_STOP on
\echo 'Checking the model...'

DO $$
DECLARE
  n bigint;
  total bigint;
BEGIN
  IF to_regclass('public.customers') IS NULL THEN
    RAISE EXCEPTION 'customers table is missing';
  END IF;
  IF to_regclass('public.products') IS NULL THEN
    RAISE EXCEPTION 'products table is missing';
  END IF;
  IF to_regclass('public.orders') IS NULL THEN
    RAISE EXCEPTION 'orders table is missing';
  END IF;
  IF to_regclass('public.order_items') IS NULL THEN
    RAISE EXCEPTION 'order_items table is missing';
  END IF;
  IF to_regclass('public.invoices') IS NULL THEN
    RAISE EXCEPTION 'invoices table is missing';
  END IF;
  IF to_regclass('public.payments') IS NULL THEN
    RAISE EXCEPTION 'payments table is missing';
  END IF;

  SELECT count(*) INTO n FROM customers;
  IF n <> 6 THEN RAISE EXCEPTION 'customers: expected 6, got %', n; END IF;

  SELECT count(*) INTO n FROM products;
  IF n <> 6 THEN RAISE EXCEPTION 'products: expected 6, got %', n; END IF;

  SELECT count(*) INTO n FROM orders;
  IF n <> 10 THEN RAISE EXCEPTION 'orders: expected 10, got %', n; END IF;

  SELECT count(*) INTO n FROM order_items;
  IF n <> 15 THEN RAISE EXCEPTION 'order_items: expected 15, got %', n; END IF;

  SELECT count(*) INTO n FROM invoices;
  IF n <> 7 THEN RAISE EXCEPTION 'invoices: expected 7, got %', n; END IF;

  SELECT count(*) INTO n FROM payments;
  IF n <> 5 THEN RAISE EXCEPTION 'payments: expected 5, got %', n; END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped';

  IF total <> 53600 THEN
    RAISE EXCEPTION 'shipped revenue: expected 53600, got %', total;
  END IF;
END $$;

-- Duplicate email must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO customers (name, email) VALUES ('Duplicate Ada', 'ada@example.com');
    RAISE EXCEPTION 'duplicate customer email was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

-- Negative quantity must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
    VALUES (1, 2, -1, 3000);
    RAISE EXCEPTION 'negative quantity was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END $$;

-- Invalid status must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO orders (customer_id, ordered_at, status, shipping_address)
    VALUES (1, now(), 'lost', 'nowhere');
    RAISE EXCEPTION 'invalid order status was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END $$;

-- Invoice due before issue must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO invoices (order_id, issued_at, due_at, total_cents)
    VALUES (5, '2026-05-01 00:00+08', '2026-04-01 00:00+08', 1000);
    RAISE EXCEPTION 'invoice due before issue was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END $$;

-- One invoice per order must fail on a second invoice.
DO $$
BEGIN
  BEGIN
    INSERT INTO invoices (order_id, issued_at, due_at, total_cents)
    VALUES (1, '2026-05-01 00:00+08', '2026-05-15 00:00+08', 1000);
    RAISE EXCEPTION 'second invoice for one order was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

-- Payment for a missing invoice must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO payments (invoice_id, paid_at, amount_cents, method)
    VALUES (999, now(), 1000, 'card');
    RAISE EXCEPTION 'payment for a missing invoice was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

\echo '01-model checks passed'
