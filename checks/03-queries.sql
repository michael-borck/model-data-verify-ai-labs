\set ON_ERROR_STOP on
\echo 'Checking the query answers...'

DO $$
DECLARE
  total bigint;
  n bigint;
  product_name text;
  customer_name text;
  avg_cents numeric;
BEGIN
  SELECT sum(oi.quantity * oi.unit_price_cents) INTO total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped';
  IF total <> 53600 THEN
    RAISE EXCEPTION 'shipped revenue: expected 53600, got %', total;
  END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped'
    AND o.ordered_at >= '2026-04-01 00:00+08'
    AND o.ordered_at <  '2026-05-01 00:00+08';
  IF total <> 14800 THEN
    RAISE EXCEPTION 'April revenue: expected 14800, got %', total;
  END IF;

  SELECT count(*), sum(total_cents) INTO n, total
  FROM invoices
  WHERE paid_at IS NULL
    AND due_at < '2026-05-01 00:00+08';
  IF n <> 2 THEN
    RAISE EXCEPTION 'overdue invoices: expected 2, got %', n;
  END IF;
  IF total <> 15800 THEN
    RAISE EXCEPTION 'overdue total: expected 15800, got %', total;
  END IF;

  SELECT p.name INTO product_name
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status = 'shipped'
  GROUP BY p.product_id, p.name
  ORDER BY sum(oi.quantity) DESC, p.name
  LIMIT 1;
  IF product_name <> 'Harbour Espresso Blend 1kg' THEN
    RAISE EXCEPTION 'top product: expected Harbour Espresso Blend 1kg, got %', product_name;
  END IF;

  SELECT c.name INTO customer_name
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  WHERE o.order_id IS NULL
  ORDER BY c.name
  LIMIT 1;
  IF customer_name <> 'Barbara Liskov' THEN
    RAISE EXCEPTION 'customer with no orders: expected Barbara Liskov, got %', customer_name;
  END IF;

  SELECT round(avg(total_cents), 2) INTO avg_cents
  FROM (
    SELECT o.order_id, sum(oi.quantity * oi.unit_price_cents) AS total_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
      AND o.ordered_at >= '2026-01-01 00:00+08'
      AND o.ordered_at <  '2026-02-01 00:00+08'
    GROUP BY o.order_id
  ) january;
  IF avg_cents <> 8350.00 THEN
    RAISE EXCEPTION 'January average order: expected 8350.00, got %', avg_cents;
  END IF;
END $$;

\echo '03-query checks passed'
