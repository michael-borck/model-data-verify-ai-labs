\set ON_ERROR_STOP on
\echo 'Checking the channel migration...'

DO $$
DECLARE
  n bigint;
  nullable text;
BEGIN
  SELECT count(*) INTO n
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'channel';

  IF n <> 1 THEN
    RAISE EXCEPTION 'orders.channel is missing. Run the migration first.';
  END IF;

  SELECT is_nullable INTO nullable
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'channel';

  IF nullable <> 'NO' THEN
    RAISE EXCEPTION 'orders.channel is still nullable';
  END IF;

  SELECT count(*) INTO n FROM orders WHERE channel IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'orders.channel has % null rows', n;
  END IF;

  SELECT count(*) INTO n FROM orders WHERE channel NOT IN ('web', 'wholesale', 'phone');
  IF n <> 0 THEN
    RAISE EXCEPTION 'orders.channel has % rows outside the allowed values', n;
  END IF;
END $$;

-- An invalid channel must fail.
DO $$
BEGIN
  BEGIN
    INSERT INTO orders (customer_id, ordered_at, status, shipping_address, channel)
    VALUES (1, now(), 'pending', 'nowhere', 'fax');
    RAISE EXCEPTION 'invalid channel was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END $$;

\echo '04-migration checks passed'
