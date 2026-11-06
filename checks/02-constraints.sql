\set ON_ERROR_STOP on
\echo 'Checking relationships and constraints...'

DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n
  FROM pg_constraint
  WHERE connamespace = 'public'::regnamespace
    AND contype = 'f';
  IF n < 5 THEN
    RAISE EXCEPTION 'expected at least 5 foreign keys, found %', n;
  END IF;

  SELECT count(*) INTO n
  FROM pg_constraint
  WHERE connamespace = 'public'::regnamespace
    AND contype = 'u';
  IF n < 2 THEN
    RAISE EXCEPTION 'expected at least 2 unique constraints, found %', n;
  END IF;
END $$;

-- Order for a missing customer must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO orders (customer_id, ordered_at, status, shipping_address)
    VALUES (999, now(), 'pending', 'nowhere');
    RAISE EXCEPTION 'order for a missing customer was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- Order item for a missing product must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
    VALUES (1, 999, 1, 1000);
    RAISE EXCEPTION 'order item for a missing product was accepted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- The same product twice on one order must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
    VALUES (1, 1, 1, 3200);
    RAISE EXCEPTION 'duplicate product line on one order was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

-- A second invoice for one order must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO invoices (order_id, issued_at, due_at, total_cents)
    VALUES (1, now(), now() + interval '14 days', 1000);
    RAISE EXCEPTION 'second invoice for one order was accepted';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

-- Deleting a customer with orders must fail.
DO $$
BEGIN
  BEGIN
    DELETE FROM customers WHERE customer_id = 1;
    RAISE EXCEPTION 'customer with orders was deleted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- Deleting a product that has been sold must fail.
DO $$
BEGIN
  BEGIN
    DELETE FROM products WHERE product_id = 1;
    RAISE EXCEPTION 'product with order items was deleted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- Deleting an order with an invoice must fail.
DO $$
BEGIN
  BEGIN
    DELETE FROM orders WHERE order_id = 1;
    RAISE EXCEPTION 'order with an invoice was deleted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- Deleting an invoice with a payment must fail.
DO $$
BEGIN
  BEGIN
    DELETE FROM invoices WHERE invoice_id = 1;
    RAISE EXCEPTION 'invoice with a payment was deleted';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END $$;

-- An order without an invoice should cascade to its items.
DO $$
DECLARE
  oid integer;
BEGIN
  INSERT INTO orders (customer_id, ordered_at, status, shipping_address)
  VALUES (1, now(), 'pending', 'cascade test')
  RETURNING order_id INTO oid;

  INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents)
  VALUES (oid, 1, 1, 3200);

  DELETE FROM orders WHERE order_id = oid;

  IF EXISTS (SELECT 1 FROM order_items WHERE order_id = oid) THEN
    RAISE EXCEPTION 'order items did not cascade';
  END IF;
END $$;

\echo '02-constraint checks passed'
