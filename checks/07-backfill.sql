\set ON_ERROR_STOP on
\echo 'Checking the backfill and its rerun...'

DROP TABLE IF EXISTS lab_backfill;
CREATE TABLE lab_backfill (
  id           integer PRIMARY KEY,
  payload      text NOT NULL,
  processed_at timestamptz
);

INSERT INTO lab_backfill (id, payload, processed_at)
SELECT g, 'row ' || g, NULL
FROM generate_series(1, 1000) AS g;

DO $$
DECLARE
  n integer;
  passes integer := 0;
  remaining bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT id
      FROM lab_backfill
      WHERE processed_at IS NULL
      ORDER BY id
      LIMIT 100
    )
    UPDATE lab_backfill b
    SET processed_at = now()
    FROM batch
    WHERE b.id = batch.id;

    GET DIAGNOSTICS n = ROW_COUNT;
    passes := passes + 1;
    EXIT WHEN n = 0;

    IF passes > 20 THEN
      RAISE EXCEPTION 'batch loop did not finish';
    END IF;
  END LOOP;

  SELECT count(*) INTO remaining
  FROM lab_backfill
  WHERE processed_at IS NULL;

  IF remaining <> 0 THEN
    RAISE EXCEPTION 'expected 0 unprocessed rows, got %', remaining;
  END IF;

  IF passes <> 11 THEN
    RAISE EXCEPTION 'expected 11 passes (10 batches plus one empty pass), got %', passes;
  END IF;

  -- The second run must change nothing.
  WITH batch AS (
    SELECT id
    FROM lab_backfill
    WHERE processed_at IS NULL
    ORDER BY id
    LIMIT 100
  )
  UPDATE lab_backfill b
  SET processed_at = now()
  FROM batch
  WHERE b.id = batch.id;

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN
    RAISE EXCEPTION 'rerun changed % rows', n;
  END IF;
END $$;

DROP TABLE lab_backfill;
\echo '07-backfill checks passed'
