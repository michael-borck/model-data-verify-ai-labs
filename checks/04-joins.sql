\set ON_ERROR_STOP on
\echo 'Checking joins and the grain...'

DO $$
DECLARE
  joined_rows bigint;
  orders bigint;
  item_rows bigint;
  revenue bigint;
  fanout_total bigint;
  invoice_total bigint;
  top_product text;
  no_order_customer text;
BEGIN
  SELECT count(*),
         count(DISTINCT o.order_id),
         count(oi.product_id)
  INTO joined_rows, orders, item_rows
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id;

  IF joined_rows <> 15 THEN
    RAISE EXCEPTION 'joined rows: expected 15, got %', joined_rows;
  END IF;
  IF orders <> 10 THEN
    RAISE EXCEPTION 'distinct orders: expected 10, got %', orders;
  END IF;
  IF item_rows <> 15 THEN
    RAISE EXCEPTION 'item rows: expected 15, got %', item_rows;
  END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped';

  IF revenue <> 53600 THEN
    RAISE EXCEPTION 'shipped revenue: expected 53600, got %', revenue;
  END IF;

  -- The deliberate fan-out: invoice totals repeated once per item.
  SELECT sum(i.total_cents) INTO fanout_total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN invoices i ON i.order_id = o.order_id
  WHERE o.status = 'shipped';

  IF fanout_total <> 90800 THEN
    RAISE EXCEPTION 'fan-out total: expected 90800, got %', fanout_total;
  END IF;

  -- The same totals at invoice grain.
  SELECT sum(i.total_cents) INTO invoice_total
  FROM invoices i
  JOIN orders o ON o.order_id = i.order_id
  WHERE o.status = 'shipped';

  IF invoice_total <> 53600 THEN
    RAISE EXCEPTION 'invoice total: expected 53600, got %', invoice_total;
  END IF;

  SELECT p.name INTO top_product
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status = 'shipped'
  GROUP BY p.product_id, p.name
  ORDER BY sum(oi.quantity) DESC, p.name
  LIMIT 1;

  IF top_product <> 'Harbour Espresso Blend 1kg' THEN
    RAISE EXCEPTION 'top product: expected Harbour Espresso Blend 1kg, got %', top_product;
  END IF;

  SELECT c.name INTO no_order_customer
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  WHERE o.order_id IS NULL
  ORDER BY c.name
  LIMIT 1;

  IF no_order_customer <> 'Barbara Liskov' THEN
    RAISE EXCEPTION 'customer with no orders: expected Barbara Liskov, got %', no_order_customer;
  END IF;
END $$;

\echo '04-join checks passed'
