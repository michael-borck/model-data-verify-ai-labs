\set ON_ERROR_STOP on
\echo 'Checking aggregation and grouping...'

DO $$
DECLARE
  total bigint;
  jan bigint;
  apr bigint;
  avg_order numeric;
  avg_line numeric;
  ada bigint;
  orders bigint;
  lines bigint;
  customers bigint;
  over_10k bigint;
  barbara bigint;
BEGIN
  SELECT sum(oi.quantity * oi.unit_price_cents) INTO total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped';

  IF total <> 53600 THEN
    RAISE EXCEPTION 'shipped revenue: expected 53600, got %', total;
  END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO jan
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped'
    AND o.ordered_at >= '2026-01-01 00:00+08'
    AND o.ordered_at <  '2026-02-01 00:00+08';

  IF jan <> 16700 THEN
    RAISE EXCEPTION 'January revenue: expected 16700, got %', jan;
  END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO apr
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped'
    AND o.ordered_at >= '2026-04-01 00:00+08'
    AND o.ordered_at <  '2026-05-01 00:00+08';

  IF apr <> 14800 THEN
    RAISE EXCEPTION 'April revenue: expected 14800, got %', apr;
  END IF;

  WITH order_totals AS (
    SELECT o.order_id,
           sum(oi.quantity * oi.unit_price_cents) AS total_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY o.order_id
  )
  SELECT round(avg(total_cents), 2) INTO avg_order
  FROM order_totals;

  IF avg_order <> 7657.14 THEN
    RAISE EXCEPTION 'average order value: expected 7657.14, got %', avg_order;
  END IF;

  SELECT round(avg(oi.quantity * oi.unit_price_cents), 2) INTO avg_line
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped';

  IF avg_line <> 4466.67 THEN
    RAISE EXCEPTION 'average line value: expected 4466.67, got %', avg_line;
  END IF;

  SELECT sum(oi.quantity * oi.unit_price_cents) INTO ada
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'shipped'
    AND o.customer_id = 1;

  IF ada <> 17800 THEN
    RAISE EXCEPTION 'Ada revenue: expected 17800, got %', ada;
  END IF;

  SELECT count(*) INTO orders FROM orders;
  IF orders <> 10 THEN
    RAISE EXCEPTION 'orders: expected 10, got %', orders;
  END IF;

  SELECT count(*) INTO lines FROM order_items;
  IF lines <> 15 THEN
    RAISE EXCEPTION 'order items: expected 15, got %', lines;
  END IF;

  SELECT count(DISTINCT customer_id) INTO customers FROM orders;
  IF customers <> 5 THEN
    RAISE EXCEPTION 'customers with orders: expected 5, got %', customers;
  END IF;

  SELECT count(*) INTO over_10k
  FROM (
    SELECT o.customer_id
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY o.customer_id
    HAVING sum(oi.quantity * oi.unit_price_cents) > 10000
  ) expensive;

  IF over_10k <> 2 THEN
    RAISE EXCEPTION 'customers over 10000: expected 2, got %', over_10k;
  END IF;

  SELECT COALESCE((
    SELECT sum(oi.quantity * oi.unit_price_cents)
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
      AND o.customer_id = 6
  ), 0) INTO barbara;

  IF barbara <> 0 THEN
    RAISE EXCEPTION 'Barbara revenue: expected 0, got %', barbara;
  END IF;
END $$;

\echo '14-aggregation checks passed'
