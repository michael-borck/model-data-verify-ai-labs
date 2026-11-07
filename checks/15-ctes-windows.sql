\set ON_ERROR_STOP on
\echo 'Checking CTEs and window functions...'

DO $$
DECLARE
  top_months text;
  last_running bigint;
  previous bigint;
  null_previous bigint;
  ranks text;
BEGIN
  WITH order_totals AS (
    SELECT o.order_id,
           o.customer_id,
           to_char(o.ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
           sum(oi.quantity * oi.unit_price_cents) AS total_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY o.order_id, o.customer_id, month
  ),
  monthly_customer AS (
    SELECT month, customer_id, sum(total_cents) AS revenue_cents
    FROM order_totals
    GROUP BY month, customer_id
  ),
  ranked AS (
    SELECT month, customer_id, revenue_cents,
           row_number() OVER (
             PARTITION BY month
             ORDER BY revenue_cents DESC, customer_id
           ) AS rn
    FROM monthly_customer
  )
  SELECT string_agg(month || ':' || customer_id, ',' ORDER BY month)
  INTO top_months
  FROM ranked
  WHERE rn = 1;

  IF top_months <> '2026-01:2,2026-02:3,2026-03:5,2026-04:1' THEN
    RAISE EXCEPTION 'top customer by month: expected 2026-01:2,2026-02:3,2026-03:5,2026-04:1, got %', top_months;
  END IF;

  WITH monthly AS (
    SELECT to_char(o.ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
           sum(oi.quantity * oi.unit_price_cents) AS revenue_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY month
  ),
  running AS (
    SELECT month,
           revenue_cents,
           sum(revenue_cents) OVER (
             ORDER BY month
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS running_total
    FROM monthly
  )
  SELECT running_total INTO last_running
  FROM running
  ORDER BY month DESC
  LIMIT 1;

  IF last_running <> 53600 THEN
    RAISE EXCEPTION 'running total: expected 53600, got %', last_running;
  END IF;

  WITH monthly AS (
    SELECT to_char(o.ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
           sum(oi.quantity * oi.unit_price_cents) AS revenue_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY month
  ),
  with_previous AS (
    SELECT month,
           revenue_cents,
           lag(revenue_cents) OVER (ORDER BY month) AS previous_month
    FROM monthly
  )
  SELECT previous_month INTO previous
  FROM with_previous
  ORDER BY month DESC
  LIMIT 1;

  IF previous <> 15300 THEN
    RAISE EXCEPTION 'previous month: expected 15300, got %', previous;
  END IF;

  WITH monthly AS (
    SELECT to_char(o.ordered_at AT TIME ZONE 'Australia/Perth', 'YYYY-MM') AS month,
           sum(oi.quantity * oi.unit_price_cents) AS revenue_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY month
  ),
  with_previous AS (
    SELECT lag(revenue_cents) OVER (ORDER BY month) AS previous_month
    FROM monthly
  )
  SELECT count(*) INTO null_previous
  FROM with_previous
  WHERE previous_month IS NULL;

  IF null_previous <> 1 THEN
    RAISE EXCEPTION 'first month should have one null previous value, got %', null_previous;
  END IF;

  WITH customer_totals AS (
    SELECT o.customer_id,
           sum(oi.quantity * oi.unit_price_cents) AS revenue_cents
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'shipped'
    GROUP BY o.customer_id
  ),
  ranked AS (
    SELECT customer_id,
           revenue_cents,
           rank() OVER (ORDER BY revenue_cents DESC) AS rnk
    FROM customer_totals
  )
  SELECT string_agg(customer_id || ':' || rnk, ',' ORDER BY rnk, customer_id)
  INTO ranks
  FROM ranked;

  IF ranks <> '1:1,2:2,5:3,3:4,4:5' THEN
    RAISE EXCEPTION 'customer ranks: expected 1:1,2:2,5:3,3:4,4:5, got %', ranks;
  END IF;
END $$;

\echo '15-cte-window checks passed'
