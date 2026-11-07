\set ON_ERROR_STOP on
\echo 'Checking the index and the plan...'

DROP TABLE IF EXISTS lab_index_orders;
CREATE TABLE lab_index_orders (
  order_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id integer NOT NULL,
  ordered_at  timestamptz NOT NULL,
  status      text NOT NULL,
  note        text
);

INSERT INTO lab_index_orders (customer_id, ordered_at, status, note)
SELECT (g % 1000) + 1,
       timestamptz '2026-01-01 00:00+08' + (g || ' minutes')::interval,
       CASE WHEN g % 10 = 0 THEN 'cancelled' ELSE 'shipped' END,
       'row ' || g
FROM generate_series(1, 100000) AS g;

ANALYZE lab_index_orders;

DO $$
DECLARE
  plan json;
BEGIN
  EXECUTE $sql$
    EXPLAIN (FORMAT JSON)
    SELECT order_id
    FROM lab_index_orders
    WHERE customer_id = 42
      AND ordered_at >= '2026-01-02 00:00+08'
    ORDER BY ordered_at DESC
  $sql$ INTO plan;

  IF plan IS NULL THEN
    RAISE EXCEPTION 'could not read the plan';
  END IF;
  IF plan::text NOT LIKE '%Seq Scan%' THEN
    RAISE EXCEPTION 'expected a Seq Scan before the index, got %', plan::text;
  END IF;
  IF plan::text LIKE '%Index Scan%' OR plan::text LIKE '%Bitmap Heap Scan%' THEN
    RAISE EXCEPTION 'an index plan appeared before the index was created';
  END IF;
END $$;

CREATE INDEX lab_index_orders_customer_time_idx
ON lab_index_orders (customer_id, ordered_at);

ANALYZE lab_index_orders;

DO $$
DECLARE
  plan json;
BEGIN
  EXECUTE $sql$
    EXPLAIN (FORMAT JSON)
    SELECT order_id
    FROM lab_index_orders
    WHERE customer_id = 42
      AND ordered_at >= '2026-01-02 00:00+08'
    ORDER BY ordered_at DESC
  $sql$ INTO plan;

  IF plan IS NULL THEN
    RAISE EXCEPTION 'could not read the plan after the index';
  END IF;
  IF plan::text NOT LIKE '%Index Scan%' AND plan::text NOT LIKE '%Bitmap Heap Scan%' THEN
    RAISE EXCEPTION 'expected an index plan after the index, got %', plan::text;
  END IF;
END $$;

DROP TABLE lab_index_orders;
\echo '08-index checks passed'
