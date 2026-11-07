\set ON_ERROR_STOP on
\echo 'Checking injection and retention...'

DROP FUNCTION IF EXISTS lab_search_unsafe(text);
DROP FUNCTION IF EXISTS lab_search_safe(text);
DROP TABLE IF EXISTS lab_tickets;
DROP TABLE IF EXISTS lab_deletion_log;

CREATE TABLE lab_tickets (
  ticket_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email     text NOT NULL,
  body      text NOT NULL,
  closed_at timestamptz
);

INSERT INTO lab_tickets (email, body, closed_at) VALUES
  ('ada@example.com',   'Refund request',   '2025-12-01 10:00+08'),
  ('grace@example.com', 'Delivery delay',   '2025-12-15 11:00+08'),
  ('alan@example.com',  'Refund request',   '2026-04-01 09:00+08'),
  ('edsger@example.com','Password reset',   '2026-04-10 14:00+08'),
  ('barbara@example.com','Refund request',  NULL);

-- Deliberately unsafe: the term becomes SQL.
CREATE FUNCTION lab_search_unsafe(term text) RETURNS bigint AS $$
DECLARE
  n bigint;
BEGIN
  EXECUTE 'SELECT count(*) FROM lab_tickets WHERE body LIKE ''%' || term || '%''' INTO n;
  RETURN n;
END $$ LANGUAGE plpgsql;

-- Safe: the term is a parameter.
CREATE FUNCTION lab_search_safe(term text) RETURNS bigint AS $$
DECLARE
  n bigint;
BEGIN
  EXECUTE 'SELECT count(*) FROM lab_tickets WHERE body LIKE $1'
  INTO n
  USING '%' || term || '%';
  RETURN n;
END $$ LANGUAGE plpgsql;

DO $$
DECLARE
  n bigint;
BEGIN
  n := lab_search_unsafe('Refund');
  IF n <> 3 THEN
    RAISE EXCEPTION 'unsafe normal search: expected 3, got %', n;
  END IF;

  n := lab_search_unsafe(''' OR true --');
  IF n <> 5 THEN
    RAISE EXCEPTION 'unsafe injection: expected all 5 rows, got %', n;
  END IF;

  n := lab_search_safe('Refund');
  IF n <> 3 THEN
    RAISE EXCEPTION 'safe normal search: expected 3, got %', n;
  END IF;

  n := lab_search_safe(''' OR true --');
  IF n <> 0 THEN
    RAISE EXCEPTION 'safe injection: expected 0 rows, got %', n;
  END IF;
END $$;

CREATE TABLE lab_deletion_log (
  run_at        timestamptz NOT NULL DEFAULT now(),
  deleted_count integer NOT NULL
);

DO $$
DECLARE
  n integer;
BEGIN
  DELETE FROM lab_tickets
  WHERE closed_at IS NOT NULL
    AND closed_at < '2026-01-01 00:00+08';

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 2 THEN
    RAISE EXCEPTION 'retention: expected 2 deleted rows, got %', n;
  END IF;

  INSERT INTO lab_deletion_log (deleted_count) VALUES (n);

  SELECT count(*) INTO n FROM lab_tickets WHERE closed_at < '2026-01-01 00:00+08';
  IF n <> 0 THEN
    RAISE EXCEPTION 'retention left % old rows', n;
  END IF;

  SELECT count(*) INTO n FROM lab_tickets;
  IF n <> 3 THEN
    RAISE EXCEPTION 'retention: expected 3 remaining rows, got %', n;
  END IF;

  SELECT deleted_count INTO n FROM lab_deletion_log ORDER BY run_at DESC LIMIT 1;
  IF n <> 2 THEN
    RAISE EXCEPTION 'deletion log: expected 2, got %', n;
  END IF;
END $$;

DROP FUNCTION lab_search_unsafe(text);
DROP FUNCTION lab_search_safe(text);
DROP TABLE lab_tickets;
DROP TABLE lab_deletion_log;

\echo '11-privacy checks passed'
